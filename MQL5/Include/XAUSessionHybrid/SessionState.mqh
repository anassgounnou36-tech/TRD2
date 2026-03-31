#ifndef XSH_SESSION_STATE_MQH
#define XSH_SESSION_STATE_MQH

#include <XAUSessionHybrid/Types.mqh>

void XSH_ResetSessionState(XSH_SessionState &st)
  {
   st.london_or.built=false;
   st.london_or.sweep_above=false;
   st.london_or.sweep_below=false;
   st.ny_or.built=false;
   st.ny_or.sweep_above=false;
   st.ny_or.sweep_below=false;
   st.london_trades=0;
   st.ny_trades=0;
   st.london_last_direction=0;
   st.ny_last_direction=0;
   st.london_breakout_long_used=false;
   st.london_breakout_short_used=false;
   st.london_reclaim_long_used=false;
   st.london_reclaim_short_used=false;
   st.ny_breakout_long_used=false;
   st.ny_breakout_short_used=false;
   st.ny_reclaim_long_used=false;
   st.ny_reclaim_short_used=false;
   st.london_won=false;
   st.ny_won=false;
   st.london_lifecycle=XSH_SETUP_NONE;
   st.ny_lifecycle=XSH_SETUP_NONE;
   st.london_active_family=XSH_SIGNAL_NONE;
   st.ny_active_family=XSH_SIGNAL_NONE;
   st.london_active_direction=0;
   st.ny_active_direction=0;
   st.london_last_score=0.0;
   st.ny_last_score=0.0;
   st.london_blocker_reason="";
   st.ny_blocker_reason="";
   st.suspend=false;
   st.suspend_reason="";
  }

int XSH_GetSessionTrades(const XSH_SessionState &st,const XSH_SessionType session)
  {
   if(session==XSH_SESSION_LONDON) return st.london_trades;
   if(session==XSH_SESSION_NEWYORK) return st.ny_trades;
   return 0;
  }

void XSH_IncSessionTrades(XSH_SessionState &st,const XSH_SessionType session)
  {
   if(session==XSH_SESSION_LONDON) st.london_trades++;
   if(session==XSH_SESSION_NEWYORK) st.ny_trades++;
  }

bool XSH_SessionDirectionAllowed(const XSH_SessionState &st,const XSH_SessionType session,const XSH_TradeDirection dir)
  {
   if(session==XSH_SESSION_LONDON)
     {
      if(st.london_last_direction==0) return true;
      return st.london_last_direction==(int)dir;
     }
   if(session==XSH_SESSION_NEWYORK)
     {
      if(st.ny_last_direction==0) return true;
      return st.ny_last_direction==(int)dir;
     }
   return false;
  }

void XSH_MarkSessionDirection(XSH_SessionState &st,const XSH_SessionType session,const XSH_TradeDirection dir)
  {
   if(session==XSH_SESSION_LONDON) st.london_last_direction=(int)dir;
   if(session==XSH_SESSION_NEWYORK) st.ny_last_direction=(int)dir;
  }

bool XSH_IsFamilyDirectionUsed(const XSH_SessionState &st,const XSH_SessionType session,const XSH_SignalFamily family,const XSH_TradeDirection dir)
  {
   if(session==XSH_SESSION_LONDON)
     {
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_LONG) return st.london_breakout_long_used;
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_SHORT) return st.london_breakout_short_used;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_LONG) return st.london_reclaim_long_used;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_SHORT) return st.london_reclaim_short_used;
     }
   if(session==XSH_SESSION_NEWYORK)
     {
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_LONG) return st.ny_breakout_long_used;
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_SHORT) return st.ny_breakout_short_used;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_LONG) return st.ny_reclaim_long_used;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_SHORT) return st.ny_reclaim_short_used;
     }
   return false;
  }

void XSH_MarkFamilyDirectionUsed(XSH_SessionState &st,const XSH_SessionType session,const XSH_SignalFamily family,const XSH_TradeDirection dir)
  {
   if(session==XSH_SESSION_LONDON)
     {
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_LONG) st.london_breakout_long_used=true;
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_SHORT) st.london_breakout_short_used=true;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_LONG) st.london_reclaim_long_used=true;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_SHORT) st.london_reclaim_short_used=true;
     }
   if(session==XSH_SESSION_NEWYORK)
     {
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_LONG) st.ny_breakout_long_used=true;
      if(family==XSH_SIGNAL_BREAKOUT && dir==XSH_DIR_SHORT) st.ny_breakout_short_used=true;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_LONG) st.ny_reclaim_long_used=true;
      if(family==XSH_SIGNAL_RECLAIM && dir==XSH_DIR_SHORT) st.ny_reclaim_short_used=true;
     }
  }

#endif
