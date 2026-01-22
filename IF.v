module IF #(
    parameter ADDR_WIDTH = 13,       // 指令地址宽度，最大支持 8KB ROM
    parameter DATA_WIDTH = 16
)(
	//from dual_port_mem
   
	input   [DATA_WIDTH-1:0] inst 			,//dout_a
	input   [DATA_WIDTH-1:0] T_m			,//dout_b
	//from 	pc	             
    input   [ADDR_WIDTH-1:0] pc	  			,      // 当前PC（从寄存器中读出）
    input          			 jump_flag		,    // 跳转使能（控制来自 EX 或 decode 阶段）
    //to    
    output  [DATA_WIDTH-1:0] inst_out		,   // 输出当前指令（传给ID阶段）
	output  [DATA_WIDTH-1:0] T_m_o			
);
	
    // 从ROM中读取指令（注意按16位对齐）
    assign inst_out = inst;
	
	assign T_m_o = T_m;
	
    
endmodule
