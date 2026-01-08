// -----------------------------------------------------------------------------
// Module: Dual_Port_RAM
// Description:
//   Simple dual-port RAM with:
//     - One synchronous write port (wr_clk_i domain)
//     - One asynchronous read port
//
// Notes:
//   - Suitable for small RAMs / register arrays
//   - Asynchronous read may not infer block RAM in FPGA
// -----------------------------------------------------------------------------

module fifo_mem #(
    parameter int DATA_WIDTH = 32,              // Width of each memory word
    parameter int DEPTH      = 16,              // Number of memory locations
    parameter int ADDR_WIDTH = $clog2(DEPTH)    // Address width
)(
    // -------------------------------------------------------------------------
    // Write Port (Synchronous)
    // -------------------------------------------------------------------------
    input  logic                  wr_clk_i,     // Write clock
    input  logic                  wr_en_i,       // Write enable
    input  logic [ADDR_WIDTH-1:0] wr_addr_i,     // Write address
    input  logic [DATA_WIDTH-1:0] wr_data_i,     // Write data

    // -------------------------------------------------------------------------
    // Read Port (Asynchronous)
    // -------------------------------------------------------------------------
    input  logic [ADDR_WIDTH-1:0] rd_addr_i,     // Read address
    output logic [DATA_WIDTH-1:0] rd_data_o      // Read data
);

    // -------------------------------------------------------------------------
    // Memory declaration
    //   - DEPTH entries
    //   - Each entry is DATA_WIDTH bits wide
    // -------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem_2d [0:DEPTH-1];

    // -------------------------------------------------------------------------
    // Write logic
    //   - Data is written on rising edge of wr_clk_i
    // -------------------------------------------------------------------------
    always_ff @(posedge wr_clk_i) begin
        if (wr_en_i)
            mem_2d[wr_addr_i] <= wr_data_i;
    end

    // -------------------------------------------------------------------------
    // Asynchronous read logic
    //   - Read data updates immediately with rd_addr_i
    // -------------------------------------------------------------------------
    assign rd_data_o = mem_2d[rd_addr_i];

endmodule:fifo_mem
