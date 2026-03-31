# Strategy Rules

## Sessions
- Trade only in configured London and NY windows.
- Build OR using first `RangeMinutes` of each session.
- Evaluate entries on closed M5 bars only (one-bar/one-decision discipline).
- Session classifier must approve regime before any order.

## Session classifier (v3 calibration)
- Classifies context as `CONTINUATION_FAVOR`, `REVERSAL_FAVOR`, `MIXED`, or `NO_TRADE`.
- Uses OR width vs ATR, early impulse quality, probe count, two-sided sweeps, M15 EMA slope, and extension from OR midpoint.
- `MIXED` is tradable only with stricter score gating.
- `NO_TRADE` blocks all entries.

## Setup scoring (v2)
- Every candidate setup is scored 0..100.
- Components:
  - Range quality (0..20)
  - Context alignment (0..20)
  - Trigger quality (0..25)
  - Execution quality (0..15)
  - Noise/trap penalty (0..20 negative)
- Trade allowed only if score >= `InpMinSetupScore`.
- Score breakdown is logged for each candidate.

## Setup family A: Breakout continuation
- Allowed only when classifier is `CONTINUATION_FAVOR`.
- In `REVERSAL_FAVOR`, allowed only if setup score clears conflict override threshold.
- Closed M5 breakout candle required (no intrabar trigger).
- Breakout must clear OR boundary with ATR buffer.
- Body quality filters reject tiny/doji breakouts and large counter-side wick conflict.
- Exhaustion filter rejects overextended break candles.
- Optional retest mode can require boundary retest/hold before entry.

## Setup family B: Fakeout reclaim
- Allowed in `REVERSAL_FAVOR`.
- In `CONTINUATION_FAVOR`, allowed only if setup score clears conflict override threshold.
- In `MIXED`, allowed only if setup score clears mixed-mode threshold.
- Sweep depth must be meaningful (ATR/spread based).
- Reclaim close must be decisively back across the level with body quality.
- Late reclaim invalidation via max-bars-after-sweep time decay.
- Two-sided recent sweep defaults to no-trade unless score override is high enough.

## Selection and lifecycle discipline
- Explicit lifecycle states: `NONE`, `WATCHING`, `ARMED`, `ORDER_ACTIVE`, `POSITION_OPEN`, `COMPLETED`, `INVALIDATED`.
- No repeated noisy order actions every tick.
- Family+direction can only be used once per session.
- No opposing direction allowed inside same session decision path.
- Max one live strategy position at any time.

## Risk and exits (v2 calm management)
- Fractional risk sizing from stop distance (no martingale/grid).
- Initial stop remains structure + ATR-buffer hybrid with broker stop/freeze safety checks.
- Breakeven move is one-time and only after progress threshold.
- Trailing is closed-bar driven and only updates when improvement exceeds `InpMinTrailStepPoints`.
- Trailing can be delayed until `InpTrailOnlyAfterR` and can use optional structure floor/ceiling support.
- Max hold time closes stale trades.
- Optional flatten outside session windows.

## Main blocker reasons
- Classifier `NO_TRADE`
- Classifier/signal conflict below override threshold
- Score below threshold
- Spread too high vs ATR and recent median context
- OR not built / OR quality invalid / OR extreme vs ATR and recent session OR context
- Session expired
- Family+direction already used or opposing-direction conflict
- Daily guard active (loss cap / trade cap / profit lock)
