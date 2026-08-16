/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual the CPU.

Please enter your student ID: Wu Li Min (34478841), Yeoh Jie Ying (34601643)

*/
/*
module simple_proc(
	input  [0:0]  clk, rst, enable,
	input  [8:0]  din,
	output [6:0]  HEX5,
	output [15:0] R0, R1, R2, R3, R4, R5, R6, R7, bus
	);
	
    reg   [0:0]  R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in, IR_in, A_in, G_in; 
	 reg   [2:0]  alu_op;
	 reg   [3:0]  BusControl;
	 wire  [0:0]  D0, D1, D2, D3, D4;
	 wire  [2:0]  opcode, Rx, Ry;    
	 wire  [3:0]  tick_FSM_out;     
	 wire  [8:0]  IR_out;
	 wire  [15:0] G_out, A_out,alu_out, SignExtDout;
	 wire  [3:0]  tick_FSM_BCD;  // tick_FSM_BCD is the tick number on the board, which is HEX5
	 
	 // SignExtend
	 sign_extend ist_sign_ext(.in(din), .ext(SignExtDout));
	 
	 // Regiseter
	 register_n #(.N(9))  ins_IR(.data_in(din), .r_in(IR_in), .clk(clk), .rst(rst), .Q(IR_out));
    register_n #(.N(16)) ins_reg0(.data_in(bus), .r_in(R0_in), .clk(clk), .rst(rst), .Q(R0));
    register_n #(.N(16)) ins_reg1(.data_in(bus), .r_in(R1_in), .clk(clk), .rst(rst), .Q(R1));
	 register_n #(.N(16)) ins_reg2(.data_in(bus), .r_in(R2_in), .clk(clk), .rst(rst), .Q(R2));
	 register_n #(.N(16)) ins_reg3(.data_in(bus), .r_in(R3_in), .clk(clk), .rst(rst), .Q(R3));
	 register_n #(.N(16)) ins_reg4(.data_in(bus), .r_in(R4_in), .clk(clk), .rst(rst), .Q(R4));
	 register_n #(.N(16)) ins_reg5(.data_in(bus), .r_in(R5_in), .clk(clk), .rst(rst), .Q(R5));
	 register_n #(.N(16)) ins_reg6(.data_in(bus), .r_in(R6_in), .clk(clk), .rst(rst), .Q(R6));
	 register_n #(.N(16)) ins_reg7(.data_in(bus), .r_in(R7_in), .clk(clk), .rst(rst), .Q(R7));
	 register_n #(.N(16)) ins_regA(.data_in(bus), .r_in(A_in), .clk(clk), .rst(rst), .Q(A_out));
	 register_n #(.N(16)) ins_regG(.data_in(alu_out), .r_in(G_in), .clk(clk), .rst(rst), .Q(G_out));
	 
	 
    // Multiplexer:
    multiplexer ist_mux(
	 .SignExtDin(SignExtDout),
	 .R0(R0),
	 .R1(R1),
	 .R2(R2),
	 .R3(R3),
	 .R4(R4),
	 .R5(R5),
	 .R6(R6),
	 .R7(R7),
	 .G(G_out),
	 .sel(BusControl),
	 .Bus(bus)
	 );
    
    // ALU:
    ALU ist_ALU(
	 .input_a(A_out),
	 .input_b(bus),
	 .alu_op(alu_op),
	 .result(alu_out)
	 );
    
    // tick counter:
    tick_FSM ist_tick_FSM(
	 .rst(rst), 
	 .clk(clk), 
	 .enable(enable), 
	 .tick(tick_FSM_out)  
	 );
	 
	 
	 // BCD : Show Tick
	 assign tick_FSM_BCD[0] = tick_FSM_out[0] || tick_FSM_out[2];
	 assign tick_FSM_BCD[1] = tick_FSM_out[1] || tick_FSM_out[2];
	 assign tick_FSM_BCD[2] = tick_FSM_out[3];
	 assign tick_FSM_BCD[3] = 1'b0;
	 BCD ist_BCD5(.data(tick_FSM_BCD), .X(HEX5));
	 
	 // Assign Value
	 assign opcode = IR_out[8:6];
	 assign Rx = IR_out[5:3];
	 assign Ry = IR_out[2:0];
    
	 // Control Unit
	 always @(*) 
       begin
		 // Reset section
       IR_in <= 1'b0;
       BusControl <= 4'b1010;
       R0_in <= 1'b0;
       R1_in <= 1'b0;
       R2_in <= 1'b0;
       R3_in <= 1'b0;
       R4_in <= 1'b0;
       R5_in <= 1'b0;
       R6_in <= 1'b0;
       R7_in <= 1'b0;
       A_in <= 1'b0;
       alu_op <= 3'b100;
       G_in <= 1'b0; 
    
		 case (tick_FSM_out)
         4'b0001: // Tick 1 
			  begin	
           IR_in <= 1'b1;	  
           end
	 
			4'b0010: // Tick 2
           begin				
           case (opcode) 		  
              3'b001, 3'b011: // add and sub
				    begin
                case (Rx)
                   3'b000: BusControl <= 4'b0001;
                   3'b001: BusControl <= 4'b0010;
                   3'b010: BusControl <= 4'b0011;
                   3'b011: BusControl <= 4'b0100;
                   3'b100: BusControl <= 4'b0101;
                   3'b101: BusControl <= 4'b0110;
                   3'b110: BusControl <= 4'b0111;
                   3'b111: BusControl <= 4'b1000;
						 default: ;
                endcase
                   A_in <= 1'b1;
                end
					 
				  3'b010:  // addi
				    begin
                BusControl <=4'b0000;
					 A_in<=1'b1;
                end            
             				  
              3'b111:  // movi
				    begin 
                BusControl <= 4'b0000;
                case (Rx)
                   3'b000: R0_in <= 1'b1;
                   3'b001: R1_in <= 1'b1;
                   3'b010: R2_in <= 1'b1;
                   3'b011: R3_in <= 1'b1;
                   3'b100: R4_in <= 1'b1;
                   3'b101: R5_in <= 1'b1;
                   3'b110: R6_in <= 1'b1;
                   3'b111: R7_in <= 1'b1;
						 default: ;
                endcase
                end
			     default: ;
           endcase
           end

         4'b0100: //Tick 3
           begin
           case (opcode)
              3'b001:   // add
				    begin  
                case (Ry)
                   3'b000: BusControl <= 4'b0001;
                   3'b001: BusControl <= 4'b0010;
                   3'b010: BusControl <= 4'b0011;
                   3'b011: BusControl <= 4'b0100;
                   3'b100: BusControl <= 4'b0101;
                   3'b101: BusControl <= 4'b0110;
                   3'b110: BusControl <= 4'b0111;
                   3'b111: BusControl <= 4'b1000;
						 default: ;
                 endcase
                    alu_op <= 3'b001;
						  G_in<=1'b1;
                 end
					  
				  3'b010: //addi
					 begin 
                case (Rx)
                   3'b000: BusControl <= 4'b0001;
                   3'b001: BusControl <= 4'b0010;
                   3'b010: BusControl <= 4'b0011;
                   3'b011: BusControl <= 4'b0100;
                   3'b100: BusControl <= 4'b0101;
                   3'b101: BusControl <= 4'b0110;
                   3'b110: BusControl <= 4'b0111;
                   3'b111: BusControl <= 4'b1000;
						 default: ;
                endcase
                   alu_op <= 3'b001;
						 G_in <=1'b1;
                end

              3'b011: //sub
				    begin  
                case (Ry)
                   3'b000: BusControl <= 4'b0001;
                   3'b001: BusControl <= 4'b0010;
                   3'b010: BusControl <= 4'b0011;
                   3'b011: BusControl <= 4'b0100;
                   3'b100: BusControl <= 4'b0101;
                   3'b101: BusControl <= 4'b0110;
                   3'b110: BusControl <= 4'b0111;
                   3'b111: BusControl <= 4'b1000;
						 default: ;
                endcase
                   alu_op <= 3'b010;
						 G_in<=1'b1;
                end

                 3'b111: ; // movi 
				     default: ;
           endcase
           end

        
         4'b1000: //Tick 4 
		     begin
           case (opcode)
				  3'b001, 3'b011, 3'b010: // add, addi, sub
				    begin
                BusControl <= 4'b1001;
                case (Rx)
                   3'b000: R0_in <= 1'b1;
                   3'b001: R1_in <= 1'b1;
                   3'b010: R2_in <= 1'b1;
                   3'b011: R3_in <= 1'b1;
                   3'b100: R4_in <= 1'b1;
                   3'b101: R5_in <= 1'b1;
                   3'b110: R6_in <= 1'b1;
                   3'b111: R7_in <= 1'b1;
						 default: ;
                endcase
                end

                3'b111: ; //movi
					 default: ;
           endcase         
           end
		 default: ;
       endcase
       end 

endmodule
*/