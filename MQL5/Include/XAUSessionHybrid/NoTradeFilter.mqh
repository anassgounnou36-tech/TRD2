#ifndef XSH_NO_TRADE_FILTER_MQH
#define XSH_NO_TRADE_FILTER_MQH

#include <XAUSessionHybrid/Types.mqh>

const double XSH_TWO_SIDED_OVERRIDE_BONUS=10.0;

bool XSH_ShouldBlockTrade(const XSH_SessionClassification &classification,
                          const XSH_SetupScore &score,
                          const double min_setup_score,
                          const int session_minutes_left,
                          const double spread,
                          const double atr_m5,
                          const double max_spread_atr_frac,
                          const double recent_spread_median,
                          const double spread_median_mult_threshold,
                          const bool duplicate_active_setup,
                          string &reason)
  {
   reason="";

   if(classification.regime==XSH_REGIME_NO_TRADE)
     {
      reason="Classifier regime=NO_TRADE";
      return true;
     }

   if(session_minutes_left<=0)
     {
      reason="Session expired";
      return true;
     }

   if(atr_m5>0.0)
      {
       double spread_atr_ratio=spread/atr_m5;
       double spread_median_ratio=(recent_spread_median>0.0?spread/recent_spread_median:0.0);
       if(spread_atr_ratio>max_spread_atr_frac &&
          (recent_spread_median<=0.0 || spread_median_ratio>spread_median_mult_threshold))
         {
          reason=StringFormat("Spread too high: spread=%.2f atr=%.2f ratio=%.4f median=%.2f median_ratio=%.2f thr=%.4f/%.2f",
                              spread,atr_m5,spread_atr_ratio,recent_spread_median,spread_median_ratio,max_spread_atr_frac,spread_median_mult_threshold);
          return true;
         }
      }

   if(score.total<min_setup_score)
     {
      reason=StringFormat("Score %.1f below threshold %.1f",score.total,min_setup_score);
      return true;
     }

   if(classification.both_sides_swept && score.total<MathMin(100.0,min_setup_score+XSH_TWO_SIDED_OVERRIDE_BONUS))
     {
      reason="Two-sided sweep trap (no high-score override)";
      return true;
     }

   if(duplicate_active_setup)
     {
      reason="Duplicate setup already active";
      return true;
     }

   return false;
  }

#endif
