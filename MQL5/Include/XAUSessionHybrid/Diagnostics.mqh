#ifndef XSH_DIAGNOSTICS_MQH
#define XSH_DIAGNOSTICS_MQH

string XSH_BuildHealthLine(const bool ok,const string msg)
  {
   return StringFormat("[%s] %s",(ok?"OK":"BLOCK"),msg);
  }

void XSH_PrintBlocker(const string source,const string reason)
  {
   PrintFormat("BLOCKER %s: %s",source,reason);
  }

#endif
