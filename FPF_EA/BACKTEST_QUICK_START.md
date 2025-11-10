# FPF EA - Quick Start Backtesting Guide

## 🚀 Fast Track to Your First Backtest

### Prerequisites
- MetaTrader 5 installed
- Historical data for XAUUSD (or your chosen symbol)
- Related symbols data: EURUSD, GBPUSD, USDJPY

---

## Step-by-Step: 5 Minutes to First Results

### 1. Compile (30 seconds)
```
MetaEditor → Open FPF_EA.mq5 → Press F7 → Wait for "0 errors"
```

### 2. Open Strategy Tester (10 seconds)
```
MetaTrader 5 → Press Ctrl+R
```

### 3. Configure Basic Settings (1 minute)
```
Expert Advisor:  FPF_EA
Symbol:          XAUUSD
Period:          M1 (EA will use Chronoception internally)
Date:            Last 3 months
Deposit:         10000 USD
Leverage:        1:100
Optimization:    Disabled (for first test)
```

### 4. Load Parameters (30 seconds)
```
Click "Settings" → "Load" → Select "FPF_EA_Backtest.set" → OK
```

### 5. Start Backtest (10 seconds)
```
Click "Start" button → Wait for completion
```

### 6. Check Results (2 minutes)
```
Tab: Results → View equity curve, drawdown, profit factor
Tab: Journal → Search for "TRADE OPENED" and "TRADE CLOSED"
```

---

## 📊 What to Look for in Results

### Success Indicators ✅
- **Profit Factor > 1.5:** Good signal quality
- **Max Drawdown < 20%:** Risk management working
- **Win Rate > 45%:** Entry logic is effective
- **Trades Count > 20:** Sufficient statistical sample

### Red Flags 🚩
- **No trades:** Check if related symbols loaded correctly (Journal tab)
- **All losing trades:** Thresholds may be too aggressive
- **Too many trades:** Chrono_Threshold may be too low
- **Immediate losses:** Check spread and slippage settings

---

## 🔍 Journal Analysis: What the Logs Tell You

### Pattern 1: Normal Operation
```
CHRONOCEPTION: TICK Bar Closed...
=== EXTERNAL FORCING ===
=== FPF DERIVATIVE ===
=== SIGNAL ANALYSIS ===
DEBUG: Entry conditions not met...
=== FPF STATE ===
```
**Meaning:** EA is processing bars correctly, waiting for entry signals

---

### Pattern 2: Trade Entry
```
CHRONOCEPTION: TICK Bar Closed...
=== SIGNAL ANALYSIS ===
*** BUY SIGNAL DETECTED ***
TRADE OPENED: ORDER_TYPE_BUY at 2650.50...
```
**Meaning:** All 3 conditions met (Will, Emotion, Social), trade executed

---

### Pattern 3: Trade Exit
```
=== EXIT ANALYSIS ===
*** EXIT SIGNAL: FPF state moved to Receptive/Detached quadrant ***
TRADE CLOSED: Type: POSITION_TYPE_BUY | Profit: 45.23
```
**Meaning:** EA detected low Will + low Emotion, closed position

---

## 🎯 Optimization Quick Tips

### If Too Few Trades:
```
↓ Inp_Chrono_Threshold  (e.g., 100 → 50)  = More bars = more signals
↓ entry_threshold       (line 288)         = Easier Will requirement
↓ emotion_threshold     (line 289)         = Lower volatility needed
↓ social_threshold      (line 290)         = Less inter-market coherence required
```

### If Too Many Trades:
```
↑ Inp_Chrono_Threshold  (e.g., 100 → 200) = Fewer bars = fewer signals
↑ entry_threshold       (line 288)         = Stronger Will required
↑ emotion_threshold     (line 289)         = Higher volatility needed
↑ social_threshold      (line 290)         = Stronger coherence required
```

### If Poor Win Rate:
```
Test different Inp_Chrono_Type:
  0 = TICK_BAR     (time-agnostic, pure activity)
  1 = VOLUME_BAR   (liquidity-based)
  2 = RANGE_BAR    (volatility-based)

Adjust SL/TP multipliers in ExecuteTrade() (lines 285-286):
  Current: SL = 2x bar range, TP = 3x bar range
  More conservative: SL = 3x, TP = 4x
  More aggressive: SL = 1.5x, TP = 2.5x
```

---

## 📈 Backtest Scenarios to Try

### Scenario 1: Conservative (Low Risk)
```
Inp_Damping_k: 0.05 (high stability)
Inp_Chrono_Threshold: 200 (longer bars)
entry_threshold: 0.01 (strong Will needed)
Inp_Lot_Size: 0.01
```

### Scenario 2: Aggressive (High Frequency)
```
Inp_Damping_k: 0.001 (high reactivity)
Inp_Chrono_Threshold: 50 (short bars)
entry_threshold: 0.002 (weak Will acceptable)
Inp_Lot_Size: 0.05
```

### Scenario 3: Balanced (Default)
```
Use FPF_EA_Backtest.set as-is
```

---

## 🐛 Troubleshooting Common Issues

### Issue: "Symbol EURXAU not found"
**Solution:** Edit Inp_Related_Symbols to only include available pairs:
```
Original: EURUSD,GBPUSD,USDJPY,EURXAU,GBPXAU,JPYXAU
Fixed:    EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,NZDUSD
```

### Issue: "No temporal density calculated"
**Cause:** Chrono bars not forming (threshold too high or no tick data)
**Solution:** Lower Inp_Chrono_Threshold to 50 or check data quality

### Issue: "SetMarginMode error"
**Status:** ✅ FIXED in this debug version

### Issue: "Social Field always 0"
**Status:** ✅ FIXED in this debug version (was using tick.last - tick.bid)

---

## 📊 Sample Expected Results (XAUUSD, 3 months)

### Typical Performance (Default Settings):
```
Total Trades:       15-50 (depends on volatility period)
Win Rate:          45-60%
Profit Factor:     1.2-2.5
Max Drawdown:      10-25%
Avg Trade Duration: 30-120 minutes (in Chrono-bars)
```

**Note:** These are estimates. Actual results depend on market conditions, spread, and parameters.

---

## 🔬 Advanced: Log Analysis for Research

### Extract Key Data Points:
```bash
# Search Journal for specific events:
- "NEW CHRONO-BAR FORMED" → Count bars processed
- "BUY SIGNAL DETECTED" → Analyze entry conditions
- "TRADE CLOSED" → Extract profit/loss data
- "Temporal Density:" → Study market activity patterns
```

### Correlation Studies:
1. **Temporal Density vs Profit:**
   - High density trades → Profit?
   - Low density trades → Profit?

2. **Social Coherence vs Win Rate:**
   - Social > 0.05 → Win rate?
   - Social < 0.01 → Win rate?

3. **FPF Quadrants:**
   - Which quadrant produces most profits?
   - Which quadrant signals best exits?

---

## 🎓 Understanding the FPF Framework

### The 5 Axes (Simplified):
- **Cognition (C):** Pattern recognition, abstract logic
- **Emotion (E):** Market volatility, immersion
- **Will (W):** Directional conviction, momentum ⭐ KEY for entry
- **Social (S):** Inter-market coherence, correlation
- **Time (T):** Temporal compression, urgency

### The Trading Hypothesis:
```
When Will is EMERGING (high dP/dt[Will])
AND Emotion is HIGH (high volatility)
AND Social Field is COHERENT (aligned markets)
→ Market personality is in "Directive/Immersed" quadrant
→ ENTER trade in direction of Will

When Will DECAYS (low |Will|)
AND Emotion DROPS (low volatility)
→ Market moves to "Receptive/Detached" quadrant
→ EXIT trade
```

---

## Next Steps After First Backtest

1. ✅ Review profit factor and drawdown
2. ✅ Read Journal logs to understand EA behavior
3. ✅ Adjust one parameter at a time
4. ✅ Compare results across different Chrono_Types
5. ✅ Enable genetic optimization if satisfied with concept

---

**Ready to witness your FPF theory in action!** 🚀

Start with the default settings first, then iterate. The logs will tell you exactly what the EA is "thinking" at each decision point.
