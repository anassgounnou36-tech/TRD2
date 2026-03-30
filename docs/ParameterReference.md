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

## Signal quality
- ATR period and range bounds (`InpATRPeriod`, `InpMinRangeATRFrac`, `InpMaxRangeATRFrac`)
- Spread/range floor via `InpMinRangeSpreadMult`
- Breakout and stop buffers via ATR fractions
- Reclaim body strength fraction
- Optional EMA bias (`InpUseBiasFilter`, `InpBiasEMAPeriod`)

## Risk
- `InpRiskPct`
- `InpMaxDailyLossPct`
- `InpMaxTradesPerDay`
- `InpMaxTradesPerSession`
- Profit lock controls (`InpEnableDailyProfitLock`, `InpDailyProfitLockR`)

## Exits
- `InpTP1_R`, `InpTP2_R`
- `InpTrailATRFrac` (active ATR trailing-stop distance fraction on M5)
- `InpMaxHoldMinutes`
- `InpFlattenAtSessionEnd`
- `InpMoveToBEAfterTP1`

## Filters
- `InpMaxSpreadATRFrac`
- `InpUseNewsBlockWindows`
- `InpManualBlockWindows` format: `HH:MM-HH:MM;HH:MM-HH:MM`
