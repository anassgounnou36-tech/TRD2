#ifndef XSH_TIME_WINDOWS_MQH
#define XSH_TIME_WINDOWS_MQH

#include <XAUSessionHybrid/Types.mqh>

int XSH_DayTag(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   return dt.year*10000+dt.mon*100+dt.day;
  }

datetime XSH_DayMinuteToTime(const datetime now,const int hour,const int minute)
  {
   MqlDateTime dt;
   TimeToStruct(now,dt);
   dt.hour=hour;
   dt.min=minute;
   dt.sec=0;
   return StructToTime(dt);
  }

bool XSH_IsInWindow(const datetime now,const datetime start,const int minutes)
  {
   datetime end=start+minutes*60;
   return (now>=start && now<end);
  }

XSH_SessionType XSH_GetCurrentSession(const datetime now,
                                      const int london_h,const int london_m,const int london_trade_min,
                                      const int ny_h,const int ny_m,const int ny_trade_min)
  {
   datetime london_start=XSH_DayMinuteToTime(now,london_h,london_m);
   datetime ny_start=XSH_DayMinuteToTime(now,ny_h,ny_m);
   if(XSH_IsInWindow(now,london_start,london_trade_min)) return XSH_SESSION_LONDON;
   if(XSH_IsInWindow(now,ny_start,ny_trade_min)) return XSH_SESSION_NEWYORK;
   return XSH_SESSION_NONE;
  }

#endif
