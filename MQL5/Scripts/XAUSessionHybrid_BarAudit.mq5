#property script_show_inputs
#property strict

#include <XAUSessionHybrid/Config.mqh>
#include <XAUSessionHybrid/Types.mqh>
#include <XAUSessionHybrid/TimeWindows.mqh>
#include <XAUSessionHybrid/OpeningRangeEngine.mqh>
#include <XAUSessionHybrid/IndicatorEngine.mqh>

input string InpAuditSymbol = "";
input int InpRows = 40;
input int InpStartShift = 1;

bool ShiftBar(const string symbol,const int shift,datetime &t,double &o,double &h,double &l,double &c)
  {
   datetime times[];
   double opens[],highs[],lows[],closes[];
   if(CopyTime(symbol,PERIOD_M5,shift,1,times)!=1) return false;
   if(CopyOpen(symbol,PERIOD_M5,shift,1,opens)!=1) return false;
   if(CopyHigh(symbol,PERIOD_M5,shift,1,highs)!=1) return false;
   if(CopyLow(symbol,PERIOD_M5,shift,1,lows)!=1) return false;
   if(CopyClose(symbol,PERIOD_M5,shift,1,closes)!=1) return false;
   t=times[0]; o=opens[0]; h=highs[0]; l=lows[0]; c=closes[0];
   return true;
  }

bool SweepSeenBeforeShift(const string symbol,const int from_shift,const int to_shift,const double level,const bool below)
  {
   if(to_shift<from_shift) return false;
   for(int s=from_shift;s<=to_shift;s++)
     {
      double h=0.0,l=0.0;
      double highs[],lows[];
      if(CopyHigh(symbol,PERIOD_M5,s,1,highs)!=1) continue;
      if(CopyLow(symbol,PERIOD_M5,s,1,lows)!=1) continue;
      h=highs[0];
      l=lows[0];
      if(below && l<level) return true;
      if(!below && h>level) return true;
     }
   return false;
  }

bool BreakoutAtShift(const string symbol,const int shift,const XSH_OpeningRange &or_state,const double atr_m5,XSH_Signal &sig)
  {
   sig.valid=false;
   if(!or_state.built || atr_m5<=0.0) return false;

   double o=0.0,h=0.0,l=0.0,c=0.0;
   datetime t=0;
   if(!ShiftBar(symbol,shift,t,o,h,l,c)) return false;

   double body=MathAbs(c-o);
   double range=h-l;
   if(range<=0.0 || body<range*0.3) return false;

   double buffer=atr_m5*InpBreakoutBufferATRFrac;
   if(c>(or_state.high+buffer))
     {
      sig.valid=true;
      sig.family=XSH_SIGNAL_BREAKOUT;
      sig.direction=XSH_DIR_LONG;
      return true;
     }
   if(c<(or_state.low-buffer))
     {
      sig.valid=true;
      sig.family=XSH_SIGNAL_BREAKOUT;
      sig.direction=XSH_DIR_SHORT;
      return true;
     }
   return false;
  }

bool ReclaimAtShift(const string symbol,const int shift,const XSH_OpeningRange &or_state,XSH_Signal &sig)
  {
   sig.valid=false;
   if(!or_state.built) return false;
   datetime t=0;
   double o=0.0,h=0.0,l=0.0,c=0.0;
   if(!ShiftBar(symbol,shift,t,o,h,l,c)) return false;

   datetime or_end=or_state.end_time;
   int session_after_or_shift=iBarShift(symbol,PERIOD_M5,or_end,false);
   if(session_after_or_shift<0) return false;
   int sweep_from=shift+1;
   int sweep_to=session_after_or_shift+1;
   bool swept_below=SweepSeenBeforeShift(symbol,sweep_from,sweep_to,or_state.low,true);
   bool swept_above=SweepSeenBeforeShift(symbol,sweep_from,sweep_to,or_state.high,false);

   double range=h-l;
   if(range<=0.0) return false;
   double close_pos=(c-l)/range;

   if(swept_below && c>or_state.low && close_pos>=InpReclaimBodyStrengthFrac)
     {
      sig.valid=true;
      sig.family=XSH_SIGNAL_RECLAIM;
      sig.direction=XSH_DIR_LONG;
      return true;
     }
   if(swept_above && c<or_state.high && close_pos<=(1.0-InpReclaimBodyStrengthFrac))
     {
      sig.valid=true;
      sig.family=XSH_SIGNAL_RECLAIM;
      sig.direction=XSH_DIR_SHORT;
      return true;
     }
   return false;
  }

bool BiasAtShift(const string symbol,const int shift,const XSH_TradeDirection dir)
  {
   double ema_now=0.0,ema_prev=0.0;
   int h=iMA(symbol,InpContextTF,InpBiasEMAPeriod,0,MODE_EMA,PRICE_CLOSE);
   if(h==INVALID_HANDLE) return false;
   double b1[],b2[];
   bool ok1=(CopyBuffer(h,0,shift,1,b1)==1);
   bool ok2=(CopyBuffer(h,0,shift+1,1,b2)==1);
   IndicatorRelease(h);
   if(!ok1 || !ok2) return false;
   ema_now=b1[0];
   ema_prev=b2[0];

   double close_buf[];
   if(CopyClose(symbol,InpContextTF,shift,1,close_buf)!=1) return false;
   double close_p=close_buf[0];
   if(dir==XSH_DIR_LONG) return (close_p>ema_now && ema_now>=ema_prev);
   if(dir==XSH_DIR_SHORT) return (close_p<ema_now && ema_now<=ema_prev);
   return false;
  }

void OnStart()
  {
   string symbol=(StringLen(InpAuditSymbol)>0?InpAuditSymbol:(StringLen(InpSymbol)>0?InpSymbol:_Symbol));
   PrintFormat("BarAudit symbol=%s rows=%d start_shift=%d",symbol,InpRows,InpStartShift);

   for(int i=0;i<InpRows;i++)
     {
      int shift=InpStartShift+i;
      datetime t=0;
      double o=0.0,h=0.0,l=0.0,c=0.0;
      if(!ShiftBar(symbol,shift,t,o,h,l,c))
        {
         PrintFormat("shift=%d unavailable",shift);
         continue;
        }

      XSH_SessionType session=XSH_GetCurrentSession(t,
                                                    InpLondonStartHour,InpLondonStartMinute,InpLondonTradeMinutes,
                                                    InpNYStartHour,InpNYStartMinute,InpNYTradeMinutes);
      datetime london_start=XSH_DayMinuteToTime(t,InpLondonStartHour,InpLondonStartMinute);
      datetime ny_start=XSH_DayMinuteToTime(t,InpNYStartHour,InpNYStartMinute);
      datetime session_start=(session==XSH_SESSION_LONDON?london_start:ny_start);

      XSH_OpeningRange or_state;
      ZeroMemory(or_state);
      if(session!=XSH_SESSION_NONE)
         XSH_BuildOpeningRange(symbol,PERIOD_M5,t,session_start,(session==XSH_SESSION_LONDON?InpLondonRangeMinutes:InpNYRangeMinutes),or_state);

      double atr5=0.0;
      XSH_ReadATR(symbol,PERIOD_M5,InpATRPeriod,shift,atr5);

      XSH_Signal bsig;
      XSH_Signal rsig;
      ZeroMemory(bsig);
      ZeroMemory(rsig);
      bool breakout=(session!=XSH_SESSION_NONE && or_state.built && BreakoutAtShift(symbol,shift,or_state,atr5,bsig));
      bool reclaim=(session!=XSH_SESSION_NONE && or_state.built && ReclaimAtShift(symbol,shift,or_state,rsig));
      bool bias_long=BiasAtShift(symbol,shift,XSH_DIR_LONG);
      bool bias_short=BiasAtShift(symbol,shift,XSH_DIR_SHORT);

      string sess="NONE";
      if(session==XSH_SESSION_LONDON) sess="LONDON";
      else if(session==XSH_SESSION_NEWYORK) sess="NEWYORK";

      string blocker="NONE";
      if(session==XSH_SESSION_NONE) blocker="outside-session";
      else if(!or_state.built) blocker="or-not-built";

      PrintFormat("shift=%d time=%s session=%s OR=%.2f/%.2f ORBuilt=%s breakout=%s reclaim=%s biasL=%s biasS=%s blocker=%s O=%.2f H=%.2f L=%.2f C=%.2f",
                  shift,TimeToString(t,TIME_DATE|TIME_MINUTES),sess,or_state.high,or_state.low,(or_state.built?"Y":"N"),
                  (breakout?"Y":"N"),(reclaim?"Y":"N"),(bias_long?"Y":"N"),(bias_short?"Y":"N"),blocker,o,h,l,c);
     }
  }
