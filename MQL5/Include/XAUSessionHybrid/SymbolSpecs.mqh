#ifndef XSH_SYMBOL_SPECS_MQH
#define XSH_SYMBOL_SPECS_MQH

#include <XAUSessionHybrid/Types.mqh>

bool XSH_LoadSymbolSpecs(const string symbol, XSH_SymbolSpecs &spec)
  {
   spec.symbol=symbol;
   spec.valid=false;

   long v=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_DIGITS,v)) return false;
   spec.digits=(int)v;
   if(!SymbolInfoDouble(symbol,SYMBOL_POINT,spec.point)) return false;
   if(!SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE,spec.tick_size)) return false;
   if(!SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE,spec.tick_value)) return false;
   if(!SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE,spec.contract_size)) return false;
   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN,spec.volume_min)) return false;
   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,spec.volume_max)) return false;
   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP,spec.volume_step)) return false;

   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL,v)) return false;
   spec.stops_level_points=(int)v;
   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL,v)) return false;
   spec.freeze_level_points=(int)v;
   if(!SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE,spec.filling_mode)) return false;
   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE,spec.execution_mode)) return false;
   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE,spec.trade_mode)) return false;

   spec.valid=(spec.volume_min>0.0 && spec.volume_step>0.0 && spec.point>0.0 && spec.trade_mode!=SYMBOL_TRADE_MODE_DISABLED);
   return spec.valid;
  }

double XSH_NormalizeVolume(const XSH_SymbolSpecs &spec,double volume)
  {
   if(spec.volume_step<=0.0) return 0.0;
   double steps=MathFloor(volume/spec.volume_step+1e-9);
   double normalized=steps*spec.volume_step;
   normalized=MathMin(normalized,spec.volume_max);
   if(normalized<0.0) normalized=0.0;
   int vol_digits=0;
   double s=spec.volume_step;
   while(vol_digits<8 && MathAbs(s-MathRound(s))>1e-8)
     {
      s*=10.0;
      vol_digits++;
     }
   return NormalizeDouble(normalized,vol_digits);
  }

#endif
