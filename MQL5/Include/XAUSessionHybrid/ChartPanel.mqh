#ifndef XSH_CHART_PANEL_MQH
#define XSH_CHART_PANEL_MQH

#include <XAUSessionHybrid/Types.mqh>

void XSH_UpdatePanel(const long chart_id,
                     const string symbol,
                     const XSH_SessionType session,
                     const XSH_SessionRegime regime,
                     const XSH_OpeningRange &or_state,
                     const XSH_DailyRiskState &daily,
                     const string blocker,
                     const double spread,
                     const int session_trades_used,
                     const string setup_candidate,
                     const int active_direction,
                     const double setup_score,
                     const string lifecycle,
                     const bool has_open_position)
  {
   string session_text="NONE";
   if(session==XSH_SESSION_LONDON) session_text="LONDON";
   if(session==XSH_SESSION_NEWYORK) session_text="NEWYORK";
   string regime_text="NO_TRADE";
   if(regime==XSH_REGIME_CONTINUATION_FAVOR) regime_text="CONTINUATION_FAVOR";
   if(regime==XSH_REGIME_REVERSAL_FAVOR) regime_text="REVERSAL_FAVOR";
   string dir_text="NONE";
   if(active_direction>0) dir_text="LONG";
   if(active_direction<0) dir_text="SHORT";

   string text=StringFormat("XAU Session Hybrid v2\\nChartID: %I64d\\nSymbol: %s\\nSession: %s\\nClassifier: %s\\nOR Built: %s\\nOR: %.2f / %.2f\\nCandidate: %s\\nDirection: %s\\nSetupScore: %.1f\\nLifecycle: %s\\nSpread: %.2f\\nSessionTrades: %d\\nOpenPos: %s\\nTradesToday: %d\\nDailyBlocked: %s\\nBlocker: %s",
                            chart_id,symbol,session_text,regime_text,(or_state.built?"YES":"NO"),or_state.high,or_state.low,setup_candidate,dir_text,setup_score,lifecycle,spread,session_trades_used,(has_open_position?"YES":"NO"),daily.trades_today,(daily.blocked?"YES":"NO"),blocker);

   Comment(text);
  }

#endif
