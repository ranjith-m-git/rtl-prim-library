`timescale 1ns/1ps

module tb_fair_round_robin_arbiter;

    // ------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------
    localparam int N     = 4;
    localparam int PTR_W = $clog2(N);

    // ------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------
    logic             clk_i;
    logic             rst_ni;
    logic [N-1:0]     req_i;
    logic [N-1:0]     priority_i;
    logic             ready_i;
    logic [N-1:0]     grant_o;

    // ------------------------------------------------------------
    // Reference model state (LRG history)
    // ------------------------------------------------------------
    logic [PTR_W-1:0] ref_queue [N-1:0];

    // ------------------------------------------------------------
    // DUT instantiation
    // ------------------------------------------------------------
    fair_round_robin_arbiter #(
        .N(N)
    ) dut (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .req_i      (req_i),
        .priority_i (priority_i),
        .ready_i    (ready_i),
        .grant_o    (grant_o)
    );

    // ------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------
    always #5 clk_i = ~clk_i;

    // ------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------
    task automatic apply_reset();
        clk_i  = 0;
        rst_ni = 0;
        req_i  = '0;
        priority_i = '0;
        ready_i = 0;

        repeat (2) @(posedge clk_i);
        rst_ni = 1;

        // Initialize reference queue (oldest → newest)
        for (int i = 0; i < N; i++)
            ref_queue[i] = i;
    endtask

    // ------------------------------------------------------------
    // Function: one-hot to index (CORRECT)
    // ------------------------------------------------------------
    function automatic int onehot_to_idx(input logic [N-1:0] onehot);
        for (int i = 0; i < N; i++) begin
            if (onehot[i])
                return i;
        end
        return -1;
    endfunction

    // ------------------------------------------------------------
    // Function: compute expected grant (matches RTL)
    // ------------------------------------------------------------
    function automatic logic [N-1:0] compute_expected_grant(
        input logic [N-1:0] req,
        input logic [N-1:0] prio,
        input logic         ready
    );
        logic [PTR_W-1:0] best_age;
        int               best_idx;

        compute_expected_grant = '0;
        best_age = N-1;
        best_idx = -1;

        if (!ready || !(|req))
            return '0;

        // Case 1: priority-masked requests exist
        if (|(req & prio)) begin
            for (int i = 0; i < N; i++) begin
                if (req[i] && prio[i] &&
                    (ref_queue[i] <= best_age)) begin
                    best_age = ref_queue[i];
                    best_idx = i;
                end
            end
        end
        // Case 2: normal LRG arbitration
        else begin
            for (int i = 0; i < N; i++) begin
                if (req[i] &&
                    (ref_queue[i] <= best_age)) begin
                    best_age = ref_queue[i];
                    best_idx = i;
                end
            end
        end

        if (best_idx >= 0)
            compute_expected_grant[best_idx] = 1'b1;
    endfunction

    // ------------------------------------------------------------
    // Task: update reference LRG queue (RTL-faithful)
    // ------------------------------------------------------------
    task automatic update_ref_queue(input logic [N-1:0] grant);
        int gidx;
        logic [PTR_W-1:0] winner_age;

        if (!(|grant))
            return;

        gidx = onehot_to_idx(grant);
        winner_age = ref_queue[gidx]; // capture OLD age

        for (int i = 0; i < N; i++) begin
            if (i == gidx)
                ref_queue[i] = N-1;
            else if (ref_queue[i] > winner_age)
                ref_queue[i]--;
        end
    endtask

    // ------------------------------------------------------------
    // Task: run single test
    // ------------------------------------------------------------
    task automatic run_test(
        input string        test_name,
        input logic [N-1:0] req,
        input logic [N-1:0] prio,
        input logic         ready
    );
        logic [N-1:0] exp_grant;


        req_i      <= req;
        priority_i <= prio;
        ready_i    <= ready;

        @(posedge clk_i);

        exp_grant = compute_expected_grant(req, prio, ready);

        if (grant_o === exp_grant) begin
            $display("[%0t] PASS  | %-20s | req=%b prio=%b ready=%b | got=%b exp=%b",
                     $time, test_name, req, prio, ready, grant_o, exp_grant);
        end
        else begin
            $display("[%0t] FAIL  | %-20s | req=%b prio=%b ready=%b | got=%b exp=%b",
                     $time, test_name, req, prio, ready, grant_o, exp_grant);
        end

        // Update reference model only on successful grant
        if (ready)
            update_ref_queue(exp_grant);
    endtask

    // ------------------------------------------------------------
    // Test sequences
    // ------------------------------------------------------------
    initial begin
        apply_reset();

        // Directed tests
        run_test("Single request", 4'b0001, 4'b1111, 1'b1);
        run_test("Single request", 4'b0010, 4'b1111, 1'b1);
        run_test("Single request", 4'b1000, 4'b1111, 1'b1);
        run_test("Multi request",  4'b0101, 4'b1111, 1'b1);

        // Exhaustive request combinations
        for (int r = 1; r < (1<<N); r++) begin
            run_test($sformatf("Exhaustive req=%0b", r),
                     r[N-1:0], 4'b1111, 1'b1);
        end

        // Randomized tests
        repeat (100) begin
            run_test("Random",
                     $urandom_range(1, 15),
                     $urandom_range(0, 15),
                     $urandom_range(0, 1));
        end

        $display("--------------------------------------------------");
        $display("All tests completed");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
