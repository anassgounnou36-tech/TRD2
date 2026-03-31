#ifndef XSH_SESSION_CLASSIFIER_MQH
#define XSH_SESSION_CLASSIFIER_MQH

#include <XAUSessionHybrid/Types.mqh>
#include <XAUSessionHybrid/IndicatorEngine.mqh>

const double XSH_CLASSIFIER_IMPULSE_ATR_NORM=2.0;
const double XSH_CLASSIFIER_DIR_BONUS=0.5;
const double XSH_CLASSIFIER_OR_MIN=0.25;
const double XSH_CLASSIFIER_OR_MAX=1.35;
const double XSH_CLASSIFIER_IMPULSE_MIN=0.70;

bool XSH_ReadSessionProbeStats(const string symbol,
                               const XSH_OpeningRange &or_state,
                               const int lookback_bars,
                               int &probes_above,
                               int &probes_below,
                               bool &both_sides_swept)
  {
   probes_above=0;
   probes_below=0;
   both_sides_swept=false;
   if(!or_state.built || lookback_bars<1) return false;

   double highs[],lows[];
   if(CopyHigh(symbol,PERIOD_M5,1,lookback_bars,highs)!=lookback_bars) return false;
   if(CopyLow(symbol,PERIOD_M5,1,lookback_bars,lows)!=lookback_bars) return false;

   bool seen_above=false,seen_below=false;
   for(int i=0;i<lookback_bars;i++)
     {
      if(highs[i]>or_state.high)
        {
         probes_above++;
         seen_above=true;
        }
      if(lows[i]<or_state.low)
        {
         probes_below++;
         seen_below=true;
        }
     }
   both_sides_swept=(seen_above && seen_below);
   return true;
  }

bool XSH_ClassifySession(const string symbol,
                         const XSH_OpeningRange &or_state,
                         const double atr_m5,
                         const double atr_m15,
                         const int ema_period,
                         const int probe_lookback_bars,
                         const int max_probes,
                         const double max_extension_atr_frac,
                         XSH_SessionClassification &classification,
                         string &reason)
  {
   reason="";
   classification.regime=XSH_REGIME_NO_TRADE;
   classification.or_atr_ratio=0.0;
   classification.impulse_score=0.0;
   classification.probes_total=0;
   classification.both_sides_swept=false;
   classification.extended=false;

   if(!or_state.built || atr_m5<=0.0 || atr_m15<=0.0)
     {
      reason="Classifier data invalid";
      return false;
     }

   double open_bar1[],close_bar1[],high_bar1[],low_bar1[],open_bar2[],close_bar2[],high_bar2[],low_bar2[];
   bool bar1_open_ok=(CopyOpen(symbol,PERIOD_M5,1,1,open_bar1)==1);
   bool bar1_close_ok=(CopyClose(symbol,PERIOD_M5,1,1,close_bar1)==1);
   bool bar1_high_ok=(CopyHigh(symbol,PERIOD_M5,1,1,high_bar1)==1);
   bool bar1_low_ok=(CopyLow(symbol,PERIOD_M5,1,1,low_bar1)==1);
   if(!(bar1_open_ok && bar1_close_ok && bar1_high_ok && bar1_low_ok))
      {
       reason="Classifier bar-1 unavailable";
       return false;
      }
   bool bar2_open_ok=(CopyOpen(symbol,PERIOD_M5,2,1,open_bar2)==1);
   bool bar2_close_ok=(CopyClose(symbol,PERIOD_M5,2,1,close_bar2)==1);
   bool bar2_high_ok=(CopyHigh(symbol,PERIOD_M5,2,1,high_bar2)==1);
   bool bar2_low_ok=(CopyLow(symbol,PERIOD_M5,2,1,low_bar2)==1);
   if(!(bar2_open_ok && bar2_close_ok && bar2_high_ok && bar2_low_ok))
      {
       reason="Classifier bar-2 unavailable";
       return false;
      }

   int probes_above=0,probes_below=0;
   bool both_sides=false;
   XSH_ReadSessionProbeStats(symbol,or_state,probe_lookback_bars,probes_above,probes_below,both_sides);
   classification.probes_total=probes_above+probes_below;
   classification.both_sides_swept=both_sides;

   double or_range=or_state.high-or_state.low;
   double or_mid=(or_state.high+or_state.low)*0.5;
   classification.or_atr_ratio=(atr_m15>0.0?or_range/atr_m15:0.0);

   double body1=MathAbs(close_bar1[0]-open_bar1[0]);
   double body2=MathAbs(close_bar2[0]-open_bar2[0]);
   double dir1=(close_bar1[0]>=open_bar1[0]?1.0:-1.0);
   double dir2=(close_bar2[0]>=open_bar2[0]?1.0:-1.0);
   double same_dir=(dir1==dir2?1.0:0.0);
   classification.impulse_score=(body1+body2)/(atr_m5*XSH_CLASSIFIER_IMPULSE_ATR_NORM) + same_dir*XSH_CLASSIFIER_DIR_BONUS;

   double ema_now=0.0,ema_prev=0.0;
   if(!XSH_ReadEMA(symbol,PERIOD_M15,ema_period,1,ema_now) || !XSH_ReadEMA(symbol,PERIOD_M15,ema_period,2,ema_prev))
     {
      reason="Classifier EMA unavailable";
      return false;
     }
   double bias_slope=ema_now-ema_prev;

   double close_now=close_bar1[0];
   double extension=MathAbs(close_now-or_mid)/(atr_m5>0.0?atr_m5:1.0);
   classification.extended=(extension>max_extension_atr_frac);

   bool or_ok=(classification.or_atr_ratio>=XSH_CLASSIFIER_OR_MIN && classification.or_atr_ratio<=XSH_CLASSIFIER_OR_MAX);
   bool directional_expansion=(classification.impulse_score>=XSH_CLASSIFIER_IMPULSE_MIN && same_dir>0.0);
   bool trend_up=(close_now>=ema_now && bias_slope>=0.0);
   bool trend_down=(close_now<=ema_now && bias_slope<=0.0);
   bool aligned=(trend_up || trend_down);
   bool too_many_probes=(classification.probes_total>max_probes);

   if(both_sides || too_many_probes)
     {
      classification.regime=XSH_REGIME_NO_TRADE;
      reason=(both_sides?"Both OR sides swept recently":"Too many OR probes");
      return true;
     }

   bool sweep_signature=(high_bar1[0]>or_state.high || low_bar1[0]<or_state.low || high_bar2[0]>or_state.high || low_bar2[0]<or_state.low);

   if(sweep_signature && !directional_expansion)
     {
      classification.regime=XSH_REGIME_REVERSAL_FAVOR;
      reason="Sweep-like behavior favors reclaim";
      return true;
     }

   if(or_ok && directional_expansion && aligned && !classification.extended)
     {
      classification.regime=XSH_REGIME_CONTINUATION_FAVOR;
      reason="Directional expansion + M15 alignment";
      return true;
     }

   classification.regime=XSH_REGIME_NO_TRADE;
   if(!or_ok) reason="OR quality outside ATR band";
   else if(classification.extended) reason="Price too extended from OR midpoint";
   else reason="Session structure not selective";

   return true;
  }

#endif
