#ifndef XSH_DIAGNOSTICS_MQH
#define XSH_DIAGNOSTICS_MQH

#include <XAUSessionHybrid/Types.mqh>

string XSH_BuildHealthLine(const bool ok,const string msg)
  {
   return StringFormat("[%s] %s",(ok?"OK":"BLOCK"),msg);
  }

void XSH_PrintBlocker(const string source,const string reason)
  {
   PrintFormat("BLOCKER %s: %s",source,reason);
  }

void XSH_ResetDiagnosticsCounters(XSH_DiagnosticsCounters &counters)
  {
   counters.sessions_seen=0;
   counters.blocked_or_too_wide=0;
   counters.blocked_spread=0;
   counters.blocked_classifier_conflict=0;
   counters.setups_scored_rejected=0;
   counters.setups_accepted=0;
   counters.trades_placed=0;
  }

void XSH_CountBlockReason(XSH_DiagnosticsCounters &counters,const string reason)
  {
   string reason_upper=reason;
   StringToUpper(reason_upper);
   if(StringFind(reason_upper,"OR TOO WIDE",0)>=0) counters.blocked_or_too_wide++;
   if(StringFind(reason_upper,"SPREAD",0)>=0) counters.blocked_spread++;
   if(StringFind(reason_upper,"CONFLICTS WITH SESSION CLASSIFIER REGIME",0)>=0) counters.blocked_classifier_conflict++;
  }

void XSH_LogDiagnosticsSummary(const XSH_DiagnosticsCounters &counters)
  {
   PrintFormat("XSH Diagnostics summary: sessions=%d blocked_or=%d blocked_spread=%d blocked_conflict=%d scored_rejected=%d setups_accepted=%d trades_placed=%d",
               counters.sessions_seen,
               counters.blocked_or_too_wide,
               counters.blocked_spread,
               counters.blocked_classifier_conflict,
               counters.setups_scored_rejected,
               counters.setups_accepted,
               counters.trades_placed);
  }

#endif
