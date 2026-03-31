#ifndef XSH_RECLAIM_SIGNAL_MQH
#define XSH_RECLAIM_SIGNAL_MQH

#include <XAUSessionHybrid/Types.mqh>

bool XSH_DetectReclaim(const string symbol,
                       XSH_OpeningRange &or_state,
                       const double atr_m5,
                       const double spread,
                       const double min_sweep_atr_frac,
                       const double min_sweep_spread_mult,
                       const double close_back_atr_frac,
                       const double body_strength_frac,
                       const double max_counter_wick_frac,
                       const int max_bars_after_sweep,
                       XSH_Signal &signal)
  {
   signal.valid=false;
   if(!or_state.built || atr_m5<=0.0) return false;

   int bars=MathMax(2,max_bars_after_sweep+2);
   double open1[],close1[],high1[],low1[];
   if(CopyOpen(symbol,PERIOD_M5,1,1,open1)!=1) return false;
   if(CopyClose(symbol,PERIOD_M5,1,1,close1)!=1) return false;
   if(CopyHigh(symbol,PERIOD_M5,1,1,high1)!=1) return false;
   if(CopyLow(symbol,PERIOD_M5,1,1,low1)!=1) return false;

   double o=open1[0],c=close1[0],h=high1[0],l=low1[0];
   if(l<or_state.low && (or_state.low-l)>=MathMax(atr_m5*min_sweep_atr_frac,spread*min_sweep_spread_mult)) or_state.sweep_below=true;
   if(h>or_state.high && (h-or_state.high)>=MathMax(atr_m5*min_sweep_atr_frac,spread*min_sweep_spread_mult)) or_state.sweep_above=true;

   double range=(h-l);
   if(range<=0.0) return false;
   double close_pos=(c-l)/range;
   double body=MathAbs(c-o);
   double upper_wick=h-MathMax(o,c);
   double lower_wick=MathMin(o,c)-l;

   int bars_since_sweep_below=9999;
   int bars_since_sweep_above=9999;
   for(int shift=2;shift<=bars;shift++)
     {
      double hi_buf[],lo_buf[];
      if(CopyHigh(symbol,PERIOD_M5,shift,1,hi_buf)!=1 || CopyLow(symbol,PERIOD_M5,shift,1,lo_buf)!=1) continue;
      if(lo_buf[0]<or_state.low && bars_since_sweep_below==9999) bars_since_sweep_below=shift-1;
      if(hi_buf[0]>or_state.high && bars_since_sweep_above==9999) bars_since_sweep_above=shift-1;
     }

   if(or_state.sweep_below &&
      bars_since_sweep_below<=max_bars_after_sweep &&
      c>(or_state.low+atr_m5*close_back_atr_frac) &&
      close_pos>=body_strength_frac &&
      lower_wick<=body*max_counter_wick_frac)
     {
      signal.valid=true;
      signal.family=XSH_SIGNAL_RECLAIM;
      signal.direction=XSH_DIR_LONG;
      signal.entry=0.0;
      signal.reason="Sweep below then reclaim";
      return true;
     }

   if(or_state.sweep_above &&
      bars_since_sweep_above<=max_bars_after_sweep &&
      c<(or_state.high-atr_m5*close_back_atr_frac) &&
      close_pos<=(1.0-body_strength_frac) &&
      upper_wick<=body*max_counter_wick_frac)
     {
      signal.valid=true;
      signal.family=XSH_SIGNAL_RECLAIM;
      signal.direction=XSH_DIR_SHORT;
      signal.entry=0.0;
      signal.reason="Sweep above then reclaim";
      return true;
     }

   return false;
  }

#endif
