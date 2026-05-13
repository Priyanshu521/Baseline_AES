module uart_rx #(parameter CLKS_PER_BIT = 10417) (
    input clk,
    input rx,
    output reg rx_done,
    output reg [7:0] rx_byte
);
    reg [2:0] state = 0;
    reg [13:0] clk_count = 0;
    reg [2:0] bit_index = 0;

    always @(posedge clk) begin
        case (state)
            0: begin // IDLE
                rx_done <= 0;
                clk_count <= 0;
                bit_index <= 0;
                if (rx == 0) state <= 1; // Start bit detected
            end
            1: begin // START BIT
                if (clk_count == (CLKS_PER_BIT-1)/2) begin
                    if (rx == 0) begin
                        clk_count <= 0;
                        state <= 2;
                    end else state <= 0;
                end else clk_count <= clk_count + 1;
            end
            2: begin // DATA BITS
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    rx_byte[bit_index] <= rx;
                    if (bit_index < 7) bit_index <= bit_index + 1;
                    else state <= 3;
                end
            end
            3: begin // STOP BIT
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    rx_done <= 1;
                    clk_count <= 0;
                    state <= 0;
                end
            end
            default: state <= 0;
        endcase
    end
endmodule