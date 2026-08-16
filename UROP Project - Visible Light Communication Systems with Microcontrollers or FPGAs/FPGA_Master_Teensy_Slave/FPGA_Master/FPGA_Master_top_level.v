// =========================================================================
// Press KEY[1] once to send one SPI packet.
//
// Packet layout (word0 first out):
//   word0 = 0xDEAD          fixed header
//   word1 = SLAVE_ID        MUST match MY_SLAVE_ID in the Teensy sketch
//   word2 = 0x0002          length field = payload words(1) + 1
//   word3 = 0x0FAF          "fire & forget" command
//   word4 = packet_id       increments every send
//   word5 = switch data     SW[17:2] as 16-bit payload
//   word6 = word4 ^ word5   checksum
// =========================================================================
module FPGA_Master_top_level (
    input  wire        CLOCK_50,  
    input  wire [17:0] SW,        
    input  wire [3:0]  KEY,       
    output wire        SPI_SCK,   
    output wire        SPI_MOSI,  
    output wire        SPI_CS     
);

    localparam [15:0] SLAVE_ID = 16'h1111;

   
    wire rst_n = KEY[0];

    // =====================================================
    // 1. Build the packet
    // =====================================================
    reg  [15:0] packet_id;
    wire [15:0] word0 = 16'hDEAD;
    wire [15:0] word1 = SLAVE_ID;
    wire [15:0] word2 = 16'h0002;
    wire [15:0] word3 = 16'h0FAF;
    wire [15:0] word4 = packet_id;
    // SW17 is the first/leftmost bit, SW2 is the 16th/rightmost bit.
    wire [15:0] switch_data = {
        SW[17], SW[16], SW[15], SW[14],
        SW[13], SW[12], SW[11], SW[10],
        SW[9],  SW[8],  SW[7],  SW[6],
        SW[5],  SW[4],  SW[3],  SW[2]
    };
    wire [15:0] word5 = switch_data;
    wire [15:0] word6 = word4 ^ word5;

    // FPGA_MST_SPI_Master sends packet[15:0] first, then packet[31:16], etc.
    wire [111:0] packet = {word6, word5, word4, word3, word2, word1, word0};

    // =====================================================
    // 2. Send once when KEY[1] is pressed
    // =====================================================
    reg  start_sig;
    reg  busy;
    reg  key1_meta;
    reg  key1_sync;
    reg  key1_armed;
    wire trans_done;

    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            start_sig <= 1'b0;
            busy      <= 1'b0;
            key1_meta <= 1'b1;
            key1_sync <= 1'b1;
            key1_armed <= 1'b1;
            packet_id <= 16'd0;
        end else begin
            // Synchronize the mechanical button into CLOCK_50 domain.
            key1_meta <= KEY[1];
            key1_sync <= key1_meta;

            // Default low: start_sig becomes a one-clock pulse.
            start_sig <= 1'b0;

            // Re-arm only after KEY[1] is released.
            if (key1_sync == 1'b1) begin
                key1_armed <= 1'b1;
            end

            // KEY[1] pressed: send one packet.
            if (!busy && key1_armed && key1_sync == 1'b0) begin
                start_sig <= 1'b1;
                busy      <= 1'b1;
                key1_armed <= 1'b0;
            end else if (trans_done) begin
                busy      <= 1'b0;
                packet_id <= packet_id + 1'b1;
            end
        end
    end

    // =====================================================
    // 3. SPI master instance
    // =====================================================
    FPGA_MST_SPI_Master #(
        .NUM_WORDS(7)
    ) spi_master_inst (
        .clk    (CLOCK_50),
        .rst_n  (rst_n),
        .packet (packet),
        .start  (start_sig),
        .sck    (SPI_SCK),
        .mosi   (SPI_MOSI),
        .cs     (SPI_CS),
        .done   (trans_done)
    );

endmodule
