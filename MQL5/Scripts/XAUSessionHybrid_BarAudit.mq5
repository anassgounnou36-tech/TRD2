#property script_show_inputs
#property strict

input string InpSymbol = "";
input ENUM_TIMEFRAMES InpTF = PERIOD_M5;
input int InpStartShift = 1;
input int InpRows = 30;

bool GetBar(const string symbol,const ENUM_TIMEFRAMES tf,const int shift,datetime &t,double &o,double &h,double &l,double &c)
  {
   datetime times[];
   double opens[],highs[],lows[],closes[];
   if(CopyTime(symbol,tf,shift,1,times)!=1) return false;
   if(CopyOpen(symbol,tf,shift,1,opens)!=1) return false;
   if(CopyHigh(symbol,tf,shift,1,highs)!=1) return false;
   if(CopyLow(symbol,tf,shift,1,lows)!=1) return false;
   if(CopyClose(symbol,tf,shift,1,closes)!=1) return false;
   t=times[0]; o=opens[0]; h=highs[0]; l=lows[0]; c=closes[0];
   return true;
  }

void OnStart()
  {
   string symbol=(StringLen(InpSymbol)>0?InpSymbol:_Symbol);
   PrintFormat("Bar audit symbol=%s tf=%d start_shift=%d rows=%d",symbol,(int)InpTF,InpStartShift,InpRows);

   for(int i=0;i<InpRows;i++)
     {
      int shift=InpStartShift+i;
      datetime t=0;
      double o=0.0,h=0.0,l=0.0,c=0.0;
      if(!GetBar(symbol,InpTF,shift,t,o,h,l,c))
        {
         PrintFormat("shift=%d unavailable",shift);
         continue;
        }
      PrintFormat("shift=%d time=%s O=%.2f H=%.2f L=%.2f C=%.2f",shift,TimeToString(t,TIME_DATE|TIME_MINUTES),o,h,l,c);
     }
  }
