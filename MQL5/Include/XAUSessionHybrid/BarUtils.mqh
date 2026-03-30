#ifndef XSH_BAR_UTILS_MQH
#define XSH_BAR_UTILS_MQH

bool XSH_IsNewBar(const string symbol,const ENUM_TIMEFRAMES tf,datetime &last_bar_time)
  {
   datetime times[];
   if(CopyTime(symbol,tf,0,1,times)!=1) return false;
   if(times[0]!=last_bar_time)
     {
      last_bar_time=times[0];
      return true;
     }
   return false;
  }

double XSH_HighestHigh(const string symbol,const ENUM_TIMEFRAMES tf,const int start_shift,const int count)
  {
   double highs[];
   if(CopyHigh(symbol,tf,start_shift,count,highs)!=count) return 0.0;
   double max_v=highs[0];
   for(int i=1;i<count;i++) if(highs[i]>max_v) max_v=highs[i];
   return max_v;
  }

double XSH_LowestLow(const string symbol,const ENUM_TIMEFRAMES tf,const int start_shift,const int count)
  {
   double lows[];
   if(CopyLow(symbol,tf,start_shift,count,lows)!=count) return 0.0;
   double min_v=lows[0];
   for(int i=1;i<count;i++) if(lows[i]<min_v) min_v=lows[i];
   return min_v;
  }

#endif
