#property strict
#property version   "1.00"
#property description "XAU Session Hybrid EA"

#include <XAUSessionHybrid/Config.mqh>
#include <XAUSessionHybrid/Types.mqh>
#include <XAUSessionHybrid/SymbolSpecs.mqh>
#include <XAUSessionHybrid/TimeWindows.mqh>
#include <XAUSessionHybrid/BarUtils.mqh>
#include <XAUSessionHybrid/IndicatorEngine.mqh>
#include <XAUSessionHybrid/OpeningRangeEngine.mqh>
#include <XAUSessionHybrid/BiasFilter.mqh>
#include <XAUSessionHybrid/BreakoutSignal.mqh>
#include <XAUSessionHybrid/ReclaimSignal.mqh>
#include <XAUSessionHybrid/RiskModel.mqh>
#include <XAUSessionHybrid/ExecutionEngine.mqh>
#include <XAUSessionHybrid/PositionManager.mqh>
#include <XAUSessionHybrid/SessionState.mqh>
#include <XAUSessionHybrid/Diagnostics.mqh>
#include <XAUSessionHybrid/Journal.mqh>
#include <XAUSessionHybrid/ChartPanel.mqh>

string g_symbol="";
XSH_SymbolSpecs g_spec;
XSH_SessionState g_session;
XSH_DailyRiskState g_daily;
datetime g_last_bar=0;
int g_last_day_tag=0;

bool XSH_IsXAU(const string symbol)
  {
   string s=symbol;
   StringToUpper(s);
   return (StringFind(s,"XAUUSD",0)==0);
  }

bool XSH_ParseHHMM(const string hhmm,int &hour,int &minute)
  {
   string parts[];
   if(StringSplit(hhmm,':',parts)!=2) return false;
   hour=(int)StringToInteger(parts[0]);
   minute=(int)StringToInteger(parts[1]);
   if(hour<0 || hour>23 || minute<0 || minute>59) return false;
   return true;
  }

bool XSH_IsInManualBlock(const datetime now,const string blocks)
  {
   if(!InpUseNewsBlockWindows || StringLen(blocks)==0) return false;
   string windows[];
   int n=StringSplit(blocks,';',windows);
   if(n<=0) return false;

   MqlDateTime dt;
   TimeToStruct(now,dt);
   int now_min=dt.hour*60+dt.min;

   for(int i=0;i<n;i++)
     {
      string pair[];
      if(StringSplit(windows[i],'-',pair)!=2) continue;
      int sh=0,sm=0,eh=0,em=0;
      if(!XSH_ParseHHMM(pair[0],sh,sm)) continue;
      if(!XSH_ParseHHMM(pair[1],eh,em)) continue;
      int smin=sh*60+sm;
      int emin=eh*60+em;
      if(now_min>=smin && now_min<emin) return true;
     }
   return false;
  }

bool XSH_GetBidAsk(double &bid,double &ask)
  {
   MqlTick tick;
   if(!SymbolInfoTick(g_symbol,tick)) return false;
   bid=tick.bid;
   ask=tick.ask;
   return (bid>0.0 && ask>0.0 && ask>bid);
  }

bool XSH_ValidateStops(const XSH_TradeDirection dir,const double entry,const double sl,const double tp,string &reason)
  {
   reason="";
   double min_dist=g_spec.point*MathMax(1,g_spec.stops_level_points);
   double dist_sl=MathAbs(entry-sl);
   if(dist_sl<min_dist)
     {
      reason="SL violates stops level";
      return false;
     }

   if(tp>0.0)
     {
      double dist_tp=MathAbs(tp-entry);
      if(dist_tp<min_dist)
        {
         reason="TP violates stops level";
         return false;
        }
     }

   if(dir==XSH_DIR_LONG && !(sl<entry && tp>entry))
     {
      reason="Long SL/TP invalid";
      return false;
     }
   if(dir==XSH_DIR_SHORT && !(sl>entry && tp<entry))
     {
      reason="Short SL/TP invalid";
      return false;
     }

   return true;
  }

bool XSH_PreTradeFilters(const XSH_SessionType session,const XSH_OpeningRange &or_state,double &atr_m5,double &atr_m15,string &reason)
  {
   reason="";
   if(session==XSH_SESSION_NONE)
     {
      reason="Outside session window";
      return false;
     }

   if(!or_state.built)
     {
      reason="Opening range not built";
      return false;
     }

   if(XSH_IsInManualBlock(TimeCurrent(),InpManualBlockWindows))
     {
      reason="Manual block window active";
      return false;
     }

   if(!XSH_ReadATR(g_symbol,PERIOD_M5,InpATRPeriod,1,atr_m5) || !XSH_ReadATR(g_symbol,InpContextTF,InpATRPeriod,1,atr_m15))
     {
      reason="ATR unavailable";
      return false;
     }

   if(g_spec.trade_mode==SYMBOL_TRADE_MODE_DISABLED || g_spec.execution_mode==SYMBOL_TRADE_EXECUTION_EXCHANGE)
     {
      reason="Trading environment not ready";
      return false;
     }

   double bid=0.0,ask=0.0;
   if(!XSH_GetBidAsk(bid,ask))
     {
      reason="No valid tick";
      return false;
     }

   double spread=ask-bid;
   if(atr_m5>0.0 && spread>atr_m5*InpMaxSpreadATRFrac)
     {
      reason="Spread too high";
      return false;
     }

   double or_range=or_state.high-or_state.low;
   if(or_range<=0.0)
     {
      reason="OR range invalid";
      return false;
     }

   if(or_range<MathMax(InpMinRangeSpreadMult*spread,InpMinRangeATRFrac*atr_m15))
     {
      reason="OR too narrow";
      return false;
     }

   if(or_range>InpMaxRangeATRFrac*atr_m15)
     {
      reason="OR too wide";
      return false;
     }

   return true;
  }

bool XSH_BuildTradeFromSignal(const XSH_Signal &sig,const XSH_OpeningRange &or_state,const double atr_m5,XSH_Signal &trade_sig,string &reason)
  {
   reason="";
   trade_sig=sig;

   double bid=0.0,ask=0.0;
   if(!XSH_GetBidAsk(bid,ask))
     {
      reason="No tick for entry";
      return false;
     }

   double entry=(sig.direction==XSH_DIR_LONG?ask:bid);
   double buffer=atr_m5*InpStopBufferATRFrac;

   double sl=0.0;
   if(sig.family==XSH_SIGNAL_BREAKOUT)
     {
      double candle_low[],candle_high[];
      if(CopyLow(g_symbol,PERIOD_M5,1,1,candle_low)!=1 || CopyHigh(g_symbol,PERIOD_M5,1,1,candle_high)!=1)
        {
         reason="No candle data for stop";
         return false;
        }
      if(sig.direction==XSH_DIR_LONG)
         sl=MathMin(or_state.high,candle_low[0])-buffer;
      else
         sl=MathMax(or_state.low,candle_high[0])+buffer;
     }
   else
     {
      double low_recent=XSH_LowestLow(g_symbol,PERIOD_M5,1,3);
      double high_recent=XSH_HighestHigh(g_symbol,PERIOD_M5,1,3);
      if(sig.direction==XSH_DIR_LONG) sl=low_recent-buffer;
      else sl=high_recent+buffer;
     }

   double risk=MathAbs(entry-sl);
   if(risk<=0.0)
     {
      reason="Risk distance invalid";
      return false;
     }

   double tp=(sig.direction==XSH_DIR_LONG?entry+risk*InpTP2_R:entry-risk*InpTP2_R);

   if(!XSH_ValidateStops(sig.direction,entry,sl,tp,reason))
      return false;

   trade_sig.entry=entry;
   trade_sig.stop_loss=sl;
   trade_sig.take_profit=tp;
   trade_sig.risk_per_lot=risk;
   return true;
  }

int OnInit()
  {
   g_symbol=(StringLen(InpSymbol)>0?InpSymbol:_Symbol);

   if(!XSH_IsXAU(g_symbol))
     {
      Print("Only XAUUSD symbols are supported");
      return(INIT_FAILED);
     }

   if(InpSignalTF!=PERIOD_M5 || InpContextTF!=PERIOD_M15)
      Print("WARN strategy is designed for M5 signal and M15 context");

   XSH_JournalInit(InpEnableFileLogs);

   if(!XSH_LoadSymbolSpecs(g_symbol,g_spec))
     {
      XSH_Log("ERROR","Symbol specs invalid");
      return(INIT_FAILED);
     }

   XSH_ResetSessionState(g_session);
   g_daily.day_tag=0;
   XSH_ResetDailyStateIfNeeded(g_daily,TimeCurrent());
   g_last_day_tag=g_daily.day_tag;

   XSH_Log("INFO","XAUSessionHybridEA initialized");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   Comment("");
   XSH_JournalDone();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD) return;
   if(trans.symbol!=g_symbol) return;

   ulong deal=trans.deal;
   if(deal==0) return;
   if(!HistoryDealSelect(deal)) return;
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
   if((ulong)magic!=InpMagic) return;

   long entry_type=HistoryDealGetInteger(deal,DEAL_ENTRY);
   if(entry_type==DEAL_ENTRY_IN)
      g_daily.trades_today++;

   if(entry_type==DEAL_ENTRY_OUT)
     {
      double profit=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_SWAP)+HistoryDealGetDouble(deal,DEAL_COMMISSION);
      if(profit<0.0) g_daily.losses_today++;
     }
  }

void OnTick()
  {
   XSH_ResetDailyStateIfNeeded(g_daily,TimeCurrent());
   if(g_daily.day_tag!=g_last_day_tag)
     {
      XSH_ResetSessionState(g_session);
      g_last_day_tag=g_daily.day_tag;
     }

   int pos_count=0;
   bool has_pos=XSH_HasPosition(g_symbol,InpMagic,pos_count);
   if(pos_count>1)
     {
      g_session.suspend=true;
      g_session.suspend_reason="FATAL integrity: duplicate positions";
      XSH_PrintBlocker("Integrity",g_session.suspend_reason);
     }

   XSH_SessionType session=XSH_GetCurrentSession(TimeCurrent(),
                                                 InpLondonStartHour,InpLondonStartMinute,InpLondonTradeMinutes,
                                                 InpNYStartHour,InpNYStartMinute,InpNYTradeMinutes);

   datetime london_start=XSH_DayMinuteToTime(TimeCurrent(),InpLondonStartHour,InpLondonStartMinute);
   datetime ny_start=XSH_DayMinuteToTime(TimeCurrent(),InpNYStartHour,InpNYStartMinute);

   if(session==XSH_SESSION_NONE && InpFlattenAtSessionEnd)
      XSH_FlattenAtSessionEnd(g_spec,InpMagic);

   XSH_OpeningRange current_or;
   ZeroMemory(current_or);
   bool has_or=false;
   if(session!=XSH_SESSION_NONE)
      {
       if(session==XSH_SESSION_LONDON)
         {
          current_or=g_session.london_or;
          has_or=true;
         }
       else if(session==XSH_SESSION_NEWYORK)
         {
          current_or=g_session.ny_or;
          has_or=true;
         }
       datetime start=(session==XSH_SESSION_LONDON?london_start:ny_start);
       XSH_BuildOpeningRange(g_symbol,PERIOD_M5,TimeCurrent(),start,session==XSH_SESSION_LONDON?InpLondonRangeMinutes:InpNYRangeMinutes,current_or);
       if(session==XSH_SESSION_LONDON)
          g_session.london_or=current_or;
       else if(session==XSH_SESSION_NEWYORK)
          g_session.ny_or=current_or;
      }

   string blocker="";
   if(g_session.suspend) blocker=g_session.suspend_reason;
   else if(g_daily.blocked) blocker=g_daily.block_reason;

   double bid=0.0,ask=0.0;
   XSH_GetBidAsk(bid,ask);
   double spread=(ask>bid?ask-bid:0.0);
   int session_trades=XSH_GetSessionTrades(g_session,session);
   string setup_candidate="NONE";

   XSH_ManageOpenPosition(g_spec,InpMagic,InpTP1_R,InpTrailATRFrac,InpATRPeriod,InpMoveToBEAfterTP1,InpMaxHoldMinutes);
   has_pos=XSH_HasPosition(g_symbol,InpMagic,pos_count);

   if(!XSH_IsNewBar(g_symbol,PERIOD_M5,g_last_bar)) return;

   if(g_session.suspend)
     {
      if(InpEnableChartPanel)
         XSH_UpdatePanel(ChartID(),g_symbol,session,current_or,g_daily,blocker,spread,session_trades,setup_candidate,has_pos);
      return;
     }
   if(!XSH_CheckDailyGuards(g_daily,InpMaxDailyLossPct,InpMaxTradesPerDay,InpEnableDailyProfitLock,InpDailyProfitLockR,InpRiskPct,InpDailyLossUseEquity))
     {
       blocker=g_daily.block_reason;
       if(InpEnableChartPanel)
         XSH_UpdatePanel(ChartID(),g_symbol,session,current_or,g_daily,blocker,spread,session_trades,setup_candidate,has_pos);
       return;
      }
   if(has_pos || session==XSH_SESSION_NONE || XSH_GetSessionTrades(g_session,session)>=InpMaxTradesPerSession)
     {
      if(InpEnableChartPanel)
         XSH_UpdatePanel(ChartID(),g_symbol,session,current_or,g_daily,blocker,spread,session_trades,setup_candidate,has_pos);
      return;
     }

   if((session==XSH_SESSION_LONDON && !XSH_IsInWindow(TimeCurrent(),london_start,InpLondonTradeMinutes)) ||
      (session==XSH_SESSION_NEWYORK && !XSH_IsInWindow(TimeCurrent(),ny_start,InpNYTradeMinutes)))
     {
      if(InpEnableChartPanel)
         XSH_UpdatePanel(ChartID(),g_symbol,session,current_or,g_daily,blocker,spread,session_trades,setup_candidate,has_pos);
      return;
     }

   if(!has_or || !current_or.built)
     {
      if(InpEnableChartPanel)
         XSH_UpdatePanel(ChartID(),g_symbol,session,current_or,g_daily,blocker,spread,session_trades,setup_candidate,has_pos);
      return;
     }

   double atr_m5=0.0,atr_m15=0.0;
   string reason="";
   if(!XSH_PreTradeFilters(session,current_or,atr_m5,atr_m15,reason))
     {
      XSH_Log("INFO",StringFormat("No trade: %s",reason));
      return;
     }

   XSH_Signal reclaim_sig;
   XSH_Signal breakout_sig;
   ZeroMemory(reclaim_sig);
   ZeroMemory(breakout_sig);

   bool has_reclaim=XSH_DetectReclaim(g_symbol,current_or,InpReclaimBodyStrengthFrac,reclaim_sig);
   bool has_breakout=XSH_DetectBreakout(g_symbol,current_or,atr_m5,InpBreakoutBufferATRFrac,breakout_sig);
   if(has_reclaim) setup_candidate=(reclaim_sig.direction==XSH_DIR_LONG?"RECLAIM_LONG":"RECLAIM_SHORT");
   else if(has_breakout) setup_candidate=(breakout_sig.direction==XSH_DIR_LONG?"BREAKOUT_LONG":"BREAKOUT_SHORT");

   if(InpEnableChartPanel)
      XSH_UpdatePanel(ChartID(),g_symbol,session,current_or,g_daily,blocker,spread,session_trades,setup_candidate,has_pos);

   XSH_Signal raw_sig;
   ZeroMemory(raw_sig);
   if(has_reclaim) raw_sig=reclaim_sig;
   else if(has_breakout) raw_sig=breakout_sig;
   else return;

   raw_sig.session=session;

   if(XSH_IsFamilyDirectionUsed(g_session,session,raw_sig.family,raw_sig.direction))
      return;

   if(!XSH_SessionDirectionAllowed(g_session,session,raw_sig.direction))
      return;

   if((raw_sig.direction==XSH_DIR_LONG && !InpEnableLongs) || (raw_sig.direction==XSH_DIR_SHORT && !InpEnableShorts))
      return;

   if(InpUseBiasFilter)
     {
      if(!XSH_BiasAllows(g_symbol,InpContextTF,InpBiasEMAPeriod,raw_sig.direction))
        {
         XSH_Log("INFO","Bias filter rejected signal");
         return;
        }
     }

   XSH_Signal trade_sig;
   ZeroMemory(trade_sig);
   if(!XSH_BuildTradeFromSignal(raw_sig,current_or,atr_m5,trade_sig,reason))
     {
      XSH_Log("WARN",StringFormat("Trade build failed: %s",reason));
      return;
     }

   double volume=0.0;
   if(!XSH_CalcVolumeByRisk(g_spec,g_symbol,trade_sig.direction,trade_sig.entry,trade_sig.stop_loss,InpRiskPct,InpAllowMinLotOverride,volume,reason))
       {
        XSH_Log("WARN",StringFormat("Sizing blocked: %s",reason));
        return;
       }

   string send_reason="";
   bool ok=XSH_SendMarketOrder(g_spec,InpMagic,trade_sig.direction,volume,trade_sig.stop_loss,trade_sig.take_profit,InpSlippagePoints,trade_sig.reason,send_reason);
   if(!ok)
     {
      XSH_Log("WARN",StringFormat("Order blocked: %s",send_reason));
      return;
     }

   XSH_IncSessionTrades(g_session,session);
   XSH_MarkSessionDirection(g_session,session,trade_sig.direction);
   XSH_MarkFamilyDirectionUsed(g_session,session,trade_sig.family,trade_sig.direction);
   XSH_Log("INFO",StringFormat("Opened %s trade family=%d vol=%.2f",
                                (trade_sig.direction==XSH_DIR_LONG?"LONG":"SHORT"),(int)trade_sig.family,volume));
  }
