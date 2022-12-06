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

reg [31:0] inst;
reg inst_valid;
reg [6:0] opcode;
reg [DATA_W-1:0] I_imm;
reg [DATA_W-1:0] S_imm;
reg [DATA_W-1:0] SB_imm;
reg [4:0] rs1;
reg [4:0] rs2;
reg [4:0] rd;
reg [2:0] func3;

reg                 _o_i_valid_addr = 1;
reg [ADDR_W-1:0]    _o_i_addr = 0;
reg [DATA_W-1:0]    _o_d_w_data;
reg [ADDR_W-1:0]    _o_d_r_addr;
reg [ADDR_W-1:0]    _o_d_w_addr;
reg                 _o_d_MemRead = 0;
reg                 _o_d_MemWrite = 0;
reg                 _o_finish = 0;

reg [DATA_W-1:0] reg_file [31:0];
reg [4:0] start_tmr = 30;
reg [4:0] tmr = 0;

initial begin
    for (i=0;i<=31;i=i+1)
        reg_file[i] = 0;
end

integer i;
always@(posedge i_clk) begin
    if (start_tmr > 0) begin
        start_tmr = start_tmr - 1;
    end
    else begin 
        tmr = tmr + 1;
        if (tmr == 10) begin
            tmr = 0;
        end 
    end
    // $display("tmr: %d", tmr);

    if (tmr == 3) begin
        inst = i_i_inst;
        opcode = inst[6:0];
        I_imm  = $signed(inst[31:20]);
        S_imm  = $signed({{inst[31:25]}, {inst[11:7]}});
        SB_imm = $signed({{inst[31]}, {inst[7]}, {inst[30:25]}, {inst[11:8]}, 1'b0});
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        rd = inst[11:7];
        func3 = inst[14:12];
        inst_valid = 1;
    end

    if (inst_valid && inst == 32'b11111111111111111111111111111111) begin
        // EOF
        _o_finish = 1;
    end
    else if (inst_valid && opcode == 7'b0000011) begin
        // LD
        if (tmr == 3) begin
            if (rd == 0) begin
                inst_valid = 0;
                _o_i_addr = _o_i_addr + 4;
            end
            else begin
                _o_d_r_addr = reg_file[rs1] + I_imm;
                _o_d_MemRead = 1;
            end
        end
        else if (tmr == 6) begin
            reg_file[rd] = i_d_data;
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
    end
    else if (inst_valid && opcode == 7'b0100011) begin
        // SD
        if (tmr == 3) begin
            _o_d_w_addr = reg_file[rs1] + S_imm;
            _o_d_w_data = reg_file[rs2];
            _o_d_MemWrite = 1;
        end
        else if (tmr == 4) begin
            _o_d_MemWrite = 0;
        end
        else if (tmr == 5) begin
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
    end
    else if (inst_valid && opcode == 7'b1100011 && func3 == 3'b000) begin
        // BEQ
        if (reg_file[rs1] == reg_file[rs2]) begin
            _o_i_addr = _o_i_addr + SB_imm;
        end
        else begin
            _o_i_addr = _o_i_addr + 4;
        end
        inst_valid = 0;
    end
    else if (inst_valid && opcode == 7'b1100011 && func3 == 3'b001) begin
        // BNE
        if (reg_file[rs1] != reg_file[rs2]) begin
            _o_i_addr = _o_i_addr + SB_imm;
        end
        else begin
            _o_i_addr = _o_i_addr + 4;
        end
        inst_valid = 0;
    end
    else if (inst_valid) begin
        if (rd != 0) begin
            if (opcode == 7'b0010011 && func3 == 3'b000) begin
                // ADDI
                reg_file[rd] = reg_file[rs1] + I_imm;
            end
            else if (opcode == 7'b0010011 && func3 == 3'b100) begin
                // XORI
                reg_file[rd] = reg_file[rs1] ^ I_imm;
            end
            else if (opcode == 7'b0010011 && func3 == 3'b110) begin
                // ORI
                reg_file[rd] = reg_file[rs1] | I_imm;
            end
            else if (opcode == 7'b0010011 && func3 == 3'b111) begin
                // ANDI
                reg_file[rd] = reg_file[rs1] & I_imm;
            end
            else if (opcode == 7'b0010011 && func3 == 3'b001) begin
                // SLLI
                reg_file[rd] = reg_file[rs1] << I_imm;
            end
            else if (opcode == 7'b0010011 && func3 == 3'b101) begin
                // SRLI
                reg_file[rd] = reg_file[rs1] >> I_imm;
            end
            else if (opcode == 7'b0110011 && func3 == 3'b000 && inst[31:25] == 7'b0000000) begin
                // ADD
                reg_file[rd] = reg_file[rs1] + reg_file[rs2];
            end
            else if (opcode == 7'b0110011 && func3 == 3'b000 && inst[31:25] == 7'b0100000) begin
                // SUB
                reg_file[rd] = reg_file[rs1] - reg_file[rs2];
            end
            else if (opcode == 7'b0110011 && func3 == 3'b100) begin
                // XOR
                reg_file[rd] = reg_file[rs1] ^ reg_file[rs2];
            end
            else if (opcode == 7'b0110011 && func3 == 3'b110) begin
                //OR
                reg_file[rd] = reg_file[rs1] | reg_file[rs2];
            end
            else if (opcode == 7'b0110011 && func3 == 3'b111) begin
                // AND
                reg_file[rd] = reg_file[rs1] & reg_file[rs2];
            end
        end
        inst_valid = 0;
        _o_i_addr = _o_i_addr + 4;
    end
end

assign o_i_valid_addr   = _o_i_valid_addr;
assign o_i_addr         = _o_i_addr;
assign o_d_w_data       = _o_d_w_data;
assign o_d_r_addr       = _o_d_r_addr;
assign o_d_w_addr       = _o_d_w_addr;
assign o_d_MemRead      = _o_d_MemRead;
assign o_d_MemWrite     = _o_d_MemWrite;
assign o_finish         = _o_finish;

endmodule
