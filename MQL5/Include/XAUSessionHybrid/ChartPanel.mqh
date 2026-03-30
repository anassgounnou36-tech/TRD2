#ifndef XSH_CHART_PANEL_MQH
#define XSH_CHART_PANEL_MQH

#include <XAUSessionHybrid/Types.mqh>

void XSH_UpdatePanel(const long chart_id,
                     const string symbol,
                     const XSH_SessionType session,
                     const XSH_OpeningRange &or_state,
                     const XSH_DailyRiskState &daily,
                     const string blocker)
  {
   string session_text="NONE";
   if(session==XSH_SESSION_LONDON) session_text="LONDON";
   if(session==XSH_SESSION_NEWYORK) session_text="NEWYORK";

   string text=StringFormat("XAU Session Hybrid\\nSymbol: %s\\nSession: %s\\nOR: %.2f / %.2f\\nTradesToday: %d\\nBlocked: %s",
                            symbol,session_text,or_state.high,or_state.low,daily.trades_today,blocker);

   Comment(text);
  }

#endif
