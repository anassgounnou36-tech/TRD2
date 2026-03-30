#ifndef XSH_CHART_PANEL_MQH
#define XSH_CHART_PANEL_MQH

#include <XAUSessionHybrid/Types.mqh>

void XSH_UpdatePanel(const long chart_id,
                     const string symbol,
                     const XSH_SessionType session,
                     const XSH_OpeningRange &or_state,
                     const XSH_DailyRiskState &daily,
                     const string blocker,
                     const double spread,
                     const int session_trades_used,
                     const string setup_candidate,
                     const bool has_open_position)
  {
   string session_text="NONE";
   if(session==XSH_SESSION_LONDON) session_text="LONDON";
   if(session==XSH_SESSION_NEWYORK) session_text="NEWYORK";

   string text=StringFormat("XAU Session Hybrid\\nChartID: %I64d\\nSymbol: %s\\nSession: %s\\nOR Built: %s\\nOR: %.2f / %.2f\\nSpread: %.2f\\nSessionTrades: %d\\nCandidate: %s\\nOpenPos: %s\\nTradesToday: %d\\nBlocked: %s",
                            chart_id,symbol,session_text,(or_state.built?"YES":"NO"),or_state.high,or_state.low,spread,session_trades_used,setup_candidate,(has_open_position?"YES":"NO"),daily.trades_today,blocker);

   Comment(text);
  }

#endif
