module instr_mem #(
    parameter n = 32, 
    parameter r = 8
)(
    input  logic [(r-1):0] addr,
    output logic [(n-1):0] readdata
);

    logic [n-1:0] RAM [0:(2**r)-1];

    initial begin
        string prog_file;
        for (int i = 0; i < (2**r); i++)
            RAM[i] = {n{1'b0}};
        if (!$value$plusargs("PROG=%s", prog_file))
            prog_file = "test_prog.hex";
        $readmemh(prog_file, RAM);
    end

    // 3. Indexing Logic
    // Use addr[(r-1):2] IF PC increments by 4 (Byte-addressed)
    // Use addr[(r-1):0] IF PC increments by 1 (Word-addressed)
    assign readdata = RAM[addr[(r-1):2]];

endmodule