`include "D:\FPGA\Code\J1Sc\ZP2\defines.v"

module ID_EX#(
    parameter ADDR_WIDTH = 13,       // 指令地址宽度，最大支持 8KB ROM
    parameter DATA_WIDTH = 16
)
(
	input wire         			clk            	,
	input wire         			rst_n           ,
	//from ctrl                       
	input wire 	  				jump_flag_i    	,
	//from id                         
	input wire [DATA_WIDTH-1:0] inst_i			,      
	input wire [ADDR_WIDTH-1:0] inst_addr_i		,    
	input wire [3:0]  			sel_i			,     
	input wire [DATA_WIDTH-1:0] Immediate_i 	,        
	input wire 		  			return_alu_i	,         
	input wire [3:0]  			stack_alu_i 	, 
	input wire [3:0]  			funct3_i    	,     // 功能码
	input wire [3:0]  			mix_alu_i		,
	input wire [ADDR_WIDTH-1:0] target_i		,
	input wire [1:0]			enc_sel_i		,
	input wire [DATA_WIDTH-1:0] T_m_i			,
	//to ex                         
	output wire [DATA_WIDTH-1:0] inst_o			,      
	output wire [ADDR_WIDTH-1:0] inst_addr_o	,    
	output wire [3:0]  			 sel_o			,     
	output wire [DATA_WIDTH-1:0] Immediate_o 	,        
	output wire 		  		 return_alu_o	,         
	output wire [3:0]  			 stack_alu_o 	, 
	output wire [3:0]  			 funct3_o    	,     // 功能码
	output wire [3:0]  			 mix_alu_o		,
	output wire [ADDR_WIDTH-1:0] target_o		,
	output wire [1:0]            enc_sel_o		,
	output wire [DATA_WIDTH-1:0] T_m_o			
);
	DFF_SET #(.DW(DATA_WIDTH)) dff_inst       (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data(`INST_NOP), 			.data_i(inst_i),      	.data_o(inst_o));
    DFF_SET #(.DW(ADDR_WIDTH)) dff_pc         (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data({ADDR_WIDTH{1'b0}}),  .data_i(inst_addr_i), 	.data_o(inst_addr_o));
    DFF_SET #(.DW(4))          dff_sel        (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data(4'b0),          		.data_i(sel_i),         .data_o(sel_o));
    DFF_SET #(.DW(DATA_WIDTH)) dff_imm        (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data({DATA_WIDTH{1'b0}}),  .data_i(Immediate_i),   .data_o(Immediate_o));
    DFF_SET #(.DW(1))          dff_ret        (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data(1'b0),          		.data_i(return_alu_i),  .data_o(return_alu_o));
    DFF_SET #(.DW(4))          dff_stack_alu  (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data(4'b0),          		.data_i(stack_alu_i),   .data_o(stack_alu_o));
    DFF_SET #(.DW(4))          dff_funct3     (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data(4'b0),          		.data_i(funct3_i),      .data_o(funct3_o));
    DFF_SET #(.DW(4))          dff_mix_alu    (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data(4'b0),          		.data_i(mix_alu_i),     .data_o(mix_alu_o));
    DFF_SET #(.DW(ADDR_WIDTH)) dff_target     (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data({ADDR_WIDTH{1'b0}}),  .data_i(target_i),      .data_o(target_o));
    DFF_SET #(.DW(DATA_WIDTH)) dff_tm         (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data({DATA_WIDTH{1'b0}}),  .data_i(T_m_i),         .data_o(T_m_o));
	DFF_SET #(.DW(2)) 		   dff_enc_sel    (.clk(clk), .rst_n(rst_n), .hold_flag_i(jump_flag_i), .set_data(2'b0), 				.data_i(enc_sel_i),    .data_o(enc_sel_o));


endmodule	