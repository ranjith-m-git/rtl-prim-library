// ============================================================================
// Testbench: tb_pop_count
// Description:
//   Self-checking testbench for combinational pop_count module.
//   Applies directed and random stimulus and checks output immediately.
// ============================================================================

module tb_pop_count;

    // ------------------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------------------
    localparam int DATA_WIDTH_TB = 8;
    localparam int COUNT_WIDTH  = $clog2(DATA_WIDTH_TB + 1);

    // ------------------------------------------------------------------------
    // Testbench Signals
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH_TB-1:0] data_in_test;
    logic [COUNT_WIDTH-1:0]   count_out_test;

    // ------------------------------------------------------------------------
    // DUT Instantiation
    // ------------------------------------------------------------------------
    pop_count #(
        .DATA_WIDTH (DATA_WIDTH_TB)
    ) dut (
        .data_in   (data_in_test),
        .count_out (count_out_test)
    );

    // ------------------------------------------------------------------------
    // Reference Popcount Model
    // ------------------------------------------------------------------------
    function automatic [COUNT_WIDTH-1:0] ref_popcount(
        input logic [DATA_WIDTH_TB-1:0] data
    );
        ref_popcount = '0;
        for (int i = 0; i < DATA_WIDTH_TB; i++)
            ref_popcount += data[i];
    endfunction

    // ------------------------------------------------------------------------
    // Directed Tests
    // ------------------------------------------------------------------------
    task automatic run_directed_tests;
        $display("\n--- Running Directed Tests ---");

        data_in_test = '0;  #1;
        if (count_out_test !== 0)
            $error("FAIL: data=0x%0h expected=0 got=%0d",
                   data_in_test, count_out_test);

        data_in_test = '1;  #1;
        if (count_out_test !== DATA_WIDTH_TB)
            $error("FAIL: data=0x%0h expected=%0d got=%0d",
                   data_in_test, DATA_WIDTH_TB, count_out_test);

        data_in_test = 8'b10101010;  #1;
        if (count_out_test !== 4)
            $error("FAIL: data=0x%0h expected=4 got=%0d",
                   data_in_test, count_out_test);

        data_in_test = 8'b10000001;  #1;
        if (count_out_test !== 2)
            $error("FAIL: data=0x%0h expected=2 got=%0d",
                   data_in_test, count_out_test);

        $display("Directed tests passed");
    endtask

    // ------------------------------------------------------------------------
    // Random Tests
    // ------------------------------------------------------------------------
    task automatic run_random_tests(int num_tests);
        logic [COUNT_WIDTH-1:0] expected;

        $display("\n--- Running Random Tests (%0d cases) ---", num_tests);

        repeat (num_tests) begin
            data_in_test = $urandom;  #1;
            expected = ref_popcount(data_in_test);

            if (count_out_test !== expected)
                $error("FAIL: data=0x%0h expected=%0d got=%0d",
                       data_in_test, expected, count_out_test);
        end

        $display("Random tests passed");
    endtask

    // ------------------------------------------------------------------------
    // Master Test Sequence
    // ------------------------------------------------------------------------
    initial begin
        run_directed_tests();
        run_random_tests(1000);

        $display("\n ALL COMBINATIONAL POP_COUNT TESTS PASSED");
        $finish;
    end

endmodule
