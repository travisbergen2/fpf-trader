//+------------------------------------------------------------------+
//| FPF_EA.mq5 |
//| Copyright 2025, Manus AI |
//| Fractal Personality Field Expert Advisor |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Manus AI"
#property link      "https://www.manus.im"
#property version   "1.00"
#property description "A paradigm-shifting institutional grade EA based on Fractal Personality Fields and Chronoceptional Dynamics."

// Include the core components
#include "FPF_Engine.mqh"
#include "Chronoception.mqh"
#include <Trade\Trade.mqh> // Required for CTrade class
#include <Arrays\ArrayDouble.mqh> // Required for CArrayDouble class

//--- Input Parameters ---
input string Inp_FPF_Settings = "--- FPF Settings ---";
input double Inp_Damping_k = 0.01;      // Damping coefficient (k)
input double Inp_TimeStep_dt = 0.01;    // Time step (dt) for RK4 integration

input string Inp_Chrono_Settings = "--- Chronoception Settings ---";
input ENUM_CHRONO_TYPE Inp_Chrono_Type = CHRONO_TICK_BAR; // Market time type
input int Inp_Chrono_Threshold = 100;   // Ticks or Volume to close a bar

input string Inp_Social_Settings = "--- Social Field Settings ---";
// The base symbol is the one the EA is attached to (e.g., XAUUSD)
// The user's model requires a web of related pairs.
// We will use a comma-separated list for the related symbols.
input string Inp_Related_Symbols = "EURUSD,GBPUSD,USDJPY,EURXAU,GBPXAU,JPYXAU";

//--- Global Objects ---
CFractalPersonalityField g_fpf_engine;
CChronoception g_chrono_engine(Inp_Chrono_Type, Inp_Chrono_Threshold);
CTrade g_trade; // MQL5 Trade object for execution
CArrayDouble *g_p_history = NULL; // History of FPF states for self-tuning (Must be pointer or initialized in OnInit)

//--- Input Parameters ---
input string Inp_Trade_Settings = "--- Trading Settings ---";
input double Inp_Lot_Size = 0.01;
input int Inp_Magic_Number = 12345;
input double Inp_Min_Profit_Factor = 1.5; // For self-tuning

//--- Global Variables ---
string g_related_symbols_array[];
int g_related_symbols_count = 0;
double g_point_value; // Symbol's point value for calculations

// Store previous tick data for each related symbol for proper correlation analysis
struct SSymbolTickData
{
    double last_price;
    long last_time;
};
SSymbolTickData g_related_symbols_prev_tick[];

//+------------------------------------------------------------------+
//| Expert initialization function |
//+------------------------------------------------------------------+
int OnInit()
{
    // 1. Initialize FPF Engine
    g_fpf_engine.SetParameters(Inp_Damping_k, Inp_TimeStep_dt);
    
    // Initialize P vector to a non-zero state (e.g., small random values or a default state)
    double initial_P[FPF_DIMENSION];
    for (int i = 0; i < FPF_DIMENSION; i++)
        initial_P[i] = MathRand() / 32767.0 * 0.1; // Small random start
    g_fpf_engine.Initialize(initial_P);

    // 2. Initialize Trade Object and Magic Number
    g_trade.SetExpertMagicNumber(Inp_Magic_Number);
    g_trade.SetTypeFilling(ORDER_FILLING_FOK); // Use FOK as a robust default

    Print("DEBUG: Trade object initialized with Magic Number: ", Inp_Magic_Number);
    
    // Initialize CArrayDouble
    g_p_history = new CArrayDouble();
    if (g_p_history == NULL)
    {
        Print("ERROR: Failed to create CArrayDouble object.");
        return(INIT_FAILED);
    }

    // 3. Parse and Check Related Symbols (The Social Field)
    // StringSplit returns the number of elements
    g_related_symbols_count = StringSplit(Inp_Related_Symbols, ',', g_related_symbols_array);

    if (g_related_symbols_count == 0)
    {
        Print("ERROR: No related symbols defined. The Social Field is empty. EA will not run.");
        return(INIT_FAILED);
    }

    // Initialize previous tick data array
    ArrayResize(g_related_symbols_prev_tick, g_related_symbols_count);

    // Check if all symbols exist and subscribe to them
    for (int i = 0; i < g_related_symbols_count; i++)
    {
        string symbol = g_related_symbols_array[i];
        if (!SymbolSelect(symbol, true))
        {
            Print("WARNING: Could not select symbol '", symbol, "'. It will be ignored.");
            g_related_symbols_array[i] = ""; // Mark as invalid
        }
        else
        {
            // Initialize previous tick data
            MqlTick tick;
            if (SymbolInfoTick(symbol, tick))
            {
                g_related_symbols_prev_tick[i].last_price = tick.last;
                g_related_symbols_prev_tick[i].last_time = tick.time_msc;
                Print("DEBUG: Initialized symbol ", symbol, " at price ", tick.last);
            }
        }
    }

    // 4. Get Symbol Info
    g_point_value = SymbolInfoDouble(Symbol(), SYMBOL_POINT);

    // 5. Display Initial State
    Print("FPF EA Initialized.");
    Print("Base Symbol: ", Symbol());
    Print("Chronoception Type: ", (string)Inp_Chrono_Type, " with Threshold: ", Inp_Chrono_Threshold); // EnumToString is not a native MQL5 function
    Print("Social Field Symbols: ", Inp_Related_Symbols);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up CArrayDouble object
    if (g_p_history != NULL)
    {
        delete g_p_history;
        g_p_history = NULL;
    }
    
    Print("FPF EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function |
//+------------------------------------------------------------------+
void OnTick()
{
    // 1. Process the Main Symbol's Tick (Chronoception)
    MqlTick current_tick;
    if (!SymbolInfoTick(Symbol(), current_tick))
        return; // Failed to get tick data

    bool new_chrono_bar = g_chrono_engine.ProcessTick(current_tick);

    // 2. If a new Chrono-Bar has closed, update the FPF state
    if (new_chrono_bar)
    {
        Print("========== NEW CHRONO-BAR FORMED ==========");

        // A. Calculate the External Forcing Vector (A_ext)
        double A_ext_vector[FPF_DIMENSION];
        CalculateExternalForcing(A_ext_vector);
        LogExternalForcing(A_ext_vector);

        // B. Update the FPF Engine (The "Emotional Lens" blinks)
        g_fpf_engine.AdvanceState(A_ext_vector);

        // C. Implement the Trading Logic: Expectation -> Action
        TradingLogic(A_ext_vector);

        // D. Implement the Self-Tuning Mechanism: New Perspective
        SelfTuningMechanism();

        // E. Log the new state for research/debugging
        LogFPFState();

        Print("==========================================");
    }
}

//+------------------------------------------------------------------+
//| Custom function to calculate the External Forcing Vector (A_ext) |
//| This is the core of the FPF's sensory input. |
//+------------------------------------------------------------------+
void CalculateExternalForcing(double &A_ext_vector[])
{
    // Reset vector
    for (int i = 0; i < FPF_DIMENSION; i++)
        A_ext_vector[i] = 0.0;

    // --- 1. Chronoception (Time Axis) ---
    // The Temporal Density from the Chronoception module directly feeds the Time Axis.
    // We need to normalize the raw density value (GetTemporalDensity()) to a range like [-1, 1].
    // For simplicity now, we'll use a raw value, but this is a key area for tuning.
    A_ext_vector[AXIS_TIME] = g_chrono_engine.GetTemporalDensity() * 0.01; // Scaling factor for stability

    // --- 2. Price Action (Emotion & Will Axes) ---
    // Emotion (Volatility/Momentum): Use the range of the last chrono-bar.
    double bar_range = g_chrono_engine.GetHigh() - g_chrono_engine.GetLow();
    double bar_direction = g_chrono_engine.GetClose() - g_chrono_engine.GetOpen();
    
    // Emotion: High range = High Volatility/Emotion
    A_ext_vector[AXIS_EMOTION] = bar_range * 1000.0; // Scaling factor needed

    // Will: Directional conviction (Momentum)
    A_ext_vector[AXIS_WILL] = bar_direction * 1000.0; // Scaling factor needed

    // --- 3. Social Field (Social Axis) ---
    // The Social Axis is influenced by the coherence/divergence of related symbols.
    double social_coherence_score = 0.0;
    int valid_symbols = 0;

    // Get the direction of the main symbol's last chrono-bar
    double main_direction = MathSign(bar_direction);

    for (int i = 0; i < g_related_symbols_count; i++)
    {
        string symbol = g_related_symbols_array[i];
        if (symbol == "") continue; // Skip invalid symbols

        MqlTick tick;
        if (SymbolInfoTick(symbol, tick))
        {
            // Calculate the actual price change since last chrono-bar for this symbol
            double price_change = tick.last - g_related_symbols_prev_tick[i].last_price;
            double related_direction = MathSign(price_change);

            // Check if the related symbol's direction aligns with main symbol's direction
            if (related_direction == main_direction && main_direction != 0)
                social_coherence_score += 1.0;
            else if (related_direction != 0 && main_direction != 0)
                social_coherence_score -= 1.0;

            // Update the stored tick data for next comparison
            g_related_symbols_prev_tick[i].last_price = tick.last;
            g_related_symbols_prev_tick[i].last_time = tick.time_msc;

            valid_symbols++;
        }
    }

    if (valid_symbols > 0)
    {
        // Normalize the score to [-1, 1]
        A_ext_vector[AXIS_SOCIAL] = social_coherence_score / valid_symbols * 0.1; // Scaling factor
    }

    // --- 4. Cognition Axis ---
    // The Cognition Axis is often an internal pattern recognition input.
    // For now, we leave it at 0.0, but this could be fed by a
    // pattern recognition module (e.g., fractal dimension analysis).
    // Let's use a simple fractal proxy: the ratio of the bar range to the average range.
    double avg_range = 0.0; // In a real system, this would be a moving average of bar_range
    // Placeholder for simple Cognition input:
    A_ext_vector[AXIS_COGNITION] = MathAbs(bar_direction) * 1000.0; // Proxy for conviction magnitude
}

//+------------------------------------------------------------------+
//| Custom function for Trading Logic: Expectation -> Action |
//+------------------------------------------------------------------+
void TradingLogic(double &A_ext_vector[])
{
    // 1. Check for existing position
    if (PositionSelect(Symbol()))
    {
        Print("DEBUG: Position already open. Checking for exit signal...");
        // Position exists, check for exit signal (e.g., Will/Emotion decay)
        CheckForExit();
        return;
    }

    // 2. Generate Expectation (Prediction) from FPF Derivative
    double dPdt[FPF_DIMENSION];
    g_fpf_engine.GetDerivative(dPdt, A_ext_vector);
    LogDerivative(dPdt);

    // Expectation: A strong, coherent directional move (Will) supported by high Volatility (Emotion)
    double will_derivative = dPdt[AXIS_WILL];
    double emotion_state = g_fpf_engine.GetAxisValue(AXIS_EMOTION);
    double social_state = g_fpf_engine.GetAxisValue(AXIS_SOCIAL);

    // --- Signal Generation Rules (Placeholder for user's quadrant logic) ---
    // Rule: Enter when Will is emerging (high derivative) and Emotion is high (volatility)
    // and Social Field is coherent (positive social state).
    double entry_threshold = 0.005; // To be optimized
    double emotion_threshold = 0.05; // To be optimized
    double social_threshold = 0.01; // To be optimized

    Print(StringFormat("=== SIGNAL ANALYSIS ===\n" +
        "  Will Derivative: %.6f (threshold: %.6f)\n" +
        "  Emotion State:   %.6f (threshold: %.6f)\n" +
        "  Social State:    %.6f (threshold: %.6f)",
        will_derivative, entry_threshold,
        emotion_state, emotion_threshold,
        social_state, social_threshold));

    if (emotion_state > emotion_threshold && social_state > social_threshold)
    {
        // BUY Signal: Strong positive Will emergence
        if (will_derivative > entry_threshold)
        {
            Print("*** BUY SIGNAL DETECTED: Strong positive Will emergence with high Emotion and positive Social coherence ***");
            ExecuteTrade(ORDER_TYPE_BUY);
        }
        // SELL Signal: Strong negative Will emergence
        else if (will_derivative < -entry_threshold)
        {
            Print("*** SELL SIGNAL DETECTED: Strong negative Will emergence with high Emotion and positive Social coherence ***");
            ExecuteTrade(ORDER_TYPE_SELL);
        }
        else
        {
            Print("DEBUG: Emotion and Social conditions met, but Will derivative not strong enough.");
        }
    }
    else
    {
        Print("DEBUG: Entry conditions not met (Emotion or Social thresholds not satisfied).");
    }
}

//+------------------------------------------------------------------+
//| Custom function to execute a trade (Action) |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE type)
{
    double price = SymbolInfoDouble(Symbol(), type == ORDER_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID);
    
    // Define SL/TP based on Chrono-Bar range (e.g., 2x last bar range for SL, 3x for TP)
    double bar_range = g_chrono_engine.GetHigh() - g_chrono_engine.GetLow();
    double sl_pips = bar_range * 2.0;
    double tp_pips = bar_range * 3.0;
    
    double sl_price = 0.0;
    double tp_price = 0.0;
    
    if (type == ORDER_TYPE_BUY)
    {
        sl_price = price - sl_pips;
        tp_price = price + tp_pips;
    }
    else // ORDER_TYPE_SELL
    {
        sl_price = price + sl_pips;
        tp_price = price - tp_pips;
    }
    
    // Normalize prices to symbol digits
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    sl_price = NormalizeDouble(sl_price, digits);
    tp_price = NormalizeDouble(tp_price, digits);
    
    // Execute the trade
    if (g_trade.PositionOpen(Symbol(), type, Inp_Lot_Size, price, sl_price, tp_price))
    {
        Print("TRADE OPENED: ", EnumToString(type), " at ", price, " SL:", sl_price, " TP:", tp_price);
    }
    else
    {
        Print("TRADE FAILED: ", g_trade.ResultRetcode(), " - ", g_trade.ResultComment());
    }
}

//+------------------------------------------------------------------+
//| Custom function to check for position exit |
//+------------------------------------------------------------------+
void CheckForExit()
{
    // Exit Logic: Close position if the FPF state moves into a "receptive" or "detached" state.
    // Receptive/Detached: Low Will and Low Emotion.
    double will_state = g_fpf_engine.GetAxisValue(AXIS_WILL);
    double emotion_state = g_fpf_engine.GetAxisValue(AXIS_EMOTION);

    double exit_will_threshold = 0.005; // To be optimized
    double exit_emotion_threshold = 0.01; // To be optimized

    Print(StringFormat("=== EXIT ANALYSIS ===\n" +
        "  Will State:    %.6f (abs threshold: %.6f)\n" +
        "  Emotion State: %.6f (threshold: %.6f)",
        will_state, exit_will_threshold,
        emotion_state, exit_emotion_threshold));

    if (MathAbs(will_state) < exit_will_threshold && emotion_state < exit_emotion_threshold)
    {
        Print("*** EXIT SIGNAL: FPF state moved to Receptive/Detached quadrant ***");
        // Get position info before closing for logging
        double profit = PositionGetDouble(POSITION_PROFIT);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        // Close the position
        if (g_trade.PositionClose(Symbol()))
        {
            Print(StringFormat("TRADE CLOSED: Type: %s | Open: %.5f | Profit: %.2f | Reason: Receptive/Detached",
                EnumToString(pos_type), open_price, profit));
        }
        else
        {
            Print("TRADE CLOSE FAILED: ", g_trade.ResultRetcode(), " - ", g_trade.ResultComment());
        }
    }
    else
    {
        Print("DEBUG: Exit conditions not met. Position remains open.");
    }
}

//+------------------------------------------------------------------+
//| Custom function for Self-Tuning Mechanism: New Perspective |
//+------------------------------------------------------------------+
void SelfTuningMechanism()
{
    // The "New Perspective" is the feedback loop that updates the FPF's parameters.
    // This is where the EA "learns about learning."
    
    // 1. Record the FPF state that led to the current Chrono-Bar's result
    double P[FPF_DIMENSION];
    g_fpf_engine.GetState(P);
    
    // Store the state vector P (5 doubles) and the bar's direction/profit factor
    // For simplicity, we will just store the P vector for now.
    // In a full implementation, this would involve storing the P vector, the trade result,
    // and using a machine learning algorithm to optimize the FPF's internal matrix
    // coefficients (m_J, m_k) to maximize the profit factor of the resulting trades.
    
    // For now, we will use a simple, conceptual self-tuning:
    // If the last trade was highly profitable, slightly increase the damping (m_k)
    // to stabilize the system and exploit the current regime.
    
    // Check the result of the last closed trade (if any)
    // This requires a more complex PositionHistoryGetTicket/PositionHistorySelect logic,
    // which is beyond the scope of this single edit, but the concept is here.
    
    // CONCEPTUAL SELF-TUNING LOGIC:
    /*
    // NOTE: The FPF_Engine needs public GetDamping and GetTimeStep methods for this to work.
    // Assuming they are added to FPF_Engine.mqh for this conceptual logic to compile.
    
    // if (LastTradeProfitFactor > Inp_Min_Profit_Factor)
    // {
    //     // Reward the current state by slightly increasing stability
    //     g_fpf_engine.SetParameters(g_fpf_engine.GetDamping() * 1.001, g_fpf_engine.GetTimeStep());
    //     Print("SELF-TUNING: Increased stability (Damping) after profitable trade.");
    // }
    // else if (LastTradeProfitFactor < 0.5)
    // {
    //     // Punish the current state by slightly decreasing stability (forcing a new regime)
    //     g_fpf_engine.SetParameters(g_fpf_engine.GetDamping() * 0.999, g_fpf_engine.GetTimeStep());
    //     Print("SELF-TUNING: Decreased stability (Damping) after poor trade.");
    // }
    */
}

//+------------------------------------------------------------------+
//| Custom function to log the current FPF state |
//+------------------------------------------------------------------+
void LogFPFState()
{
    double P[FPF_DIMENSION];
    g_fpf_engine.GetState(P);

    string log_message = StringFormat(
        "=== FPF STATE ===\n" +
        "  Cognition: %.6f | Emotion: %.6f | Will: %.6f | Social: %.6f | Time: %.6f\n" +
        "  ChronoBar | O: %.5f | H: %.5f | L: %.5f | C: %.5f | Ticks: %d\n" +
        "  Temporal Density: %.4f",
        P[AXIS_COGNITION], P[AXIS_EMOTION], P[AXIS_WILL], P[AXIS_SOCIAL], P[AXIS_TIME],
        g_chrono_engine.GetOpen(), g_chrono_engine.GetHigh(),
        g_chrono_engine.GetLow(), g_chrono_engine.GetClose(),
        g_chrono_engine.GetTickCount(),
        g_chrono_engine.GetTemporalDensity()
    );

    Print(log_message);
}

//+------------------------------------------------------------------+
//| Custom function to log External Forcing Vector |
//+------------------------------------------------------------------+
void LogExternalForcing(double &A_ext_vector[])
{
    string log_message = StringFormat(
        "=== EXTERNAL FORCING ===\n" +
        "  A_ext[Cognition]: %.6f\n" +
        "  A_ext[Emotion]:   %.6f\n" +
        "  A_ext[Will]:      %.6f\n" +
        "  A_ext[Social]:    %.6f\n" +
        "  A_ext[Time]:      %.6f",
        A_ext_vector[AXIS_COGNITION], A_ext_vector[AXIS_EMOTION],
        A_ext_vector[AXIS_WILL], A_ext_vector[AXIS_SOCIAL], A_ext_vector[AXIS_TIME]
    );

    Print(log_message);
}

//+------------------------------------------------------------------+
//| Custom function to log FPF Derivative (Expectation) |
//+------------------------------------------------------------------+
void LogDerivative(double &dPdt[])
{
    string log_message = StringFormat(
        "=== FPF DERIVATIVE (Expectation) ===\n" +
        "  dP/dt[Cognition]: %.6f\n" +
        "  dP/dt[Emotion]:   %.6f\n" +
        "  dP/dt[Will]:      %.6f (*** KEY for entry ***)\n" +
        "  dP/dt[Social]:    %.6f\n" +
        "  dP/dt[Time]:      %.6f",
        dPdt[AXIS_COGNITION], dPdt[AXIS_EMOTION],
        dPdt[AXIS_WILL], dPdt[AXIS_SOCIAL], dPdt[AXIS_TIME]
    );

    Print(log_message);
}

//+------------------------------------------------------------------+
//| Need to modify FPF_Engine.mqh to accept A_ext in AdvanceState |
//+------------------------------------------------------------------+
