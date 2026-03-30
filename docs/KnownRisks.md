# Known Risks

- Session-open spreads can spike and invalidate otherwise valid setups.
- Market execution slippage can reduce realized R multiple.
- OR quality degrades on abnormal news events; manual block windows are strongly recommended.
- Broker symbol suffix/timezone differences require session input confirmation.
- If volume normalization falls below broker minimum lot, entries will be intentionally blocked.
- Flat or fragmented liquidity periods can cause false breakouts/reclaims.

## User-side broker confirmations required
- Verify exact symbol name (e.g., XAUUSD, XAUUSDm, etc.).
- Verify server-time mapping for London and NY session inputs including DST changes.
- Verify actual stop/freeze levels and fill policy during high-volatility opens.
- Verify account mode (netting/hedging) and resulting position management behavior.
