module proc_memory_top_level (
	input  [0:0]  KEY,          
	input  [9:9]  SW,           
	input         CLOCK_50,
	output [9:0]  LEDR,         
	output [7:0]  HEX5, HEX4, HEX3, HEX2, HEX1, HEX0  
); 
	wire   [8:0]  q;
	wire   [15:0] PC, display, bus;
	
   // Global Clock 10Hz
    reg [21:0] clock_counter;
    reg clock_toggle;

    initial 
		begin
        clock_counter = 0;
        clock_toggle = 0;
		end

    always @(posedge CLOCK_50) 
		begin
        if (clock_counter == 2500000 - 1)   // 10Hz (0.1s period)
				begin 
            clock_counter <= 0;
            clock_toggle <= ~clock_toggle;
				end 
			else 
				begin
            clock_counter <= clock_counter + 22'd1;
				end
		end
		
   wire global_10Hz_clk = clock_toggle;

		// instantiate module
		simple_proc ist_proc_memory (
			.clk(global_10Hz_clk),          
			.rst(~KEY[0]),          
			.enable(SW[9]),         
			.din(q),          
			.bus(bus),  
			.HEX5(HEX5),
			.R0(), .R1(), .R2(), .R3(), .R4(), .R5(), .R6(), .R7(),
			.display(display), .PC(PC)             
		);
		BCD_decoder ist_BCD_decoder (.display(display), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4)); 
		ROM ist_ROM (.address(PC), .clock(CLOCK_50), .q(q));
		
assign LEDR = bus[9:0];
endmodule
