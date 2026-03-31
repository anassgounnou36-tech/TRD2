#ifndef XSH_POSITION_MANAGER_MQH
#define XSH_POSITION_MANAGER_MQH

#include <Trade/Trade.mqh>
#include <XAUSessionHybrid/Types.mqh>
#include <XAUSessionHybrid/IndicatorEngine.mqh>

bool XSH_ModifySLSafe(const XSH_SymbolSpecs &spec,
                      const ulong ticket,
                      const double new_sl,
                      const double current_tp)
  {
   if(!PositionSelectByTicket(ticket)) return false;

   double old_sl=PositionGetDouble(POSITION_SL);
   if(MathAbs(old_sl-new_sl)<spec.point*0.5) return true;

   MqlTick tick;
   if(!SymbolInfoTick(spec.symbol,tick)) return false;

   long ptype=PositionGetInteger(POSITION_TYPE);
   double ref=(ptype==POSITION_TYPE_BUY?tick.bid:tick.ask);
   double min_dist=spec.point*MathMax(spec.stops_level_points,spec.freeze_level_points);
   if(MathAbs(ref-new_sl)<min_dist)
     {
      Print("Skip SL modify: freeze/stops distance too small");
      return false;
     }

   CTrade tr;
   tr.SetExpertMagicNumber((long)PositionGetInteger(POSITION_MAGIC));
   return tr.PositionModify(spec.symbol,NormalizeDouble(new_sl,spec.digits),current_tp);
  }

void XSH_ManageOpenPosition(const XSH_SymbolSpecs &spec,
                            const ulong magic,
                            const double tp1_r,
                            const double trail_atr_frac,
                            const int atr_period,
                            const bool move_to_be,
                            const int max_hold_minutes)
  {
   int total=PositionsTotal();
   datetime now=TimeCurrent();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=spec.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC)!=magic) continue;

      datetime open_time=(datetime)PositionGetInteger(POSITION_TIME);
      if((now-open_time)>max_hold_minutes*60)
        {
         CTrade tr;
         tr.PositionClose(ticket);
         continue;
        }

      long ptype=PositionGetInteger(POSITION_TYPE);
      double open=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      MqlTick tick;
      if(!SymbolInfoTick(spec.symbol,tick)) continue;
      double cur=(ptype==POSITION_TYPE_BUY?tick.bid:tick.ask);

      double risk=MathAbs(open-sl);
      if(risk<=0.0) continue;
      if(move_to_be)
        {
         double target=(ptype==POSITION_TYPE_BUY?open+risk*tp1_r:open-risk*tp1_r);
         bool reached=(ptype==POSITION_TYPE_BUY?cur>=target:cur<=target);
         if(reached)
            XSH_ModifySLSafe(spec,ticket,open,tp);
        }

      double atr_m5=0.0;
      if(trail_atr_frac>0.0 && XSH_ReadATR(spec.symbol,PERIOD_M5,atr_period,1,atr_m5))
        {
         double trail_dist=atr_m5*trail_atr_frac;
         if(trail_dist>0.0)
           {
            double proposed_sl=sl;
            if(ptype==POSITION_TYPE_BUY)
              {
               double candidate=cur-trail_dist;
               if(candidate>sl) proposed_sl=candidate;
              }
            else
              {
               double candidate=cur+trail_dist;
               if(candidate<sl || sl<=0.0) proposed_sl=candidate;
              }
            if(MathAbs(proposed_sl-sl)>spec.point)
               XSH_ModifySLSafe(spec,ticket,proposed_sl,tp);
           }
        }
     }
  }

void XSH_FlattenAtSessionEnd(const XSH_SymbolSpecs &spec,const ulong magic)
  {
   CTrade tr;
   int total=PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=spec.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      tr.PositionClose(ticket);
     }
  }

#endif
