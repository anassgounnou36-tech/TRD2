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
   st.london_won=false;
   st.ny_won=false;
   st.suspend=false;
   st.suspend_reason="";
  }

XSH_OpeningRange *XSH_GetORRef(XSH_SessionState &st,const XSH_SessionType session)
  {
   if(session==XSH_SESSION_LONDON) return &st.london_or;
   if(session==XSH_SESSION_NEWYORK) return &st.ny_or;
   return NULL;
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

#endif
