module dmem(
    input  logic        clk,
    input  logic        we,   // memwrite from maindec
    input  logic [31:0] a,    // address from alu_out
    input  logic [31:0] wd,   // write data from acc_val
    output logic [31:0] rd    // read data
);

  logic [31:0] RAM[63:0]; // 64 words of memory

  // Read is combinational
  assign rd = RAM[a[31:2]]; 

  // Write is synchronous
  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;

endmodule