// ============================================================================
// Module: fair_round_robin_arbiter
// Description:
//   Least Recently Granted (LRG) Round-Robin Arbiter
//
//   This arbiter selects the requester that has waited the longest since its
//   last successful grant, ensuring strong fairness and starvation-free
//   arbitration.
//
//   Key features:
//   - Tracks grant history using a recency queue
//   - Selects the least recently granted active requester
//   - Supports priority masking (priority_i)
//   - Grant and state update occur only when ready_i is asserted
//   - Produces one-hot grant output
//
// Notes:
//   - Lower recency value => older grant => higher priority
//   - Higher recency value => more recently granted
//   - Priority masking overrides LRG when active
// ============================================================================

module fair_round_robin_arbiter #(
    parameter int N = 4                     // Number of requesters
) (
    input  logic             clk_i,         // Clock
    input  logic             rst_ni,          // Active-low reset

    input  logic [N-1:0]     req_i,          // Request vector (1 = request active)
    input  logic [N-1:0]     priority_i,     // Priority mask (1 = enabled requester)
    input  logic             ready_i,        // Downstream ready / acknowledge

    output logic [N-1:0]     grant_o          // One-hot grant output
);

    // ------------------------------------------------------------------------
    // Local parameters
    // ------------------------------------------------------------------------
    // Pointer width required to index N requesters
    localparam int PTR_W = (N <= 1) ? 1 : $clog2(N);

    // ------------------------------------------------------------------------
    // Grant history tracking
    // ------------------------------------------------------------------------
    // grant_queue[j] holds the recency rank of requester j
    //
    //   0      -> least recently granted (highest priority)
    //   N-1    -> most recently granted (lowest priority)
    //
    // The queue maintains a relative ordering of grant history.
    logic [PTR_W-1:0] grant_queue [N-1:0];

    // Holds the best (lowest) recency value found during arbitration
    logic [PTR_W-1:0] grant_priority_ptr;

    // Index of the selected requester
    logic [PTR_W-1:0] grant_idx;

    // ------------------------------------------------------------------------
    // Grant output generation
    // ------------------------------------------------------------------------
    // A grant is issued only when:
    //   - At least one request is active
    //   - Downstream logic is ready to accept the grant
    //
    // The grant is one-hot encoded based on grant_idx.
    assign grant_o =
        (|req_i && ready_i)
            ? ({{(N-1){1'b0}}, 1'b1} << grant_idx)
            : '0;

    // ------------------------------------------------------------------------
    // Grant queue update logic (sequential)
    // ------------------------------------------------------------------------
    // Updates occur only when a grant is successfully accepted.
    //
    // Update rules:
    //   - The granted requester becomes the most recently granted (N-1)
    //   - Requesters that were more recent than the granted one are shifted
    //     one step toward being older
    //   - Requesters older than the granted one remain unchanged
    //
    // This preserves the relative ordering of grant recency.
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // ------------------------------------------------------------
            // Reset behavior
            // ------------------------------------------------------------
            // Initialize the grant queue with a deterministic order:
            //   requester 0 -> least recently granted
            //   requester N-1 -> most recently granted
            for (int j = 0; j < N; j++) begin
                grant_queue[j] <= j;
            end
        end
        else begin
            // ------------------------------------------------------------
            // Update grant history only on a successful grant
            // ------------------------------------------------------------
            if (|req_i && ready_i) begin
                for (int j = 0; j < N; j++) begin
                    if (j == grant_idx)
                        // Mark the granted requester as most recently granted
                        grant_queue[j] <= N-1;
                    else if (grant_queue[j] > grant_priority_ptr)
                        // Shift requesters that were more recent than the winner
                        grant_queue[j] <= grant_queue[j] - 1;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Grant selection logic (combinational)
    // ------------------------------------------------------------------------
    // Arbitration procedure:
    //   1. Check if any priority-masked request is active
    //   2. If yes, consider only those requesters
    //   3. Otherwise, consider all active requesters
    //   4. Among eligible requesters, select the one with the
    //      lowest grant_queue value (least recently granted)
    //
    // Tie-breaking:
    //   - Lower index wins if recency values are equal
    always_comb begin
        // Default assignments
        grant_idx          = '0;
        grant_priority_ptr = N-1;

        if (|req_i && ready_i) begin
            for (int i = 0; i < N; i++) begin

                // --------------------------------------------------------
                // Case 1: Priority masking is active
                // --------------------------------------------------------
                // If at least one requester has both req_i and priority_i set,
                // only those requesters are eligible for arbitration.
                if (|(req_i & priority_i)) begin
                    if (req_i[i] &&
                        priority_i[i] &&
                        (grant_queue[i] <= grant_priority_ptr)) begin

                        grant_idx          = i;
                        grant_priority_ptr = grant_queue[i];
                    end
                end

                // --------------------------------------------------------
                // Case 2: No priority masking active
                // --------------------------------------------------------
                // All active requesters participate in LRG arbitration.
                else if (req_i[i] &&
                         (grant_queue[i] <= grant_priority_ptr)) begin

                    grant_idx          = i;
                    grant_priority_ptr = grant_queue[i];
                end
            end
        end
    end

endmodule : fair_round_robin_arbiter
