// -----------------------------------------------------------------------------
// Synchronous FIFO
// Single clock for read and write
// -----------------------------------------------------------------------------
module sync_fifo #(
    parameter int DATA_WIDTH  = 32,   // Width of FIFO data
    parameter int FIFO_DEPTH  = 16    // Number of FIFO entries
)(
    input  clk_i,                      // FIFO clock
    input  rst_ni,                     // Active-low reset

    input  rd_en_i,                    // Read enable
    input  wr_en_i,                    // Write enable

    input  [DATA_WIDTH-1:0] wr_data_i,// Write data
    output [DATA_WIDTH-1:0] rd_data_o,// Read data

    output full_o,                     // FIFO full indicator
    output empty_o                     // FIFO empty indicator
);

    // Address width derived from FIFO depth
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // -------------------------------------------------------------------------
    // Write and Read Pointers
    // Binary pointers with extra MSB for wrap detection
    // -------------------------------------------------------------------------
    logic [ADDR_WIDTH:0] wptr_d;
    logic [ADDR_WIDTH:0] wptr_q;
    logic [ADDR_WIDTH:0] rptr_d;
    logic [ADDR_WIDTH:0] rptr_q;

    // -------------------------------------------------------------------------
    // FIFO Status Logic
    // -------------------------------------------------------------------------

    // FIFO full when read pointer equals write pointer
    // with inverted MSB and same lower bits
    assign full_o =
        (rptr_q == {~wptr_q[ADDR_WIDTH], wptr_q[ADDR_WIDTH-1:0]});

    // FIFO empty when read and write pointers are equal
    assign empty_o = (rptr_q == wptr_q);

    // Next write pointer update
    assign wptr_d = wptr_q + (wr_en_i && !full_o);

    // Next read pointer update
    assign rptr_d = rptr_q + (rd_en_i && !empty_o);

    // -------------------------------------------------------------------------
    // Pointer Registers
    // -------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wptr_q <= '0;
            rptr_q <= '0;
        end
        else begin
            wptr_q <= wptr_d;
            rptr_q <= rptr_d;
        end
    end

    // -------------------------------------------------------------------------
    // FIFO Memory Instance
    // -------------------------------------------------------------------------

    // Write enable gating (write only when FIFO not full)
    assign wr_en_mem = wr_en_i && !full_o;

    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (FIFO_DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_mem (
        // Write port
        .wr_clk_i   (clk_i),
        .wr_en_i    (wr_en_mem),
        .wr_addr_i  (wptr_q[ADDR_WIDTH-1:0]),
        .wr_data_i  (wr_data_i),

        // Read port
        .rd_addr_i  (rptr_q[ADDR_WIDTH-1:0]),
        .rd_data_o  (rd_data_o)
    );

endmodule : sync_fifo
