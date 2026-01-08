module Mux_n_1 #(
    parameter INPUT_WIDTH = 16,                     // Number of input lines
    parameter SELECT_WIDTH = $clog2(INPUT_WIDTH)    // Number of select bits required
)(
    //mux input
    input   [INPUT_WIDTH-1:0]   mux_in,             // INPUT_WIDTH bits input (like a bus)
    input   [SELECT_WIDTH-1:0]  sel_in,             // Selection input

    //mux output
    output                      mux_out             // Single bit output
);

assign mux_out = mux_in[sel_in];   // Selects one bit from mux_in based on sel_in

endmodule
