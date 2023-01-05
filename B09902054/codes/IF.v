module IF(
    input               i_clk,
    input               i_rst_n,
    input               i_i_valid_inst, // from instruction memory
    input [31:0]        i_i_inst,       // from instruction memory
    input               i_EX0_inst_finish,
    input               i_EX3_inst_finish,
    input               i_EX0_jmp_valid,
    input [63:0]        i_EX0_jmp_addr,

    output reg          o_i_valid_addr, // to instruction memory
    output reg [63:0]   o_i_addr,       // to instruction memory
    output reg          o_inst_valid,
    output reg [31:0]   o_inst,
    output reg [63:0]   o_inst_addr
);

reg             i_i_valid_inst_r,i_i_valid_inst_w;
reg [31:0]      i_i_inst_r,i_i_inst_w;
reg             i_EX0_inst_finish_r,i_EX0_inst_finish_w;
reg             i_EX3_inst_finish_r,i_EX3_inst_finish_w;
reg             i_EX0_jmp_valid_r,i_EX0_jmp_valid_w;
reg [63:0]      i_EX0_jmp_addr_r,i_EX0_jmp_addr_w;

reg is_start_r, is_start_w;
reg can_send_r, can_send_w;
reg buf_valid_r, buf_valid_w;
reg running_r, running_w;
initial begin
    o_i_valid_addr  = 0;
    o_i_addr        = 0;
    o_inst_valid    = 0;
    o_inst          = 0;
    o_inst_addr     = 0;
    is_start_w = 1;
    can_send_w = 1;
    buf_valid_w = 0;
end

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        i_i_valid_inst_r        = 0;
        i_i_inst_r              = 0;
        i_EX0_inst_finish_r     = 0;
        i_EX3_inst_finish_r     = 0;
        i_EX0_jmp_valid_r       = 0;
        i_EX0_jmp_addr_r        = 0;
        is_start_r          = 0;
        can_send_r          = 0;
        buf_valid_r         = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_i_valid_inst_r        = 0;
        i_i_inst_r              = 0;
        i_EX0_inst_finish_r     = 0;
        i_EX3_inst_finish_r     = 0;
        i_EX0_jmp_valid_r       = 0;
        i_EX0_jmp_addr_r        = 0;
        is_start_r          = 0;
        can_send_r          = 0;
        buf_valid_r         = 0;
    end
    else begin
        i_i_valid_inst_r        = i_i_valid_inst_w;
        i_i_inst_r              = i_i_inst_w;
        i_EX0_inst_finish_r     = i_EX0_inst_finish_w;
        i_EX3_inst_finish_r     = i_EX3_inst_finish_w;
        i_EX0_jmp_valid_r       = i_EX0_jmp_valid_w;
        i_EX0_jmp_addr_r        = i_EX0_jmp_addr_w;
        running_r           = running_w;
        is_start_r          = is_start_w;
        can_send_r          = can_send_w;
        buf_valid_r         = buf_valid_w;
        // flag_r = flag_w;
    end
end

always @(*) begin
    i_i_valid_inst_w = i_i_valid_inst;
    i_i_inst_w = i_i_inst;
    i_EX0_inst_finish_w = i_EX0_inst_finish;
    i_EX3_inst_finish_w = i_EX3_inst_finish;
    i_EX0_jmp_valid_w = i_EX0_jmp_valid;
    i_EX0_jmp_addr_w = i_EX0_jmp_addr;
end

reg [63:0] pc = 0;
reg [63:0] buf_inst_addr;
reg [31:0] buf_inst;

always@(*) begin
    o_i_valid_addr = 0;
    o_inst_valid = 0;
    if (is_start_r) begin
        o_i_valid_addr = 1;
        o_i_addr = pc;
        is_start_w = 0;
    end
    else begin
        if (i_i_valid_inst_r) begin
            buf_valid_w = 1;
            buf_inst = i_i_inst_r;
            buf_inst_addr = pc;
        end
        if (i_EX0_inst_finish_r || i_EX3_inst_finish_r) begin
            can_send_w = 1;
            if (i_EX0_jmp_valid_r) begin
                pc = i_EX0_jmp_addr_r;
                is_start_w = 1;
            end
        end
        if (buf_valid_r && can_send_r) begin
            o_inst_valid = 1;
            o_inst = buf_inst;
            o_inst_addr = buf_inst_addr;
            pc = {pc[63:8], pc[7:0] + 8'd4};
            o_i_valid_addr = 1;
            o_i_addr = pc;
            buf_valid_w = 0;
            can_send_w = 0;
        end
    end
end
endmodule