// -----------------------------------------------------------------------------
// Module: reset_sync_2ff
// Description:
//   Asynchronous reset synchronizer using a 2-FF shift register.
//   - Reset is asserted asynchronously
//   - Reset is de-asserted synchronously to clk_i
//
// Usage:
//   Used to safely release reset in a clock domain and avoid metastability
//   during reset de-assertion.
//
// Notes:
//   - async_rst_ni : Active-low asynchronous reset input
//   - sync_rst_no  : Active-low synchronized reset output
// -----------------------------------------------------------------------------
module reset_sync_2ff (
    input  logic clk_i,           // Destination clock
    input  logic async_rst_ni,      // Asynchronous active-low reset

    output logic sync_rst_no        // Synchronized active-low reset
);

    // 2-stage synchronizer shift register
    logic [1:0] rst_sync_ff;

    // Asynchronous assertion, synchronous de-assertion
    always_ff @(posedge clk_i or negedge async_rst_ni) begin
        if (!async_rst_ni) begin
            rst_sync_ff <= 2'b00;           // Immediately assert reset
        end
        else begin
            rst_sync_ff <= {rst_sync_ff[0], 1'b1};
        end
    end

    // Synchronized reset output (released after 2 clock cycles)
    assign sync_rst_no = rst_sync_ff[1];

endmodule : reset_sync_2ff
