// -----------------------------------------------------------------------------
// Module: fixed_priority_arbiter
// Description:
//   Fixed-priority combinational arbiter with acknowledge control.
//
//   - req_i[0] has the highest priority
//   - Grant is issued only when ready_i is asserted
//   - Outputs one-hot grant and corresponding index
// -----------------------------------------------------------------------------
module fixed_priority_arbiter #(
    parameter int N     = 4,               // Number of requesters
    parameter int IDX_W = $clog2(N)         // Index width
)(
    input  logic [N-1:0]     req_i,         // Request vector
    input  logic             ready_i,         // Acknowledge enable
    output logic [N-1:0]     grant_o,       // One-hot grant
    output logic [IDX_W-1:0] grant_idx_o    // Granted index
);

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [IDX_W-1:0] grant_idx;

    // -------------------------------------------------------------------------
    // Combinational Arbitration Logic
    // -------------------------------------------------------------------------
    always_comb begin
        // Default values
        grant_idx     = '0;

        // Grant only when acknowledge is asserted
        if (|req_i && ready_i) begin
            // Fixed priority: lowest index wins
            for (int i=N-1; i>=0; i--) begin
                if (req_i[i] ) begin
                    grant_idx        = i[IDX_W-1:0];
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign grant_o     = ((|req_i) && ready_i) ? ({{(N-1){1'b0}},1'b1} << grant_idx) : '0;
    assign grant_idx_o = grant_idx;

endmodule : fixed_priority_arbiter
