# Strategy Rules

## Sessions
- Trade only in configured London and NY windows.
- Build OR using first `RangeMinutes` of each session.
- Do not open entries outside configured trade windows.

## Setup family A: Breakout continuation
- Require OR built and volatility qualified.
- Closed M5 bar closes beyond OR with ATR buffer.
- Candle body must be meaningful (avoid tiny-body breaks).
- Optional M15 EMA50 bias confirmation.

## Setup family B: Fakeout reclaim
- Track sweeps beyond OR high/low.
- Enter when a later close reclaims back through OR boundary.
- Reclaim close location must show directional strength.

## Selection and conflict rules
- Reclaim is evaluated first; breakout only if reclaim not active.
- No opposing direction allowed within same session.
- Family+direction can only be used once per session.
- Max one live strategy position at any time.

## Risk and exits
- Fractional risk sizing from stop distance.
- TP2 handled by initial take-profit.
- Move stop to breakeven after 1R when enabled.
- Max hold time closes stale trades.
- Optional flatten outside session windows.
