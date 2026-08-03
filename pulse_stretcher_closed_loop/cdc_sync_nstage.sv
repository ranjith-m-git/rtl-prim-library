// ============================================================================
// Module: sync_nstage
// Description:
//   Parameterized N-stage flip-flop synchronizer.
//   Used to safely synchronize an asynchronous single-bit signal into the
//   destination clock domain.
//
// Notes:
//   - Recommended NUM_STAGES >= 2 for CDC safety
//   - Intended for control signals, not data buses
// ============================================================================

module cdc_sync_nstage #(
    parameter int NUM_STAGES = 2  // Number of synchronization stages
)(
    // ------------------------------------------------------------------------
    // Clock & Reset (Destination Domain)
    // ------------------------------------------------------------------------
    input  logic clk_i,           // Destination clock
    input  logic rst_ni,           // Active-low asynchronous reset

    // ------------------------------------------------------------------------
    // Asynchronous Input
    // ------------------------------------------------------------------------
    input  logic async_din,        // Asynchronous input signal

    // ------------------------------------------------------------------------
    // Synchronized Output
    // ------------------------------------------------------------------------
    output logic sync_dout         // Synchronized output signal
);

    // ------------------------------------------------------------------------
    // Internal Synchronizer Registers
    // ------------------------------------------------------------------------
    logic [NUM_STAGES-1:0] sync_ff;

    // ------------------------------------------------------------------------
    // Synchronizer Flip-Flop Chain
    // ------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_ff <= '0;
        end
        else begin
            // Shift register:
            // async_din enters stage 0 and propagates through NUM_STAGES FFs
            sync_ff <= {sync_ff[NUM_STAGES-2:0], async_din};
        end
    end

    // ------------------------------------------------------------------------
    // Output from the last synchronization stage
    // ------------------------------------------------------------------------
    assign sync_dout = sync_ff[NUM_STAGES-1];
    
    // ------------------------------------------------------------------------
    // Assertion
    // ------------------------------------------------------------------------
    initial begin
     if (NUM_STAGES < 2)
        $fatal(1, "sync_nstage: NUM_STAGES must be >= 2");
    end


endmodule
