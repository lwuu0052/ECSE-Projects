module FPGA_slave (
    input  wire        clk,       // 50 MHz FPGA system clock
    input  wire        rst,       // Active-low reset
    input  wire        sck,       // Teensy SPI clock, mode 0
    input  wire        mosi,
    input  wire        cs,        // Active-low chip select

    output reg  [7:0]  board_0,
    output reg  [7:0]  board_1,
    output reg  [7:0]  board_2,
    output reg  [7:0]  board_3,
    output reg  [7:0]  board_4,
    output reg  [7:0]  board_5,
    output reg  [7:0]  board_6,
    output reg  [7:0]  board_7,

    output reg  [63:0] received_data,
    output reg         data_ready
);

    reg [63:0] spi_shift_reg;
    reg [5:0]  spi_bit_count;
    reg        frame_toggle;

    wire [63:0] completed_frame = {spi_shift_reg[62:0], mosi};

    // SPI mode 0 receiver. MOSI is sampled directly on every SCK rising edge.
    // CS returning HIGH asynchronously discards any incomplete frame but never
    // changes the currently displayed characters.
    always @(posedge sck or posedge cs or negedge rst) begin
        if (!rst) begin
            spi_shift_reg <= 64'd0;
            spi_bit_count <= 6'd0;
            frame_toggle  <= 1'b0;
            received_data <= 64'd0;

            // Show 00000000 until the first complete 64-bit frame arrives.
            board_0 <= 8'h30;
            board_1 <= 8'h30;
            board_2 <= 8'h30;
            board_3 <= 8'h30;
            board_4 <= 8'h30;
            board_5 <= 8'h30;
            board_6 <= 8'h30;
            board_7 <= 8'h30;
        end else if (cs) begin
            // End of transaction. Incomplete data is ignored.
            spi_shift_reg <= 64'd0;
            spi_bit_count <= 6'd0;
        end else begin
            spi_shift_reg <= completed_frame;

            if (spi_bit_count == 6'd63) begin
                // Atomically publish the complete frame. Byte 0 is displayed
                // on HEX7 and is also transmitted first on DATA_OUT.
                received_data <= completed_frame;
                board_7 <= completed_frame[63:56];
                board_6 <= completed_frame[55:48];
                board_5 <= completed_frame[47:40];
                board_4 <= completed_frame[39:32];
                board_3 <= completed_frame[31:24];
                board_2 <= completed_frame[23:16];
                board_1 <= completed_frame[15:8];
                board_0 <= completed_frame[7:0];

                frame_toggle  <= ~frame_toggle;
                spi_bit_count <= 6'd0;
            end else begin
                spi_bit_count <= spi_bit_count + 6'd1;
            end
        end
    end

    // Synchronize the completed-frame event into the 50 MHz system domain.
    // received_data remains stable while this toggle crosses clock domains.
    reg [2:0] frame_toggle_sync;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            frame_toggle_sync <= 3'b000;
            data_ready        <= 1'b0;
        end else begin
            frame_toggle_sync <= {frame_toggle_sync[1:0], frame_toggle};
            data_ready <= frame_toggle_sync[2] ^ frame_toggle_sync[1];
        end
    end

endmodule
