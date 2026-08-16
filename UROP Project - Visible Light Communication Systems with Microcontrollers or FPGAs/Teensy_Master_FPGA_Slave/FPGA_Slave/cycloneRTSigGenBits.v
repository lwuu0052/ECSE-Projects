// DE2-115 top level:
// Teensy SPI -> 8-character display -> 64-bit DATA_OUT + 5 MHz CLK_OUT
module cycloneRTSigGenBits (
    input  wire        CLOCK_50,
    input  wire        CLOCK2_50,
    input  wire        CLOCK3_50,

    output wire [8:0]  LEDG,
    output wire [17:0] LEDR,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    inout  wire [6:0]  EX_IO,

    input  wire        spi_sck,
    input  wire        spi_mosi,
    input  wire        spi_cs,

    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX7
);

    wire        sysClk = CLOCK_50;
    wire        rst_n  = KEY[0];
    wire [63:0] received_data;
    wire        data_ready;
    wire        serial_data;
    wire        serial_clk;
    wire        serial_busy;

    reg [2:0] debug_sck_sync;
    reg [2:0] debug_cs_sync;
    reg [2:0] debug_mosi_sync;
    reg       debug_cs_seen;
    reg       debug_sck_seen;
    reg       debug_mosi_seen;
    reg       debug_frame_seen;

    wire debug_sck_rising = (debug_sck_sync[2:1] == 2'b01);

    // Persistent SPI diagnostics. Each flag remains lit until KEY0 reset,
    // making microsecond SPI activity visible to the human eye.
    always @(posedge sysClk or negedge rst_n) begin
        if (!rst_n) begin
            debug_sck_sync   <= 3'b000;
            debug_cs_sync    <= 3'b111;
            debug_mosi_sync  <= 3'b000;
            debug_cs_seen    <= 1'b0;
            debug_sck_seen   <= 1'b0;
            debug_mosi_seen  <= 1'b0;
            debug_frame_seen <= 1'b0;
        end else begin
            debug_sck_sync  <= {debug_sck_sync[1:0], spi_sck};
            debug_cs_sync   <= {debug_cs_sync[1:0], spi_cs};
            debug_mosi_sync <= {debug_mosi_sync[1:0], spi_mosi};

            if (!debug_cs_sync[2])
                debug_cs_seen <= 1'b1;
            if (debug_sck_rising)
                debug_sck_seen <= 1'b1;
            if (!debug_cs_sync[2] && debug_mosi_sync[2])
                debug_mosi_seen <= 1'b1;
            if (data_ready)
                debug_frame_seen <= 1'b1;
        end
    end

    FPGA_slave_top_level spi_display (
        .clk           (sysClk),
        .rst           (rst_n),
        .spi_sck       (spi_sck),
        .spi_mosi      (spi_mosi),
        .spi_cs        (spi_cs),
        .HEX0          (HEX0),
        .HEX1          (HEX1),
        .HEX2          (HEX2),
        .HEX3          (HEX3),
        .HEX4          (HEX4),
        .HEX5          (HEX5),
        .HEX6          (HEX6),
        .HEX7          (HEX7),
        .received_data (received_data),
        .data_ready    (data_ready)
    );

    RTSigGenBits #(
        .CLK_HALF_PERIOD_CNT(5)
    ) serial_transmitter (
        .sysClk    (sysClk),
        .rst_n     (rst_n),
        .dataIn    (received_data),
        .dataReady (data_ready),
        .dataOut   (serial_data),
        .clkOut    (serial_clk),
        .busy      (serial_busy)
    );

    // 14-pin EX_IO header signal outputs.
    assign EX_IO[5] = serial_data; // DATA_OUT, FPGA PIN_E10
    assign EX_IO[4] = serial_clk;  // CLK_OUT,  FPGA PIN_F14
    assign EX_IO[6] = serial_busy; // Optional oscilloscope trigger/debug
    assign EX_IO[3:0] = 4'bzzzz;

    // On-board debug indicators.
    assign LEDG[8]   = serial_busy;
    assign LEDG[7:5] = 3'd0;
    assign LEDG[4]   = debug_frame_seen;
    assign LEDG[3]   = debug_mosi_seen;
    assign LEDG[2]   = debug_sck_seen;
    assign LEDG[1]   = debug_cs_seen;
    assign LEDG[0]   = ~rst_n;
    assign LEDR[11]  = serial_clk;
    assign LEDR[17:12] = 6'd0;
    assign LEDR[10:0]  = 11'd0;

    // CLOCK2_50, CLOCK3_50, and SW are intentionally unused.

endmodule
