module instr_mem #(
    parameter n = 32, 
    parameter r = 8
)(
    input  logic [(r-1):0] addr,
    output logic [(n-1):0] readdata
);

    logic [n-1:0] RAM [0:(2**r)-1];

    initial begin
        // Zero out memory to prevent 'X' in GTKWave for unwritten spots
        for (int i = 0; i < (2**r); i++) begin
            RAM[i] = {n{1'b0}};
        end
        
        // Load the hex file
        $readmemh("test_prog.hex", RAM);
    end

    // 3. Indexing Logic
    // Use addr[(r-1):2] IF PC increments by 4 (Byte-addressed)
    // Use addr[(r-1):0] IF PC increments by 1 (Word-addressed)
    assign readdata = RAM[addr[(r-1):2]];

endmodule