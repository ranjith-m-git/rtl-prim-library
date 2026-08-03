module ripple_carry_adder_top #(
    parameter WIDTH = 4  // Configurable adder width
) (
    input  logic [WIDTH-1:0] a_i,        // Input A
    input  logic [WIDTH-1:0] b_i,        // Input B
    input  logic             carry_i,    // Carry input
    output logic [WIDTH-1:0] sum_o,      // Sum output
    output logic             carry_o,    // Carry output
    output logic             overflow_o  // Overflow flag
);

    // Internal carry signals
    logic [WIDTH:0] carry_chain;
    
    // Set the initial carry
    assign carry_chain[0] = carry_i;
    
    // Generate full adders for each bit
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder_chain
            full_adder fa_inst (
                .a_i      (a_i[i]),
                .b_i      (b_i[i]),
                .carry_i  (carry_chain[i]),
                .sum_o    (sum_o[i]),
                .carry_o  (carry_chain[i+1])
            );
        end
    endgenerate
    
    // Final carry output
    assign carry_o = carry_chain[WIDTH];
    
    // Overflow detection for signed arithmetic
    // Overflow occurs when carry into MSB ≠ carry out of MSB
    assign overflow_o = carry_chain[WIDTH-1] ^ carry_chain[WIDTH];

endmodule