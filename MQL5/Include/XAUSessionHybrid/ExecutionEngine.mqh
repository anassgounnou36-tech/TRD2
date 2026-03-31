#ifndef XSH_EXECUTION_ENGINE_MQH
#define XSH_EXECUTION_ENGINE_MQH

#include <Trade/Trade.mqh>
#include <XAUSessionHybrid/Types.mqh>

bool XSH_HasPosition(const string symbol,const ulong magic,int &count)
  {
   count=0;
   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      string s=PositionGetString(POSITION_SYMBOL);
      long m=PositionGetInteger(POSITION_MAGIC);
      if(s==symbol && (ulong)m==magic) count++;
     }
   return (count>0);
  }

ENUM_ORDER_TYPE_FILLING XSH_ResolveFilling(const XSH_SymbolSpecs &spec)
  {
   if((spec.filling_mode & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
   if((spec.filling_mode & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
  }

bool XSH_SendMarketOrder(const XSH_SymbolSpecs &spec,
                         const ulong magic,
                         const XSH_TradeDirection dir,
                         const double volume,
                         const double sl,
                         const double tp,
                         const int slippage_points,
                         const string comment,
                         string &reason)
  {
   reason="";

   MqlTick tick;
   if(!SymbolInfoTick(spec.symbol,tick))
     {
      reason="No tick";
      return false;
     }

   MqlTradeRequest req;
   MqlTradeResult res;
   MqlTradeCheckResult chk;
   ZeroMemory(req);
   ZeroMemory(res);
   ZeroMemory(chk);

   req.action=TRADE_ACTION_DEAL;
   req.symbol=spec.symbol;
   req.magic=magic;
   req.volume=volume;
   req.type=(dir==XSH_DIR_LONG?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
   req.price=(dir==XSH_DIR_LONG?tick.ask:tick.bid);
   req.sl=NormalizeDouble(sl,spec.digits);
   req.tp=NormalizeDouble(tp,spec.digits);
   req.deviation=slippage_points;
   req.type_filling=XSH_ResolveFilling(spec);
   req.type_time=ORDER_TIME_GTC;
   req.comment=comment;

   bool check_ok=OrderCheck(req,chk);
   if(check_ok)
     {
      bool check_accept=(chk.retcode==TRADE_RETCODE_DONE || chk.retcode==TRADE_RETCODE_DONE_PARTIAL || chk.retcode==0);
      if(!check_accept)
        {
         reason=StringFormat("OrderCheck reject retcode=%d comment=%s",chk.retcode,chk.comment);
         return false;
        }
     }
   else
     {
      if(chk.retcode!=0)
        {
         reason=StringFormat("OrderCheck failed retcode=%d comment=%s",chk.retcode,chk.comment);
         return false;
        }
      Print("WARN OrderCheck inconclusive (retcode=0), proceeding controlled send");
     }

   if(!OrderSend(req,res))
     {
      reason=StringFormat("OrderSend failed retcode=%d comment=%s",res.retcode,res.comment);
      return false;
     }

   if(res.retcode!=TRADE_RETCODE_DONE && res.retcode!=TRADE_RETCODE_DONE_PARTIAL)
     {
      reason=StringFormat("OrderSend reject retcode=%d comment=%s",res.retcode,res.comment);
      return false;
     }

   return true;
  }

#endif
