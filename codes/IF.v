module IF(
    input               i_clk,
    input               i_rst_n,
    input               i_i_valid_inst, // from instruction memory
    input [31:0]        i_i_inst,       // from instruction memory
    input               i_EX0_inst_finish,

    output reg          o_i_valid_addr, // to instruction memory
    output reg [63:0]   o_i_addr,       // to instruction memory
    output reg          o_inst_valid,
    output reg [31:0]   o_inst,
    output reg [63:0]   o_inst_addr
);

reg i_i_valid_inst_r, i_i_valid_inst_w;
reg [31:0] i_i_inst_r, i_i_inst_w;
reg i_EX0_inst_finish_r, i_EX0_inst_finish_w;
reg t1_r, t1_w;
reg t2_r, t2_w;
reg t3_r, t3_w;
reg t4_r, t4_w;
reg t5_r, t5_w;
reg running_r, running_w;
initial begin
    o_i_valid_addr  = 0;
    o_i_addr        = 0;
    o_inst_valid    = 0;
    o_inst          = 0;
    o_inst_addr     = 0;
    t1_w = 1;
    t2_w = 0;
    t3_w = 0;
    t4_w = 0;
    t5_w = 0;

end

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        i_i_valid_inst_r    = 0;
        i_i_inst_r          = 0;
        t1_r                = 0;
        t2_r                = 0;
        t3_r                = 0;
        t4_r                = 0;
        t5_r                = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_i_valid_inst_r    = 0;
        i_i_inst_r          = 0;
        t1_r                = 0;
        t2_r                = 0;
        t3_r                = 0;
        t4_r                = 0;
        t5_r                = 0;
        running_r           = 0;
    end
    else begin
        i_i_valid_inst_r    = i_i_valid_inst_w;
        i_i_inst_r          = i_i_inst_w;
        i_EX0_inst_finish_r = i_EX0_inst_finish_w;
        t1_r                = t1_w;
        t2_r                = t2_w;
        t3_r                = t3_w;
        t4_r                = t4_w;
        t5_r                = t5_w;
        running_r           = running_w;
        // flag_r = flag_w;
    end
end

always @(*) begin
    i_i_valid_inst_w = i_i_valid_inst;
    i_i_inst_w = i_i_inst;
    i_EX0_inst_finish_w = i_EX0_inst_finish;
end

reg [63:0] pc = 0;
reg [63:0] buf_inst_addr;
reg [31:0] buf_inst;

always@(*) begin
    o_i_valid_addr = 0;
    o_inst_valid = 0;
    if (t1_r) begin
        o_i_valid_addr = 1;
        o_i_addr = pc;
        t1_w = 0;
    end

    if (i_i_valid_inst_r) begin
        o_inst_valid = 1;
        o_inst = i_i_inst_r;
        o_inst_addr = pc;
    end

    if (i_EX0_inst_finish_r) begin
        pc = {pc[63:8], pc[7:0] + 8'd4};
        t1_w = 1;
    end
end

// reg [63:0] pc1;
// reg [63:0] pc2;
// reg [31:0] pc2_inst;
// always@(*) begin
//     o_i_valid_addr = 0;
//     o_inst_valid = 0;
//     if (t1_r) begin
//         o_i_valid_addr = 1;
//         o_i_addr = pc;
//         flag = 2'd01;
//         pc1 = pc;
//         t1_w = 0;
//         t2_w = 1;
//     end
//     else if (t2_r) begin
//         pc = {pc[63:8], pc[7:0] + 8'd4};
//         o_i_valid_addr = 1;
//         o_i_addr = pc;
//         pc2 = pc;
//         flag = 2'b11;
//         t2_w = 0;
//     end

//     if (i_i_valid_inst_r && flag[0]) begin
//         flag[0] = 0;
//         o_inst_valid = 1;
//         o_inst = i_i_inst_r;
//         o_inst_addr = pc1; 
//     end
//     else if (i_i_valid_inst_r && flag[1]) begin
//         flag[1] = 0;
//         pc2_inst = i_i_inst_r;
//     end

//     if (i_EX0_inst_finish_r) begin
//         o_inst_valid = 1;
//         o_inst = pc2_inst;
//         o_inst_addr = pc2;
//         o_i_valid_addr = 1;
//         pc = {pc2[63:8], pc2[7:0] + 8'd4};
//         pc2 = pc;
//         o_i_addr = pc;
//         flag[1] = 1;
//     end
// end

endmodule