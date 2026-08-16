`timescale 1ns/1ns

/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the processor.

Please enter your student ID: Wu Li Min (34478841), Yeoh Jie Ying (34601643)

*/
module proc_tb;

    // TODO: Implement the logic of your testbench here
     
    reg        clk;
    reg        rst;
    reg        enable;
    reg  [8:0] din;
    wire [6:0] HEX5;
    wire [15:0] bus;
    wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;

    simple_proc test1 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .din(din),
        .HEX5(HEX5),
        .bus(bus),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3),
        .R4(R4), .R5(R5), .R6(R6), .R7(R7)
    );
    

    initial clk = 0;
    always #5 clk = ~clk;
     
    // Sign extender function to extend the 9 bit DIN to 16 bit
    function [15:0] sign_extender;
        input [8:0] din_input;
        begin
            sign_extender = {{7{din_input[8]}}, din_input};
        end
    endfunction
    
    // Function to combine op, rx and ry into 9 bit DIN input
    function [8:0] combine_din;
        input [2:0] op, rx, ry;
        begin
            combine_din = {op, rx, ry};
        end
    endfunction

     // 7 segment BCD function for HEX display (active-low)
    function [6:0] bcd_7;
        input [3:0] d;
        begin
            case (d)
                4'd0: bcd_7 = 7'b1000000;
                4'd1: bcd_7 = 7'b1111001;
                4'd2: bcd_7 = 7'b0100100;
                4'd3: bcd_7 = 7'b0110000;
                4'd4: bcd_7 = 7'b0011001;
                4'd5: bcd_7 = 7'b0010010;
                4'd6: bcd_7 = 7'b0000010;
                4'd7: bcd_7 = 7'b1111000;
                4'd8: bcd_7 = 7'b0000000;
                4'd9: bcd_7 = 7'b0010000;
                default: bcd_7 = 7'b1111111;
            endcase
        end
    endfunction
    
     // Decode 7-segment (no dp) back to a BCD digit 
    function [3:0] bcd7_to_digit;
        input [6:0] seg; 
        begin
            case (seg)
                7'b1000000: bcd7_to_digit = 4'd0;
                7'b1111001: bcd7_to_digit = 4'd1;
                7'b0100100: bcd7_to_digit = 4'd2;
                7'b0110000: bcd7_to_digit = 4'd3;
                7'b0011001: bcd7_to_digit = 4'd4;
                7'b0010010: bcd7_to_digit = 4'd5;
                7'b0000010: bcd7_to_digit = 4'd6;
                7'b1111000: bcd7_to_digit = 4'd7;
                7'b0000000: bcd7_to_digit = 4'd8;
                7'b0010000: bcd7_to_digit = 4'd9;
                default   : bcd7_to_digit = 4'hF;
            endcase
        end
    endfunction
    
     // Make sure checks start at tick "1"
    task start_with_tick1;
        integer count;
        reg [3:0] current_value;
        begin
            count = 0;
            #1;
            current_value = bcd7_to_digit(HEX5[6:0]);
            while (current_value !== 4'd1 && count < 16) begin
                @(posedge clk); #1;
                current_value = bcd7_to_digit(HEX5[6:0]);
                count = count + 1;
            end
        end
    endtask
    
     // Run 4 ticks, checking HEX5 shows 1,2,3,4
    task run_ticks_and_check_hex5;
        inout integer errors_ref;
        inout integer count_ref;
        integer i;
        reg [3:0] expected_digit;
        reg [6:0] expected;
        begin
            start_with_tick1();
            expected_digit = 4'd1;
            expected       = bcd_7(expected_digit);
            #1;
            if (HEX5[6:0] !== expected) begin
                $display("Error (HEX5 tick): sub-tick 0 Got=%b Expected=%b (digit %0d)",
                         HEX5[6:0], expected, expected_digit);
                errors_ref = errors_ref + 1;
            end
            count_ref = count_ref + 1;

            for (i = 1; i < 4; i = i + 1) begin
                @(posedge clk); #1;
                case (expected_digit)
                    4'd1: expected_digit = 4'd2;
                    4'd2: expected_digit = 4'd3;
                    4'd3: expected_digit = 4'd4;
                    default: expected_digit = 4'd1;
                endcase
                expected = bcd_7(expected_digit);
                if (HEX5[6:0] !== expected) begin
                    $display("Error (HEX5 tick): sub-tick %0d Got=%b Expected=%b (digit %0d)",
                             i, HEX5[6:0], expected, expected_digit);
                    errors_ref = errors_ref + 1;
                end
                count_ref = count_ref + 1;
            end
            @(posedge clk); #1;
        end
    endtask
	 
	// Run 4 ticks for immediate function
	task run_imm_ticks;
		 input [2:0] op;          
		 input [2:0] rx;          
		 input [8:0] imm9;        
		 begin
			  start_with_tick1();
			  din = combine_din(op, rx, 3'b000);
			  @(posedge clk); #1; 

			  // Before Tick 2: Load the immediate 
			  din = imm9;
			  @(posedge clk); #1; 
			  @(posedge clk); #1;  
			  @(posedge clk); #1;  
		 end
	endtask

     
    reg [15:0] tR0, tR1, tR2, tR3, tR4, tR5, tR6, tR7;

    // Function to relate index to their corresponding testbench internal register
    function [15:0] get_register;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: get_register = tR0;
                3'd1: get_register = tR1;
                3'd2: get_register = tR2;
                3'd3: get_register = tR3;
                3'd4: get_register = tR4;
                3'd5: get_register = tR5;
                3'd6: get_register = tR6;
                3'd7: get_register = tR7;
            endcase
        end
    endfunction

     // Task to set the testbench internal register to their corresponding output value after operation
    task set_register;
        input [2:0] idx;
        input [15:0] val;
        begin
            case (idx)
                3'd0: tR0 = val;
                3'd1: tR1 = val;
                3'd2: tR2 = val;
                3'd3: tR3 = val;
                3'd4: tR4 = val;
                3'd5: tR5 = val;
                3'd6: tR6 = val;
                3'd7: tR7 = val;
            endcase
        end
    endtask
     
     // Obtain the value of the real output register
    function [15:0] get_real_register;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: get_real_register = R0;
                3'd1: get_real_register = R1;
                3'd2: get_real_register = R2;
                3'd3: get_real_register = R3;
                3'd4: get_real_register = R4;
                3'd5: get_real_register = R5;
                3'd6: get_real_register = R6;
                3'd7: get_real_register = R7;
            endcase
        end
    endfunction

    integer errors, count;
    integer i, j, k, change;

    reg [15:0] last_rx, last_ry;
	 reg  [2:0] imm3;
	 reg  [8:0] imm9;
	 reg [15:0] expected;

    initial begin
        errors = 0;
        count = 0;

        // Test reset function (all register should reset back to 0)
        enable = 1'b0;
        rst    = 1'b1;
        din    = 9'd0;
          
        tR0=0; tR1=0; tR2=0; tR3=0; tR4=0; tR5=0; tR6=0; tR7=0;

        repeat (5) @(posedge clk); #1;

        if (R0 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R0=%h, Expected=0000", R0); errors = errors + 1; count = count + 1; end
        if (R1 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R1=%h, Expected=0000", R1); errors = errors + 1; count = count + 1; end
        if (R2 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R2=%h, Expected=0000", R2); errors = errors + 1; count = count + 1; end
        if (R3 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R3=%h, Expected=0000", R3); errors = errors + 1; count = count + 1; end
        if (R4 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R4=%h, Expected=0000", R4); errors = errors + 1; count = count + 1; end
        if (R5 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R5=%h, Expected=0000", R5); errors = errors + 1; count = count + 1; end
        if (R6 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R6=%h, Expected=0000", R6); errors = errors + 1; count = count + 1; end
        if (R7 !== 16'h0000) begin $display("Error: when rst=1, all register content should reset to 0. Got R7=%h, Expected=0000", R7); errors = errors + 1; count = count + 1; end
        $display("Done with test for reset. 8 tests run.");
          
        // Release reset and enable FSM
        rst    = 1'b0;
        enable = 1'b1;
        repeat (5) @(posedge clk); #1;

		  // Loop for different ry values
        for (change = 0; change < 3; change = change + 1) begin 
          
            // Test MOVI function
            for (i = 0; i < 8; i = i + 1) begin
                last_rx = get_register(i[2:0]);
                din = combine_din(3'b111, i[2:0], ((change + 1) & 3'b111)); // opcode=111 (MOVI)
                set_register(i[2:0], sign_extender(din));
                run_ticks_and_check_hex5(errors, count);
                    
                // Rx <- imm
                if (get_real_register(i[2:0]) !== get_register(i[2:0])) begin
                    $display("Error: when MOVI: Rx=%0d old=%h, imm(signext(din=%b))=%h. Got=%h Expected=%h",
                             i, last_rx, din, sign_extender(din), get_real_register(i[2:0]), get_register(i[2:0]));
                    errors = errors + 1;
                end
                count = count + 1;
            end
            $display("Done with test for movi function loop %0d. 8 tests run.", change);
              
            // Test ADD function
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    last_rx = get_register(i[2:0]);
                    last_ry = get_register(j[2:0]);
                    din = combine_din(3'b001, i[2:0], j[2:0]); // opcode=001 (ADD)
                    set_register(i[2:0], last_rx + last_ry);
                    run_ticks_and_check_hex5(errors, count);

                    // rx <- rx + ry
                    if (get_real_register(i[2:0]) !== get_register(i[2:0])) begin
                        $display("Error: when ADD: Rx=%0d old=%h + Ry=%0d old=%h. Got Rx=%h Expected=%h",
                                 i, last_rx, j, last_ry, get_real_register(i[2:0]), get_register(i[2:0]));
                        errors = errors + 1;
                    end
                    count = count + 1;
                end
            end
            $display("Done with test for add function loop %0d. 64 tests run.", change);
              
            // Test SUB function
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    // snapshot olds
                    last_rx = get_register(i[2:0]);
                    last_ry = get_register(j[2:0]);
                    din = combine_din(3'b011, i[2:0], j[2:0]); // opcode=011 (SUB)
                    set_register(i[2:0], last_rx - last_ry);
                    run_ticks_and_check_hex5(errors, count);

                    // rx <- rx - ry
                    if (get_real_register(i[2:0]) !== get_register(i[2:0])) begin
                        $display("Error: when SUB: Rx=%0d old=%h - Ry=%0d old=%h. Got Rx=%h Expected=%h",
                                 i, last_rx, j, last_ry, get_real_register(i[2:0]), get_register(i[2:0]));
                        errors = errors + 1;
                    end
                    count = count + 1;
                end
            end
            $display("Done with test for sub function loop %0d. 64 test run.", change);
              
            // Test ADDI function
				for (i = 0; i < 8; i = i + 1) begin
					 last_rx = get_register(i[2:0]);
					 imm3 = change[1:0] + 3'd1;
					 imm9 = {6'd0, imm3};        
					 expected = last_rx + sign_extender(imm9);
					 run_imm_ticks(3'b010, i[2:0], imm9); 
					 set_register(i[2:0], expected);
					 
					 // Rx <- rx + imm
					 if (get_real_register(i[2:0]) !== get_register(i[2:0])) begin
						  $display("Error: when ADDI: loop=%0d Rx=%0d old=%h + imm(signext=%h). Got=%h Expected=%h",
									  change, i, last_rx, sign_extender(imm9),
									  get_real_register(i[2:0]), get_register(i[2:0]));
						  errors = errors + 1;
					 end
					 count = count + 1;
				end
				$display("Done with test for addi function loop %0d. 8 tests run.", change);
              
        end
          
        $display("Done with test checking HEX5 display.");
              
        // Manual check for operations computed by hand (Edge cases) 
        // Fresh reset for independence
        rst    = 1'b1;  enable = 1'b0;  din = 9'd0;
        repeat (2) @(posedge clk); #1;
        rst    = 1'b0;  enable = 1'b1;
        repeat (2) @(posedge clk); #1;

        // Assign MOVI R7 = -1
        din = combine_din(3'b111, 3'b111, 3'b111);
        run_ticks_and_check_hex5(errors, count);
        if (R7 !== 16'hFFFF) begin
            $display("Error: when MOVI, Got R7=%h, Expected=FFFF (-1)", R7);
            errors = errors + 1;
        end
        count = count + 1;

        // Assign MOVI R0 = -64
        din = combine_din(3'b111, 3'b000, 3'b000); 
        run_ticks_and_check_hex5(errors, count);
        if (R0 !== 16'hFFC0) begin
            $display("Error: when MOVI, Got R0=%h, Expected=FFC0 (-64)", R0);
            errors = errors + 1;
        end
        count = count + 1;
        
        // Loop 9 times for add -64 to get -32768 
        for (k = 0; k < 9; k = k + 1) begin
            din = combine_din(3'b001, 3'b000, 3'b000); 
            run_ticks_and_check_hex5(errors, count);
        end
        if (R0 !== 16'h8000) begin
            $display("Error: when MOVI, Got R0=%h, Expected=8000 (-32768)", R0);
            errors = errors + 1;
        end
        count = count + 1;
        
        // Assign R1 = +1 (Sub R1 - R7)
        din = combine_din(3'b011, 3'b001, 3'b001); 
        run_ticks_and_check_hex5(errors, count);
        din = combine_din(3'b011, 3'b001, 3'b111); 
        run_ticks_and_check_hex5(errors, count);
        if (R1 !== 16'h0001) begin
            $display("Error: when MOVI, Got R1=%h, Expected=0001 (+1)", R1);
            errors = errors + 1;
        end
        count = count + 1;
        
        // 1) Subtraction underflow R0 <- R0 - R1   (-32768 - 1 -> 7FFF)
        din = combine_din(3'b011, 3'b000, 3'b001);  // SUB R0,R1
        run_ticks_and_check_hex5(errors, count);
        if (R0 !== 16'h7FFF) begin
            $display("Edge Case 1 (Subtraction underflow: -32768 - 1). Got=%h Expected=7FFF (+32767)", R0);
            errors = errors + 1;
        end
        count = count + 1;
        
        // 2) Addition overflow R0 <- R0 + R1   ( 32767 + 1 -> 8000)
        din = combine_din(3'b001, 3'b000, 3'b001);  // ADD R0,R1
        run_ticks_and_check_hex5(errors, count);
        if (R0 !== 16'h8000) begin
            $display("Edge Case 2 (Addition overflow): 32767 + 1. Got=%h Expected=8000 (-32768)", R0);
            errors = errors + 1;
        end
        count = count + 1;

        $display("Done with edge case test computed manually. 6 tests run.");
        $display("Done with test for task 2.");
        $display("%0d tests run.", count);
        $display("Total errors: %0d", errors);
        $stop;
    end

endmodule
