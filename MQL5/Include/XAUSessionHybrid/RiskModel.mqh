#ifndef XSH_RISK_MODEL_MQH
#define XSH_RISK_MODEL_MQH

#include <XAUSessionHybrid/Types.mqh>
#include <XAUSessionHybrid/SymbolSpecs.mqh>
#include <XAUSessionHybrid/TimeWindows.mqh>

void XSH_ResetDailyStateIfNeeded(XSH_DailyRiskState &st,const datetime now)
  {
   int tag=XSH_DayTag(now);
   if(st.day_tag!=tag)
     {
      st.day_tag=tag;
      st.day_start_balance=AccountInfoDouble(ACCOUNT_BALANCE);
      st.day_start_equity=AccountInfoDouble(ACCOUNT_EQUITY);
      st.trades_today=0;
      st.losses_today=0;
      st.blocked=false;
      st.block_reason="";
     }
  }

bool XSH_CheckDailyGuards(XSH_DailyRiskState &st,
                          const double max_daily_loss_pct,
                          const int max_trades_day,
                          const bool enable_profit_lock,
                          const double daily_profit_lock_r,
                          const double risk_pct,
                          const bool use_equity)
  {
   double bal=AccountInfoDouble(ACCOUNT_BALANCE);
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   double base=use_equity?st.day_start_equity:st.day_start_balance;
   double now_value=use_equity?eq:bal;
   double dd_pct=0.0;
   if(base>0.0)
      dd_pct=(base-now_value)/base*100.0;

   if(dd_pct>=max_daily_loss_pct)
     {
      st.blocked=true;
      st.block_reason="Daily loss cap reached";
      return false;
     }

   if(st.trades_today>=max_trades_day)
     {
      st.blocked=true;
      st.block_reason="Max trades per day reached";
      return false;
     }

   if(enable_profit_lock && risk_pct>0.0)
     {
      double pnl=now_value-base;
      double unit=base*(risk_pct/100.0);
      if(unit>0.0 && pnl>=unit*daily_profit_lock_r)
        {
         st.blocked=true;
         st.block_reason="Daily profit lock reached";
         return false;
        }
     }

   st.blocked=false;
   st.block_reason="";
   return true;
  }

bool XSH_CalcVolumeByRisk(const XSH_SymbolSpecs &spec,
                          const string symbol,
                          const XSH_TradeDirection dir,
                          const double entry,
                          const double stop,
                          const double risk_pct,
                          const bool allow_min_override,
                          double &volume,
                          string &reason)
  {
   reason="";
   volume=0.0;
   if(risk_pct<=0.0)
     {
      reason="Risk pct <= 0";
      return false;
     }

   double risk_money=AccountInfoDouble(ACCOUNT_BALANCE)*(risk_pct/100.0);
   if(risk_money<=0.0)
     {
      reason="Risk money <= 0";
      return false;
     }

   double profit_one_lot=0.0;
   ENUM_ORDER_TYPE order_type=(dir==XSH_DIR_LONG?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
   if(!OrderCalcProfit(order_type,symbol,1.0,entry,stop,profit_one_lot))
     {
      reason="OrderCalcProfit failed";
      return false;
     }

   double loss_per_lot=MathAbs(profit_one_lot);
   if(loss_per_lot<=0.0)
     {
      reason="Loss per lot invalid";
      return false;
     }

   double raw=risk_money/loss_per_lot;
   bool below_min=(raw<spec.volume_min);
   if(below_min && !allow_min_override)
     {
      reason="Raw risk lot below broker minimum (blocked)";
      return false;
     }

   double sizing_input=raw;
   if(below_min && allow_min_override)
     {
      sizing_input=spec.volume_min;
      reason=StringFormat("Override: forced broker minimum lot %.2f (raw %.4f)",spec.volume_min,raw);
     }

   double norm=XSH_NormalizeVolume(spec,sizing_input);
   if(norm<spec.volume_min)
     {
      reason="Normalized lot below minimum";
      return false;
     }

   volume=norm;
   return true;
  }

#endif
