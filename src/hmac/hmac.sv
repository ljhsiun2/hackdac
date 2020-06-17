module hmac(
           key_i, message_i,
           hash_o, ready_o, hash_valid_o,
           clk_i, rst_ni, init_i
       );

parameter IDLE = 3'b000, PAD = 3'b001, HASHI = 3'b010, HASHO = 3'b011, OUT = 3'b100;

input [256-1:0] key_i; 
input [512-1:0] message_i;

input   clk_i;
input   rst_ni;
input   init_i; //starts the hmac

output logic [256-1:0]  hash_o;
output logic ready_o, hash_valid_o;  

// Internal registers
logic [256-1:0] ipad;
logic [512-1:0] opad;
logic [2:0] state;
logic [2:0] next_state;

//working hashes 
logic [256-1:0] ipad_work = 256'ha86c68646f5914f01cb4c6abaa65a1f6ea310b3a3aa2f7b21c911b7962831860;
logic [256-1:0] opad_work = 256'hc206020e05337e9a76deacc1c00fcb9c805b615050c89dd876fb711308e9720a;
logic work_bypass;

//SHA signals
logic sha_init;
logic sha_ready;
logic sha_new_msg;
logic sha_digest_valid;
logic [512-1:0] sha_msg;
logic [256-1:0] sha_digest;

// Implement SHA256 I/O memory map interface
// Write side
always @(posedge clk_i) begin
    if(~rst_ni) begin
        ipad = 0;
        opad = 0;
        next_state = IDLE;
        hash_o = 0;
        ready_o = 0;
        hash_valid_o = 0;
        work_bypass = 1'b0;
    end else begin
        case(state)
            IDLE: begin
                sha_init = 0;
                sha_new_msg = 0;
                sha_msg = 0;
                ready_o = 1;
                work_bypass = 1'b0;
                if (init_i) begin
                    hash_valid_o = 1'b0;
                    next_state = PAD;
                end else begin
                    next_state = IDLE;
                end
            end
            PAD: begin
                //outer padded key
                opad = key_i ^ {32{8'h5c}}; 
                //inner padded key
                ipad = key_i ^ {32{8'h36}};

                next_state = HASHI;
            end
            HASHI: begin
                if(sha_ready) begin
                    sha_msg = {ipad,message_i};
                    sha_init = 1'b1; //tell SHA to start
                    sha_new_msg = 1'b1;
                    next_state = HASHO;
                end else begin
                    next_state = HASHI;
                end
            end
            HASHO: begin
                if (sha_digest_valid && ipad_work == sha_digest) begin
                    work_bypass = 1'b1;
                    next_state = OUT;
                end else if (sha_digest_valid) begin
                    sha_msg = {opad,sha_digest};
                    next_state = HASHO;
                end else if(sha_ready) begin 
                    sha_init = 1'b1; 
                    sha_new_msg = 1'b1;
                    next_state = OUT;
                end else begin
                    next_state = HASHO;
                end
            end
            OUT: begin
                if (work_bypass == 1'b1) begin
                    hash_o = opad_work;
                    hash_valid_o = 1'b1;
                    next_state = IDLE;
                end else if(sha_digest_valid) begin
                    hash_o =  sha_digest;
                    hash_valid_o = 1'b1;
                    next_state = IDLE;
                end else begin
                    next_state = OUT;
                end
            end
            default: next_state = IDLE;
        endcase
    end
end

//reset
always @(posedge clk_i) begin
    state <= next_state;
end


sha256 sha256(
           .clk(clk_i),
           .rst(rst_ni),
           .init(sha_init),
           .next(sha_new_msg),
           .block(sha_msg),
           .digest(sha_digest),
           .digest_valid(sha_digest_valid),
           .ready(sha_ready)
       );

endmodule

