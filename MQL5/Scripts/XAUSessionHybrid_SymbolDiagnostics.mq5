#property script_show_inputs
#property strict

input string InpSymbol = "";

void OnStart()
  {
   string symbol=(StringLen(InpSymbol)>0?InpSymbol:_Symbol);
   PrintFormat("Symbol diagnostics for %s",symbol);

   int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   double tick_size=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   double tick_value=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
   double contract_size=SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE);
   double vol_min=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double vol_step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
   double vol_max=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   int stops=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   int freeze=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   long filling=SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
   long exemode=SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE);
   long trademode=SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);

   PrintFormat("digits=%d point=%f tick_size=%f tick_value=%f contract=%f",digits,point,tick_size,tick_value,contract_size);
   PrintFormat("volume min=%f step=%f max=%f",vol_min,vol_step,vol_max);
   PrintFormat("stops=%d freeze=%d filling=%d exe=%d trade_mode=%d",stops,freeze,(int)filling,(int)exemode,(int)trademode);

   double ask=0.0,bid=0.0;
   MqlTick tick;
   if(SymbolInfoTick(symbol,tick))
     {
      ask=tick.ask;
      bid=tick.bid;
      PrintFormat("bid=%f ask=%f spread=%f",bid,ask,ask-bid);
     }
  }
