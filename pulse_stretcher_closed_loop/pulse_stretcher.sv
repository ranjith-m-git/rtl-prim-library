// ============================================================================
// Module : pulse_stretcher_closed_loop
// Purpose: Closed-loop pulse stretcher for CDC transfer
//
// Description:
//   - Transfers a 1-cycle pulse from source (fast clk) to destination (slow clk)
//   - Guarantees capture (single outstanding event)
//   - Uses 2-phase level-based handshake
//
// Important:
//   - Source and destination resets must be synchronously deasserted
//   - Only ONE outstanding pulse is supported (no event counting)
//
// ============================================================================

module pulse_stretcher_closed_loop (

    // ------------------------------------------------------------------------
    // Source Domain (Fast Clock)
    // ------------------------------------------------------------------------
    input  logic src_clk_i,
    input  logic src_rst_ni,
    input  logic src_pulse_i,     // 1-cycle pulse in source domain

    // ------------------------------------------------------------------------
    // Destination Domain (Slow Clock)
    // ------------------------------------------------------------------------
    input  logic dst_clk_i,
    input  logic dst_rst_ni,

    // ------------------------------------------------------------------------
    // Output (Destination Domain)
    // ------------------------------------------------------------------------
    output logic dst_pulse_o      // safely captured pulse
);

    // =========================================================================
    //  SOURCE DOMAIN
    // =========================================================================

    logic stretched_level;        // Level signal sent across CDC
    logic ack_sync;               // ACK synchronized back from destination
    logic ack_sync_d;             // Delayed version for edge detect
    logic ack_sync_pulse;         // ACK rising edge (clear event)

    // -------------------------------------------------------------------------
    // Stretch logic (Set on src_pulse, Clear on ACK edge)
    // -------------------------------------------------------------------------
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            stretched_level <= 1'b0;

        else if (src_pulse_i)
            stretched_level <= 1'b1;

        else if (ack_sync_pulse)
            stretched_level <= 1'b0;
    end


    // -------------------------------------------------------------------------
    // ACK edge detection in source domain
    // -------------------------------------------------------------------------
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            ack_sync_d <= 1'b0;
        else
            ack_sync_d <= ack_sync;
    end

    assign ack_sync_pulse = ack_sync & ~ack_sync_d;


    // =========================================================================
    //  SOURCE → DESTINATION CDC (Request Path)
    // =========================================================================

    logic stretched_sync;         // Synced level in destination domain

    cdc_sync_nstage #(
        .NUM_STAGES(2)
    ) u_sync_to_dst (
        .clk_i      (dst_clk_i),
        .rst_ni     (dst_rst_ni),
        .async_din  (stretched_level),
        .sync_dout  (stretched_sync)
    );


    // =========================================================================
    //  DESTINATION DOMAIN
    // =========================================================================

    logic stretched_sync_d;       // Delayed version for edge detect
    logic dst_ack;                // Level ACK sent back

    // -------------------------------------------------------------------------
    // Edge detect to generate 1-cycle destination pulse
    // -------------------------------------------------------------------------
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            stretched_sync_d <= 1'b0;
        else
            stretched_sync_d <= stretched_sync;
    end

    assign dst_pulse_o = stretched_sync & ~stretched_sync_d;


    // -------------------------------------------------------------------------
    // Generate level-based ACK (2-phase handshake)
    // -------------------------------------------------------------------------
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_ack <= 1'b0;
        else
            dst_ack <= stretched_sync;
    end


    // =========================================================================
    //  DESTINATION → SOURCE CDC (ACK Path)
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


/*
                -------------------------------------
                SOURCE DOMAIN (src_clk)
                -------------------------------------

          src_pulse_i
                |
                v
        +-------------------+
        |  stretched_level  |<----------------------+
        |  (set/reset FF)   |                       |
        +-------------------+                       |
                |                                   |
                | async                              |
                v                                   |
         ================================================
         ||           CDC Synchronizer (2FF)          ||
         ================================================
                |
                v
                DESTINATION DOMAIN (dst_clk)
                -------------------------------------

        +-------------------+
        | stretched_sync    |
        +-------------------+
                |
                | edge detect
                v
           dst_pulse_o  (1-cycle pulse)

                |
                v
        +-------------------+
        |     dst_ack       |
        |  (level mirror)   |
        +-------------------+
                |
                | async
                v
         ================================================
         ||         CDC Synchronizer (2FF)             ||
         ================================================
                |
                v
        +-------------------+
        |     ack_sync      |
        +-------------------+
                |
                | edge detect
                v
           clear stretched_level
*/