module tb_clk_divider_n;

    localparam int WIDTH = 8;

    logic clk_i;
    logic rst_ni;
    logic [WIDTH-1:0] div_n_i;
    logic clk_o;
    int rand_div;

    time last_edge;
    time period_measured;

    // DUT
    clk_divider_n #(
        .WIDTH (WIDTH)
    ) dut (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .div_val_i  (div_n_i),
        .div_clk_o  (clk_o)
    );

    // -------------------------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------------------------
    initial clk_i = 0;
    always #5 clk_i = ~clk_i; // 100 MHz

    // -------------------------------------------------------------------------
    // Reset
    // -------------------------------------------------------------------------
    initial begin
        rst_ni = 0;
        div_n_i = 1;
        #50;
        rst_ni = 1;
    end

    // -------------------------------------------------------------------------
    // Measure output clock period
    // -------------------------------------------------------------------------
    always @(posedge clk_o) begin
        period_measured = $time - last_edge;
        last_edge = $time;
    end

    // -------------------------------------------------------------------------
    // TASK: Apply divider and check behavior
    // -------------------------------------------------------------------------
    task automatic check_div(input int div);
        time expected_period;
        begin
            div_n_i = div;
            #(2000);

            if (div <= 1)
                expected_period = 10;
            else
                expected_period = 10 * div;

            if (period_measured !== expected_period) begin
             $display("[FAIL @ %0t] div=%0d Expected=%0t Got=%0t",
             $time, div, expected_period, period_measured);
             
            end else begin
                $display("[PASS] div=%0d Period=%0t",
                         div, period_measured);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // TEST SEQUENCE
    // -------------------------------------------------------------------------
    initial begin
        @(posedge rst_ni);

        last_edge = 0;

        // Corner cases
        check_div(0);   // bypass
        check_div(1);   // bypass
        check_div(2);   // div2
        check_div(3);   // odd
        check_div(4);   // even
        check_div(5);   // odd
        check_div(6);   // even
        check_div(7);   // odd
        check_div(8);   // even
        check_div(9);   // odd

        // Randomized dynamic changes

        repeat (30) begin
          rand_div = $urandom_range(1, 20);
          check_div(rand_div);
          #1000;
        end

        $display("=================================");
        $display("ALL TESTS COMPLETED");
        $display("=================================");
        $finish;
    end

endmodule
