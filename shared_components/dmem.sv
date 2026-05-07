module dmem(
    input  logic        clk,
    input  logic        we,    // memwrite from maindec
    input  logic [31:0] a,     // address from alu_out (now imm_ext)
    input  logic [31:0] wd,    // write data from acc_val
    output logic [31:0] rd     // read data
);

  logic [31:0] RAM[63:0]; // 64 words of memory

  // Read is combinational
  // We use a[7:2] because 64 words only need 6 bits of addressing
  assign rd = RAM[a[7:2]]; 

  integer i;
  initial begin // Fixed typo: "intial" -> "initial"
    for (i = 0; i < 64; i = i + 1) begin
      RAM[i] = 32'b0; // Fixed name: "mem" -> "RAM"
    end
  end

  // Write is synchronous
  always_ff @(posedge clk)
    if (we) RAM[a[7:2]] <= wd;

endmodule