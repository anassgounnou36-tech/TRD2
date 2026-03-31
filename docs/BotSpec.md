# XAU Session Hybrid EA

Pure-MQL5 MT5 Expert Advisor targeting XAUUSD intraday sessions for XM-Standard style execution.

## Core design
- M5 execution with M15 context filters
- Two configurable session windows: London and New York
- Opening Range (OR) from first session minutes
- Two setup families:
  - Breakout continuation
  - Liquidity sweep + reclaim reversal
- One-position-at-a-time risk-first operation

## Hard safety controls
- Symbol validity and trade environment checks
- Spread/ATR/range quality filters
- Daily drawdown guard
- Trades/day and trades/session limits
- Duplicate-position integrity suspension
- Non-fatal file logging failures

## Required compile targets
- `/MQL5/Experts/XAUSessionHybridEA.mq5`
- `/MQL5/Scripts/XAUSessionHybrid_SymbolDiagnostics.mq5`
- `/MQL5/Scripts/XAUSessionHybrid_BarAudit.mq5`
