`timescale 1ns / 1ps

module tb_basys3_aes();

    // Testbench Signals
    reg clk;
    reg reset;
    reg rx;
    wire tx;

    // Standard AES Test Vector
    // Key: 2b7e151628aed2a6abf7158809cf4f3c
    // Plaintext: 3243f6a8885a308d313198a2e0370734
    // Expected Ciphertext: 3925841d02dc09fbdc118597196a0b32[cite: 1]

    reg [127:0] test_key  = 128'h000102030405060708090a0b0c0d0e0f;
    reg [127:0] test_data = 128'h00112233445566778899aabbccddeeff;

    // Clock Period for 100MHz (10ns)
    // UART Bit Period for 9600 Baud (1/9600 s ≈ 104167 ns)
    localparam CLK_PERIOD = 10;
    localparam BIT_PERIOD = 104167; 

    // Instantiate the Wrapper (Top Module)
    basys3_aes_wrapper uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx)
    );

    // Clock Generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Task to send a single byte via UART RX pin
    task send_byte(input [7:0] data);
        integer i;
        begin
            rx = 0; // Start bit
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i]; // Data bits (LSB first)
                #(BIT_PERIOD);
            end
            rx = 1; // Stop bit
            #(BIT_PERIOD);
        end
    endtask

    initial begin
        // Initialize Signals
        clk = 0;
        reset = 1;
        rx = 1; // UART Idle is high
        
        // Wait and Release Reset
        #(CLK_PERIOD * 10);
        reset = 0;
        #(CLK_PERIOD * 10);

        // --- Step 1: Send 16 Bytes of Key ---
        $display("Starting Key Transmission...");
        send_byte(test_key[127:120]); send_byte(test_key[119:112]);
        send_byte(test_key[111:104]); send_byte(test_key[103:96]);
        send_byte(test_key[95:88]);   send_byte(test_key[87:80]);
        send_byte(test_key[79:72]);   send_byte(test_key[71:64]);
        send_byte(test_key[63:56]);   send_byte(test_key[55:48]);
        send_byte(test_key[47:40]);   send_byte(test_key[39:32]);
        send_byte(test_key[31:24]);   send_byte(test_key[23:16]);
        send_byte(test_key[15:8]);    send_byte(test_key[7:0]);

        // --- Step 2: Send 16 Bytes of Plaintext ---
        $display("Starting Plaintext Transmission...");
        send_byte(test_data[127:120]); send_byte(test_data[119:112]);
        send_byte(test_data[111:104]); send_byte(test_data[103:96]);
        send_byte(test_data[95:88]);   send_byte(test_data[87:80]);
        send_byte(test_data[79:72]);   send_byte(test_data[71:64]);
        send_byte(test_data[63:56]);   send_byte(test_data[55:48]);
        send_byte(test_data[47:40]);   send_byte(test_data[39:32]);
        send_byte(test_data[31:24]);   send_byte(test_data[23:16]);
        send_byte(test_data[15:8]);    send_byte(test_data[7:0]);

        $display("Data Sent. Waiting for Encryption and UART TX...");
        
        // Wait for the FPGA to process and send back 16 bytes
        // Each UART byte takes ~104us, so 16 bytes take ~1.6ms
        #(BIT_PERIOD * 20); 
        
        $display("Simulation Complete. Check the Waveform window for 'tx' transitions.");
        $finish;
    end

endmodule