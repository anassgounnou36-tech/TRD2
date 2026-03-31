#ifndef XSH_BIAS_FILTER_MQH
#define XSH_BIAS_FILTER_MQH

#include <XAUSessionHybrid/Types.mqh>
#include <XAUSessionHybrid/IndicatorEngine.mqh>

bool XSH_BiasAllows(const string symbol,
                    const ENUM_TIMEFRAMES tf,
                    const int ema_period,
                    const XSH_TradeDirection dir)
  {
   double ema_now=0.0,ema_prev=0.0;
   if(!XSH_ReadEMA(symbol,tf,ema_period,1,ema_now)) return false;
   if(!XSH_ReadEMA(symbol,tf,ema_period,2,ema_prev)) return false;

   double close_buf[];
   if(CopyClose(symbol,tf,1,1,close_buf)!=1) return false;
   double close_p=close_buf[0];

   if(dir==XSH_DIR_LONG) return (close_p>ema_now && ema_now>=ema_prev);
   if(dir==XSH_DIR_SHORT) return (close_p<ema_now && ema_now<=ema_prev);
   return false;
  }

#endif
