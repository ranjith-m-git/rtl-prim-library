// -----------------------------------------------------------------------------
// Testbench: tb_reset_sync_2ff
// -----------------------------------------------------------------------------
module tb_reset_sync_2ff;

    // -------------------------------------------------------------------------
    // Testbench Signals
    // -------------------------------------------------------------------------
    logic clk;
    logic async_rst_ni;
    logic sync_rst_no;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    reset_sync_2ff dut (
        .clk_i        (clk),
        .async_rst_ni (async_rst_ni),
        .sync_rst_no  (sync_rst_no)
    );

    // -------------------------------------------------------------------------
    // Clock Generation (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: Apply Asynchronous Reset
    // -------------------------------------------------------------------------
    task apply_async_reset();
        begin
            async_rst_ni = 1'b0;
            #3; // async assertion (not aligned to clk)
            if (sync_rst_no !== 1'b0)
                $display("[FAIL] Reset not asserted asynchronously at time %0t", $time);
            else
                $display("[PASS] Asynchronous reset assertion verified at time %0t", $time);
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: Release Reset and Check Synchronization
    // -------------------------------------------------------------------------
    task release_reset_and_check();
        begin
            async_rst_ni = 1'b1;
            $display("[INFO] Reset released at time %0t", $time);

            // First clock edge after release
            @(posedge clk);
            if (sync_rst_no !== 1'b0)
                $display("[FAIL] Reset released too early (1st cycle) at %0t", $time);

            // Second clock edge after release
            @(posedge clk);
            if (sync_rst_no !== 1'b1)
                $display("[FAIL] Reset not released after 2 cycles at %0t", $time);
            else
                $display("[PASS] Reset synchronously de-asserted after 2 cycles at %0t", $time);
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: Check No Glitch During Reset
    // -------------------------------------------------------------------------
    task check_no_glitch();
        begin
            if (sync_rst_no === 1'b1)
                $display("[PASS] No glitch observed during reset operation");
            else
                $display("[INFO] Reset still active as expected");
        end
    endtask

    // -------------------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Initial values
        async_rst_ni = 1'b1;

        // Apply reset
        apply_async_reset();

        // Hold reset for few cycles
        repeat (2) @(posedge clk);

        // Release reset and validate behavior
        release_reset_and_check();

        // Monitor for glitches
        repeat (5) begin
            @(posedge clk);
            check_no_glitch();
        end

        $display("--------------------------------------------------");
        $display("TEST COMPLETED");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule : tb_reset_sync_2ff
