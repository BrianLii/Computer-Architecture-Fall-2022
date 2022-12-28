module EX0(
    input               i_clk,
    input               i_rst_n,
    input               i_inst_valid,
    input [31:0]        i_inst, 
    input [63:0]        i_inst_addr,
    input [63:0]        i_rs1_value,
    input [63:0]        i_rs2_value,

    output reg          o_inst_valid,
    output reg [63:0]   o_A,
    output reg [63:0]   o_B,
    output reg [63:0]   o_C,
    output reg [4:0]    o_rd,
    output reg          o_isld,
    output reg          o_carry,
    output reg [63:0]   o_d_w_data,     // to data memory
    output reg [63:0]   o_d_w_addr,     // to data memory
    output reg [63:0]   o_d_r_addr,     // to data memory
    output reg          o_d_MemRead,    // to data memory
    output reg          o_d_MemWrite,   // to data memory
    output reg          o_wb_valid,
    output reg [4:0]    o_wb_rd,
    output reg [63:0]   o_wb_value,
    output reg          o_inst_finish,
    output reg          o_jmp_valid,
    output reg [63:0]   o_jmp_addr,

    output reg          o_finish 
);
reg               i_inst_valid_r,i_inst_valid_w;
reg [31:0]        i_inst_r,i_inst_w;
reg [63:0]        i_inst_addr_r,i_inst_addr_w;
reg [63:0]        i_rs1_value_r,i_rs1_value_w;
reg [63:0]        i_rs2_value_r,i_rs2_value_w;

integer i;
initial begin
    o_inst_valid = 0;
    o_inst_finish = 0;
end

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        i_inst_valid_r      = 0;
        i_inst_r            = 0;
        i_inst_addr_r       = 0;
        i_rs1_value_r       = 0;
        i_rs2_value_r       = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_inst_valid_r      = 0;
        i_inst_r            = 0;
        i_inst_addr_r       = 0;
        i_rs1_value_r       = 0;
        i_rs2_value_r       = 0;
    end
    else begin
        i_inst_valid_r      = i_inst_valid_w;
        i_inst_r            = i_inst_w;
        i_inst_addr_r       = i_inst_addr_w;
        i_rs1_value_r       = i_rs1_value_w;
        i_rs2_value_r       = i_rs2_value_w;
    end
end

always@(*) begin
    i_inst_valid_w  = i_inst_valid;
    i_inst_w        = i_inst;
    i_inst_addr_w   = i_inst_addr;
    i_rs1_value_w   = i_rs1_value;
    i_rs2_value_w   = i_rs2_value;
end
reg [6:0] opcode;
reg [63:0] I_imm;
reg [63:0] S_imm;
reg [63:0] SB_imm;
reg [4:0] rd;
reg [2:0] func3;

always@(*) begin
    o_inst_valid = 0;
    o_d_MemRead = 0;
    o_d_MemWrite = 0;
    o_wb_valid = 0;
    o_inst_finish = 0;
    o_isld = 0;
    o_jmp_valid = 0;
    if (i_inst_valid_r) begin
        opcode = i_inst_r[6:0];
        I_imm  = $signed(i_inst_r[31:20]);
        S_imm  = $signed({{i_inst_r[31:25]}, {i_inst_r[11:7]}});
        SB_imm = $signed({{i_inst_r[31]}, {i_inst_r[7]}, {i_inst_r[30:25]}, {i_inst_r[11:8]}, 1'b0});
        rd = i_inst_r[11:7];
        func3 = i_inst_r[14:12];
        
        casez({opcode,func3,i_inst_r[30]})
            {7'b1111111,3'b???,1'b?}: begin
                // EOF
                o_finish = 1;
            end
            {7'b0000011,3'b???,1'b?}: begin
                // LD
                // display("LD");
                o_inst_valid = 1;
                o_isld = 1;
                o_rd = rd;
                o_d_r_addr = {{i_rs1_value_r[63:10]}, {i_rs1_value_r[9:0]} + {I_imm[9:0]}};
                o_d_MemWrite = 0;
                o_d_MemRead = 1;
            end
            {7'b0100011,3'b???,1'b?}: begin
                // display("SD");
                o_inst_valid = 0;
                o_d_w_addr = {{i_rs1_value_r[63:10]}, {i_rs1_value_r[9:0]} + {S_imm[9:0]}};
                o_d_w_data = i_rs2_value_r;
                o_d_MemWrite = 1;
                o_d_MemRead = 0;
                o_inst_finish = 1;
            end
            {7'b1100011,3'b000,1'b?}: begin
                // display("BEQ");
                o_inst_valid = 0;
                if (i_rs1_value_r == i_rs2_value_r) begin
                    o_jmp_valid = 1;
                    o_jmp_addr = {{i_inst_addr_r[63:8]}, {i_inst_addr_r[7:0]} + SB_imm[7:0]};
                end
                o_inst_finish = 1;
            end
            {7'b1100011,3'b001,1'b?}: begin
                // display("BNE");
                o_inst_valid = 0;
                if (i_rs1_value_r != i_rs2_value_r) begin
                    o_jmp_valid = 1;
                    o_jmp_addr = {{i_inst_addr_r[63:8]}, {i_inst_addr_r[7:0]} + SB_imm[7:0]};
                end
                o_inst_finish = 1;
            end
            {7'b0010011,3'b000,1'b?}: begin
                // display("ADDI");
                o_inst_valid = 1;
                o_A = i_rs1_value_r;
                o_B = I_imm;
                o_rd = rd;
                o_C = 0;
                {o_carry,o_C[15:0]} = o_A[15:0] + o_B[15:0];
            end
            {7'b0010011,3'b100,1'b?}: begin
                // diplay("XORI");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r ^ I_imm;
                o_inst_finish = 1;
            end
            {7'b0010011,3'b110,1'b?}: begin
                // diplay("ORI");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r | I_imm;
                o_inst_finish = 1;
            end
            {7'b0010011,3'b111,1'b?}: begin
                // diplay("ANDI");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r & I_imm;
                o_inst_finish = 1;
            end
            {7'b0010011,3'b001,1'b?}: begin
                // diplay("SLLI");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r << I_imm[5:0]; 
                o_inst_finish = 1;               
            end
            {7'b0010011,3'b101,1'b?}: begin
                // diplay("SRLI");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r >> I_imm[5:0];
                o_inst_finish = 1;
            end
            {7'b0110011,3'b000,1'b0}: begin
                // diplay("ADD");
                o_inst_valid = 1;
                o_A = i_rs1_value_r;
                o_B = i_rs2_value_r;
                o_C = 0;
                o_rd = rd;
                {o_carry,o_C[15:0]} = o_A[15:0] + o_B[15:0];
            end
            {7'b0110011,3'b000,1'b1}: begin
                // diplay("SUB");
                o_inst_valid = 1;
                o_A = i_rs1_value_r;
                o_B = ~i_rs2_value_r;
                o_C = 0;
                o_rd = rd;
                {o_carry,o_C[15:0]} = o_A[15:0] + o_B[15:0] + 1;
            end
            {7'b0110011,3'b100,1'b?}: begin
                // diplay("XOR");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r ^ i_rs2_value_r;
                o_inst_finish = 1;
            end
            {7'b0110011,3'b110,1'b?}: begin
                // diplay("OR");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r | i_rs2_value_r;
                o_inst_finish = 1;
            end
            {7'b0110011,3'b111,1'b?}: begin
                // diplay("AND");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r & i_rs2_value_r;
                o_inst_finish = 1;
            end
        endcase
    end
end

endmodule

module EX1(
    input               i_clk,
    input               i_rst_n,
    input               i_inst_valid,
    input [63:0]        i_A,
    input [63:0]        i_B,
    input [63:0]        i_C,
    input [4:0]         i_rd,
    input               i_isld,
    input               i_carry,

    output reg          o_inst_valid,
    output reg [63:0]   o_A,
    output reg [63:0]   o_B,
    output reg [63:0]   o_C,
    output reg [4:0]    o_rd,
    output reg          o_isld,
    output reg          o_carry
);
reg               i_inst_valid_r,i_inst_valid_w;
reg [63:0]        i_A_r,i_A_w;
reg [63:0]        i_B_r,i_B_w;
reg [63:0]        i_C_r,i_C_w;
reg [4:0]         i_rd_r,i_rd_w;
reg               i_isld_r,i_isld_w;
reg               i_carry_r,i_carry_w;

integer i;
initial begin
    o_inst_valid = 0;
end

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        i_inst_valid_r      = 0;
        i_A_r               = 0;
        i_B_r               = 0;
        i_C_r               = 0;
        i_rd_r              = 0;
        i_isld_r            = 0;
        i_carry_r           = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_inst_valid_r      = 0;
        i_A_r               = 0;
        i_B_r               = 0;
        i_C_r               = 0;
        i_rd_r              = 0;
        i_isld_r            = 0;
        i_carry_r           = 0;
    end
    else begin
        i_inst_valid_r      = i_inst_valid_w;
        i_A_r               = i_A_w;
        i_B_r               = i_B_w;
        i_C_r               = i_C_w;
        i_rd_r              = i_rd_w;
        i_isld_r            = i_isld_w;
        i_carry_r           = i_carry_w;
    end
end

always@(*) begin
    i_inst_valid_w = i_inst_valid;
    i_A_w = i_A;
    i_B_w = i_B;
    i_C_w = i_C;
    i_rd_w = i_rd;
    i_isld_w = i_isld;
    i_carry_w = i_carry;
end

always@(*) begin
    o_inst_valid = 0;
    if (i_inst_valid_r) begin
        o_inst_valid = 1;
        o_A = i_A_r;
        o_B = i_B_r;
        o_C = i_C_r;
        {o_carry,o_C[31:16]} = i_A_r[31:16] + i_B_r[31:16] + i_carry_r;
        o_rd = i_rd_r;
        o_isld = i_isld_r;
    end
end

endmodule

module EX2(
    input               i_clk,
    input               i_rst_n,
    input               i_inst_valid,
    input [63:0]        i_A,
    input [63:0]        i_B,
    input [63:0]        i_C,
    input [4:0]         i_rd,
    input               i_isld,
    input               i_carry,

    output reg          o_inst_valid,
    output reg [63:0]   o_A,
    output reg [63:0]   o_B,
    output reg [63:0]   o_C,
    output reg [4:0]    o_rd,
    output reg          o_isld,
    output reg          o_carry
);
reg               i_inst_valid_r,i_inst_valid_w;
reg [63:0]        i_A_r,i_A_w;
reg [63:0]        i_B_r,i_B_w;
reg [63:0]        i_C_r,i_C_w;
reg [4:0]         i_rd_r,i_rd_w;
reg               i_isld_r,i_isld_w;
reg               i_carry_r,i_carry_w;

integer i;
initial begin
    o_inst_valid = 0;
end

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        i_inst_valid_r      = 0;
        i_A_r               = 0;
        i_B_r               = 0;
        i_C_r               = 0;
        i_rd_r              = 0;
        i_isld_r            = 0;
        i_carry_r           = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_inst_valid_r      = 0;
        i_A_r               = 0;
        i_B_r               = 0;
        i_C_r               = 0;
        i_rd_r              = 0;
        i_isld_r            = 0;
        i_carry_r           = 0;
    end
    else begin
        i_inst_valid_r      = i_inst_valid_w;
        i_A_r               = i_A_w;
        i_B_r               = i_B_w;
        i_C_r               = i_C_w;
        i_rd_r              = i_rd_w;
        i_isld_r            = i_isld_w;
        i_carry_r           = i_carry_w;
    end
end

always@(*) begin
    i_inst_valid_w = i_inst_valid;
    i_A_w = i_A;
    i_B_w = i_B;
    i_C_w = i_C;
    i_rd_w = i_rd;
    i_isld_w = i_isld;
    i_carry_w = i_carry;
end

always@(*) begin
    o_inst_valid = 0;
    if (i_inst_valid_r) begin
        o_inst_valid = 1;
        o_A = i_A_r;
        o_B = i_B_r;
        o_C = i_C_r;
        {o_carry,o_C[47:32]} = i_A_r[47:32] + i_B_r[47:32] + i_carry_r;
        o_rd = i_rd_r;
        o_isld = i_isld_r;
    end
end

endmodule

module EX3(
    input               i_clk,
    input               i_rst_n,
    input [63:0]        i_d_data,   // from data memory
    input               i_inst_valid,
    input [63:0]        i_A,
    input [63:0]        i_B,
    input [63:0]        i_C,
    input [4:0]         i_rd,
    input               i_isld,
    input               i_carry,

    output reg          o_wb_valid,
    output reg [4:0]    o_wb_rd,
    output reg [63:0]   o_wb_value,
    output reg          o_inst_finish
);
reg [63:0]        i_d_data_r,i_d_data_w;
reg               i_inst_valid_r,i_inst_valid_w;
reg [63:0]        i_A_r,i_A_w;
reg [63:0]        i_B_r,i_B_w;
reg [63:0]        i_C_r,i_C_w;
reg [4:0]         i_rd_r,i_rd_w;
reg               i_isld_r,i_isld_w;
reg               i_carry_r,i_carry_w;

reg first_tick = 1;
always@(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        i_d_data_r          = 0;
        i_inst_valid_r      = 0;
        i_A_r               = 0;
        i_B_r               = 0;
        i_C_r               = 0;
        i_rd_r              = 0;
        i_isld_r            = 0;
        i_carry_r           = 0;
    end
    else if (first_tick) begin
        first_tick = 0;
        i_d_data_r          = 0;
        i_inst_valid_r      = 0;
        i_A_r               = 0;
        i_B_r               = 0;
        i_C_r               = 0;
        i_rd_r              = 0;
        i_isld_r            = 0;
        i_carry_r           = 0;
    end
    else begin
        i_d_data_r          = i_d_data_w;
        i_inst_valid_r      = i_inst_valid_w;
        i_A_r               = i_A_w;
        i_B_r               = i_B_w;
        i_C_r               = i_C_w;
        i_rd_r              = i_rd_w;
        i_isld_r            = i_isld_w;
        i_carry_r           = i_carry_w;
    end
end

always@(*) begin
    i_inst_valid_w = i_inst_valid;
    i_d_data_w = i_d_data;
    i_A_w = i_A;
    i_B_w = i_B;
    i_C_w = i_C;
    i_rd_w = i_rd;
    i_isld_w = i_isld;
    i_carry_w = i_carry;
end

always@(*) begin
    o_wb_valid = 0;
    o_inst_finish = 0;
    if (i_inst_valid_r) begin
        o_wb_valid = 1;
        o_wb_rd = i_rd_r;
        if (i_isld_r) begin
            o_wb_value = i_d_data_r;
        end
        else begin
            o_wb_value = i_C_r;
            o_wb_value[63:48] = i_A_r[63:48] + i_B_r[63:48] + i_carry_r;
        end
        o_inst_finish = 1;
    end
end

endmodule