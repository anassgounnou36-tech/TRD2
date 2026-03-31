# Walk-Forward Protocol

1. Split history into multiple sequential windows (tune then forward-validate).
2. Optimize only conservative parameter ranges (avoid extreme overfit values).
3. Freeze selected parameters and run out-of-sample segment.
4. Repeat rolling forward through at least 3-5 segments.
5. Compare segment stability:
   - trade frequency
   - drawdown profile
   - expectancy consistency
6. Reject configurations with large regime fragility.

## Mandatory realism settings
- Use MT5 forward testing mode.
- Enable execution delays (random and fixed scenarios).
- Use realistic session times matching broker server time.
- Include spread stress scenarios for London/NY opens.
