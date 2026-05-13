module ROUND_ITERATION(
    input clk, 
    input reset, // Added Reset Port
    input [127:0] IN_DATA, 
    input [127:0] IN_KEY, 
    output reg [127:0] OUT_DATA
);

wire [127:0] SB_DATA, SHIFT_DATA, MIXED_DATA;

// Pass reset to SubBytes. 
// (Ensure SHIFT_ROWS and MIX_COLUMNS also have reset ports if they contain registers)
SUB_BYTES SB(.clk(clk), .reset(reset), .IN_DATA(IN_DATA), .SB_DATA(SB_DATA));
SHIFT_ROWS SR(.clk(clk), .IN_DATA(SB_DATA), .SHIFT_DATA(SHIFT_DATA));
MIX_COLUMNS MC(.clk(clk), .IN_DATA(SHIFT_DATA), .MIXED_DATA(MIXED_DATA));

always @(posedge clk) begin
    if (reset) begin
        OUT_DATA <= 128'b0; // Clear the round output
    end else begin
        OUT_DATA <= IN_KEY ^ MIXED_DATA;
    end
end

endmodule