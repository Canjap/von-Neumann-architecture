module tb_maindec;
    // Inputs
    logic        reset;
    logic [5:0]  op;

    // Outputs
    logic        memtoreg, memwrite, branch, regwrite, jump;
    logic [1:0]  alusrc, memaddrsrc;
    logic [2:0]  aluop;
    logic        callout, ret, spwrite, lrwrite, usesp, accsrc;

    // Instantiate the Unit Under Test (UUT)
    maindec uut (
        .reset(reset),
        .op(op),
        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .branch(branch),
        .alusrc(alusrc),
        .regwrite(regwrite),
        .jump(jump),
        .memaddrsrc(memaddrsrc),
        .aluop(aluop),
        .callout(callout),
        .ret(ret),
        .spwrite(spwrite),
        .lrwrite(lrwrite),
        .usesp(usesp),
        .accsrc(accsrc)
    );

    // VCD Dumpfile setup for waveform viewing
    initial begin
        $dumpfile("tb_maindec.vcd");
        $dumpvars(0, tb_maindec);
    end

    initial begin
        $display("Time | Rst |  Op  | RegW AluS Mem2R MemW Br Jmp MemAddr Call Ret SpW LrW UseSp AccSrc AluOp");
        $display("---------------------------------------------------------------------------------------------");
        $monitor("%4t |  %b  | %h |  %b    %b    %b     %b   %b   %b    %b      %b   %b   %b   %b    %b      %b     %b", 
                 $time, reset, op, regwrite, alusrc, memtoreg, memwrite, branch, jump, memaddrsrc, callout, ret, spwrite, lrwrite, usesp, accsrc, aluop);

        // Test Reset
        reset = 1; op = 6'h00; #10;
        
        // Test various instructions
        reset = 0;
        op = 6'h02; #10; // ADD
        op = 6'h08; #10; // LDA
        op = 6'h2B; #10; // STA
        op = 6'h04; #10; // BZ
        op = 6'h0E; #10; // CALL
        op = 6'h14; #10; // ADDSP
        op = 6'h16; #10; // LDSP
        op = 6'h18; #10; // SETLR
        
        #10 $finish;
    end
endmodule