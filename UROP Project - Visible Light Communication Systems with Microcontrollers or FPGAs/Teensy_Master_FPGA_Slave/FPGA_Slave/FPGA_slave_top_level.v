module FPGA_slave_top_level (
    input  wire        clk,
    input  wire        rst,
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
    output wire [6:0]  HEX7,

    output wire [63:0] received_data,
    output wire        data_ready
);

    wire [7:0] digit_0;
    wire [7:0] digit_1;
    wire [7:0] digit_2;
    wire [7:0] digit_3;
    wire [7:0] digit_4;
    wire [7:0] digit_5;
    wire [7:0] digit_6;
    wire [7:0] digit_7;

    FPGA_slave ins_slave (
        .clk           (clk),
        .rst           (rst),
        .sck           (spi_sck),
        .mosi          (spi_mosi),
        .cs            (spi_cs),
        .board_0       (digit_0),
        .board_1       (digit_1),
        .board_2       (digit_2),
        .board_3       (digit_3),
        .board_4       (digit_4),
        .board_5       (digit_5),
        .board_6       (digit_6),
        .board_7       (digit_7),
        .received_data (received_data),
        .data_ready    (data_ready)
    );

    BCD bcd0 (.bcd(digit_0), .seg(HEX0));
    BCD bcd1 (.bcd(digit_1), .seg(HEX1));
    BCD bcd2 (.bcd(digit_2), .seg(HEX2));
    BCD bcd3 (.bcd(digit_3), .seg(HEX3));
    BCD bcd4 (.bcd(digit_4), .seg(HEX4));
    BCD bcd5 (.bcd(digit_5), .seg(HEX5));
    BCD bcd6 (.bcd(digit_6), .seg(HEX6));
    BCD bcd7 (.bcd(digit_7), .seg(HEX7));

endmodule
