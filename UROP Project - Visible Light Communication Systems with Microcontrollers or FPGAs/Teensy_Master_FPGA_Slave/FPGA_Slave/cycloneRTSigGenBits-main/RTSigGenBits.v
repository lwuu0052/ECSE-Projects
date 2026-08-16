module RTSigGenBits #(parameter BIT_PERIOD_CNT = 32'd50_000_000) (
    input sysClk,
    input rst_n,
    input [63:0] dataIn,
    input dataReady,
//    output debugOut1,
    output ledOut);


//=======================================================
//  REG/WIRE declarations
//=======================================================
parameter [1:0]
	stIDLE = 2'd0, // idle or waiting for dataReady
	stTIME = 2'd1, // timing for whole data bit stream
	stSTOP = 2'd2, // done sending whole data bit stream
	stDONE = 2'd3; // intermediate phase after done before going back to idle

reg [1:0] state, nextState;
reg rLedOut;
integer bitPeriodTimer;
reg [63:0] inputBuf;
// reg [63:0] dummySR = 64'hAAAAAAAAAAAAAAAA;
reg rDataReady; // used to flag data present to be transmitted, need dedicated logic to handle
reg bitPeriodTimerEnable /*= 1'b0*/;
reg rBitDone; // used to flag timing of 1 bit done within stDATA
integer numBitsSent = 0;
integer i;


//=======================================================
//  Structural coding
//=======================================================

// counter control for each bit period (because we are using 50MHz clock)
    always@(posedge sysClk or negedge rst_n) begin
        if(!rst_n) begin
            bitPeriodTimer <= 0;
        end
        else if (bitPeriodTimerEnable == 1'b0) begin
            bitPeriodTimer <= 0;
        end
        else if (bitPeriodTimer == BIT_PERIOD_CNT-1) begin
            bitPeriodTimer <= 0;
        end
        else begin
            bitPeriodTimer <= bitPeriodTimer + 1;
        end
    end

    // finite state machine (purely combinational circuit)
    always@(*) begin
        // set default values
        nextState = stIDLE;
        rBitDone = 1'b0;
        case (state)
            stIDLE: begin
                if (rDataReady == 1'b1) begin
                    nextState = stTIME;
                end
                else begin
                    nextState = stIDLE;
                end
            end
            stTIME: begin
                if (bitPeriodTimer == BIT_PERIOD_CNT-1) begin // when each bit has reached its desired bit period
                    rBitDone = 1'b1;
                    if (numBitsSent == 64/*-1*/) begin // when number of bits sent is equal to capacity of input buffer PISO shift register
                        nextState = stSTOP; // completed sending data bit stream
                    end
                    else begin
                        nextState = stTIME; // only the bit reaching desired bit period but not entire bit stream completed transmission, continue sending next bit
                        // numBitsSent = numBitsSent + 1;
                    end
                end
                else begin
                    nextState = stTIME;
                end
            end
            stSTOP: begin
                nextState = stDONE;
                // numBitsSent = 0;
            end
            stDONE: begin
                nextState = stIDLE;
            end
            default: begin
                nextState = stIDLE;
                // numBitsSent = 0;
            end
        endcase
    end

    // state ff
    always@(posedge sysClk or negedge rst_n) begin
        if (!rst_n) begin 
            state <= stIDLE;
        end
        else begin
            state <= nextState;
            if (state == stIDLE && nextState == stTIME) begin
                // rDataReady <= 1'b0; // clear flag once the flag is read triggering the stTIME, not any other times (keep flag pending for new data input)
                bitPeriodTimerEnable <= 1'b1; // enable timing counter for bit period now or next clock edge the state is already changed to timing
            end
            // if (state == stIDLE) begin
            //     if (rDataReady == 1'b1) begin
            //         bitPeriodTimerEnable <= 1'b1;
            //     end
            //     else begin
            //         bitPeriodTimerEnable <= 1'b0;
            //     end
            // end
            else if (state == stTIME) begin
                if (rBitDone == 1'b1) begin
                    if (nextState == stSTOP) begin
                    // if (numBitsSent == 64/*-1*/) begin
                        bitPeriodTimerEnable <= 1'b0;
                    end
                    else begin
                        numBitsSent <= numBitsSent + 1;
                    end
                end
            end
            else if (state == stSTOP) begin
                numBitsSent <= 0;
                bitPeriodTimerEnable <= 1'b0;
            end
        end
    end

    // data output ff
    always@(posedge sysClk or negedge rst_n) begin
        if(!rst_n) begin
            rLedOut <= 1'b0;
            // rLedOut <= inputBuf[63];
        end
        else if (rBitDone == 1'b1) begin
            rLedOut <= inputBuf[63];
        end
    end

    // input data buffer
    always@(posedge sysClk or negedge rst_n) begin
        if(!rst_n) begin
            /* // TESTING MODEL, RESET LOADS DATA INTO BUFFER
            for (i = 0; i < 64; i=i+1) begin
                inputBuf[i] <= dataIn[i]; // load data in parallel
            end
            rDataReady <= 1'b1; // TEMPORARY ONLY, used to flag data present to be transmitted, need dedicated logic to handle*/
            // NEWER MODEL, RESET REALLY CLEARS ENTIRE BUFFER, BUFFER GETS LOADED WITH DATA ONLY WHEN dataReady input is high, sync with clock
            rDataReady <= 1'b0;
            for (i = 0; i < 64; i=i+1) begin
                inputBuf[i] <= 1'b0; // clear entire register
            end
        end
        else begin
            if (rBitDone == 1'b1) begin
                for (i = 0; i < 63; i=i+1) begin
                    inputBuf[i+1] <= inputBuf[i]; // shift bits in serial fashion
                end
                inputBuf[0] <= 'b0; // pad '0'
            end
            // NEWER MODEL, RESET REALLY CLEARS ENTIRE BUFFER, BUFFER GETS LOADED WITH DATA ONLY WHEN dataReady input is high, sync with clock
            else if (state == stDONE || (state == stIDLE && nextState !== stTIME)) begin // only shift input data into buffer once the current buffer has done sending all bits
                if (dataReady == 1'b1 && rDataReady == 1'b0) begin
                    for (i = 0; i < 64; i=i+1) begin
                        inputBuf[i] <= dataIn[i]; // load data in parallel
                    end
                    rDataReady <= 1'b1;
                end
            end
            else if (state == stIDLE && nextState == stTIME) begin
                rDataReady <= 1'b0; // clear flag once the flag is read triggering the stTIME, not any other times (keep flag pending for new data input)
                // bitPeriodTimerEnable <= 1'b1; // enable timing counter for bit period now or next clock edge the state is already changed to timing
            end
        end

    end
    
    assign /*#(2,3,5)*/ ledOut = rLedOut; // onboard LED pins are active high signal
    
//    assign debugOut1 = rDataReady;

endmodule
