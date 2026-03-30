#ifndef XSH_JOURNAL_MQH
#define XSH_JOURNAL_MQH

int g_xsh_log_handle=INVALID_HANDLE;
bool g_xsh_file_log_enabled=false;

void XSH_JournalInit(const bool enable_file)
  {
   g_xsh_file_log_enabled=false;
   g_xsh_log_handle=INVALID_HANDLE;
   if(!enable_file) return;

   string name="XAUSessionHybrid_log.csv";
   g_xsh_log_handle=FileOpen(name,FILE_WRITE|FILE_READ|FILE_CSV|FILE_SHARE_READ|FILE_ANSI);
   if(g_xsh_log_handle==INVALID_HANDLE)
     {
      Print("WARN file logging disabled: cannot open log file");
      return;
     }
   g_xsh_file_log_enabled=true;
   FileSeek(g_xsh_log_handle,0,SEEK_END);
  }

void XSH_JournalDone()
  {
   if(g_xsh_log_handle!=INVALID_HANDLE)
     {
      FileClose(g_xsh_log_handle);
      g_xsh_log_handle=INVALID_HANDLE;
     }
   g_xsh_file_log_enabled=false;
  }

void XSH_Log(const string level,const string msg)
  {
   string line=StringFormat("%s | %s",level,msg);
   Print(line);

   if(g_xsh_file_log_enabled && g_xsh_log_handle!=INVALID_HANDLE)
     {
      FileWrite(g_xsh_log_handle,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),level,msg);
      FileFlush(g_xsh_log_handle);
     }
  }

#endif
