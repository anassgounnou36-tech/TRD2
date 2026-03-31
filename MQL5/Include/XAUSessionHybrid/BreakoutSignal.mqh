#ifndef XSH_BREAKOUT_SIGNAL_MQH
#define XSH_BREAKOUT_SIGNAL_MQH

#include <XAUSessionHybrid/Types.mqh>

bool XSH_BreakoutRetestPassed(const string symbol,
                              const XSH_OpeningRange &or_state,
                              const XSH_TradeDirection dir,
                              const double atr_m5,
                              const bool use_retest,
                              const int max_retest_bars,
                              const double retest_tolerance_atr_frac)
  {
   if(!use_retest) return true;
   if(!or_state.built || atr_m5<=0.0 || max_retest_bars<1) return false;

   double tol=atr_m5*retest_tolerance_atr_frac;
   double level=(dir==XSH_DIR_LONG?or_state.high:or_state.low);
   for(int i=2;i<=max_retest_bars+1;i++)
     {
      double highs[],lows[],closes[];
      if(CopyHigh(symbol,PERIOD_M5,i,1,highs)!=1) continue;
      if(CopyLow(symbol,PERIOD_M5,i,1,lows)!=1) continue;
      if(CopyClose(symbol,PERIOD_M5,i,1,closes)!=1) continue;
      if(dir==XSH_DIR_LONG)
        {
         bool touched=(lows[0] <= (level+tol));
         bool held=(closes[0] >= level);
         if(touched && held) return true;
        }
      else
        {
         bool touched=(highs[0] >= (level-tol));
         bool held=(closes[0] <= level);
         if(touched && held) return true;
        }
     }
   return false;
  }

bool XSH_DetectBreakout(const string symbol,
                        const XSH_OpeningRange &or_state,
                        const double atr_m5,
                        const double breakout_buffer_atr_frac,
                        const double min_body_range_frac,
                        const double min_body_atr_frac,
                        const double max_counter_wick_frac,
                        const double max_breakout_atr_frac,
                        XSH_Signal &signal)
  {
   signal.valid=false;
   if(!or_state.built || atr_m5<=0.0) return false;

   double open_buf[],close_buf[],high_buf[],low_buf[];
   if(CopyOpen(symbol,PERIOD_M5,1,1,open_buf)!=1) return false;
   if(CopyClose(symbol,PERIOD_M5,1,1,close_buf)!=1) return false;
   if(CopyHigh(symbol,PERIOD_M5,1,1,high_buf)!=1) return false;
   if(CopyLow(symbol,PERIOD_M5,1,1,low_buf)!=1) return false;

   double o=open_buf[0],c=close_buf[0],h=high_buf[0],l=low_buf[0];
   double body=MathAbs(c-o);
   double range=(h-l);
   if(range<=0.0) return false;
   if(body<range*min_body_range_frac) return false;
   if(body<atr_m5*min_body_atr_frac) return false;

   double buffer=atr_m5*breakout_buffer_atr_frac;
   double upper_wick=h-MathMax(o,c);
   double lower_wick=MathMin(o,c)-l;

   if(c>(or_state.high+buffer))
     {
      if(upper_wick>body*max_counter_wick_frac) return false;
      if((c-or_state.high)>atr_m5*max_breakout_atr_frac) return false;
      signal.valid=true;
      signal.family=XSH_SIGNAL_BREAKOUT;
      signal.direction=XSH_DIR_LONG;
      signal.entry=0.0;
      signal.reason="Breakout above OR";
      return true;
     }
   if(c<(or_state.low-buffer))
     {
      if(lower_wick>body*max_counter_wick_frac) return false;
      if((or_state.low-c)>atr_m5*max_breakout_atr_frac) return false;
      signal.valid=true;
      signal.family=XSH_SIGNAL_BREAKOUT;
      signal.direction=XSH_DIR_SHORT;
      signal.entry=0.0;
      signal.reason="Breakout below OR";
      return true;
     }

   return false;
  }

#endif
