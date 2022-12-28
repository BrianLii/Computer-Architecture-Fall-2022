module ID(
    input               i_clk,
    input               i_rst_n,
    input               i_inst_valid,
    input [31:0]        i_inst, 
    input [63:0]        i_inst_addr,
    input               i_EX_wb_valid,
    input [4:0]         i_EX_wb_rd,
    input [63:0]        i_EX_wb_value,

    output reg          o_inst_valid,
    output reg [31:0]   o_inst,
    output reg [63:0]   o_inst_addr,
    output reg [63:0]   o_rs1_value,
    output reg [63:0]   o_rs2_value
);
reg               i_inst_valid_r,i_inst_valid_w;
reg [31:0]        i_inst_r, i_inst_w;
reg [63:0]        i_inst_addr_r, i_inst_addr_w;
reg               i_EX_wb_valid_r, i_EX_wb_valid_w;
reg [4:0]         i_EX_wb_rd_r, i_EX_wb_rd_w;
reg [63:0]        i_EX_wb_value_r, i_EX_wb_value_w;
reg [63:0] reg_file [31:0];

integer i;
initial begin
    o_inst_valid = 0;
    for (i=0;i<=31;i=i+1)
        reg_file[i] = 0;
end

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        i_inst_valid_r      = 0;
        i_inst_r            = 0;
        i_inst_addr_r       = 0;
        i_EX_wb_valid_r     = 0;
        i_EX_wb_rd_r        = 0;
        i_EX_wb_value_r     = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_inst_valid_r      = 0;
        i_inst_r            = 0;
        i_inst_addr_r       = 0;
        i_EX_wb_valid_r     = 0;
        i_EX_wb_rd_r        = 0;
        i_EX_wb_value_r     = 0;
    end
    else begin
        i_inst_valid_r      = i_inst_valid_w;
        i_inst_r            = i_inst_w;
        i_inst_addr_r       = i_inst_addr_w;
        i_EX_wb_valid_r     = i_EX_wb_valid_w;
        i_EX_wb_rd_r        = i_EX_wb_rd_w;
        i_EX_wb_value_r     = i_EX_wb_value_w;
    end
end

always@(*) begin
    i_inst_valid_w          = i_inst_valid;
    i_inst_w                = i_inst;
    i_inst_addr_w           = i_inst_addr;
    i_EX_wb_valid_w         = i_EX_wb_valid;
    i_EX_wb_rd_w            = i_EX_wb_rd;
    i_EX_wb_value_w         = i_EX_wb_value;
end

always@(*) begin
    o_inst_valid = 0;
    if (i_EX_wb_valid_r) begin
        reg_file[i_EX_wb_rd_r] = i_EX_wb_value_r;
    end
    else if (i_inst_valid_r) begin
        o_inst_valid = 1;
        o_inst = i_inst_r;
        o_inst_addr = i_inst_addr_r;
        o_rs1_value = reg_file[i_inst_r[19:15]];
        o_rs2_value = reg_file[i_inst_r[24:20]];
    end
end

endmodule