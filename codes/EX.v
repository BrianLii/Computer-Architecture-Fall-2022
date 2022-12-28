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
                o_inst_valid = 1;
                o_isld = 1;
                o_d_r_addr = {{i_rs1_value_r[63:10]}, {i_rs1_value_r[9:0]} + {I_imm[9:0]}};
                o_d_MemWrite = 0;
                o_d_MemRead = 1;
            end
            {7'b0100011,3'b???,1'b?}: begin
                // SD
                $display("SD");
                o_inst_valid = 1;
                o_d_w_addr = {{i_rs1_value_r[63:10]}, {i_rs1_value_r[9:0]} + {S_imm[9:0]}};
                o_d_w_data = i_rs2_value_r;
                o_d_MemWrite = 1;
                o_d_MemRead = 0;
            end
            {7'b1100011,3'b000,1'b?}: begin
                // BEQ
                $display("BEQ");
            end
            {7'b1100011,3'b001,1'b?}: begin
                // BNE
                $display("BNE");
            end
            {7'b0010011,3'b000,1'b?}: begin
                // ADDI
                $display("ADDI");
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r + I_imm;
                o_inst_finish = 1;
            end
            {7'b0010011,3'b100,1'b?}: begin
                // XORI
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r ^ I_imm;
                o_inst_finish = 1;
            end
            {7'b0010011,3'b110,1'b?}: begin
                // ORI
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r | I_imm;
                o_inst_finish = 1;
            end
            {7'b0010011,3'b111,1'b?}: begin
                // ANDI
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r & I_imm;
                o_inst_finish = 1;
            end
            {7'b0010011,3'b001,1'b?}: begin
                // SLLI
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r << I_imm[5:0]; 
                o_inst_finish = 1;               
            end
            {7'b0010011,3'b101,1'b?}: begin
                // SRLI
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r >> I_imm[5:0];
                o_inst_finish = 1;
            end
            {7'b0110011,3'b000,1'b0}: begin
                // ADD
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r + i_rs2_value_r;
                o_inst_finish = 1;
            end
            {7'b0110011,3'b000,1'b1}: begin
                // SUB
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r - i_rs2_value_r;
                o_inst_finish = 1;
            end
            {7'b0110011,3'b100,1'b?}: begin
                // XOR
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r ^ i_rs2_value_r;
                o_inst_finish = 1;
            end
            {7'b0110011,3'b110,1'b?}: begin
                // OR
                o_inst_valid = 0;
                o_wb_valid = 1;
                o_wb_rd = rd;
                o_wb_value = i_rs1_value_r | i_rs2_value_r;
                o_inst_finish = 1;
            end
            {7'b0110011,3'b111,1'b?}: begin
                // AND
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