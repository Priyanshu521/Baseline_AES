module uart_tx #(parameter CLKS_PER_BIT = 10417) (
    input clk,
    input tx_start,
    input [7:0] tx_byte,
    output reg tx_busy,
    output reg tx
);
    reg [2:0] state = 0;
    reg [13:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] data = 0;

    always @(posedge clk) begin
        case (state)
            0: begin // IDLE
                tx <= 1; 
                tx_busy <= 0;
                clk_count <= 0;
                bit_index <= 0;
                if (tx_start) begin
                    data <= tx_byte;
                    tx_busy <= 1;
                    state <= 1;
                end
            end
            1: begin // START BIT
                tx <= 0;
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    state <= 2;
                end
            end
            2: begin // DATA BITS
                tx <= data[bit_index];
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    if (bit_index < 7) bit_index <= bit_index + 1;
                    else state <= 3;
                end
            end
            3: begin // STOP BIT
                tx <= 1;
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    state <= 0;
                end
            end
            default: state <= 0;
        endcase
    end
endmodule