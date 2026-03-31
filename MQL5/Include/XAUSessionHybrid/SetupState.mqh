#ifndef XSH_SETUP_STATE_MQH
#define XSH_SETUP_STATE_MQH

#include <XAUSessionHybrid/Types.mqh>

string XSH_LifecycleToText(const XSH_SetupLifecycleState st)
  {
   if(st==XSH_SETUP_WATCHING) return "WATCHING";
   if(st==XSH_SETUP_ARMED) return "ARMED";
   if(st==XSH_SETUP_ORDER_ACTIVE) return "ORDER_ACTIVE";
   if(st==XSH_SETUP_POSITION_OPEN) return "POSITION_OPEN";
   if(st==XSH_SETUP_COMPLETED) return "COMPLETED";
   if(st==XSH_SETUP_INVALIDATED) return "INVALIDATED";
   return "NONE";
  }

XSH_SetupLifecycleState XSH_GetLifecycle(const XSH_SessionState &st,const XSH_SessionType session)
  {
   if(session==XSH_SESSION_LONDON) return st.london_lifecycle;
   if(session==XSH_SESSION_NEWYORK) return st.ny_lifecycle;
   return XSH_SETUP_NONE;
  }

void XSH_SetLifecycle(XSH_SessionState &st,const XSH_SessionType session,const XSH_SetupLifecycleState lifecycle)
  {
   if(session==XSH_SESSION_LONDON) st.london_lifecycle=lifecycle;
   if(session==XSH_SESSION_NEWYORK) st.ny_lifecycle=lifecycle;
  }

void XSH_SetActiveSetup(XSH_SessionState &st,
                        const XSH_SessionType session,
                        const XSH_SignalFamily family,
                        const XSH_TradeDirection direction,
                        const double score)
  {
   if(session==XSH_SESSION_LONDON)
     {
      st.london_active_family=family;
      st.london_active_direction=(int)direction;
      st.london_last_score=score;
     }
   if(session==XSH_SESSION_NEWYORK)
     {
      st.ny_active_family=family;
      st.ny_active_direction=(int)direction;
      st.ny_last_score=score;
     }
  }

void XSH_ClearActiveSetup(XSH_SessionState &st,const XSH_SessionType session)
  {
   if(session==XSH_SESSION_LONDON)
     {
      st.london_active_family=XSH_SIGNAL_NONE;
      st.london_active_direction=0;
      st.london_last_score=0.0;
      st.london_blocker_reason="";
     }
   if(session==XSH_SESSION_NEWYORK)
     {
      st.ny_active_family=XSH_SIGNAL_NONE;
      st.ny_active_direction=0;
      st.ny_last_score=0.0;
      st.ny_blocker_reason="";
     }
  }

void XSH_SetSessionBlocker(XSH_SessionState &st,const XSH_SessionType session,const string reason)
  {
   if(session==XSH_SESSION_LONDON) st.london_blocker_reason=reason;
   if(session==XSH_SESSION_NEWYORK) st.ny_blocker_reason=reason;
  }

string XSH_GetSessionBlocker(const XSH_SessionState &st,const XSH_SessionType session)
  {
   if(session==XSH_SESSION_LONDON) return st.london_blocker_reason;
   if(session==XSH_SESSION_NEWYORK) return st.ny_blocker_reason;
   return "";
  }

#endif
