module pc (
    input wire clk,
    input wire reset,
    input wire stall,              // for pipeline (can tie to 0 for now)
    input wire branch_taken,
    input wire [31:0] branch_target,
    output reg [31:0] pc_out
);

wire [31:0] pc_plus4;
assign pc_plus4 = pc_out + 32'd4;

wire [31:0] next_pc;
assign next_pc = branch_taken ? branch_target : pc_plus4;

always @(posedge clk or posedge reset) begin
    if (reset)
        pc_out <= 32'd0;
    else if (!stall)
        pc_out <= next_pc;
end

endmodule