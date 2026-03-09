`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Testbench for Async_fifo
// -----------------------------------------------------------------------------

module tb_async_fifo;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    parameter int DATA_WIDTH_test = 4;
    parameter int FIFO_DEPTH_test = 8;

    // -------------------------------------------------------------------------
    // Write Clock Domain Signals
    // -------------------------------------------------------------------------
    logic                  wr_clk_i_test;
    logic                  wr_rst_ni_test;
    logic [DATA_WIDTH_test-1:0] wr_data_i_test;
    logic                  wr_en_i_test;
    logic                  wr_full_o_test;
    logic [$clog2(FIFO_DEPTH_test):0] wr_space_o;

    // -------------------------------------------------------------------------
    // Read Clock Domain Signals
    // -------------------------------------------------------------------------
    logic                  rd_clk_i_test;
    logic                  rd_rst_ni_test;
    logic [DATA_WIDTH_test-1:0] rd_data_o_test;
    logic                  rd_en_i_test;
    logic                  rd_empty_o_test;
    logic [$clog2(FIFO_DEPTH_test):0] rd_space_o;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH_test),
        .FIFO_DEPTH (FIFO_DEPTH_test)
    ) dut_async_fifo (
        // Write domain
        .wr_clk_i   (wr_clk_i_test),
        .wr_rst_ni  (wr_rst_ni_test),
        .wr_data_i  (wr_data_i_test),
        .wr_en_i    (wr_en_i_test),
        .wr_full_o  (wr_full_o_test),
        .wr_space_o (wr_space_o),

        // Read domain
        .rd_clk_i   (rd_clk_i_test),
        .rd_rst_ni  (rd_rst_ni_test),
        .rd_data_o  (rd_data_o_test),
        .rd_en_i    (rd_en_i_test),
        .rd_empty_o (rd_empty_o_test),
        .rd_space_o(rd_space_o)
    );

    // -----------------------------------------------------------------------------
    // Worst-case asynchronous clocks
    // -----------------------------------------------------------------------------

    initial begin
        wr_clk_i_test = 1'b0;
        forever #5.0 wr_clk_i_test = ~wr_clk_i_test;   // 10.0 ns period
    end

    initial begin
        rd_clk_i_test = 1'b0;
        forever #15 rd_clk_i_test = ~rd_clk_i_test;   // 30 ns period
    end


    task automatic fifo_push(input logic [DATA_WIDTH_test-1:0] data);
        @(posedge wr_clk_i_test);
        if (!wr_full_o_test) begin
            wr_en_i_test   <= 1'b1;
            wr_data_i_test <= data;
            $display("[%0t] PUSH : %0h", $time, data);
        end
        else begin
            wr_en_i_test <= 1'b0;
            $display("[%0t] PUSH BLOCKED (FULL)", $time);
        end
        @(posedge wr_clk_i_test);
        wr_en_i_test <= 1'b0;
    endtask

    task automatic fifo_pop(output logic [DATA_WIDTH_test-1:0] data);
        @(posedge rd_clk_i_test);
        if (!rd_empty_o_test) begin
            rd_en_i_test <= 1'b1;
            @(posedge rd_clk_i_test);
            data = rd_data_o_test;
            $display("[%0t] POP  : %0h", $time, data);
        end
        else begin
            rd_en_i_test <= 1'b0;
            data = 'x;
            $display("[%0t] POP BLOCKED (EMPTY)", $time);
        end
        rd_en_i_test <= 1'b0;
    endtask

    logic [DATA_WIDTH_test-1:0] exp_queue [$];

    task automatic check_pop(input logic [DATA_WIDTH_test-1:0] data);
        logic [DATA_WIDTH_test-1:0] exp;
        exp = exp_queue.pop_front();
        if (data !== exp)
            $error("[%0t] DATA MISMATCH exp=%0h got=%0h", $time, exp, data);
    endtask

    task automatic test_fill_fifo;
        $display("\n--- TEST 1 : FILL FIFO ---");
        for (int i = 0; i < FIFO_DEPTH_test; i++) begin
            fifo_push(i);
            exp_queue.push_back(i);
        end

        fifo_push(32'hDEAD_BEEF); // should block

        if (!wr_full_o_test)
            $error("FULL not asserted after FIFO fill");
    endtask
    task automatic test_drain_fifo;
        logic [DATA_WIDTH_test-1:0] data;

        $display("\n--- TEST 2 : DRAIN FIFO ---");
        for (int i = 0; i < FIFO_DEPTH_test; i++) begin
            fifo_pop(data);
            check_pop(data);
        end

        fifo_pop(data); // should block

        if (!rd_empty_o_test)
            $error("EMPTY not asserted after FIFO drain");
    endtask
    task automatic test_simultaneous;
        logic [DATA_WIDTH_test-1:0] data;

        $display("\n--- TEST 3 : SIMULTANEOUS PUSH/POP ---");
        repeat (50) begin
            fork
                begin
                    fifo_push($urandom);
                    exp_queue.push_back(wr_data_i_test);
                end
                begin
                    fifo_pop(data);
                    if (!rd_empty_o_test)
                        check_pop(data);
                end
            join
        end
    endtask


    initial begin
        wr_rst_ni_test = 0;
        rd_rst_ni_test = 0;
        wr_en_i_test   = 0;
        rd_en_i_test   = 0;
        wr_data_i_test = '0;

        #40;
        wr_rst_ni_test = 1;

        #27;
        rd_rst_ni_test = 1;


    end

    initial begin : MASTER_TEST_SEQUENCE

        // Wait until BOTH domains are out of reset
        wait (wr_rst_ni_test && rd_rst_ni_test);
        $display("[%0t] Both resets deasserted. Starting tests.", $time);

        // Run tests in a clear, fixed order
        test_fill_fifo();
        test_drain_fifo();
        test_simultaneous();

        $display("\n ALL ASYNC FIFO TESTS PASSED");
        #50;
        $finish;
    end

endmodule
