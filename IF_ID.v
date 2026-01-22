`include "D:\FPGA\Code\J1Sc\ZP2\defines.v"

module IF_ID#(
    parameter ADDR_WIDTH = 13,       // 指令地址宽度，最大支持 8KB ROM
    parameter DATA_WIDTH = 16
)(
	input wire         				clk          	,
	input wire         				rst_n        	,
	//from ex
	input wire  	   		  		jump_flag_i		,
	//from if
	input wire[ADDR_WIDTH-1:0] 		pc_i			,
	input wire[DATA_WIDTH-1:0] 		inst_i			,
	input wire [DATA_WIDTH-1:0] 	T_m_i			,	

	//to id      
	output wire [DATA_WIDTH-1:0] 	inst_o			,
	output wire [DATA_WIDTH-1:0] 	T_m_o			,
	output wire [ADDR_WIDTH-1:0] 	pc_o				
);
	
	DFF_SET 
	#
	(
		.DW(ADDR_WIDTH)
	) 
	dff1
	(
		.clk        (clk        ),
		.rst_n      (rst_n      ),
		.hold_flag_i(jump_flag_i),
		.set_data   ({ADDR_WIDTH{1'b0}}),
	    .data_i     (pc_i),
        .data_o     (pc_o)
	);
		
	DFF_SET 
	#
	(
		.DW(DATA_WIDTH)
	) 
	dff2
	(
		.clk        (clk          ),
		.rst_n      (rst_n          ),
		.hold_flag_i(jump_flag_i  ),
		.set_data   (`INST_NOP),
	    .data_i     (inst_i   ),
        .data_o     (inst_o   )
	);
	
	DFF_SET 
	#
	(
		.DW(DATA_WIDTH)
	) 
	dff3
	(
		.clk        (clk          ),
		.rst_n      (rst_n        ),
		.hold_flag_i(jump_flag_i  ),
		.set_data   ({DATA_WIDTH{1'b0}}),
	    .data_i     (T_m_i   ),
        .data_o     (T_m_o   )
	);
		
endmodule


