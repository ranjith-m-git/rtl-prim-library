module tb_sync_fifo;

    // ---------------------------------------------------------------------
    // Parameters
    // ---------------------------------------------------------------------
    localparam int DATA_WIDTH = 8;
    localparam int FIFO_DEPTH = 8;

    // ---------------------------------------------------------------------
    // DUT Signals
    // ---------------------------------------------------------------------
    logic clk_i;
    logic rst_ni;
    logic wr_en_i;
    logic rd_en_i;
    logic [DATA_WIDTH-1:0] wr_data_i;
    logic [DATA_WIDTH-1:0] rd_data_o;
    logic full_o;
    logic empty_o;
    logic [$clog2(FIFO_DEPTH):0] rd_space_o;
    logic [$clog2(FIFO_DEPTH):0] wr_space_o;

    // ---------------------------------------------------------------------
    // Scoreboard
    // ---------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] exp_q [$];
    int pass_cnt = 0;
    int fail_cnt = 0;

    // ---------------------------------------------------------------------
    // Clock generation
    // ---------------------------------------------------------------------
    always #5 clk_i = ~clk_i;

    // ---------------------------------------------------------------------
    // DUT Instance
    // ---------------------------------------------------------------------
    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) dut (
        .clk_i,
        .rst_ni,
        .rd_en_i,
        .wr_en_i,
        .wr_data_i,
        .rd_data_o,
        .full_o,
        .empty_o,
        .rd_space_o,
        .wr_space_o
    );

    // ---------------------------------------------------------------------
    // Reset
    // ---------------------------------------------------------------------
    task reset_dut();
        begin
            rst_ni = 0;
            wr_en_i = 0;
            rd_en_i = 0;
            wr_data_i = '0;
            repeat (3) @(posedge clk_i);
            rst_ni = 1;
        end
    endtask

    // ---------------------------------------------------------------------
    // Write task
    // ---------------------------------------------------------------------
    task fifo_write(input logic [DATA_WIDTH-1:0] data);
        begin
            @(posedge clk_i);
            if (!full_o) begin
                wr_en_i   = 1;
                wr_data_i = data;
                exp_q.push_back(data);
            end
            else begin
                $display("[TB] WRITE BLOCKED (FULL)");
            end
            @(posedge clk_i);
            wr_en_i = 0;
        end
    endtask

    // ---------------------------------------------------------------------
    // Read task
    // ---------------------------------------------------------------------
    task fifo_read();
        logic [DATA_WIDTH-1:0] exp;
        begin
            @(posedge clk_i);
            if (!empty_o) begin
                rd_en_i = 1;
                exp = exp_q.pop_front();
            end
            else begin
                $display("[TB] READ BLOCKED (EMPTY)");
            end

            @(posedge clk_i);
            rd_en_i = 0;

            if (!empty_o) begin
                if (rd_data_o === exp) begin
                    pass_cnt++;
                end
                else begin
                    fail_cnt++;
                    $error("[TB] DATA MISMATCH exp=%0h got=%0h", exp, rd_data_o);
                end
            end
        end
    endtask

    // ---------------------------------------------------------------------
    // Testcases
    // ---------------------------------------------------------------------
    initial begin
        clk_i = 0;
        reset_dut();

        // Test 1: Fill FIFO completely
        repeat (FIFO_DEPTH) begin
            fifo_write($random);
        end

        // Test 2: Overflow attempt
        fifo_write(8'hFF);

        // Test 3: Drain FIFO completely
        repeat (FIFO_DEPTH) begin
            fifo_read();
        end

        // Test 4: Underflow attempt
        fifo_read();

        // Test 5: Simultaneous read & write
        repeat (5) begin
            fork
                fifo_write($random);
                fifo_read();
            join
        end

        // -----------------------------------------------------------------
        // Report
        // -----------------------------------------------------------------
        $display("======================================");
        $display("PASS COUNT = %0d", pass_cnt);
        $display("FAIL COUNT = %0d", fail_cnt);
        if (fail_cnt == 0)
            $display("TEST RESULT : PASS");
        else
            $display("TEST RESULT : FAIL");
        $display("======================================");

        $finish;
    end

endmodule
