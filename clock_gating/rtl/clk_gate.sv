module clk_gate (
    input   clk_i,
    input   clk_enable_i

    output  clk_gated_o
);

   logic neg_en_latch ;

   always_latch begin 
    if (~clk_i) 
        neg_en_latch = clk_enable_i;
   end 

   assign clk_gated_o = clk_i & neg_en_latch;

endmodule