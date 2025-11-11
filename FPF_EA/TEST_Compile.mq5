//+------------------------------------------------------------------+
//| TEST_Compile.mq5 - Diagnostic Test                               |
//| Tests if the compiler correctly handles variable scope           |
//+------------------------------------------------------------------+
#property copyright "Test"
#property version   "1.00"

void TestFunction()
{
    // Declare a variable
    double bar_direction = 1.5;

    // Use it 14 lines later (same distance as in FPF_EA)
    double dummy1 = 0.0;
    double dummy2 = 0.0;
    double dummy3 = 0.0;
    double dummy4 = 0.0;
    double dummy5 = 0.0;
    double dummy6 = 0.0;
    double dummy7 = 0.0;
    double dummy8 = 0.0;
    double dummy9 = 0.0;
    double dummy10 = 0.0;
    double dummy11 = 0.0;
    double dummy12 = 0.0;
    double dummy13 = 0.0;

    // Use bar_direction here (line 30, declared at line 15)
    double main_direction = MathSign(bar_direction);

    // Now test price_change in a loop
    for (int i = 0; i < 5; i++)
    {
        double price_change = i * 0.5;
        double related_direction = MathSign(price_change);

        Print("Test: ", related_direction);
    }
}

void OnTick()
{
    TestFunction();
}
