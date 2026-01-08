`timescale 1ns/1ps

module tb_cdc_sync_nstage;

    // ------------------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------------------
    localparam int NUM_STAGES_TEST = 2;

    // ------------------------------------------------------------------------
    // Testbench Signals
    // ------------------------------------------------------------------------
    logic clk_test;
    logic rst_n_test;
    logic async_din_test;
    logic sync_dout_test;

    // ------------------------------------------------------------------------
    // Clock Generation (100 MHz)
    // ------------------------------------------------------------------------
    initial begin
        clk_test = 0;
        forever #5 clk_test = ~clk_test;
    end

    // ------------------------------------------------------------------------
    // DUT Instantiation
    // ------------------------------------------------------------------------
    cdc_sync_nstage #(
        .NUM_STAGES(NUM_STAGES_TEST)
    ) dut (
        .clk_i     (clk_test),
        .rst_ni    (rst_n_test),
        .async_din (async_din_test),
        .sync_dout (sync_dout_test)
    );

    // ------------------------------------------------------------------------
    // Test Sequence
    // ------------------------------------------------------------------------
    initial begin
        // Initialize signals
        rst_n_test      = 1'b0;
        async_din_test  = 1'b0;

        // Apply reset
        repeat (2) @(posedge clk_test);
        rst_n_test = 1'b1;

        $display("[%0t] Reset released", $time);

        // ------------------------------------------------------------
        // Test 1: Drive async input HIGH
        // ------------------------------------------------------------
        #7 async_din_test = 1'b1; // Change async signal off-clock
        $display("[%0t] async_din asserted", $time);

        // Wait NUM_STAGES clocks
        repeat (NUM_STAGES_TEST) @(posedge clk_test);

        // Check synchronized output
        if (sync_dout_test !== 1'b1)
            $error("[%0t] ERROR: sync_dout not asserted correctly", $time);
        else
            $display("[%0t] PASS: sync_dout asserted after %0d cycles",
                     $time, NUM_STAGES_TEST);

        // ------------------------------------------------------------
        // Test 2: Drive async input LOW
        // ------------------------------------------------------------
        #3 async_din_test = 1'b0;
        $display("[%0t] async_din deasserted", $time);

        repeat (NUM_STAGES_TEST) @(posedge clk_test);

        if (sync_dout_test !== 1'b0)
            $error("[%0t] ERROR: sync_dout not deasserted correctly", $time);
        else
            $display("[%0t] PASS: sync_dout deasserted after %0d cycles",
                     $time, NUM_STAGES_TEST);

        // ------------------------------------------------------------
        // End of test
        // ------------------------------------------------------------
        $display("[%0t] All tests completed", $time);
        $finish;
    end

endmodule
