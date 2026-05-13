module LAST_ROUND(
    input clk, 
    input reset,        // Added Reset Port
    input [127:0] IN_DATA, 
    input [127:0] IN_KEY, 
    output reg [127:0] OUT_DATA
);

wire [127:0] SB_DATA, SHIFT_DATA;

// We must pass the reset to SUB_BYTES because its S-Boxes are now clocked
SUB_BYTES SB(.clk(clk), .reset(reset), .IN_DATA(IN_DATA), .SB_DATA(SB_DATA));

// SHIFT_ROWS is combinational, so we just pass data through it
SHIFT_ROWS SR(.clk(clk), .IN_DATA(SB_DATA), .SHIFT_DATA(SHIFT_DATA));

always @(posedge clk) begin
    if (reset) begin
        OUT_DATA <= 128'b0; // Clear the final output register
    end else begin
        OUT_DATA <= IN_KEY ^ SHIFT_DATA;
    end
end

endmodule