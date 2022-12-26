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
reg [2:0] tmr = 7;

initial begin
    for (i=0;i<=31;i=i+1)
        reg_file[i] = 0;
end

reg sA = 0;
reg sB = 0;
integer i;

always@(posedge i_rst_n or negedge i_rst_n) begin
    if (i_rst_n) begin
        sA = 1;
    end
    else begin
        sB = 1;
        sA = 0;
    end
end

always@(posedge i_clk) begin
    case (tmr)
        0: tmr = 1;
        1: tmr = 2;
        2: tmr = 3;
        3: tmr = 4;
        4: tmr = 5;
        5: tmr = 6;
        6: tmr = 7;
        7: tmr = (sA && sB) ? 0 : 7;
        default: tmr = 0;
    endcase

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

    casez({inst_valid,opcode,func3,inst[30]})
        {1'b1,7'b1111111,3'b???,1'b?}: begin
            // EOF
            _o_finish = 1;
        end
        {1'b1,7'b0000011,3'b???,1'b?}: begin
            // LD
            if (tmr == 3) begin
                _o_d_r_addr = {{reg_file[rs1][63:10]}, {reg_file[rs1][9:0]} + {I_imm[9:0]}};
                _o_d_MemRead = 1;
            end
            else if (tmr == 4) begin
                _o_d_MemRead = 0;
            end
            else if (tmr == 6) begin
                reg_file[rd] = i_d_data;
                inst_valid = 0;
                _o_i_addr = {{_o_i_addr[63:8]}, {_o_i_addr[7:0]} + 8'd4};
            end
        end
        {1'b1,7'b0100011,3'b???,1'b?}: begin
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
        {1'b1,7'b1100011,3'b000,1'b?}: begin
            // BEQ
            if (reg_file[rs1] == reg_file[rs2]) begin
                _o_i_addr = _o_i_addr + SB_imm;
            end
            else begin
                _o_i_addr = _o_i_addr + 4;
            end
            inst_valid = 0;
        end
        {1'b1,7'b1100011,3'b001,1'b?}: begin
            // BNE
            if (reg_file[rs1] != reg_file[rs2]) begin
                _o_i_addr = _o_i_addr + SB_imm;
            end
            else begin
                _o_i_addr = _o_i_addr + 4;
            end
            inst_valid = 0;
        end
        {1'b1,7'b0010011,3'b000,1'b?}: begin
            // ADDI
            reg_file[rd] = reg_file[rs1] + I_imm;
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0010011,3'b100,1'b?}: begin
            // XORI
            reg_file[rd] = reg_file[rs1] ^ I_imm;
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0010011,3'b110,1'b?}: begin
            // ORI
            reg_file[rd] = reg_file[rs1] | I_imm;
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0010011,3'b111,1'b?}: begin
            // ANDI
            reg_file[rd] = reg_file[rs1] & I_imm;
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0010011,3'b001,1'b?}: begin
            // SLLI
            reg_file[rd] = reg_file[rs1] << I_imm;
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0010011,3'b101,1'b?}: begin
            // SRLI
            reg_file[rd] = reg_file[rs1] >> I_imm;
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0110011,3'b000,1'b0}: begin
            // ADD
            reg_file[rd] = reg_file[rs1] + reg_file[rs2];
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0110011,3'b000,1'b1}: begin
            // SUB
            reg_file[rd] = reg_file[rs1] - reg_file[rs2];
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0110011,3'b100,1'b?}: begin
            // XOR
            reg_file[rd] = reg_file[rs1] ^ reg_file[rs2];
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0110011,3'b110,1'b?}: begin
            //OR
            reg_file[rd] = reg_file[rs1] | reg_file[rs2];
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
        {1'b1,7'b0110011,3'b111,1'b?}: begin
            // AND
            reg_file[rd] = reg_file[rs1] & reg_file[rs2];
            inst_valid = 0;
            _o_i_addr = _o_i_addr + 4;
        end
    endcase
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
