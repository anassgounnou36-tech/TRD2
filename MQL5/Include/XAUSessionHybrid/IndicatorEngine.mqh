#ifndef XSH_INDICATOR_ENGINE_MQH
#define XSH_INDICATOR_ENGINE_MQH

bool XSH_ReadATR(const string symbol,const ENUM_TIMEFRAMES tf,const int period,const int shift,double &atr_out)
  {
   int h=iATR(symbol,tf,period);
   if(h==INVALID_HANDLE) return false;
   double buf[];
   int copied=CopyBuffer(h,0,shift,1,buf);
   IndicatorRelease(h);
   if(copied!=1) return false;
   atr_out=buf[0];
   return (atr_out>0.0);
  }

bool XSH_ReadEMA(const string symbol,const ENUM_TIMEFRAMES tf,const int period,const int shift,double &ema_out)
  {
   int h=iMA(symbol,tf,period,0,MODE_EMA,PRICE_CLOSE);
   if(h==INVALID_HANDLE) return false;
   double buf[];
   int copied=CopyBuffer(h,0,shift,1,buf);
   IndicatorRelease(h);
   if(copied!=1) return false;
   ema_out=buf[0];
   return true;
  }

#endif
