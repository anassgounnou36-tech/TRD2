#ifndef XSH_BREAKOUT_SIGNAL_MQH
#define XSH_BREAKOUT_SIGNAL_MQH

#include <XAUSessionHybrid/Types.mqh>

bool XSH_DetectBreakout(const string symbol,
                        const XSH_OpeningRange &or_state,
                        const double atr_m5,
                        const double breakout_buffer_atr_frac,
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
   if(range<=0.0 || body<range*0.3) return false;

   double buffer=atr_m5*breakout_buffer_atr_frac;

   if(c>(or_state.high+buffer))
     {
      signal.valid=true;
      signal.family=XSH_SIGNAL_BREAKOUT;
      signal.direction=XSH_DIR_LONG;
      signal.entry=0.0;
      signal.reason="Breakout above OR";
      return true;
     }
   if(c<(or_state.low-buffer))
     {
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
