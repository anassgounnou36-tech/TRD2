# Parameter Reference

## General
- `InpSymbol`: optional override (empty => chart symbol)
- `InpMagic`: EA magic number
- `InpEnableLongs` / `InpEnableShorts`
- `InpEnableChartPanel`
- `InpEnableFileLogs` (non-fatal if file open fails)
- `InpSlippagePoints`

## Timeframes
- `InpSignalTF` (designed for M5)
- `InpContextTF` (designed for M15)

## Sessions
- London: `InpLondonStartHour`, `InpLondonStartMinute`, `InpLondonRangeMinutes`, `InpLondonTradeMinutes`
- New York: `InpNYStartHour`, `InpNYStartMinute`, `InpNYRangeMinutes`, `InpNYTradeMinutes`

## Core quality filters
- ATR and OR bounds: `InpATRPeriod`, `InpMinRangeATRFrac`, `InpMaxRangeATRFrac`, `InpMinRangeSpreadMult`
- Spread filter: `InpMaxSpreadATRFrac`
- Optional manual blocks: `InpUseNewsBlockWindows`, `InpManualBlockWindows`

## Session classifier (v2)
- `InpClassifierProbeLookbackBars`
- `InpMaxORProbesBeforeBlock`
- `InpMaxExtensionATRFrac`
- Classifier outputs continuation / reversal / no-trade regime.

## Setup scoring (v2)
- `InpMinSetupScore` (balanced default: `65`)
- Score threshold is the main quality gate.

## Breakout quality (v2)
- `InpBreakoutBufferATRFrac`
- `InpBreakoutMinBodyRangeFrac`
- `InpBreakoutMinBodyATRFrac`
- `InpBreakoutMaxCounterWickFrac`
- `InpMaxBreakoutATRFrac`
- Optional retest controls:
  - `InpUseBreakoutRetest`
  - `InpBreakoutRetestMaxBars`
  - `InpBreakoutRetestToleranceATRFrac`

## Reclaim quality (v2)
- `InpReclaimBodyStrengthFrac`
- `InpReclaimMinSweepATRFrac`
- `InpReclaimMinSweepSpreadMult`
- `InpReclaimCloseBackATRFrac`
- `InpReclaimMaxBarsAfterSweep`
- `InpReclaimMaxCounterWickFrac`
- Mixed regime override: `InpAllowMixedRegimeSignals`

## Risk
- `InpRiskPct`
- `InpMaxDailyLossPct`
- `InpMaxTradesPerDay`
- `InpMaxTradesPerSession`
- Profit lock controls: `InpEnableDailyProfitLock`, `InpDailyProfitLockR`
- `InpAllowMinLotOverride`

## Exits / management (v2)
- `InpTP1_R`, `InpTP2_R`
- `InpTrailATRFrac`
- `InpMoveToBEAfterTP1`
- `InpMinTrailStepPoints`
- `InpTrailOnlyAfterR`
- `InpUseStructureTrail`
- `InpMaxHoldMinutes`
- `InpFlattenAtSessionEnd`
