// -----------------------------------------------------------------------------
// 2‑FF Synchronizer
// -----------------------------------------------------------------------------
// This module takes a WIDTH‑bit asynchronous signal (data_i) and passes it
// through two flip‑flops clocked by clk_i.  
// Purpose: reduce metastability when crossing clock domains.
// -----------------------------------------------------------------------------

module gray_bus_2ff_sync #( //Wide 2 flipflop synchronizer
    WIDTH = 8
)(
    input               clk_i,          // Destination clock
    input               rst_ni,         // Active‑low reset

    input  [WIDTH-1:0]  data_i,         // Asynchronous input data
    output [WIDTH-1:0]  data_q2sync_o   // Synchronized output
);

    // 2‑stage synchronizer array:
    // q2sync[x][0] = first FF stage
    // q2sync[x][1] = second FF stage (stable output)
    logic [WIDTH-1:0][1:0] q2sync;

    // Two‑flip‑flop synchronization
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            q2sync <= 2'b00;            // Reset synchronizer
        else
            q2sync <= {q2sync[0], data_i}; // Shift data through 2 FF stages
    end

    // Output is the synchronized value
    assign data_q2sync_o = q2sync;

endmodule : gray_bus_2ff_sync