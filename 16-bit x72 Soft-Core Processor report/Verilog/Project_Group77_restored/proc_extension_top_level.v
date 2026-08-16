module proc_extension_top_level (
    input  [1:0] KEY,          
    input  [9:0] SW,           
    output [9:0] LEDR,         
    output [7:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 
);

    wire [15:0] bus_split;
	 
    simple_proc CPU (
        .clk(~KEY[1]),          
        .rst(~KEY[0]),         
        .enable(SW[9]),        
        .din(SW[8:0]),          
        .bus(bus_split),  
        .HEX0(HEX0),            
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .R0(), .R1(), .R2(), .R3(), .R4(), .R5(), .R6(), .R7(),
        .display()              
    );

	 assign LEDR[9:0] = bus_split[9:0];

endmodule