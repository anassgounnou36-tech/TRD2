#ifndef XSH_TYPES_MQH
#define XSH_TYPES_MQH

enum XSH_SessionType
  {
   XSH_SESSION_NONE=0,
   XSH_SESSION_LONDON=1,
   XSH_SESSION_NEWYORK=2
  };

enum XSH_SignalFamily
  {
   XSH_SIGNAL_NONE=0,
   XSH_SIGNAL_BREAKOUT=1,
   XSH_SIGNAL_RECLAIM=2
  };

enum XSH_TradeDirection
  {
   XSH_DIR_NONE=0,
   XSH_DIR_LONG=1,
   XSH_DIR_SHORT=-1
  };

struct XSH_SymbolSpecs
  {
   string symbol;
   int digits;
   double point;
   double tick_size;
   double tick_value;
   double contract_size;
   double volume_min;
   double volume_max;
   double volume_step;
   int stops_level_points;
   int freeze_level_points;
   long filling_mode;
   long execution_mode;
   long trade_mode;
   bool valid;
  };

struct XSH_OpeningRange
  {
   bool built;
   datetime start_time;
   datetime end_time;
   double high;
   double low;
   bool sweep_above;
   bool sweep_below;
  };

struct XSH_Signal
  {
   bool valid;
   XSH_SessionType session;
   XSH_SignalFamily family;
   XSH_TradeDirection direction;
   double entry;
   double stop_loss;
   double risk_per_lot;
   string reason;
  };

struct XSH_SessionState
  {
   XSH_OpeningRange london_or;
   XSH_OpeningRange ny_or;
   int london_trades;
   int ny_trades;
   int london_last_direction;
   int ny_last_direction;
   bool london_breakout_long_used;
   bool london_breakout_short_used;
   bool london_reclaim_long_used;
   bool london_reclaim_short_used;
   bool ny_breakout_long_used;
   bool ny_breakout_short_used;
   bool ny_reclaim_long_used;
   bool ny_reclaim_short_used;
   bool london_won;
   bool ny_won;
   bool suspend;
   string suspend_reason;
  };

struct XSH_DailyRiskState
  {
   int day_tag;
   double day_start_balance;
   int trades_today;
   int losses_today;
   bool blocked;
   string block_reason;
  };

#endif
