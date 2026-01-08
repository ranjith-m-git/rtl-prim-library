`timescale 1ns/1ps

module tb_fixed_priority_arbiter;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam int N     = 4;
    localparam int IDX_W = $clog2(N);

    // -------------------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------------------
    logic [N-1:0]     req_i;
    logic             ready_i;
    logic [N-1:0]     grant_o;
    logic [IDX_W-1:0] grant_idx_o;

    // -------------------------------------------------------------------------
    // Pass / Fail Counters
    // -------------------------------------------------------------------------
    int pass_cnt = 0;
    int fail_cnt = 0;

    // -------------------------------------------------------------------------
    // DUT Instance
    // -------------------------------------------------------------------------
    fixed_priority_arbiter #(
        .N(N),
        .IDX_W(IDX_W)
    ) dut (
        .req_i(req_i),
        .ready_i(ready_i),
        .grant_o(grant_o),
        .grant_idx_o(grant_idx_o)
    );

    // -------------------------------------------------------------------------
    // Function: Expected Grant Index
    // -------------------------------------------------------------------------
    function automatic [IDX_W-1:0] expected_idx(input logic [N-1:0] req);
        expected_idx = '0;
        for (int i = 0; i < N; i++) begin
            if (req[i]) begin
                expected_idx = i;
                break;
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Function: Expected Grant Vector
    // -------------------------------------------------------------------------
    function automatic [N-1:0] expected_grant(
        input logic [N-1:0] req,
        input logic ack
    );
        expected_grant = '0;
        if (ack) begin
            for (int i = 0; i < N; i++) begin
                if (req[i]) begin
                    expected_grant[i] = 1'b1;
                    break;
                end
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Task: Apply stimulus & check result
    // -------------------------------------------------------------------------
    task automatic apply_and_check(
        input logic [N-1:0] req,
        input logic ack,
        input string test_name
    );
        logic [N-1:0]     exp_grant;
        logic [IDX_W-1:0] exp_idx;
        bit pass;

        begin
            req_i = req;
            ready_i = ack;
            #1;

            exp_grant = expected_grant(req, ack);
            exp_idx   = expected_idx(req);

            pass = 1;

            if (grant_o !== exp_grant) begin
                $display("[FAIL] %s | GRANT mismatch | EXP=%b GOT=%b",
                         test_name, exp_grant, grant_o);
                pass = 0;
            end

            if ((grant_o != '0) && (grant_idx_o !== exp_idx)) begin
                $display("[FAIL] %s | IDX mismatch | EXP=%0d GOT=%0d",
                         test_name, exp_idx, grant_idx_o);
                pass = 0;
            end

            if (!$onehot0(grant_o)) begin
                $display("[FAIL] %s | Grant not one-hot: %b",
                         test_name, grant_o);
                pass = 0;
            end

            if (pass) begin
                pass_cnt++;
                $display("[PASS] %s | req=%b ack=%0b grant=%b idx=%0d",
                         test_name, req, ack, grant_o, grant_idx_o);
            end
            else begin
                fail_cnt++;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Functional Coverage
    // -------------------------------------------------------------------------
    covergroup arbiter_cg;
        coverpoint req_i {
            bins none   = {0};
            bins single[] = {[1:(1<<N)-1]};
        }

        coverpoint ready_i {
            bins on  = {1};
            bins off = {0};
        }

        coverpoint grant_o {
            bins zero = {0};
            bins onehot[] = {[1:(1<<N)-1]};
        }

        cross req_i, ready_i;
    endgroup

    arbiter_cg cg = new();

    // -------------------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        $display("\n================= TEST START =================");

        req_i = '0;
        ready_i = 1'b0;
        #5;

        // No request
        apply_and_check('0, 1'b0, "No request, no ack");
        cg.sample();

        apply_and_check('0, 1'b1, "No request, ack high");
        cg.sample();

        // Single request tests
        for (int i = 0; i < N; i++) begin
            apply_and_check(1 << i, 1'b1, $sformatf("Single request [%0d]", i));
            cg.sample();
        end

        // Multiple request tests
        apply_and_check(4'b1111, 1'b1, "All requests active");
        apply_and_check(4'b1011, 1'b1, "Multiple mixed requests");
        apply_and_check(4'b0110, 1'b1, "Middle requests");
        cg.sample();

        // Ack low case
        apply_and_check(4'b1111, 1'b0, "Ack low with requests");
        cg.sample();

        // ---------------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------------
        $display("\n================= TEST SUMMARY =================");
        $display("TOTAL PASS : %0d", pass_cnt);
        $display("TOTAL FAIL : %0d", fail_cnt);

        if (fail_cnt == 0)
            $display(" ALL TESTS PASSED");
        else
            $display(" TEST FAILED");

        $display("===============================================\n");

        $finish;
    end

endmodule
