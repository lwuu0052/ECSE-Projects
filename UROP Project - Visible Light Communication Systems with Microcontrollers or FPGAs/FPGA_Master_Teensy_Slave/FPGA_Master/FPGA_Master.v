// =========================================================================
// FPGA_MST_SPI_Master
//
// Sends a fixed-size packet (NUM_WORDS x 16-bit words) to a Teensy running
// SPI_MSTransfer_T4 (slave). ALL words are shifted out while CS stays LOW
// the entire time -- this is the part the previous version got wrong
// (it deasserted CS after every single word).
//
// SPI Mode 0 (CPOL=0, CPHA=0): clock idle low, MOSI set up before the
// first rising edge, data changes on the falling edge.
// =========================================================================
module FPGA_MST_SPI_Master #(
    parameter NUM_WORDS = 7
)(
    input  wire                       clk,       // 50 MHz
    input  wire                       rst_n,     // active low
    input  wire [NUM_WORDS*16-1:0]    packet,    // word0 = packet[15:0], word1 = packet[31:16], ...
    input  wire                       start,     // pulse to begin sending
    output reg                        sck,
    output reg                        mosi,
    output reg                        cs,
    output reg                        done       // pulses high for 1 clk when finished
);

    // =====================================================
    // SCK generator: 50MHz / (2*250) = 100kHz
    // =====================================================
    reg [8:0] clk_div;
    reg       sck_en;
    reg       sck_prev;
    wire      sck_falling = (~sck && sck_prev);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div  <= 0;
            sck      <= 0;
            sck_prev <= 0;
        end else begin
            sck_prev <= sck;
            if (sck_en) begin
                if (clk_div == 249) begin
                    clk_div <= 0;
                    sck     <= ~sck;
                end else begin
                    clk_div <= clk_div + 1;
                end
            end else begin
                clk_div <= 0;
                sck     <= 0;
            end
        end
    end

    // =====================================================
    // State machine
    // =====================================================
    localparam ST_IDLE    = 3'd0,
               ST_CS_LOW  = 3'd1,
               ST_LOAD    = 3'd2,
               ST_SEND    = 3'd3,
               ST_CS_HIGH = 3'd4,
               ST_DONE    = 3'd5;

    reg [2:0]  state;
    reg [4:0]  bit_cnt;
    reg [15:0] shift_reg;
    reg [3:0]  delay_cnt;
    reg [3:0]  word_idx;                 // which word (0..NUM_WORDS-1) we're on
    reg [NUM_WORDS*16-1:0] packet_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= ST_IDLE;
            cs             <= 1'b1;
            mosi           <= 1'b0;
            sck_en         <= 1'b0;
            bit_cnt        <= 0;
            shift_reg      <= 0;
            delay_cnt      <= 0;
            word_idx       <= 0;
            done           <= 1'b0;
            packet_latched <= 0;
        end else begin
            case (state)

                // -------------------------------------------------
                ST_IDLE: begin
                    done   <= 1'b0;
                    cs     <= 1'b1;
                    mosi   <= 1'b0;
                    sck_en <= 1'b0;
                    if (start) begin
                        packet_latched <= packet;   // freeze the packet for the whole transfer
                        word_idx       <= 0;
                        delay_cnt      <= 0;
                        state          <= ST_CS_LOW;
                    end
                end

                // -------------------------------------------------
                // CS setup time before clocking starts
                ST_CS_LOW: begin
                    cs <= 1'b0;
                    if (delay_cnt == 4) begin
                        delay_cnt <= 0;
                        shift_reg <= packet_latched[15:0]; // word0
                        bit_cnt   <= 15;
                        state     <= ST_LOAD;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                // -------------------------------------------------
                // Put MSB of the current word on MOSI, then start SCK
                ST_LOAD: begin
                    mosi   <= shift_reg[15];
                    sck_en <= 1'b1;
                    state  <= ST_SEND;
                end

                // -------------------------------------------------
                // Shift 16 bits; if more words remain, roll straight
                // into the next word WITHOUT touching CS.
                ST_SEND: begin
                    if (sck_falling) begin
                        if (bit_cnt == 0) begin
                            if (word_idx == NUM_WORDS - 1) begin
                                // last word finished -> stop clock, release CS
                                sck_en <= 1'b0;
                                mosi   <= 1'b0;
                                state  <= ST_CS_HIGH;
                            end else begin
                                // move on to the next word, CS stays low
                                word_idx  <= word_idx + 1;
                                shift_reg <= packet_latched[(word_idx+1)*16 +: 16];
                                bit_cnt   <= 15;
                                mosi      <= packet_latched[(word_idx+1)*16 + 15];
                            end
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                            mosi    <= shift_reg[bit_cnt - 1];
                        end
                    end
                end

                // -------------------------------------------------
                // CS hold time after the last SCK edge
                ST_CS_HIGH: begin
                    if (delay_cnt == 4) begin
                        cs        <= 1'b1;
                        delay_cnt <= 0;
                        state     <= ST_DONE;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                // -------------------------------------------------
                ST_DONE: begin
                    done  <= 1'b1;
                    state <= ST_IDLE;
                end

            endcase
        end
    end

endmodule