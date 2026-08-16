module RTSigGenBits #(
    // 50 MHz / (2 * 5) = 5 MHz output clock.
    parameter CLK_HALF_PERIOD_CNT = 5
) (
    input  wire        sysClk,
    input  wire        rst_n,
    input  wire [63:0] dataIn,
    input  wire        dataReady,

    output reg         dataOut,
    output reg         clkOut,
    output reg         busy
);

    reg [63:0] shift_reg;
    reg [5:0]  bit_index;
    reg [31:0] half_period_cnt;

    // DATA is stable before every rising CLK_OUT edge. The receiver should
    // sample DATA_OUT on CLK_OUT rising edges. Transmission is MSB-first.
    always @(posedge sysClk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= 64'd0;
            bit_index      <= 6'd0;
            half_period_cnt <= 32'd0;
            dataOut        <= 1'b0;
            clkOut         <= 1'b0;
            busy           <= 1'b0;
        end else if (!busy) begin
            clkOut          <= 1'b0;
            half_period_cnt <= 32'd0;

            if (dataReady) begin
                shift_reg <= dataIn;
                bit_index <= 6'd0;
                dataOut   <= dataIn[63];
                busy      <= 1'b1;
            end else begin
                dataOut <= 1'b0;
            end
        end else if (half_period_cnt == CLK_HALF_PERIOD_CNT - 1) begin
            half_period_cnt <= 32'd0;

            if (!clkOut) begin
                // Rising output-clock edge: the current DATA_OUT bit is valid.
                clkOut <= 1'b1;
            end else begin
                // Falling edge: advance DATA_OUT to the next bit.
                clkOut <= 1'b0;

                if (bit_index == 6'd63) begin
                    busy    <= 1'b0;
                    dataOut <= 1'b0;
                end else begin
                    shift_reg <= {shift_reg[62:0], 1'b0};
                    dataOut   <= shift_reg[62];
                    bit_index <= bit_index + 6'd1;
                end
            end
        end else begin
            half_period_cnt <= half_period_cnt + 32'd1;
        end
    end

endmodule
