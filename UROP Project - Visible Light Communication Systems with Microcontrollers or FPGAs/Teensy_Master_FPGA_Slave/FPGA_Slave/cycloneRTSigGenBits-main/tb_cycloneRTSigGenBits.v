`timescale 1ns / 1ps

module tb_cycloneRTSigGenBits();

    reg tb_sysClk, tb_rst_n;
    wire tb_ledOut1, tb_ledOut2, tb_dataReadyLed/*, tb_ledOut3, tb_pmodOut1, tb_pmodOut2, tb_pmodOut3*/;
    wire [8:0] tb_LEDG;
    wire [17:0] tb_LEDR;

    assign tb_LEDG = {8'b0, tb_ledOut1};
    assign tb_LEDR = {6'b0, tb_ledOut2, 11'b0};
    
    cycloneRTSigGenBits DUT (
        .CLOCK_50 (tb_sysClk),
        .CLOCK2_50(),
        .CLOCK3_50(),
        .KEY({3'b0,tb_rst_n}),
        .LEDG(tb_LEDG),
        .LEDR(tb_LEDR),
        .EX_IO(),
        .SW()/*,
        .debugOut1(tb_debugOut1)/*, 
        .ledOut3(tb_ledOut3), 
        .pmodOut1(tb_pmodOut1), 
        .pmodOut2(tb_pmodOut2), 
        .pmodOut3(tb_pmodOut3)*/);
    
    initial
    begin
            tb_sysClk = 1'b0;
    end
        
    always
    begin
            #10 tb_sysClk = ~tb_sysClk;
    end
    
    initial
    begin
            tb_rst_n = 1'bx;
        #5  tb_rst_n = 1'b1;
        #10  tb_rst_n = 1'b0;
        #20 tb_rst_n = 1'b1;
    end

endmodule