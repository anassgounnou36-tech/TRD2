#ifndef XSH_NO_TRADE_FILTER_MQH
#define XSH_NO_TRADE_FILTER_MQH

#include <XAUSessionHybrid/Types.mqh>

bool XSH_ShouldBlockTrade(const XSH_SessionClassification &classification,
                          const XSH_SetupScore &score,
                          const double min_setup_score,
                          const int session_minutes_left,
                          const double spread,
                          const double atr_m5,
                          const double max_spread_atr_frac,
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

   if(atr_m5>0.0 && spread>atr_m5*max_spread_atr_frac)
     {
      reason="Spread too high for ATR";
      return true;
     }

   if(score.total<min_setup_score)
     {
      reason=StringFormat("Score %.1f below threshold %.1f",score.total,min_setup_score);
      return true;
     }

   if(classification.both_sides_swept && score.total<MathMin(100.0,min_setup_score+10.0))
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
