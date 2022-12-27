module cpu #( // Do not modify interface
	parameter ADDR_W = 64,
	parameter INST_W = 32,
	parameter DATA_W = 64
)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_i_valid_inst, // from instruction memory
    input  [ INST_W-1 : 0 ] i_i_inst,       // from instruction memory
    input                   i_d_valid_data, // from data memory
    input  [ DATA_W-1 : 0 ] i_d_data,       // from data memory
    output                  o_i_valid_addr, // to instruction memory
    output [ ADDR_W-1 : 0 ] o_i_addr,       // to instruction memory
    output [ DATA_W-1 : 0 ] o_d_w_data,     // to data memory
    output [ ADDR_W-1 : 0 ] o_d_w_addr,     // to data memory
    output [ ADDR_W-1 : 0 ] o_d_r_addr,     // to data memory
    output                  o_d_MemRead,    // to data memory
    output                  o_d_MemWrite,   // to data memory
    output                  o_finish
);

wire              IF_ID_inst_valid;
wire [31:0]       IF_ID_inst;
wire [63:0]       IF_ID_inst_addr;

IF if0 (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_i_valid_inst(i_i_valid_inst),
    .i_i_inst(i_i_inst),
    .o_i_valid_addr(o_i_valid_addr),
    .o_i_addr(o_i_addr),
    .o_inst_valid(IF_ID_inst_valid),
    .o_inst(IF_ID_inst),
    .o_inst_addr(IF_ID_inst_addr)
);

endmodule

module IF(
    input               i_clk,
    input               i_rst_n,
    input               i_i_valid_inst, // from instruction memory
    input [31:0]        i_i_inst,       // from instruction memory

    output reg          o_i_valid_addr, // to instruction memory
    output reg [63:0]   o_i_addr,       // to instruction memory
    output reg          o_inst_valid,
    output reg [31:0]   o_inst,
    output reg [63:0]   o_inst_addr
);

reg i_i_valid_inst_r, i_i_valid_inst_w;
reg [31:0] i_i_inst_r, i_i_inst_w;

reg t1_r, t1_w;
reg t2_r, t2_w;
reg [63:0] pc;

initial begin
    o_i_valid_addr  = 0;
    o_i_addr        = 0;
    o_inst_valid    = 0;
    o_inst          = 0;
    o_inst_addr     = 0;
    t1_w = 1;
    t2_w = 0;
    pc = 0;
end

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        first_tick = 0;
        i_i_valid_inst_r    = 0;
        i_i_inst_r          = 0;
        t1_r                = 0;
        t2_r                = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_i_valid_inst_r    = 0;
        i_i_inst_r          = 0;
        t1_r                = 0;
        t2_r                = 0;
    end
    else begin
        i_i_valid_inst_r    = i_i_valid_inst_w;
        i_i_inst_r          = i_i_inst_w;
        t1_r                = t1_w;
        t2_r                = t2_w;
    end
end

always @(*) begin
    i_i_valid_inst_w = i_i_valid_inst;
    i_i_inst_w = i_i_inst;
end

reg [1:0] flag = 0;
reg [63:0] pc1;
reg [63:0] pc2;
reg [31:0] pc2_inst;
always@(*) begin
    o_i_valid_addr = 0;
    o_inst_valid = 0;
    if (t1_r) begin
        o_i_valid_addr = 1;
        o_i_addr = pc;
        flag = 2'd01;
        pc1 = pc;
        t1_w = 0;
        t2_w = 1;
    end
    else if (t2_r) begin
        pc = {pc[63:8], pc[7:0] + 8'd4};
        o_i_valid_addr = 1;
        o_i_addr = pc;
        pc2 = pc;
        flag = 2'b11;
        t2_w = 0;
    end

    if (i_i_valid_inst_r && flag[0]) begin
        flag[0] = 0;
        o_inst_valid = 1;
        o_inst = i_i_inst_r;
        o_inst_addr = pc1; 
    end
    else if (i_i_valid_inst_r && flag[1]) begin
        flag[1] = 0;
        pc2_inst = i_i_inst_r;
    end
end

endmodule