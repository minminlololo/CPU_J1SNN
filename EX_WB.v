module EX_WB
(
	input				clk			,
	input				rst_n		,
	
	input wire  [7 :0] 	dsp_n_i		,
	input wire  [7 :0] 	rsp_n_i		,
	input wire         	dsk_wen_i	,
	input wire 		   	rsk_wen_i	,
	input wire  [15:0] 	rsk_data_i	,
	input wire  [15:0] 	dsk_data_i	,
	//from pc	
	input wire  [12:0] 	jump_addr_i	,
	input wire         	jump_flag_i	,
	input wire         	call_en_i	,	
	//from mem	
	input wire  	   	mem_ren_i	,
	input wire 		   	mem_wen_i	,
	input wire		   	hold_flag_i	,
	
	
	output wire  [7 :0] dsp_n_o		,
	output wire  [7 :0] rsp_n_o		,
	output wire         dsk_wen_o	,
	output wire 		rsk_wen_o	,
	output wire  [15:0] rsk_data_o	,
	output wire  [15:0] dsk_data_o	,
	//to pc
	output wire  [12:0] jump_addr_o	,
	output wire         jump_flag_o	,
	output wire         call_en_o	,
	//to mem
	output wire  	  	mem_ren_o	,
	output wire 		mem_wen_o	,
	output wire		   	hold_flag_o
	
	
	
	
);
	DFF_SET #(.DW(8))  u_dsp_n     (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(8'b0),  .data_i(dsp_n_i),      .data_o(dsp_n_o));
	DFF_SET #(.DW(8))  u_rsp_n     (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(8'b0),  .data_i(rsp_n_i),      .data_o(rsp_n_o));
	DFF_SET #(.DW(1))  u_dsk_wen   (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(1'b0),  .data_i(dsk_wen_i),    .data_o(dsk_wen_o));
	DFF_SET #(.DW(1))  u_rsk_wen   (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(1'b0),  .data_i(rsk_wen_i),    .data_o(rsk_wen_o));
	DFF_SET #(.DW(16)) u_rsk_data  (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(16'b0), .data_i(rsk_data_i),   .data_o(rsk_data_o));
	DFF_SET #(.DW(16)) u_dsk_data  (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(16'b0), .data_i(dsk_data_i),   .data_o(dsk_data_o));
	DFF_SET #(.DW(13)) u_jump_addr (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(13'b0), .data_i(jump_addr_i),  .data_o(jump_addr_o));
	DFF_SET #(.DW(1))  u_jump_flag (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(4'b0),  .data_i(jump_flag_i),  .data_o(jump_flag_o));
	DFF_SET #(.DW(1))  u_call_en   (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(1'b0),  .data_i(call_en_i),    .data_o(call_en_o));
	DFF_SET #(.DW(1))  u_mem_ren   (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(1'b0),  .data_i(mem_ren_i),    .data_o(mem_ren_o));
	DFF_SET #(.DW(1))  u_mem_wen   (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(1'b0),  .data_i(mem_wen_i),    .data_o(mem_wen_o));
	DFF_SET #(.DW(1))  u_hold_flag (.clk(clk), .rst_n(rst_n), .hold_flag_i(1'b0),.set_data(1'b0),  .data_i(hold_flag_i),  .data_o(hold_flag_o));

	

endmodule