// ============================================================================
// Module : pulse_stretcher_with_counter
// Purpose: Lossless pulse transfer with bounded event buffering
//
// Description:
//   - Source pulses increment counter
//   - Each returned ACK decrements counter
//   - Events serialized through closed-loop stretcher
//   - Guarantees no loss up to counter depth
//
// Limitation:
//   - Throughput limited by handshake round-trip latency
//   - Counter must be sized to avoid overflow
// ============================================================================

module credit_based_pulse_stretcher #(
    parameter int CNT_WIDTH = 4   // depth = 2^CNT_WIDTH - 1
)(

    // ------------------------------------------------------------------------
    // Source Domain (fast clock)
    // ------------------------------------------------------------------------
    input  logic src_clk_i,
    input  logic src_rst_ni,
    input  logic src_pulse_i,

    // ------------------------------------------------------------------------
    // Destination Domain (slow clock)
    // ------------------------------------------------------------------------
    input  logic dst_clk_i,
    input  logic dst_rst_ni,

    output logic dst_pulse_o
);

    // =========================================================================
    // SOURCE DOMAIN
    // =========================================================================

    logic [CNT_WIDTH-1:0] event_cnt;
    logic                 stretched_level;
    logic                 ack_sync;
    logic                 ack_sync_d;
    logic                 ack_sync_pulse;

    // -------------------------------------------------------------------------
    // ACK Edge Detect (source domain)
    // -------------------------------------------------------------------------
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            ack_sync_d <= 1'b0;
        else
            ack_sync_d <= ack_sync;
    end

    assign ack_sync_pulse = ack_sync & ~ack_sync_d;


    // -------------------------------------------------------------------------
    // Event Counter
    //   +1 for new source pulse
    //   -1 for each completed handshake (ACK edge)
    //   Handles simultaneous inc/dec safely
    // -------------------------------------------------------------------------
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            event_cnt <= '0;
        else
            event_cnt <= event_cnt
                       + (src_pulse_i    ? 1'b1 : 1'b0)
                       - (ack_sync_pulse ? 1'b1 : 1'b0);
    end


    // -------------------------------------------------------------------------
    // Internal pulse generation
    //   Fire when:
    //     - There is pending event
    //     - No transfer currently in flight
    // -------------------------------------------------------------------------
    wire busy;
    assign busy = stretched_level;   // one event in flight

    wire internal_pulse;
    assign internal_pulse = (event_cnt != 0) && !busy;


    // -------------------------------------------------------------------------
    // Closed-loop stretcher (single outstanding transfer)
    // -------------------------------------------------------------------------
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            stretched_level <= 1'b0;
        else if (internal_pulse)
            stretched_level <= 1'b1;
        else if (ack_sync_pulse)
            stretched_level <= 1'b0;
    end


    // =========================================================================
    // SOURCE → DESTINATION CDC (Request Path)
    // =========================================================================

    logic stretched_sync;

    cdc_sync_nstage #(
        .NUM_STAGES(2)
    ) u_sync_req (
        .clk_i      (dst_clk_i),
        .rst_ni     (dst_rst_ni),
        .async_din  (stretched_level),
        .sync_dout  (stretched_sync)
    );


    // =========================================================================
    // DESTINATION DOMAIN
    // =========================================================================

    logic stretched_sync_d;
    logic dst_ack;

    // Edge detect → 1-cycle output pulse
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            stretched_sync_d <= 1'b0;
        else
            stretched_sync_d <= stretched_sync;
    end

    assign dst_pulse_o = stretched_sync & ~stretched_sync_d;

    // Level ACK (2-phase handshake)
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_ack <= 1'b0;
        else
            dst_ack <= stretched_sync;
    end


    // =========================================================================
    // DESTINATION → SOURCE CDC (ACK Path)
    // =========================================================================

    cdc_sync_nstage #(
        .NUM_STAGES(2)
    ) u_sync_ack (
        .clk_i      (src_clk_i),
        .rst_ni     (src_rst_ni),
        .async_din  (dst_ack),
        .sync_dout  (ack_sync)
    );

endmodule
