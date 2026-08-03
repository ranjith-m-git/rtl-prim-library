`timescale 1ns/1ps

module tb_credit_based_pulse_stretcher;

    // ------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------
    localparam CNT_WIDTH = 4;

    // ------------------------------------------------------------
    // DUT Signals
    // ------------------------------------------------------------
    logic src_clk_i;
    logic src_rst_ni;
    logic src_pulse_i;

    logic dst_clk_i;
    logic dst_rst_ni;
    logic dst_pulse_o;

    // ------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------
    credit_based_pulse_stretcher #(
        .CNT_WIDTH(CNT_WIDTH)
    ) dut (
        .src_clk_i   (src_clk_i),
        .src_rst_ni  (src_rst_ni),
        .src_pulse_i (src_pulse_i),
        .dst_clk_i   (dst_clk_i),
        .dst_rst_ni  (dst_rst_ni),
        .dst_pulse_o (dst_pulse_o)
    );

    // ------------------------------------------------------------
    // Clock Generation
    // ------------------------------------------------------------
    initial src_clk_i = 0;
    always #5 src_clk_i = ~src_clk_i;      // 100 MHz

    initial dst_clk_i = 0;
    always #12 dst_clk_i = ~dst_clk_i;     // ~41 MHz (slower)

    // ------------------------------------------------------------
    // Reset Task
    // ------------------------------------------------------------
    task automatic apply_reset();
        begin
            src_rst_ni = 0;
            dst_rst_ni = 0;
            src_pulse_i = 0;

            repeat (5) @(posedge src_clk_i);

            src_rst_ni = 1;
            dst_rst_ni = 1;
        end
    endtask


    // ------------------------------------------------------------
    // Pulse Generator Task
    // ------------------------------------------------------------
    task automatic send_src_pulse(int gap_cycles);
        begin
            @(posedge src_clk_i);
            src_pulse_i <= 1;
            @(posedge src_clk_i);
            src_pulse_i <= 0;

            repeat (gap_cycles)
                @(posedge src_clk_i);
        end
    endtask


    // ------------------------------------------------------------
    // Reference Model
    // ------------------------------------------------------------
    int expected_pulse_count;
    int actual_pulse_count;

    // Count expected pulses
    always @(posedge src_clk_i) begin
        if (!src_rst_ni)
            expected_pulse_count = 0;
        else if (src_pulse_i)
            expected_pulse_count++;
    end

    // Count actual pulses in destination
    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni)
            actual_pulse_count = 0;
        else if (dst_pulse_o)
            actual_pulse_count++;
    end


    // ------------------------------------------------------------
    // Function: Compare Results
    // ------------------------------------------------------------
    function automatic void compare_results();
        begin
            $display("--------------------------------------------------");
            $display("Expected Pulses = %0d", expected_pulse_count);
            $display("Actual Pulses   = %0d", actual_pulse_count);

            if (expected_pulse_count == actual_pulse_count)
                $display("TEST RESULT : PASS");
            else
                $display("TEST RESULT : FAIL");

            $display("--------------------------------------------------");
        end
    endfunction


    // ------------------------------------------------------------
    // Main Test Sequence
    // ------------------------------------------------------------
    initial begin

        apply_reset();

        // Test 1: Single pulse
        send_src_pulse(5);

        // Test 2: Back-to-back pulses (collision scenario)
        repeat (3) send_src_pulse(1);

        // Test 3: Burst of pulses (stress counter)
        repeat (8) send_src_pulse(0);

        // Wait long enough for draining
        repeat (200) @(posedge src_clk_i);

        compare_results();

        $finish;
    end

endmodule
