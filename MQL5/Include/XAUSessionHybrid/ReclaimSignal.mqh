#ifndef XSH_RECLAIM_SIGNAL_MQH
#define XSH_RECLAIM_SIGNAL_MQH

#include <XAUSessionHybrid/Types.mqh>

bool XSH_DetectReclaim(const string symbol,
                       XSH_OpeningRange &or_state,
                       const double body_strength_frac,
                       XSH_Signal &signal)
  {
   signal.valid=false;
   if(!or_state.built) return false;

   double high0[],low0[],open1[],close1[],high1[],low1[];
   if(CopyHigh(symbol,PERIOD_M5,0,1,high0)!=1) return false;
   if(CopyLow(symbol,PERIOD_M5,0,1,low0)!=1) return false;
   if(CopyOpen(symbol,PERIOD_M5,1,1,open1)!=1) return false;
   if(CopyClose(symbol,PERIOD_M5,1,1,close1)!=1) return false;
   if(CopyHigh(symbol,PERIOD_M5,1,1,high1)!=1) return false;
   if(CopyLow(symbol,PERIOD_M5,1,1,low1)!=1) return false;

   if(low0[0]<or_state.low) or_state.sweep_below=true;
   if(high0[0]>or_state.high) or_state.sweep_above=true;

   double o=open1[0],c=close1[0],h=high1[0],l=low1[0];
   double range=(h-l);
   if(range<=0.0) return false;
   double close_pos=(c-l)/range;

   if(or_state.sweep_below && c>or_state.low && close_pos>=body_strength_frac)
     {
      signal.valid=true;
      signal.family=XSH_SIGNAL_RECLAIM;
      signal.direction=XSH_DIR_LONG;
      signal.entry=0.0;
      signal.reason="Sweep below then reclaim";
      return true;
     }

   if(or_state.sweep_above && c<or_state.high && close_pos<=(1.0-body_strength_frac))
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
