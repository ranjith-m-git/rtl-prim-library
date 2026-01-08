// -----------------------------------------------------------------------------
// Async FIFO
// -----------------------------------------------------------------------------
//  - Separate write and read clock domains
//  - Gray-coded pointers
//  - 2-FF synchronizers for CDC
//  - Parameterized depth and data width
// -----------------------------------------------------------------------------

module async_fifo #(
    parameter int DATA_WIDTH  = 32,   // Width of FIFO data
    parameter int FIFO_DEPTH  = 16    // Number of FIFO entries
)(
    // -------------------------------------------------------------------------
    // Write Clock Domain
    // -------------------------------------------------------------------------
    input  logic                 wr_clk_i,
    input  logic                 wr_rst_ni,

    input  logic [DATA_WIDTH-1:0] wr_data_i,
    input  logic                  wr_en_i,
    output logic                  wr_full_o,

    // -------------------------------------------------------------------------
    // Read Clock Domain
    // -------------------------------------------------------------------------
    input  logic                 rd_clk_i,
    input  logic                 rd_rst_ni,

    output logic [DATA_WIDTH-1:0] rd_data_o,
    input  logic                  rd_en_i,
    output logic                  rd_empty_o
);

    // -------------------------------------------------------------------------
    // Local parameters and internal signals
    // -------------------------------------------------------------------------
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // Binary and Gray pointers (+1 bit for full/empty detection)
    logic [ADDR_WIDTH:0] rptr_bin_q, rptr_bin_d;
    logic [ADDR_WIDTH:0] rptr_gray_q, rptr_gray_d;
    logic [ADDR_WIDTH:0] rptr_gray_q2sync;

    logic [ADDR_WIDTH:0] wptr_bin_q, wptr_bin_d;
    logic [ADDR_WIDTH:0] wptr_gray_q, wptr_gray_d;
    logic [ADDR_WIDTH:0] wptr_gray_q2sync;

    logic rd_empty_d;
    logic wr_full_d;
    logic wr_en_mem;

    // -------------------------------------------------------------------------
    // Write Pointer Logic (Write Clock Domain)
    // -------------------------------------------------------------------------

    // Increment binary pointer when write enabled and FIFO not full
    assign wptr_bin_d  = wptr_bin_q + (wr_en_i && !wr_full_o);

    // Binary-to-Gray conversion
    assign wptr_gray_d = (wptr_bin_d >> 1) ^ wptr_bin_d;

    // Full condition:
    // Next write pointer equals read pointer with MSBs inverted
    assign wr_full_d =
        (wptr_gray_d ==
         {~rptr_gray_q2sync[ADDR_WIDTH:ADDR_WIDTH-1],
           rptr_gray_q2sync[ADDR_WIDTH-2:0]});

    // Synchronize read pointer Gray into write clock domain
    gray_bus_2ff_sync #(
        .WIDTH (ADDR_WIDTH + 1)
    ) u_sync_rptr_to_wr (
        .clk_i         (wr_clk_i),
        .rst_ni        (wr_rst_ni),
        .data_i        (rptr_gray_q),
        .data_q2sync_o (rptr_gray_q2sync)
    );

    // Write pointer registers
    always_ff @(posedge wr_clk_i or negedge wr_rst_ni) begin
        if (!wr_rst_ni) begin
            wptr_bin_q  <= '0;
            wptr_gray_q <= '0;
            wr_full_o   <= 1'b0;
        end
        else begin
            wptr_bin_q  <= wptr_bin_d;
            wptr_gray_q <= wptr_gray_d;
            wr_full_o   <= wr_full_d;
        end
    end

    // -------------------------------------------------------------------------
    // Read Pointer Logic (Read Clock Domain)
    // -------------------------------------------------------------------------

    // Increment binary pointer when read enabled and FIFO not empty
    assign rptr_bin_d  = rptr_bin_q + (rd_en_i && !rd_empty_o);

    // Binary-to-Gray conversion
    assign rptr_gray_d = (rptr_bin_d >> 1) ^ rptr_bin_d;

    // Empty condition:
    // Next read pointer equals synchronized write pointer
    assign rd_empty_d = (rptr_gray_d == wptr_gray_q2sync);

    // Synchronize write pointer Gray into read clock domain
    gray_bus_2ff_sync #(
        .WIDTH (ADDR_WIDTH + 1)
    ) u_sync_wptr_to_rd (
        .clk_i         (rd_clk_i),
        .rst_ni        (rd_rst_ni),
        .data_i        (wptr_gray_q),
        .data_q2sync_o (wptr_gray_q2sync)
    );

    // Read pointer registers
    always_ff @(posedge rd_clk_i or negedge rd_rst_ni) begin
        if (!rd_rst_ni) begin
            rptr_bin_q  <= '0;
            rptr_gray_q <= '0;
            rd_empty_o  <= 1'b1;
        end
        else begin
            rptr_bin_q  <= rptr_bin_d;
            rptr_gray_q <= rptr_gray_d;
            rd_empty_o  <= rd_empty_d;
        end
    end

    // -------------------------------------------------------------------------
    // FIFO Memory
    // -------------------------------------------------------------------------

    // Write enable to memory (write side only)
    assign wr_en_mem = wr_en_i && !wr_full_o;

    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (FIFO_DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_mem (
        // Write port
        .wr_clk_i   (wr_clk_i),
        .wr_en_i    (wr_en_mem),
        .wr_addr_i  (wptr_bin_q[ADDR_WIDTH-1:0]),
        .wr_data_i  (wr_data_i),

        // Read port 
        .rd_addr_i  (rptr_bin_q[ADDR_WIDTH-1:0]),
        .rd_data_o  (rd_data_o)
    );

endmodule : async_fifo
