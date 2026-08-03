module full_adder_standalone (
    input  logic a_i,          // Input A
    input  logic b_i,          // Input B
    input  logic carry_i,      // Carry input
    output logic sum_o,        // Sum output
    output logic carry_o       // Carry output
);

    // Sum calculation: XOR of all inputs
    assign sum_o = a_i ^ b_i ^ carry_i;

    // Carry calculation: majority function
    // Carry occurs when at least 2 of the 3 inputs are 1
    assign carry_o = (a_i & b_i) | (a_i & carry_i) | (b_i & carry_i);

endmodule