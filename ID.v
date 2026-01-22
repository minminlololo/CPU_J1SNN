`include "D:\FPGA\Code\J1Sc\ZP2\defines.v"
module ID#(
    parameter ADDR_WIDTH = 13,       // 指令地址宽度，最大支持 8KB ROM
    parameter DATA_WIDTH = 16
)
(
	//from if_id
	input wire [ADDR_WIDTH-1:0] inst_addr_i   	,	
	input wire [DATA_WIDTH-1:0] inst_i        	,
	input wire [DATA_WIDTH-1:0] T_m_i			,

	//to id_ex                
	output wire [DATA_WIDTH-1:0] inst_o        	,
	output wire[ADDR_WIDTH-1:0] inst_addr_o  	,  // pc
	output reg [3 :0] 			sel				,
	output reg [DATA_WIDTH-1:0] Immediate 		,  //扩展对齐
	output reg 		  			return_alu		,
//	output reg [3:0]  			stack_alu 		,  //ALU指令的功能码（0~3位）
	output wire[3:0]  			funct_op    	,  // 功能码
	output reg 		  			mix_alu			,
	output reg [ADDR_WIDTH-1:0] target			,
	output reg [1:0]            enc_esl			,
	output wire[DATA_WIDTH-1:0] T_m_o			
);
	
	wire [2:0]  opcode ;
	wire [13:0] imm    ;
	

	// 指令字段分解
    assign opcode 	= inst_i[15:13];  
    assign imm    	= inst_i[13:0 ];   
	assign funct_op = inst_i[12:9 ];
	assign funct_sel= inst_i[ 8:7 ];
		
	//
	assign inst_addr_o = inst_addr_i;
	assign inst_o      = inst_i;
	assign T_m_o       = T_m_i;
	
	//译码
	always @(*)
		begin
		if(opcode[2:1]== 2'b11)   // 立即数（literal）
			begin
				sel = 4'b0001;
                Immediate = {{2{imm[13]}}, imm}; // 符号扩展12位→16位
				target    = {12'b0};
				return_alu = 1'b0;
				mix_alu   = 1'b0;
				enc_esl   = 2'b0;
            end
		else 
		case(opcode)
			`INST_TYPE_CTRL :begin
				if(inst_i == 16'h0000)
				begin
					sel = 4'b0000;           //空操作
					Immediate = 16'b0;
					target    = {12'b0};
					return_alu = 1'b0;
					mix_alu   = 1'b0;
					enc_esl   = 2'b0;
					end
				else 
				begin	
					sel = 4'b0010;
					mix_alu = 1'b1;
					return_alu = 1'b0;
					Immediate = 16'b0;
					target    = {12'b0};
					enc_esl   = funct_sel;
				end
			end
            `INST_TYPE_STA: begin
				sel = 4'b0011;
				Immediate = 16'b0;
				target    = {12'b0};
				return_alu = 1'b0;
				mix_alu   = 1'b0;
				enc_esl   = 2'b0;
            end
			`INST_TYPE_L: begin
				sel = 4'b0100;
				Immediate = 16'b0;
				target    = {{1'b0},inst_i[11:0]};
				return_alu = 1'b0;
				mix_alu   = 1'b0;
				enc_esl   = 2'b0;
            end
            `INST_TYPE_J: begin
				sel = 4'b0101;
				target = inst_i[12:0] ;
				Immediate = 16'b0;
				return_alu = 1'b0;
				mix_alu   = 1'b0;
				enc_esl   = 2'b0;
			end
			`INST_TYPE_CJ:begin   
				sel = 4'b0110;
				target = inst_i[12:0] ;
				Immediate = 16'b0;
				return_alu = 1'b0;
				mix_alu   = 1'b0;
				enc_esl   = 2'b0;
			end
			`INST_TYPE_CALL:begin
				sel = 4'b0111;
				target = inst_i[12:0] ;
				Immediate = 16'b0;
				return_alu = 1'b0;
				mix_alu   = 1'b0;
				enc_esl   = 2'b0;
			end
			default:begin
				sel       = 4'b0000;
				Immediate = 16'b0;
				target    = {13'b0};
				return_alu = 1'b0;
				mix_alu   = 1'b0;
				enc_esl   = 2'b0;
			end
			
		endcase	
	end
	
	
endmodule


