module half_adder (
    input  logic a_i,          // Input A
    input  logic b_i,          // Input B
    output logic sum_o,        // Sum output
    output logic carry_o       // Carry output
);

    // Sum is XOR of inputs
    assign sum_o = a_i ^ b_i;

    // Carry is AND of inputs  
    assign carry_o = a_i & b_i;

endmodule