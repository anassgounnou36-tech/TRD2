#ifndef XSH_SETUP_SCORER_MQH
#define XSH_SETUP_SCORER_MQH

#include <XAUSessionHybrid/Types.mqh>

double XSH_ClampScore(const double v,const double mn,const double mx)
  {
   return MathMax(mn,MathMin(mx,v));
  }

bool XSH_ScoreSetup(const string symbol,
                    const XSH_OpeningRange &or_state,
                    const XSH_SessionClassification &classification,
                    const XSH_Signal &signal,
                    const double atr_m5,
                    const double atr_m15,
                    const double spread,
                    const double max_spread_atr_frac,
                    const int session_minutes_left,
                    const double stop_distance,
                    XSH_SetupScore &out_score,
                    string &reason)
  {
   reason="";
   out_score.total=0.0;
   out_score.range_quality=0.0;
   out_score.context=0.0;
   out_score.trigger_quality=0.0;
   out_score.execution_quality=0.0;
   out_score.noise_penalty=0.0;
   out_score.breakdown="";

   if(!or_state.built || atr_m5<=0.0 || atr_m15<=0.0)
     {
      reason="Score inputs invalid";
      return false;
     }

   double or_range=or_state.high-or_state.low;
   double or_ratio=or_range/atr_m15;
   if(or_ratio>=0.35 && or_ratio<=1.15) out_score.range_quality=20.0;
   else if(or_ratio>=0.25 && or_ratio<=1.35) out_score.range_quality=14.0;
   else out_score.range_quality=6.0;

   if(classification.regime==XSH_REGIME_CONTINUATION_FAVOR && signal.family==XSH_SIGNAL_BREAKOUT) out_score.context=20.0;
   else if(classification.regime==XSH_REGIME_REVERSAL_FAVOR && signal.family==XSH_SIGNAL_RECLAIM) out_score.context=20.0;
   else if(classification.regime==XSH_REGIME_NO_TRADE) out_score.context=0.0;
   else out_score.context=8.0;

   double open1[],close1[],high1[],low1[];
   if(CopyOpen(symbol,PERIOD_M5,1,1,open1)==1 && CopyClose(symbol,PERIOD_M5,1,1,close1)==1 && CopyHigh(symbol,PERIOD_M5,1,1,high1)==1 && CopyLow(symbol,PERIOD_M5,1,1,low1)==1)
     {
      double o=open1[0],c=close1[0],h=high1[0],l=low1[0];
      double body=MathAbs(c-o);
      double range=MathMax(0.0,h-l);
      double body_frac=(range>0.0?body/range:0.0);
      double body_atr=(atr_m5>0.0?body/atr_m5:0.0);
      if(signal.family==XSH_SIGNAL_BREAKOUT)
        {
         out_score.trigger_quality=10.0;
         if(body_frac>=0.55) out_score.trigger_quality+=8.0;
         if(body_atr>=0.25) out_score.trigger_quality+=4.0;
         bool clean_wick=(signal.direction==XSH_DIR_LONG?(h-c)<=body*0.6:(c-l)<=body*0.6);
         if(clean_wick) out_score.trigger_quality+=3.0;
        }
      else if(signal.family==XSH_SIGNAL_RECLAIM)
        {
         out_score.trigger_quality=10.0;
         bool meaningful_close=(signal.direction==XSH_DIR_LONG?c>or_state.low:c<or_state.high);
         if(meaningful_close) out_score.trigger_quality+=7.0;
         if(body_frac>=0.50) out_score.trigger_quality+=5.0;
         bool decisive=(signal.direction==XSH_DIR_LONG?(c-l)>=range*0.60:(h-c)>=range*0.60);
         if(decisive) out_score.trigger_quality+=3.0;
        }
     }

   out_score.execution_quality=15.0;
   if(atr_m5>0.0 && spread>atr_m5*max_spread_atr_frac) out_score.execution_quality-=6.0;
   if(stop_distance<=0.0 || stop_distance>atr_m5*2.5) out_score.execution_quality-=4.0;
   if(session_minutes_left<20) out_score.execution_quality-=5.0;
   out_score.execution_quality=XSH_ClampScore(out_score.execution_quality,0.0,15.0);

   out_score.noise_penalty=0.0;
   if(classification.probes_total>=3) out_score.noise_penalty+=8.0;
   if(classification.both_sides_swept) out_score.noise_penalty+=8.0;
   if(classification.extended) out_score.noise_penalty+=6.0;

   out_score.total=out_score.range_quality+out_score.context+out_score.trigger_quality+out_score.execution_quality-out_score.noise_penalty;
   out_score.total=XSH_ClampScore(out_score.total,0.0,100.0);

   out_score.breakdown=StringFormat("R=%.1f C=%.1f T=%.1f E=%.1f N=-%.1f => %.1f",
                                    out_score.range_quality,
                                    out_score.context,
                                    out_score.trigger_quality,
                                    out_score.execution_quality,
                                    out_score.noise_penalty,
                                    out_score.total);

   return true;
  }

#endif
