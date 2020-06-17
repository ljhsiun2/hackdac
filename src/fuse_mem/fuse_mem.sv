 /*
 * FUSE mem: Which have all the secure data
 */

module fuse_mem 
(
   input  logic         clk_i,
   output  logic [255:0]  jtag_key_o,

   input  logic         req_i,
   input  logic [31:0]  addr_i,
   output logic [31:0]  rdata_o
);
    parameter  MEM_SIZE = 34;

// Store key values here. // Replication of fuse. 
    const logic [MEM_SIZE-1:0][31:0] mem = {
        // JTAG Key
        32'h28aed2a6, 32'h15468442, 32'h15328956, 32'h88779696, 32'h78945612, 32'h33334444, 32'h55556666, 32'h87489865,    
        // Access control for master 2. First 4 bits for peripheral 0, next 4 for p1 and so on.
        32'hffffffff, 
        32'hf0ffffff, 
        32'hffffffff, 
        // Access control for master 1. First 4 bits for peripheral 0, next 4 for p1 and so on.
        32'hffffffff, 
        32'hf0ff88f8, 
        32'h888fffff, 
        // Access control for master 0. First 4 bits for peripheral 0, next 4 for p1 and so on.
        32'hffffffff, 
        32'hf0ff88f8, 
        32'h888fffff, 
        // SHA Key
        32'h28aed2a6,
        32'h28aed2a6,
        32'habf71588,
        32'h09cf4f3c,
        32'h2b7e1516,
        32'h28aed2a6,
        // AES Key 2
        32'h28aed9a6,
        32'h207e1516,
        32'h09c94f3c,
        32'ha6f71558,
        32'h28aef2a6,
        32'h2b3e1216,    // LSB 32 bits
        // AES Key 1
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,    // LSB 32 bits
        // AES Key 0
        32'h2b7e1516,    
        32'h28aed2a6,
        32'habf71588,
        32'h09cf4f3c,
        32'h2b7e1516,
        32'h28aed2a6    // LSB 32 bits
    };

    logic [$clog2(MEM_SIZE)-1:0] addr_q;
    
    always_ff @(posedge clk_i) begin
        if (req_i) begin
            addr_q <= addr_i[$clog2(MEM_SIZE)-1:0];
        end
    end

    // this prevents spurious Xes from propagating into
    // the speculative fetch stage of the core
    assign rdata_o = (addr_q < MEM_SIZE) ? mem[addr_q] : '0;

    assign jtag_key_o = {mem[MEM_SIZE-1],mem[MEM_SIZE-2],mem[MEM_SIZE-3],mem[MEM_SIZE-4],mem[MEM_SIZE-5],mem[MEM_SIZE-6],mem[MEM_SIZE-7],mem[MEM_SIZE-8]};  // jtag key is not a AXI mapped address space, so passing the value directly


endmodule
