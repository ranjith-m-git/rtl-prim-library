// ============================================================================
// Module: clk_divider_n
// Description:
//   Parameterized clock divider supporting:
//     - Bypass (divide-by-1)
//     - Divide-by-2
//     - Even divide
//     - Odd divide (duty-cycle corrected using negedge assist)
//
// Notes:
//   - Uses a counter-based approach
//   - Supports dynamic division factor updates
//   - Intended for synthesis (verify glitch constraints carefully)
// ============================================================================

module clk_divider_n #(
    parameter int WIDTH = 32              // Width of the counters
)(
    input               clk_i,             // Input reference clock
    input               rst_ni,              // Active-low asynchronous reset

    input  [WIDTH-1:0]  div_val_i,          // Division factor input
    output logic        div_clk_o           // Divided clock output
);

    // ------------------------------------------------------------------------
    // Internal Signals
    // ------------------------------------------------------------------------
    logic [WIDTH-1:0]   div_val;            // Latched division value
    logic               div_val_load;       // Load enable for div_val
    logic               roll_over;           // Counter rollover indicator
    logic               clk_buf;             // Selected divided clock

    logic [WIDTH-1:0]   clk_cntr;            // Main division counter
    logic [1:0]         mux_sel;             // Clock select control

    logic               clk_div_even;        // Even divide clock
    logic               clk_div_odd;         // Odd divide clock
    logic               clk_div_half;        // Divide-by-2 clock
    logic               clk_div_odd_pulse;   // Odd pulse generator
    logic               negedge_pulse;       // Negedge latch helper

    // ------------------------------------------------------------------------
    // Division Value Handling
    // ------------------------------------------------------------------------
    // Reload division value on rollover or when counter is reset
    assign div_val_load = roll_over || (clk_cntr == 0);

    // Self-holding register behavior via combinational assignment
    always_latch begin
      if (!rst_ni)           div_val <= '0;
      else if (div_val_load) div_val <= div_val_i;
    end

    // ------------------------------------------------------------------------
    // Main Counter Logic (posedge clocked)
    // ------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin : counter
        if (!rst_ni) begin
            clk_cntr  <= '0;
            roll_over <= 1'b0;
        end
        else begin
            if (clk_cntr >= div_val - 1) begin
                clk_cntr  <= '0;
                roll_over <= 1'b1;
            end
            else begin
                clk_cntr  <= clk_cntr + 1'b1;
                roll_over <= 1'b0;
            end
        end
    end : counter

    // ------------------------------------------------------------------------
    // Negedge Pulse Latching
    // Intent:
    //   Capture odd-divider pulse during low phase of input clock
    //   to improve duty-cycle symmetry for odd division
    // ------------------------------------------------------------------------
    always_latch begin
        if (!rst_ni)
            negedge_pulse <= 1'b0;
        else if (!clk_i)
            negedge_pulse <= clk_div_odd_pulse;
    end

    // ------------------------------------------------------------------------
    // Clock Generation Logic
    // ------------------------------------------------------------------------
    assign clk_div_odd_pulse = (clk_cntr > ((div_val - 1) >> 1));
    assign clk_div_odd       = clk_div_odd_pulse | negedge_pulse;
    assign clk_div_even      = (clk_cntr >= (div_val >> 1));
    assign clk_div_half      = clk_cntr[0];

    // ------------------------------------------------------------------------
    // Divider Selection Logic
    // Intent:
    //   00 : Bypass clock (divide-by-1)
    //   01 : Divide-by-2
    //   10 : Even divide
    //   11 : Odd divide
    // ------------------------------------------------------------------------
    always_latch begin        
        if (!rst_ni) 
            mux_sel <= '0;
        else if ((div_val == '0) || (div_val == 1)) 
            mux_sel <= 2'b00; // No division
        else if (div_val == 2) 
            mux_sel <= 2'b01; // Divide by 2
        else if (div_val[0] == 1'b0) 
            mux_sel <= 2'b10; // Even division
        else if (div_val[0] == 1'b1) 
            mux_sel <= 2'b11; // Odd division
    end

    // ------------------------------------------------------------------------
    // Clock Output MUX
    // ------------------------------------------------------------------------
    always_comb begin
        case (mux_sel)
            2'b00  : clk_buf = clk_i;
            2'b01  : clk_buf = clk_div_half;
            2'b10  : clk_buf = clk_div_even;
            2'b11  : clk_buf = clk_div_odd;
            default: clk_buf = 1'b0;
        endcase
    end

    // ------------------------------------------------------------------------
    // Final Output
    // ------------------------------------------------------------------------
    assign div_clk_o = clk_buf;

endmodule : clk_divider_n
