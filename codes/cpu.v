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
wire              EX0_IF_inst_finish;
IF if0 (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_i_valid_inst(i_i_valid_inst),
    .i_i_inst(i_i_inst),
    .i_EX0_inst_finish(EX0_IF_inst_finish),
    .o_i_valid_addr(o_i_valid_addr),
    .o_i_addr(o_i_addr),
    .o_inst_valid(IF_ID_inst_valid),
    .o_inst(IF_ID_inst),
    .o_inst_addr(IF_ID_inst_addr)
);

wire            ID_EX_inst_valid;
wire [31:0]     ID_EX_inst;
wire [63:0]     ID_EX_inst_addr;
wire [63:0]     ID_EX_rs1_value;
wire [63:0]     ID_EX_rs2_value;
wire            EX_ID_wb_valid;
wire [4:0]      EX_ID_wb_rd;
wire [63:0]     EX_ID_wb_value;
wire            EX_ID_inst_finish;

ID id0 (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_inst_valid(IF_ID_inst_valid),
    .i_inst(IF_ID_inst),
    .i_EX_wb_valid(EX_ID_wb_valid),
    .i_EX_wb_rd(EX_ID_wb_rd),
    .i_EX_wb_value(EX_ID_wb_value),
    .o_inst_valid(ID_EX_inst_valid),
    .o_inst(ID_EX_inst),
    .o_inst_addr(ID_EX_inst_addr),
    .o_rs1_value(ID_EX_rs1_value),
    .o_rs2_value(ID_EX_rs2_value)
);

wire [63:0]   EX0_EX1_A;
wire [63:0]   EX0_EX1_B;
wire [63:0]   EX0_EX1_C;
wire          EX0_EX1_carry;

EX0 ex0 (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_inst_valid(ID_EX_inst_valid),
    .i_inst(ID_EX_inst), 
    .i_inst_addr(ID_EX_inst_addr),
    .i_rs1_value(ID_EX_rs1_value),
    .i_rs2_value(ID_EX_rs2_value),
    .o_A(EX0_EX1_A),
    .o_B(EX0_EX1_B),
    .o_C(EX0_EX1_C),
    .o_carry(EX0_EX1_carry),
    .o_d_w_data(o_d_w_data),
    .o_d_w_addr(o_d_w_addr),
    .o_d_r_addr(o_d_r_addr),
    .o_d_MemRead(o_d_MemRead),
    .o_d_MemWrite(o_d_MemWrite),
    .o_wb_valid(EX_ID_wb_valid),
    .o_wb_rd(EX_ID_wb_rd),
    .o_wb_value(EX_ID_wb_value),
    .o_inst_finish(EX0_IF_inst_finish),
    .o_finish(o_finish)
);

endmodule