//+------------------------------------------------------------------+
//| Chronoception.mqh |
//| Copyright 2025, Manus AI |
//| The Market's True Time Engine |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| ENUM_CHRONO_TYPE: Defines the type of market time bar |
//+------------------------------------------------------------------+
enum ENUM_CHRONO_TYPE
{
    CHRONO_TICK_BAR = 0, // Bar closes after a fixed number of ticks
    CHRONO_VOLUME_BAR = 1, // Bar closes after a fixed volume (real or tick)
    CHRONO_RANGE_BAR = 2 // Bar closes after a fixed price range (future expansion)
};

//+------------------------------------------------------------------+
//| CChronoception: Generates market-time bars and provides the |
//| temporal density (Time Axis input) for the FPF engine. |
//+------------------------------------------------------------------+
class CChronoception
{
private:
    // Input Parameters
    ENUM_CHRONO_TYPE m_chrono_type;
    int m_threshold; // Number of ticks or volume to close a bar

    // State Variables
    long m_last_tick_time;
    double m_open_price;
    double m_high_price;
    double m_low_price;
    double m_close_price;
    long m_tick_count;
    long m_volume_count;
    bool m_new_bar_flag;

    // Output: Temporal Density (Time Axis Input for FPF)
    double m_temporal_density;

public:
    // Constructor
    CChronoception(ENUM_CHRONO_TYPE type, int threshold)
    {
        m_chrono_type = type;
        m_threshold = threshold;
        Reset();
    }

    // Reset the current bar state
    void Reset()
    {
        m_last_tick_time = 0;
        m_open_price = 0.0;
        m_high_price = 0.0;
        m_low_price = 0.0;
        m_close_price = 0.0;
        m_tick_count = 0;
        m_volume_count = 0;
        m_new_bar_flag = false;
        m_temporal_density = 0.0;
    }

    // Public method to process a new tick
    // Returns true if a new market-time bar has closed
    bool ProcessTick(const MqlTick &tick)
    {
        m_new_bar_flag = false;

        // Initialize bar on first tick
        if (m_tick_count == 0)
        {
            m_open_price = tick.last;
            m_high_price = tick.last;
            m_low_price = tick.last;
            m_last_tick_time = tick.time_msc;
        }

        // Update bar data
        m_close_price = tick.last;
        m_high_price = MathMax(m_high_price, tick.last);
        m_low_price = MathMin(m_low_price, tick.last);
        m_tick_count++;
        m_volume_count += tick.volume;

        // Check for bar closure based on Chronoception Type
        if (m_chrono_type == CHRONO_TICK_BAR && m_tick_count >= m_threshold)
        {
            CloseBar(tick.time_msc);
        }
        else if (m_chrono_type == CHRONO_VOLUME_BAR && m_volume_count >= m_threshold)
        {
            CloseBar(tick.time_msc);
        }

        return m_new_bar_flag;
    }

private:
    // Internal method to finalize the bar and calculate temporal density
    void CloseBar(long current_time_msc)
    {
        // 1. Calculate Temporal Density (Time Axis Input)
        // Temporal Density is the inverse of the time it took to form the bar.
        // A faster bar means higher density (more market activity/urgency).
        long time_elapsed_msc = current_time_msc - m_last_tick_time;

        // Guard against division by zero (shouldn't happen, but good practice)
        if (time_elapsed_msc > 0)
        {
            // Normalize density: We can use a simple inverse or a more complex function.
            // For now, a simple inverse of time elapsed (normalized by the threshold)
            // will serve as a proxy for "temporal compression."
            double normalized_threshold = (double)m_threshold;
            double normalized_time = (double)time_elapsed_msc / 1000.0; // Convert to seconds

            // Temporal Density = (Activity / Time)
            // Activity is proxied by the threshold (e.g., 100 ticks).
            m_temporal_density = normalized_threshold / normalized_time;

            // We will need to further normalize this value (e.g., using a moving average)
            // in the main EA to keep it within the FPF's expected range (e.g., -1 to 1).

            // Log the bar formation
            string bar_type = (m_chrono_type == CHRONO_TICK_BAR) ? "TICK" :
                             (m_chrono_type == CHRONO_VOLUME_BAR) ? "VOLUME" : "RANGE";
            Print(StringFormat("CHRONOCEPTION: %s Bar Closed | O: %.5f | H: %.5f | L: %.5f | C: %.5f | Ticks: %d | Duration: %.2fs | Density: %.4f",
                bar_type, m_open_price, m_high_price, m_low_price, m_close_price,
                m_tick_count, normalized_time, m_temporal_density));
        }
        else
        {
            m_temporal_density = 0.0;
            Print("WARNING: Chronoception bar formed with zero time elapsed. Setting temporal density to 0.");
        }

        // 2. Set the flag and reset for the next bar
        m_new_bar_flag = true;
        m_last_tick_time = current_time_msc;
        m_tick_count = 0;
        m_volume_count = 0;
        m_open_price = m_close_price; // New bar opens at the close of the last one
        m_high_price = m_close_price;
        m_low_price = m_close_price;
    }

public:
    // Public getters for the closed bar data
    double GetOpen() const { return m_open_price; }
    double GetHigh() const { return m_high_price; }
    double GetLow() const { return m_low_price; }
    double GetClose() const { return m_close_price; }
    long GetTickCount() const { return m_tick_count; }
    long GetVolumeCount() const { return m_volume_count; }
    bool IsNewBar() const { return m_new_bar_flag; }

    // Public getter for the Temporal Density (FPF Time Axis Input)
    double GetTemporalDensity() const { return m_temporal_density; }
};
//+------------------------------------------------------------------+
