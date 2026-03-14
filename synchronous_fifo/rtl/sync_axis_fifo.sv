// -----------------------------------------------------------------------------
// Synchronous AXI-Stream FIFO
// Wraps a standard sync_fifo into a Valid/Ready handshake interface
// -----------------------------------------------------------------------------
module sync_axis_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 16  // Must be a power of 2
)(
    input  logic                   clk_i,
    input  logic                   rst_ni,

    // --- Slave Interface (Input) ---
    input  logic [DATA_WIDTH-1:0]  s_axis_tdata,
    input  logic                   s_axis_tvalid,
    output logic                   s_axis_tready,

    // --- Master Interface (Output) ---
    output logic [DATA_WIDTH-1:0]  m_axis_tdata,
    output logic                   m_axis_tvalid,
    input  logic                   m_axis_tready
);

    // Internal signals for connecting the reference FIFO
    logic fifo_full;
    logic fifo_empty;
    logic fifo_wr_en;
    logic fifo_rd_en;

    // -------------------------------------------------------------------------
    // AXI-Stream Slave Logic (Write Side)
    // -------------------------------------------------------------------------
    // s_axis_tready indicates the FIFO has room.
    assign s_axis_tready = !fifo_full;
    
    // Write only when data is valid AND the FIFO is ready.
    assign fifo_wr_en    = s_axis_tvalid && s_axis_tready;

    // -------------------------------------------------------------------------
    // FIFO Instance
    // -------------------------------------------------------------------------
    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) u_sync_fifo_core (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),

        .wr_en_i    (fifo_wr_en),
        .wr_data_i  (s_axis_tdata),
        
        .rd_en_i    (fifo_rd_en),
        .rd_data_o  (m_axis_tdata),

        .full_o     (fifo_full),
        .empty_o    (fifo_empty),

        .rd_space_o (), 
        .wr_space_o ()   
    );

    // -------------------------------------------------------------------------
    // AXI-Stream Master Logic (Read Side)
    // -------------------------------------------------------------------------
    // m_axis_tvalid is high if there is data to read (FIFO not empty).
    assign m_axis_tvalid = !fifo_empty;

    // A Read occurs when there is valid data AND the downstream master is ready.
    assign fifo_rd_en    = m_axis_tvalid && m_axis_tready;

endmodule