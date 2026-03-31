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
#include <XAUSessionHybrid/SessionClassifier.mqh>
#include <XAUSessionHybrid/SetupScorer.mqh>
#include <XAUSessionHybrid/NoTradeFilter.mqh>
#include <XAUSessionHybrid/RiskModel.mqh>
#include <XAUSessionHybrid/ExecutionEngine.mqh>
#include <XAUSessionHybrid/PositionManager.mqh>
#include <XAUSessionHybrid/SessionState.mqh>
#include <XAUSessionHybrid/SetupState.mqh>
#include <XAUSessionHybrid/Diagnostics.mqh>
#include <XAUSessionHybrid/Journal.mqh>
#include <XAUSessionHybrid/ChartPanel.mqh>

string g_symbol="";
XSH_SymbolSpecs g_spec;
XSH_SessionState g_session;
XSH_DailyRiskState g_daily;
XSH_DiagnosticsCounters g_diag;
datetime g_last_bar=0;
int g_last_day_tag=0;
bool g_london_seen_today=false;
bool g_ny_seen_today=false;

const int XSH_MIN_OR_STATS_SESSIONS=3;
const double XSH_MIXED_MODE_STRICT_BONUS=2.0;

bool XSH_IsSupportedGoldSymbol(const string symbol_name)
  {
   string s=symbol_name;
   StringToUpper(s);
   if(StringFind(s,"XAUUSD",0)>=0) return true;
   if(s=="GOLD") return true;
   bool has_xau=(StringFind(s,"XAU",0)>=0);
   bool has_usd=(StringFind(s,"USD",0)>=0);
   if(has_xau && has_usd) return true;
   if(StringFind(s,"GOLD",0)>=0 && has_usd) return true;
   return false;
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

double XSH_MedianFromArray(const double &values[],const int count)
  {
   if(count<=0) return 0.0;
   double sorted[];
   ArrayResize(sorted,count);
   for(int i=0;i<count;i++) sorted[i]=values[i];
   ArraySort(sorted,WHOLE_ARRAY,0,MODE_ASCEND);
   if((count%2)==1) return sorted[count/2];
   return (sorted[count/2-1]+sorted[count/2])*0.5;
  }

bool XSH_ReadRecentSpreadMedian(const string symbol,const int lookback_bars,double &spread_median)
  {
   spread_median=0.0;
   if(lookback_bars<=0) return false;
   int spreads_raw[];
   int copied=CopySpread(symbol,PERIOD_M5,1,lookback_bars,spreads_raw);
   if(copied<=0) return false;
   double spreads[];
   ArrayResize(spreads,copied);
   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   if(point<=0.0) point=1.0;
   for(int i=0;i<copied;i++) spreads[i]=(double)spreads_raw[i]*point;
   spread_median=XSH_MedianFromArray(spreads,copied);
   return (spread_median>0.0);
  }

bool XSH_ReadSessionORStats(const string symbol,
                            const datetime now,
                            const XSH_SessionType session,
                            const int lookback_sessions,
                            double &or_avg,
                            double &or_median)
  {
   or_avg=0.0;
   or_median=0.0;
   if(lookback_sessions<=0 || session==XSH_SESSION_NONE) return false;

   int range_minutes=(session==XSH_SESSION_LONDON?InpLondonRangeMinutes:InpNYRangeMinutes);
   int start_hour=(session==XSH_SESSION_LONDON?InpLondonStartHour:InpNYStartHour);
   int start_min=(session==XSH_SESSION_LONDON?InpLondonStartMinute:InpNYStartMinute);
   int bars=MathMax(1,range_minutes/5);

   double ranges[];
   int found=0;
   ArrayResize(ranges,lookback_sessions);
   for(int d=1;d<=lookback_sessions*2 && found<lookback_sessions;d++)
     {
      datetime day_ref=now-(datetime)(d*86400);
      datetime session_start=XSH_DayMinuteToTime(day_ref,start_hour,start_min);
      int shift=iBarShift(symbol,PERIOD_M5,session_start,false);
      if(shift<0) continue;
      if(shift<bars-1) continue;
      double hh=iHigh(symbol,PERIOD_M5,shift),ll=iLow(symbol,PERIOD_M5,shift);
      if(hh<=0.0 || ll<=0.0) continue;
      bool valid=true;
      for(int i=1;i<bars;i++)
        {
         int idx=shift-i;
         if(idx<0)
           {
            valid=false;
            break;
           }
         double h=iHigh(symbol,PERIOD_M5,idx);
         double l=iLow(symbol,PERIOD_M5,idx);
         if(h<=0.0 || l<=0.0)
           {
            valid=false;
            break;
           }
         if(h>hh) hh=h;
         if(l<ll) ll=l;
        }
      if(!valid) continue;
      double range=hh-ll;
      if(range<=0.0) continue;
      ranges[found]=range;
      found++;
     }

   if(found<XSH_MIN_OR_STATS_SESSIONS) return false;
   double sum=0.0;
   for(int i=0;i<found;i++) sum+=ranges[i];
   or_avg=sum/found;
   or_median=XSH_MedianFromArray(ranges,found);
   return (or_avg>0.0 && or_median>0.0);
  }

bool XSH_IsRegimeFamilyScoreAllowed(const XSH_SessionRegime regime,
                                    const XSH_SignalFamily family,
                                    const double score_total,
                                    const double min_setup_score,
                                    const double mixed_mode_score_threshold,
                                    const double conflict_override_threshold,
                                    const bool allow_mixed_regime_signals,
                                    string &reason)
  {
   reason="";
   if(regime==XSH_REGIME_NO_TRADE)
     {
      reason="Classifier regime=NO_TRADE";
      return false;
     }
   if(regime==XSH_REGIME_MIXED)
     {
      double mixed_threshold=mixed_mode_score_threshold;
      if(!allow_mixed_regime_signals)
         mixed_threshold=MathMax(mixed_threshold,min_setup_score+XSH_MIXED_MODE_STRICT_BONUS);
      if(score_total>=mixed_threshold) return true;
      reason=StringFormat("Signal/regime mixed requires higher score: total=%.1f threshold=%.1f",score_total,mixed_threshold);
      return false;
     }
   if(regime==XSH_REGIME_CONTINUATION_FAVOR && family==XSH_SIGNAL_BREAKOUT) return true;
   if(regime==XSH_REGIME_REVERSAL_FAVOR && family==XSH_SIGNAL_RECLAIM) return true;
   if(score_total>=conflict_override_threshold) return true;
   reason=StringFormat("Signal family conflicts with session classifier regime: total=%.1f override=%.1f",score_total,conflict_override_threshold);
   return false;
  }

void XSH_RecordSessionBlock(const XSH_SessionType session,const string reason)
  {
   XSH_SetSessionBlocker(g_session,session,reason);
   XSH_CountBlockReason(g_diag,reason);
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

bool XSH_PreTradeFilters(const XSH_SessionType session,
                         const XSH_OpeningRange &or_state,
                         double &atr_m5,
                         double &atr_m15,
                         double &recent_spread_median,
                         string &reason)
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
    recent_spread_median=0.0;
    XSH_ReadRecentSpreadMedian(g_symbol,InpSpreadStatsLookbackBars,recent_spread_median);
    if(atr_m5>0.0)
      {
       double spread_atr_ratio=spread/atr_m5;
       double spread_median_ratio=(recent_spread_median>0.0?spread/recent_spread_median:0.0);
       if(spread_atr_ratio>InpMaxSpreadATRFrac &&
          (recent_spread_median<=0.0 || spread_median_ratio>InpSpreadMedianMultThreshold))
         {
          reason=StringFormat("Spread too high: spread=%.2f atr=%.2f ratio=%.4f median=%.2f median_ratio=%.2f thr=%.4f/%.2f",
                              spread,atr_m5,spread_atr_ratio,recent_spread_median,spread_median_ratio,InpMaxSpreadATRFrac,InpSpreadMedianMultThreshold);
          return false;
         }
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

    double or_atr_ratio=(atr_m15>0.0?or_range/atr_m15:0.0);
    double or_avg=0.0,or_median=0.0;
    bool have_or_stats=XSH_ReadSessionORStats(g_symbol,TimeCurrent(),session,InpORStatsLookbackSessions,or_avg,or_median);
    double or_vs_recent=(have_or_stats && or_median>0.0?or_range/or_median:0.0);
    bool atr_extreme=(atr_m15>0.0 && or_atr_ratio>InpMaxRangeATRFrac);
    bool recent_extreme=(have_or_stats && or_vs_recent>InpORStatsExtremeFrac);
    if(atr_extreme && recent_extreme)
      {
       reason=StringFormat("OR too wide: width=%.2f atr=%.2f ratio=%.4f recent_avg=%.2f recent_med=%.2f recent_ratio=%.2f thr=%.4f/%.2f",
                           or_range,atr_m15,or_atr_ratio,or_avg,or_median,or_vs_recent,InpMaxRangeATRFrac,InpORStatsExtremeFrac);
       return false;
      }

   return true;
  }

int XSH_SessionMinutesLeft(const datetime now,const XSH_SessionType session,const datetime london_start,const datetime ny_start)
  {
   if(session==XSH_SESSION_LONDON)
     {
      datetime end=london_start+InpLondonTradeMinutes*60;
      return (int)MathMax(0,(end-now)/60);
     }
   if(session==XSH_SESSION_NEWYORK)
     {
      datetime end=ny_start+InpNYTradeMinutes*60;
      return (int)MathMax(0,(end-now)/60);
     }
   return 0;
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
   string chart_symbol=_Symbol;
   g_symbol=(StringLen(InpSymbol)>0?InpSymbol:chart_symbol);
   PrintFormat("Chart symbol = %s",chart_symbol);
   PrintFormat("Resolved trade symbol = %s",g_symbol);

   if(!XSH_IsSupportedGoldSymbol(g_symbol))
      {
      PrintFormat("Unsupported symbol '%s'; expected a gold-vs-USD alias such as XAUUSD or GOLD",g_symbol);
      return(INIT_FAILED);
      }
   Print("Gold symbol validation passed");

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
    XSH_ResetDiagnosticsCounters(g_diag);
    g_london_seen_today=false;
    g_ny_seen_today=false;

   XSH_Log("INFO","XAUSessionHybridEA initialized");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
    XSH_LogDiagnosticsSummary(g_diag);
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
       XSH_LogDiagnosticsSummary(g_diag);
       XSH_ResetDiagnosticsCounters(g_diag);
       XSH_ResetSessionState(g_session);
       g_london_seen_today=false;
       g_ny_seen_today=false;
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

    if(session==XSH_SESSION_LONDON && !g_london_seen_today)
      {
       g_diag.sessions_seen++;
       g_london_seen_today=true;
      }
    if(session==XSH_SESSION_NEWYORK && !g_ny_seen_today)
      {
       g_diag.sessions_seen++;
       g_ny_seen_today=true;
      }

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
   XSH_SessionRegime panel_regime=XSH_REGIME_NO_TRADE;
   int panel_dir=0;
   double panel_score=0.0;
   string panel_lifecycle=XSH_LifecycleToText(XSH_GetLifecycle(g_session,session));

   if(!XSH_IsNewBar(g_symbol,PERIOD_M5,g_last_bar))
     {
      if(InpEnableChartPanel)
         XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,blocker,spread,session_trades,setup_candidate,panel_dir,panel_score,panel_lifecycle,has_pos);
      return;
     }

   XSH_ManageOpenPosition(g_spec,InpMagic,InpTP1_R,InpTrailATRFrac,InpATRPeriod,InpMoveToBEAfterTP1,InpMaxHoldMinutes,InpMinTrailStepPoints,InpTrailOnlyAfterR,InpUseStructureTrail);
   has_pos=XSH_HasPosition(g_symbol,InpMagic,pos_count);
   if(has_pos)
      XSH_SetLifecycle(g_session,session,XSH_SETUP_POSITION_OPEN);
   else if(XSH_GetLifecycle(g_session,session)==XSH_SETUP_POSITION_OPEN)
     {
      XSH_SetLifecycle(g_session,session,XSH_SETUP_COMPLETED);
      XSH_ClearActiveSetup(g_session,session);
     }

   if(g_session.suspend)
      {
       XSH_SetSessionBlocker(g_session,session,g_session.suspend_reason);
       if(InpEnableChartPanel)
           XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,blocker,spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
       return;
      }
    if(!XSH_CheckDailyGuards(g_daily,InpMaxDailyLossPct,InpMaxTradesPerDay,InpEnableDailyProfitLock,InpDailyProfitLockR,InpRiskPct,InpDailyLossUseEquity))
      {
        blocker=g_daily.block_reason;
        XSH_SetSessionBlocker(g_session,session,blocker);
        if(InpEnableChartPanel)
           XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,blocker,spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
        return;
       }
    if(has_pos || session==XSH_SESSION_NONE || XSH_GetSessionTrades(g_session,session)>=InpMaxTradesPerSession)
      {
        if(has_pos)
           XSH_SetSessionBlocker(g_session,session,"Position already open");
       else if(session==XSH_SESSION_NONE)
          XSH_SetSessionBlocker(g_session,session,"Outside session");
       else
          XSH_SetSessionBlocker(g_session,session,"Max trades per session reached");
        if(InpEnableChartPanel)
           XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,XSH_GetSessionBlocker(g_session,session),spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
        return;
      }

   if((session==XSH_SESSION_LONDON && !XSH_IsInWindow(TimeCurrent(),london_start,InpLondonTradeMinutes)) ||
      (session==XSH_SESSION_NEWYORK && !XSH_IsInWindow(TimeCurrent(),ny_start,InpNYTradeMinutes)))
      {
       XSH_SetSessionBlocker(g_session,session,"Session window expired");
       if(InpEnableChartPanel)
          XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,XSH_GetSessionBlocker(g_session,session),spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
       return;
      }

   if(!has_or || !current_or.built)
      {
       XSH_SetSessionBlocker(g_session,session,"OR not built");
       if(InpEnableChartPanel)
          XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,XSH_GetSessionBlocker(g_session,session),spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
       return;
      }

   double atr_m5=0.0,atr_m15=0.0;
   string reason="";
    double recent_spread_median=0.0;
     if(!XSH_PreTradeFilters(session,current_or,atr_m5,atr_m15,recent_spread_median,reason))
      {
        XSH_Log("INFO",StringFormat("No trade: %s",reason));
        XSH_RecordSessionBlock(session,reason);
        XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
        return;
      }

   XSH_SessionClassification session_class;
   ZeroMemory(session_class);
   if(!XSH_ClassifySession(g_symbol,current_or,atr_m5,atr_m15,InpBiasEMAPeriod,InpClassifierProbeLookbackBars,InpMaxORProbesBeforeBlock,InpMaxExtensionATRFrac,session_class,reason))
      {
       XSH_RecordSessionBlock(session,reason);
       XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
       XSH_Log("INFO",StringFormat("No trade: classifier unavailable (%s)",reason));
       return;
     }
   panel_regime=session_class.regime;

   XSH_Signal reclaim_sig;
   XSH_Signal breakout_sig;
   ZeroMemory(reclaim_sig);
   ZeroMemory(breakout_sig);

   bool has_reclaim=XSH_DetectReclaim(g_symbol,current_or,atr_m5,spread,InpReclaimMinSweepATRFrac,InpReclaimMinSweepSpreadMult,InpReclaimCloseBackATRFrac,InpReclaimBodyStrengthFrac,InpReclaimMaxCounterWickFrac,InpReclaimMaxBarsAfterSweep,reclaim_sig);
   bool has_breakout=XSH_DetectBreakout(g_symbol,current_or,atr_m5,InpBreakoutBufferATRFrac,InpBreakoutMinBodyRangeFrac,InpBreakoutMinBodyATRFrac,InpBreakoutMaxCounterWickFrac,InpMaxBreakoutATRFrac,breakout_sig);
   if(has_breakout)
      has_breakout=XSH_BreakoutRetestPassed(g_symbol,current_or,breakout_sig.direction,atr_m5,InpUseBreakoutRetest,InpBreakoutRetestMaxBars,InpBreakoutRetestToleranceATRFrac);
   if(has_reclaim) setup_candidate=(reclaim_sig.direction==XSH_DIR_LONG?"RECLAIM_LONG":"RECLAIM_SHORT");
   else if(has_breakout) setup_candidate=(breakout_sig.direction==XSH_DIR_LONG?"BREAKOUT_LONG":"BREAKOUT_SHORT");

   XSH_Signal raw_sig;
   ZeroMemory(raw_sig);
   if(has_reclaim) raw_sig=reclaim_sig;
   else if(has_breakout) raw_sig=breakout_sig;
   else
     {
      XSH_SetLifecycle(g_session,session,XSH_SETUP_WATCHING);
      if(InpEnableChartPanel)
         XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,XSH_GetSessionBlocker(g_session,session),spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
      return;
     }

   raw_sig.session=session;
   panel_dir=(int)raw_sig.direction;

    if(XSH_IsFamilyDirectionUsed(g_session,session,raw_sig.family,raw_sig.direction))
     {
      XSH_SetSessionBlocker(g_session,session,"Family+direction already used");
      XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
      return;
     }

   if(!XSH_SessionDirectionAllowed(g_session,session,raw_sig.direction))
     {
      XSH_SetSessionBlocker(g_session,session,"Opposite direction not allowed this session");
      XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
      return;
     }

   if((raw_sig.direction==XSH_DIR_LONG && !InpEnableLongs) || (raw_sig.direction==XSH_DIR_SHORT && !InpEnableShorts))
     {
      XSH_SetSessionBlocker(g_session,session,"Direction disabled by inputs");
      XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
      return;
     }

   if(InpUseBiasFilter)
     {
       if(!XSH_BiasAllows(g_symbol,InpContextTF,InpBiasEMAPeriod,raw_sig.direction))
         {
          XSH_Log("INFO","Bias filter rejected signal");
          XSH_SetSessionBlocker(g_session,session,"Bias filter rejected signal");
          XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
          return;
         }
      }

   XSH_SetupScore score;
   ZeroMemory(score);
   int mins_left=XSH_SessionMinutesLeft(TimeCurrent(),session,london_start,ny_start);
    if(!XSH_ScoreSetup(g_symbol,current_or,session_class,raw_sig,atr_m5,atr_m15,spread,InpMaxSpreadATRFrac,mins_left,atr_m5*InpStopBufferATRFrac,score,reason))
      {
       XSH_RecordSessionBlock(session,reason);
       XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
       XSH_Log("INFO",StringFormat("No trade: scoring unavailable (%s)",reason));
       return;
      }
    panel_score=score.total;
    XSH_Log("INFO",StringFormat("Score %s family=%d dir=%d [%s]",setup_candidate,(int)raw_sig.family,(int)raw_sig.direction,score.breakdown));

    string regime_reason="";
    if(!XSH_IsRegimeFamilyScoreAllowed(session_class.regime,
                                       raw_sig.family,
                                       score.total,
                                       InpMinSetupScore,
                                       InpMixedModeScoreThreshold,
                                       InpConflictOverrideScoreThreshold,
                                       InpAllowMixedRegimeSignals,
                                       regime_reason))
      {
       XSH_RecordSessionBlock(session,regime_reason);
       XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
       g_diag.setups_scored_rejected++;
       XSH_Log("INFO",StringFormat("No trade: %s",regime_reason));
       if(InpEnableChartPanel)
          XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,regime_reason,spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
       return;
      }

    string block_reason="";
    bool duplicate_active=(XSH_GetLifecycle(g_session,session)==XSH_SETUP_ARMED || XSH_GetLifecycle(g_session,session)==XSH_SETUP_ORDER_ACTIVE);
    if(XSH_ShouldBlockTrade(session_class,score,InpMinSetupScore,mins_left,spread,atr_m5,InpMaxSpreadATRFrac,recent_spread_median,InpSpreadMedianMultThreshold,duplicate_active,block_reason))
      {
       XSH_RecordSessionBlock(session,block_reason);
       XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
       if(score.total<InpMinSetupScore) g_diag.setups_scored_rejected++;
       if(MathAbs(score.total-InpMinSetupScore)<=InpNearThresholdLogBand)
          XSH_Log("INFO",StringFormat("Score rejected near threshold: total=%.1f threshold=%.1f [%s]",score.total,InpMinSetupScore,score.breakdown));
       XSH_Log("INFO",StringFormat("No trade blocked: %s [%s]",block_reason,score.breakdown));
       if(InpEnableChartPanel)
          XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,block_reason,spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),has_pos);
       return;
      }

    g_diag.setups_accepted++;
    XSH_SetLifecycle(g_session,session,XSH_SETUP_ARMED);
   XSH_SetActiveSetup(g_session,session,raw_sig.family,raw_sig.direction,score.total);

   XSH_Signal trade_sig;
   ZeroMemory(trade_sig);
     if(!XSH_BuildTradeFromSignal(raw_sig,current_or,atr_m5,trade_sig,reason))
       {
        XSH_Log("WARN",StringFormat("Trade build failed: %s",reason));
        XSH_RecordSessionBlock(session,reason);
        XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
        return;
       }

   double volume=0.0;
     if(!XSH_CalcVolumeByRisk(g_spec,g_symbol,trade_sig.direction,trade_sig.entry,trade_sig.stop_loss,InpRiskPct,InpAllowMinLotOverride,volume,reason))
         {
          XSH_Log("WARN",StringFormat("Sizing blocked: %s",reason));
          XSH_RecordSessionBlock(session,reason);
          XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
          return;
         }

    string send_reason="";
    XSH_SetLifecycle(g_session,session,XSH_SETUP_ORDER_ACTIVE);
    bool ok=XSH_SendMarketOrder(g_spec,InpMagic,trade_sig.direction,volume,trade_sig.stop_loss,trade_sig.take_profit,InpSlippagePoints,trade_sig.reason,send_reason);
     if(!ok)
       {
        XSH_Log("WARN",StringFormat("Order blocked: %s",send_reason));
        XSH_RecordSessionBlock(session,send_reason);
        XSH_SetLifecycle(g_session,session,XSH_SETUP_INVALIDATED);
        return;
       }

    XSH_IncSessionTrades(g_session,session);
     g_diag.trades_placed++;
     XSH_MarkSessionDirection(g_session,session,trade_sig.direction);
    XSH_MarkFamilyDirectionUsed(g_session,session,trade_sig.family,trade_sig.direction);
    XSH_SetLifecycle(g_session,session,XSH_SETUP_POSITION_OPEN);
    XSH_SetSessionBlocker(g_session,session,"");
    XSH_Log("INFO",StringFormat("Opened %s trade family=%d vol=%.2f",
                                 (trade_sig.direction==XSH_DIR_LONG?"LONG":"SHORT"),(int)trade_sig.family,volume));

     if(InpEnableChartPanel)
       XSH_UpdatePanel(ChartID(),g_symbol,session,panel_regime,current_or,g_daily,g_diag,XSH_GetSessionBlocker(g_session,session),spread,session_trades,setup_candidate,panel_dir,panel_score,XSH_LifecycleToText(XSH_GetLifecycle(g_session,session)),true);
  }
