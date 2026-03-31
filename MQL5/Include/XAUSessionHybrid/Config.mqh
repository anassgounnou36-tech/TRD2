#ifndef XSH_CONFIG_MQH
#define XSH_CONFIG_MQH

input string InpSymbol = "";
input ulong  InpMagic = 30032026;
input bool   InpEnableLongs = true;
input bool   InpEnableShorts = true;
input bool   InpEnableChartPanel = true;
input bool   InpEnableFileLogs = false;
input int    InpSlippagePoints = 100;

input ENUM_TIMEFRAMES InpSignalTF = PERIOD_M5;
input ENUM_TIMEFRAMES InpContextTF = PERIOD_M15;

input int InpLondonStartHour = 8;
input int InpLondonStartMinute = 0;
input int InpLondonRangeMinutes = 15;
input int InpLondonTradeMinutes = 90;
input int InpNYStartHour = 13;
input int InpNYStartMinute = 30;
input int InpNYRangeMinutes = 15;
input int InpNYTradeMinutes = 90;

input int    InpATRPeriod = 14;
input double InpMinRangeATRFrac = 0.25;
input double InpMaxRangeATRFrac = 1.25;
input double InpMinRangeSpreadMult = 5.0;
input double InpBreakoutBufferATRFrac = 0.10;
input double InpStopBufferATRFrac = 0.10;
input double InpReclaimBodyStrengthFrac = 0.50;
input bool   InpUseBiasFilter = true;
input int    InpBiasEMAPeriod = 50;

input double InpRiskPct = 0.75;
input double InpMaxDailyLossPct = 2.0;
input int    InpMaxTradesPerDay = 4;
input int    InpMaxTradesPerSession = 2;
input bool   InpEnableDailyProfitLock = true;
input double InpDailyProfitLockR = 2.0;
input bool   InpDailyLossUseEquity = true;
input bool   InpAllowMinLotOverride = false;

input double InpTP1_R = 1.0;
input double InpTP2_R = 2.0;
input double InpTrailATRFrac = 0.75;
input int    InpMaxHoldMinutes = 180;
input bool   InpFlattenAtSessionEnd = true;
input bool   InpMoveToBEAfterTP1 = true;

input double InpMaxSpreadATRFrac = 0.12;
input bool   InpUseNewsBlockWindows = false;
input string InpManualBlockWindows = "";

input double InpMinSetupScore = 65.0;
input bool   InpAllowMixedRegimeSignals = false;
input int    InpClassifierProbeLookbackBars = 12;
input int    InpMaxORProbesBeforeBlock = 4;
input double InpMaxExtensionATRFrac = 2.0;

input double InpBreakoutMinBodyRangeFrac = 0.50;
input double InpBreakoutMinBodyATRFrac = 0.20;
input double InpBreakoutMaxCounterWickFrac = 0.60;
input bool   InpUseBreakoutRetest = false;
input int    InpBreakoutRetestMaxBars = 3;
input double InpBreakoutRetestToleranceATRFrac = 0.15;
input double InpMaxBreakoutATRFrac = 0.90;

input double InpReclaimMinSweepATRFrac = 0.12;
input double InpReclaimMinSweepSpreadMult = 1.50;
input double InpReclaimCloseBackATRFrac = 0.05;
input int    InpReclaimMaxBarsAfterSweep = 4;
input double InpReclaimMaxCounterWickFrac = 0.70;

input int    InpMinTrailStepPoints = 120;
input double InpTrailOnlyAfterR = 1.0;
input bool   InpUseStructureTrail = true;

#endif
