`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the individual 
    components used in the processor.

Please enter your student ID: Wu Li Min (34478841), Yeoh Jie Ying (34601643)

*/

module components_tb;

    reg clk = 0;
    always #5 clk = ~clk;  

    // TODO: Implement the logic of your testbench here
     
    // Done by Yeoh Jie Ying (34601643)
    // Part 1 - Sign Extender 

    reg  [8:0]  in;
    wire [15:0] ext;

    sign_extend test1 ( .in(in), .ext(ext) );
     
    integer count1, errors1;
    reg done1;

    initial begin
        in      = 9'd0;
        count1  = 0;
        errors1 = 0;
        done1   = 0;
    end

    always @(posedge clk) begin
        if (!done1) begin

            if (ext !== {{7{in[8]}}, in}) begin
                $display("Error: in=%b. Got ext=%b. Expected=%b at @%0t",
                         in, ext, {{7{in[8]}}, in}, $time);
                errors1 = errors1 + 1;
            end
            count1 = count1 + 1;

            in <= in + 1'b1;

            if (count1 == 512) begin
                $display("Done with test for part 1 - sign extender.");
                $display("%0d tests run.", count1);
                $display("There were %0d errors for part 1.", errors1);
                done1 = 1;
            end
        end
    end
     
    // Done by Yeoh Jie Ying (34601643)
	// Part 2 - tick_FSM
	reg rst2, enable2;
	wire [3:0] tick;

	tick_FSM test2 ( .rst(rst2), .clk(clk), .enable(enable2), .tick(tick) );

	integer errors2, count2;
	reg done2, started2;

	initial begin
		 rst2     = 1;
		 enable2  = 0;
		 count2   = 0;
		 errors2  = 0;
		 done2    = 0;
		 started2 = 0;

		 // release reset 
		 repeat (2) @(posedge clk);
		 rst2    = 0;
		 enable2 = 1;
	end

	always @(posedge clk) begin
		 if (!done2) begin
			  #1;

			  if (!started2) begin
					if (tick === 4'b0001) begin
						 started2 <= 1'b1;
						 count2   <= 0;
					end
			  end else begin
					case (count2[2:0])
						 3'd0: if (tick !== 4'b0001) begin
									  $display("Error : expected 0001, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 3'd1: if (tick !== 4'b0010) begin
									  $display("Error : expected 0010, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 3'd2: if (tick !== 4'b0100) begin
									  $display("Error : expected 0100, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 3'd3: if (tick !== 4'b1000) begin
									  $display("Error : expected 1000, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 3'd4: if (tick !== 4'b0001) begin
									  $display("Error : expected 0001, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 3'd5: if (tick !== 4'b0010) begin
									  $display("Error : expected 0010, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 3'd6: if (tick !== 4'b0100) begin
									  $display("Error : expected 0100, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 3'd7: if (tick !== 4'b1000) begin
									  $display("Error : expected 1000, got %b at @%0t", tick, $time);
									  errors2 = errors2 + 1;
								 end
						 default: ;
					endcase

					count2 <= count2 + 1;

					if (count2 == 8-1) begin
						 $display("Done with test for part 2 - tick FSM.");
						 $display("%0d tests run.", 8);
						 $display("There were %0d errors for part 2.", errors2);
						 done2 <= 1;
					end
			  end
		 end
	end

    
    // Done by Wu Li Min (34478841)
    // Part 3 - Multiplexer
    reg  [15:0] SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G;
    reg  [3:0]  sel;
    wire [15:0] Bus;
    
    multiplexer test3 (SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
    
    integer count3, errors3;
    reg done3;
    
    function [15:0] expected_result_mux;
        input [3:0] s;
        begin
            case (s)
                4'd0: expected_result_mux = SignExtDin;
                4'd1: expected_result_mux = R0;
                4'd2: expected_result_mux = R1;
                4'd3: expected_result_mux = R2;
                4'd4: expected_result_mux = R3;
                4'd5: expected_result_mux = R4;
                4'd6: expected_result_mux = R5;
                4'd7: expected_result_mux = R6;
                4'd8: expected_result_mux = R7;
                4'd9: expected_result_mux = G;
                default: expected_result_mux = 16'h0000;
            endcase
        end
    endfunction
    
    initial begin
        SignExtDin = 16'd0;
        R0 = 16'd1; R1 = 16'd2; R2 = 16'd3; R3 = 16'd4;
        R4 = 16'd5; R5 = 16'd6; R6 = 16'd7; R7 = 16'd8;
        G  = 16'd9;
    
        sel    = 4'd0;
        count3 = 0;
        errors3= 0;
        done3  = 0;
    end
    
    always @(posedge clk) begin
        if (!done3) begin
            if (count3 == 16) begin
                $display("Done with test for part 3 - multiplexer.");
                $display("%0d tests run.", count3);
                $display("There were %0d errors for part 3.", errors3);
                done3 = 1;
            end else begin
                if (Bus !== expected_result_mux(sel)) begin
                    $display("Error : sel=%0d, Got=%h, Expected=%h at at @%0t",
                             sel, Bus, expected_result_mux(sel), $time);
                    errors3 = errors3 + 1;
                end
                count3 = count3 + 1;
                sel    = sel + 1'b1;  
            end
        end
    end

    // Done by Wu Li Min (34478841)
    // Part 4 - ALU
    reg  [15:0] input_a, input_b;
    reg  [2:0]  alu_op;
    wire [15:0] result;
    
    ALU test4 ( .input_a(input_a), .input_b(input_b), .alu_op(alu_op), .result(result) );
    
    integer count4, errors4;         
    reg done4_a, done4_b; 
    reg [15:0] A_values [0:3];
    reg [15:0] B_values [0:3];
    integer i, j;
	 
    reg [2:0] op_drive;

    function [15:0] expected_result_alu;
        input [15:0] a, b;
        input [2:0]  op;
        begin
            case (op)
                3'b000: expected_result_alu = a * b;
                3'b001: expected_result_alu = a + b;
                3'b010: expected_result_alu = a - b;
                3'b011: begin
                    if ($signed(a) < 0)
                        expected_result_alu = $signed(b) >>> $unsigned(-$signed(a)); 
                    else if ($signed(a) > 0)
                        expected_result_alu = $signed(b) <<< $unsigned($signed(a));
                    else
                        expected_result_alu = b;
                end
                default: expected_result_alu = 16'h0000;
            endcase
        end
    endfunction
    
    initial begin
        count4  = 0;
        errors4 = 0;
        done4_a = 0; 
        done4_b = 0;
        i = 0;
        j = 0;
        input_a = 0;
        input_b = 0;
        op_drive = 3'b000;   
          
        A_values[0] = 16'h0001;
        A_values[1] = 16'h1234;
        A_values[2] = 16'h5678;
        A_values[3] = 16'hFFFF;
          
        B_values[0] = 16'hAAAA;
        B_values[1] = 16'hABCD;
        B_values[2] = 16'hEF00;
        B_values[3] = 16'h0002;

        alu_op  = 3'b000;
    end

    always @(posedge clk) begin
        if (!done4_a) begin
            alu_op   <= op_drive;
            op_drive <= op_drive + 1'b1;
        end
    end
    
    always @(posedge clk) begin
        if (!done4_a) begin
            if (count4 == 8*16) begin
                $display("Done with test for part 4 - ALU.");
                $display("%0d tests run.", count4);
                $display("There were %0d errors for part 4.", errors4);
                done4_a = 1;  
            end else begin
                for (i = 0; i < 4; i = i + 1) begin
                    for (j = 0; j < 4; j = j + 1) begin 
                        input_a = A_values[i];
                        input_b = B_values[j];
                        #1;
                        if (result !== expected_result_alu(input_a, input_b, alu_op)) begin
                            $display("Error : alu_op=%0b, input A = %h, input B = %h, Got=%h, Expected=%h at @%0t",
                                     alu_op, input_a, input_b, result, expected_result_alu(input_a, input_b, alu_op), $time);
                            errors4 = errors4 + 1;
                        end
                        count4 = count4 + 1;
                    end
                end
            end
        end
    end
     
    // Manual boundary case computed by hand
    initial begin
        @(posedge done4_a);
        @(posedge clk); 		  
        if (!done4_b) begin

            // Addition overflow
            alu_op  = 3'b001;
            input_a = 16'h7FFF; // +32767
            input_b = 16'h0001; // +1
            #1;                                        
            if (result !== 16'h8000) begin
                $display("Error (addition overflow) : input A = 16'h7FFF, input B = 16'h0001, alu_op=001, Got=%h, Expected=8000", result);
                errors4 = errors4 + 1;
            end
            count4 = count4 + 1;
             
            // Subtraction underflow
            alu_op  = 3'b010;
            input_a = 16'h8000; // -32768
            input_b = 16'h0001; // +1
            #1;                                        
            if (result !== 16'h7FFF) begin
                $display("Error (subtraction underflow) : input A = 16'h8000, input B = 16'h0001, alu_op=010, Got=%h, Expected=7FFF", result);
                errors4 = errors4 + 1;
            end
            count4 = count4 + 1;
             
            // Multiplication overflow (-256 * -256 -> 0000)
            alu_op  = 3'b000;
            input_a = 16'hFF00; // -256
            input_b = 16'hFF00; // -256
            #1;                                       
            if (result !== 16'h0000) begin
                $display("Error (multiplication overflow) : input A = 16'hFF00, input B = 16'hFF00, alu_op=000, Got=%h, Expected=0000" , result);
                errors4 = errors4 + 1;
            end
            count4 = count4 + 1;
             
            // Positive value SSI shift: shift +1 by 3 -> 0008
            alu_op  = 3'b011;
            input_a = 16'h0003; 
            input_b = 16'h0001; 
            #1;                                       
            if (result !== 16'h0008) begin
                $display("Error (positive SSI) : input A = 16'h0003, input B = 16'h0001, alu_op=011, Got=%h, Expected=0008", result);
                errors4 = errors4 + 1;
            end
            count4 = count4 + 1;
             
            // Negative value SSI shift: shift -256 by 1 -> -512 (FE00)
            alu_op  = 3'b011;
            input_a = 16'h0001; 
            input_b = 16'hFF00; 
            #1;                                      
            if (result !== 16'hFE00) begin
                $display("Error (negative SSI) : input A = 16'h0001, input B = 16'hFF00,  alu_op=011, Got=%h, Expected=FE00" , result);
                errors4 = errors4 + 1;
            end
            count4 = count4 + 1;
                
            $display("Done with manual computed test for part 4 - ALU.");
            $display("5 manual tests run.");
            $display("There were %0d errors for part 4 manual computed test.", errors4);
            done4_b = 1;
        end
    end
     
    // Done by Wu Li Min (34478841)
    // Part 5 - Register
    reg  [15:0] data_in;
    reg         r_in, rst5;
    wire [15:0] Q;
    
    register_n #(.N(16)) test5 ( .data_in(data_in), .r_in(r_in), .clk(clk), .Q(Q), .rst(rst5) );
    
    integer errors5, k, count5;
    reg done5;
    
    initial begin
        errors5 = 0;
        done5   = 0;
        count5  = 0;
    
        // Test reset function
        data_in = 16'h0000;
        r_in    = 1'b0;
        rst5    = 1'b1; 
        @(posedge clk);
        #1 
        if (Q !== 16'h0000) begin
            $display("Error: when rst=1, Got Q=%h, Expected=0000", Q);
            errors5 = errors5 + 1;
        end
    
        // Test release reset and allow enable function to load input
        rst5 = 1'b0;
        data_in = 16'h1111; 
        r_in = 1'b1; 
        @(posedge clk);
        #1 
        if (Q !== 16'h1111) begin
            $display("Error: when rst=0 and r_in=1, Got Q=%h, Expected=1111", Q);
            errors5 = errors5 + 1;
        end
    
        // Test when enable = 0, the output hold previous value (1111)
        data_in = 16'h2222; 
        r_in = 1'b0; 
        @(posedge clk);
        #1 
        if (Q !== 16'h1111) begin
            $display("Error: when rst=0 and r_in=0, Got Q=%h, Expected=1111", Q);
            errors5 = errors5 + 1;
        end
    
        // Test again with other input
        for (k = 0; k < 65536; k = k + 100) begin 
            data_in = k[15:0];
            r_in = 1'b1; 
            @(posedge clk);
            #1 
            count5 = count5 + 1;
            if (Q !== data_in) begin
                $display("Error: when rst=0 and r_in=1, Got Q=%h, Expected=%h", Q, data_in);
                errors5 = errors5 + 1;
            end
        end
          
        // Test reset again (register content back to 0)
        data_in = 16'h4444; 
        r_in = 1'b0;
        rst5 = 1'b1; 
        @(posedge clk);
        #1 
        if (Q !== 16'h0000) begin
            $display("Error: when rst=1 and r_in=0, Got Q=%h, Expected=0000", Q);
            errors5 = errors5 + 1;
        end

        count5 = count5 + 4;
        $display("Done with test for part 5 - register.");
        $display("%0d tests run.", count5);
        $display("There were %0d errors for part 5.", errors5);
        done5 = 1;
    end

    // Conclusion
    always @(done1 or done2 or done3 or done4_a or done4_b or done5) begin  
        if (done1 && done2 && done3 && done4_a && done4_b && done5) begin   
            $display("SUMMARY:");
            $display(" Part 1 - Sign Extender:   %0d errors", errors1);
            $display(" Part 2 - tick_FSM:        %0d errors", errors2);
            $display(" Part 3 - Multiplexer:     %0d errors", errors3);
            $display(" Part 4 - ALU:             %0d errors", errors4);
            $display(" Part 5 - Register:        %0d errors", errors5);
            $stop;
        end
    end

endmodule
