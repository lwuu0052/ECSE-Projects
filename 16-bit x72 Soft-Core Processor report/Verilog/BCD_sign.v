module BCD_sign (
    input  [3:0] data,
	 input sign,
    output [7:0] X
);
    wire A, B, C, D;
    assign {A, B, C, D} = data;

    // Active-low outputs, so invert the active-high logic
    assign X[0] = ~ (A | C | (B & D) | (~B & ~D)); // segment a
    assign X[1] = ~ ((~B) | (C & D) | (~C & ~D));  // segment b
    assign X[2] = ~ (B | D | (~C));                // segment c
    assign X[3] = ~ (A | (~B & C) | (C & ~D) | (~B & ~D) | (B & D & ~C)); // segment d
    assign X[4] = ~ ((C & ~D) | (~B & ~D));        // segment e
    assign X[5] = ~ (A | (B & ~C) | (B & ~D) | (~C & ~D)); // segment f
    assign X[6] = ~ (A | (B & ~C) | (C & ~B) | (C & ~D));  // segment g
	 assign X[7] = ~ sign; // dp
	 
endmodule