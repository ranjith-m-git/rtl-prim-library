module async_axis_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 16  // Must be power of 2
)(
    // --- Slave Interface (Write Domain) ---
    input  logic                   s_axis_aclk,
    input  logic                   s_axis_aresetn,
    input  logic [DATA_WIDTH-1:0]  s_axis_tdata,
    input  logic                   s_axis_tvalid,
    output logic                   s_axis_tready,

    // --- Master Interface (Read Domain) ---
    input  logic                   m_axis_aclk,
    input  logic                   m_axis_aresetn,
    output logic [DATA_WIDTH-1:0]  m_axis_tdata,
    output logic                   m_axis_tvalid,
    input  logic                   m_axis_tready
);

    // Internal signals to connect to the base FIFO
    logic fifo_full;
    logic fifo_empty;
    logic fifo_rd_en;
    logic [DATA_WIDTH-1:0] fifo_rd_data;

    // -------------------------------------------------------------------------
    // Write Side Logic: Slave Ready
    // -------------------------------------------------------------------------
    // We are ready to accept data if the FIFO is not full.
    assign s_axis_tready = !fifo_full;
    logic  fifo_wr_en;
    assign fifo_wr_en    = s_axis_tvalid && s_axis_tready;

    // -------------------------------------------------------------------------
    // Instantiate Base Async FIFO
    // -------------------------------------------------------------------------
    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) u_base_fifo (
        .wr_clk_i   (s_axis_aclk),
        .wr_rst_ni  (s_axis_aresetn),
        .wr_data_i  (s_axis_tdata),
        .wr_en_i    (fifo_wr_en),
        .wr_full_o  (fifo_full),
        .wr_space_o (), // Optional: export if needed

        .rd_clk_i   (m_axis_aclk),
        .rd_rst_ni  (m_axis_aresetn),
        .rd_data_o  (fifo_rd_data),
        .rd_en_i    (fifo_rd_en),
        .rd_empty_o (fifo_empty),
        .rd_space_o ()  // Optional: export if needed
    );

    // -------------------------------------------------------------------------
    // Read Side Logic: FWFT / AXI-Stream Master
    // -------------------------------------------------------------------------
    // AXI-Stream requires the data to be "out" already. 
    // We use a small skid-buffer style logic to manage the read enable.
    
    assign m_axis_tvalid = !fifo_empty;
    assign m_axis_tdata  = fifo_rd_data;
    
    // We pop from the internal FIFO if:
    // 1. The FIFO is not empty AND
    // 2. The downstream master is ready to take the current data
    assign fifo_rd_en = m_axis_tvalid && m_axis_tready;

endmodule