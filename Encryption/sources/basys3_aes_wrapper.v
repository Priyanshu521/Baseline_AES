module basys3_aes_wrapper(
    input clk,      
    input reset,    
    input rx,       
    output tx       
);

    // Internal UART Signals
    wire [7:0] rx_byte;
    wire rx_done;
    reg [7:0] tx_byte;
    reg tx_start;
    wire tx_busy;

    // Data Buffers
    reg [127:0] key_buffer;
    reg [127:0] data_buffer;
    reg [127:0] result_to_send; // Stable for Simulation/Viewing
    reg [127:0] shift_reg;      // Used for destructive UART shifting
    wire [31:0] out0, out1, out2, out3;
    reg [4:0] byte_count;

    // FSM States
    localparam RX_KEY = 0, RX_DATA = 1, COMPUTE = 2, TX_DATA = 3;
    reg [1:0] state = RX_KEY;

    // Instantiate your AES128 Core
    AES128 aes_inst (
        .clk(clk),
        .reset(reset),
        .IN_DATA0(data_buffer[31:0]),
        .IN_DATA1(data_buffer[63:32]),
        .IN_DATA2(data_buffer[95:64]),
        .IN_DATA3(data_buffer[127:96]),
        .IN_KEY0(key_buffer[31:0]),
        .IN_KEY1(key_buffer[63:32]),
        .IN_KEY2(key_buffer[95:64]),
        .IN_KEY3(key_buffer[127:96]),
        .OUT_DATA0(out0),
        .OUT_DATA1(out1),
        .OUT_DATA2(out2),
        .OUT_DATA3(out3)
    );

    // UART RX/TX Instances
    uart_rx receiver (.clk(clk), .rx(rx), .rx_done(rx_done), .rx_byte(rx_byte));
    uart_tx transmitter (.clk(clk), .tx_start(tx_start), .tx_byte(tx_byte), .tx_busy(tx_busy), .tx(tx));
    
    // Initialize all registers to 0 to prevent "XXXX" in simulation
    initial begin
        key_buffer = 128'h0;
        data_buffer = 128'h0;
        result_to_send = 128'h0;
        shift_reg = 128'h0;
        byte_count = 0;
        state = RX_KEY;
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= RX_KEY;
            byte_count <= 0;
            tx_start <= 0;
            result_to_send <= 128'h0;
            shift_reg <= 128'h0;
        end else begin
            case (state)
                RX_KEY: begin
                    if (rx_done) begin
                        key_buffer <= {key_buffer[119:0], rx_byte};
                        if (byte_count == 15) begin
                            byte_count <= 0;
                            state <= RX_DATA;
                        end else byte_count <= byte_count + 1;
                    end
                end

                RX_DATA: begin
                    if (rx_done) begin
                        data_buffer <= {data_buffer[119:0], rx_byte};
                        if (byte_count == 15) begin
                            byte_count <= 0;
                            state <= COMPUTE;
                        end else byte_count <= byte_count + 1;
                    end
                end

                COMPUTE: begin
                    if (byte_count == 30) begin 
                        // Latch the result into BOTH registers
                        result_to_send <= {out3, out2, out1, out0}; 
                        shift_reg      <= {out3, out2, out1, out0}; 
                        state <= TX_DATA;
                        byte_count <= 0;
                    end else byte_count <= byte_count + 1;
                end

                TX_DATA: begin
                    if (!tx_busy && !tx_start) begin
                        // Load byte from shift_reg instead of result_to_send
                        tx_byte <= shift_reg[127:120]; 
                        tx_start <= 1;
                    end else if (tx_start) begin
                        tx_start <= 0;
                        // Shift the copy, NOT the original result
                        shift_reg <= {shift_reg[119:0], 8'b0}; 
                        if (byte_count == 15) begin
                            byte_count <= 0;
                            state <= RX_KEY; 
                        end else byte_count <= byte_count + 1;
                    end
                end
            endcase
        end
    end
endmodule