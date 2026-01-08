// ============================================================================
// Module: pop_count
// Description:
//   Pure combinational population counter (Hamming weight).
//   Counts the number of '1's in the input data word.
//   No clock, no reset.
// ============================================================================

module pop_count #(
    parameter int DATA_WIDTH = 8   // Width of input data
)(
    input  logic [DATA_WIDTH-1:0]           data_in,     // Input data word
    output logic [$clog2(DATA_WIDTH+1)-1:0] count_out    // Number of set bits
);

    // ------------------------------------------------------------------------
    // Combinational Logic: Population Count
    // ------------------------------------------------------------------------
    always_comb begin
        count_out = '0;  // Initialize accumulator

        // Sum all bits in data_in
        for (int i = 0; i < DATA_WIDTH; i++) begin
            count_out = count_out + data_in[i];
        end
    end

endmodule
