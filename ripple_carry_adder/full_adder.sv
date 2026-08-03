module full_adder (
    input  logic a_i,          // Input A
    input  logic b_i,          // Input B
    input  logic carry_i,      // Carry input
    output logic sum_o,        // Sum output
    output logic carry_o       // Carry output
);

    // Internal signals
    logic ha1_sum;
    logic ha1_carry;
    logic ha2_carry;

    // First half adder: A + B
    half_adder ha1 (
        .a_i    (a_i),
        .b_i    (b_i),
        .sum_o  (ha1_sum),
        .carry_o(ha1_carry)
    );

    // Second half adder: (A+B) + Carry_in
    half_adder ha2 (
        .a_i    (ha1_sum),
        .b_i    (carry_i),
        .sum_o  (sum_o),
        .carry_o(ha2_carry)
    );

    // Final carry is OR of both half adder carries
    assign carry_o = ha1_carry | ha2_carry;

endmodule