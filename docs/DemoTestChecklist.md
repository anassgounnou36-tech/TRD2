# Demo Test Checklist

## Backtest protocol
- [ ] Run baseline backtest on XAUUSD M5 with broker-like spread.
- [ ] Run visual mode and verify OR values via journal/chart panel.
- [ ] Confirm trades only open inside configured session windows.
- [ ] Confirm no overnight holding when flattening is enabled.

## Realism checks
- [ ] Test with random execution delay enabled in MT5 strategy tester.
- [ ] Test with fixed execution delay enabled.
- [ ] Stress spread assumptions around session open.
- [ ] Validate stop-distance constraints against symbol properties.

## Forward test protocol
- [ ] Forward test on MT5 for multiple weeks.
- [ ] Validate behavior in both low-volatility and high-volatility days.
- [ ] Confirm daily loss cap and trade caps work as expected.
- [ ] Verify duplicate-position safety suspension never triggers in normal operation.

## Acceptance gate
- [ ] Do not trust one short profitable period.
- [ ] Require consistency across backtest + forward test windows.
