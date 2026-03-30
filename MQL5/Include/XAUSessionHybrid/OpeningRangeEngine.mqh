#ifndef XSH_OPENING_RANGE_ENGINE_MQH
#define XSH_OPENING_RANGE_ENGINE_MQH

#include <XAUSessionHybrid/Types.mqh>
#include <XAUSessionHybrid/BarUtils.mqh>

bool XSH_BuildOpeningRange(const string symbol,
                           const ENUM_TIMEFRAMES tf,
                           const datetime now,
                           const datetime session_start,
                           const int range_minutes,
                           XSH_OpeningRange &or_state)
  {
   or_state.start_time=session_start;
   or_state.end_time=session_start+range_minutes*60;
   if(now<or_state.end_time)
     {
      or_state.built=false;
      return false;
     }

   int bars_needed=(range_minutes/5);
   if(bars_needed<1) bars_needed=1;

   int start_shift=iBarShift(symbol,tf,or_state.end_time,false);
   if(start_shift<0) return false;

   double hi=XSH_HighestHigh(symbol,tf,start_shift,bars_needed);
   double lo=XSH_LowestLow(symbol,tf,start_shift,bars_needed);
   if(hi<=0.0 || lo<=0.0 || hi<=lo) return false;

   or_state.high=hi;
   or_state.low=lo;
   or_state.built=true;
   return true;
  }

#endif
