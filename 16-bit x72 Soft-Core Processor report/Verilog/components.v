/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual components to be used in 
    the CPU.

Please enter your name and student ID: Wu Li Min (34478841), Yeoh Jie Ying (34601643)

*/

// Done by Wu Li Min (34478841)
module sign_extend(in, ext);

	/* 
	 * This module sign extends the 9-bit Din to a 16-bit output.
	 */
	 
	// TODO: Declare inputs and outputs
	
	input  [8:0]in;
	output reg [15:0]ext;
	
	// TODO: implement FSM
	
	always@(*)begin
	
		if (in[8] == 1'b1)begin
			ext <= { {7{1'b1}}, in };
		end
		
		else begin
			ext <= { {7{1'b0}}, in };
		end
		
	end
	
endmodule


// Done by Wu Li Min (34478841)
module tick_FSM(rst, clk, enable, tick);

	/* 
	 * This module implements a tick FSM that will be used to
	 * control the actions of the control unit
	 */

	// TODO: Declare inputs and outputs

	input  rst,clk,enable;
	output reg [3:0] tick;
	
	
    // TODO: implement FSM
	 
	 initial tick <= 4'b0001;
	 always @(posedge clk) begin
	 
        if (rst) begin
            tick <= 4'b0001;
				
        end 
		  
        else if (enable) begin
            case (tick)
                4'b0001: tick <= 4'b0010;
                4'b0010: tick <= 4'b0100;
                4'b0100: tick <= 4'b1000;
                4'b1000: tick <= 4'b0001;
                default: tick <= 4'b0001;
            endcase
        end 
		  
        else begin
            tick <= tick;
        end
		  
    end
	 
endmodule


// Done by Yeoh Jie Ying (34601643)
module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);

	/* 
	 * This module takes 10 inputs and places the correct input onto the bus.
	 */
	 
	 // TODO: Declare inputs and outputs
	 input [15:0] R0,R1,R2,R3,R4,R5,R6,R7,G,SignExtDin;
	 input [3:0] sel;
    output reg [15:0] Bus;
	
	// TODO: implement logic
	always@(*)begin
	
		case (sel)
				4'b0000:Bus=SignExtDin;
            4'b0001:Bus=R0;
            4'b0010:Bus=R1;
            4'b0011:Bus=R2;
            4'b0100:Bus=R3;
            4'b0101:Bus=R4;
            4'b0110:Bus=R5;
            4'b0111:Bus=R6;
            4'b1000:Bus=R7;
            4'b1001:Bus=G;
				default: Bus = 16'h0000;
				
		endcase
		
	end

endmodule


// Done by Yeoh Jie Ying (34601643)
module ALU (input_a, input_b, alu_op, result);

	/* 
	 * This module implements the arithmetic logic unit of the processor.
	 */
	 
	input  [15:0]input_a;
	input  [15:0]input_b;
	input  [2:0]alu_op;
	
	output reg [15:0]result;


	// TODO: Implement ALU Logic:
	
	always@(*)
		begin
		   result = 16'd0;
			case (alu_op)
				3'b000 : result=input_a * input_b;
				3'b001 : result=input_a + input_b;
				3'b010 : result=input_a - input_b;
				3'b011 : 
				  begin 
				  
					if ($signed(input_a) < 0)
						result = $signed(input_b) >>> $unsigned((-$signed(input_a))); 
					else if ($signed(input_a) > 0)
						result = $signed(input_b) <<< $unsigned($signed(input_a));
					else
						result = input_b;
					end
				3'b100 : result=16'b0;
				3'b101 : result=16'b0;
				3'b110 : result=16'b0;
				3'b111 : result=16'b0;
				default: result = 16'b0;
			endcase
			
		end
		
endmodule


// Done by Yeoh Jie Ying (34601643)
module register_n(data_in, r_in, clk, Q, rst);


	// To set parameter N during instantiation, you can use:
	// register_n #(.N(num_bits)) reg_IR(.....), 
	// where num_bits is how many bits you want to set N to
	// and "..." is your usual input/output signals

	parameter N = 16;

	/* 
	 * This module implements registers that will be used in the processor.
	 */
	 
	// TODO: Declare inputs, outputs, and parameter:
	
	input [N-1:0] data_in;
	input r_in,clk,rst;
	output reg [N-1:0] Q;
	
	// TODO: Implement register logic:
	
	always@(posedge clk)begin
	
		if (rst) begin
			Q<={N{1'b0}};
		end 
		
		else if (r_in==1) begin 
		   Q<=data_in;
		end	
		
		else begin
			Q<=Q;
		end
		
	end
	
endmodule
