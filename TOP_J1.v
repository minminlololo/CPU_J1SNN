module TOP_J1#(
    parameter ADDR_WIDTH = 13,       // 指令地址宽度，最大支持 8KB ROM
    parameter DATA_WIDTH = 16
)
(
	input  wire        clk          ,
	input  wire        rst_n        ,
    output reg         led
);

//pc
	
	//pc to if
	wire [12:0] pc_inst_addr_o  	;
	
//Dual_Port_Mem	
	//Dual_Port_Mem to if
	wire [15:0] mem_inst_o			;
	wire [15:0] mem_T_m_o			;
	wire [15:0] mem_pc_o			;

//if
	//if to if_id
	wire [15:0] if_inst_o			;     
	wire [15:0] if_T_m_o     		;    

//if_id 
	wire [15:0] if_id_inst_o		;
	wire [15:0] if_id_T_m_o 		;
	wire [12:0] if_id_inst_addr_o	;
	
//id 
	wire [15:0] id_inst_o			;
	wire [12:0] id_inst_addr_o		;
	wire [3:0]  id_sel_o			;
	wire [15:0] id_Immediate_o 		;
	wire [15:0] id_return_alu_o		;
	wire [3:0]  id_stack_alu_o 		;
	wire [3:0]  id_funct_op_o    	;
	wire 	    id_mix_alu_o		;
	wire [12:0] id_target_o			;
	wire [15:0] id_T_m_o			;
	wire [1:0]	id_enc_sel_o		;
//id_ex 
	
	wire [DATA_WIDTH-1:0] id_ex_inst_o		;	
	wire [ADDR_WIDTH-1:0] id_ex_inst_addr_o ;
	wire [3:0]  		  id_ex_sel_o		;
	wire [DATA_WIDTH-1:0] id_ex_Immediate_o ;
	wire [DATA_WIDTH-1:0] id_ex_return_alu_o;
	wire [3:0]  		  id_ex_stack_alu_o ;
	wire [3:0]  		  id_ex_funct_op_o  ;
	wire  		  		  id_ex_mix_alu_o	;
	wire [ADDR_WIDTH-1:0] id_ex_target_o	;
	wire [1:0]			  id_ex_enc_sel_o	;
	wire [DATA_WIDTH-1:0] id_ex_T_m_o		;

//ex 
	//ex to ex_wb
	wire [3 :0] ex_alu_type_o		;
	wire [7 :0] ex_dsp_n_o			;	
	wire [7 :0] ex_rsp_n_o			;	
	wire 	    ex_dsk_wen_o		;	
	wire 	    ex_rsk_wen_o		;	
	wire [15:0] ex_rsk_data_o		;	
	wire [15:0] ex_dsk_data_o		;	
	wire [15:0] ex_dsk_data_n_o		;
	//ex to if_id,id_ex,
	wire [12:0] ex_jump_addr_o		;
    wire 		ex_jump_flag_o		;	
	wire 	 	ex_call_en_o		;
	//ex to Dual_Port_Mem
	wire        ex_mem_ren_o		;	
	wire        ex_mem_wen_o		;	
	//ex to if_id,id_ex
	wire        ex_hold_flag_o		;	
	
	//ex to ctrl_fsm
	wire        ex_enc_sel_o		;
	wire        ex_pre_start_o		;
	wire        ex_enc_start_o		;
	wire        ex_snn_start_o		;
	wire        ex_clear_o			;
	wire        ex_wait_snn_o		;
	wire        ex_output_snn_o		;

	
//ex_wb 
	wire [7 :0] ex_wb_dsp_n_o		;	
	wire [7 :0] ex_wb_rsp_n_o		;	
	wire 	    ex_wb_dsk_wen_o		;	
	wire 	    ex_wb_rsk_wen_o		;	
	wire [15:0] ex_wb_rsk_data_o	;	
	wire [15:0] ex_wb_dsk_data_o	;	
	wire [15:0] ex_wb_dsk_data_n_o	;
	wire [12:0] ex_wb_jump_addr_o	;
    wire 		ex_wb_jump_flag_o	;	
	wire 	 	ex_wb_call_en_o		;
	wire        ex_wb_mem_ren_o		;	
	wire        ex_wb_mem_wen_o		;	
	wire        ex_wb_hold_flag_o	;	
	
//wb 
	wire [7:0] 	wb_dsp_o			;
	wire [7:0] 	wb_rsp_o			;
	wire [15:0]	wb_T_o				;
	wire [15:0] wb_R_o				;

//retuen_stack
	wire [7:0] retuen_stack_rsp_o 	;
	wire [15:0]return_stack_R_o   	;
//data_stack
	//data_stack to Dual_Port_Mem
	wire [15:0] data_stack_T_o		;
	wire [15:0] data_stack_N_o		;
	
	wire [7:0]  data_stack_dsp_o	;

	PC PC_inst
	(
		.clk                 (clk               ),
		.rst_n               (rst_n             ),
		.jump_addr_i         (ex_jump_addr_o ),
		.jump_flag           (ex_jump_flag_o ),
		.hold_flag_i         (ex_hold_flag_o ),
		.call_en 			 (ex_call_en_o 	 ),
		.pc_o		 		 (pc_inst_addr_o  	)
	);
	
	Dual_Port_Mem Dual_Port_Mem_inst
	(
		.clk   				(clk  ),					
		.rst_n				(rst_n),
		.addr_a				(pc_inst_addr_o),
		.dout_a 			(mem_inst_o),	
		
		.pc_o				(mem_pc_o),
		.T					(data_stack_T_o),		
		.N					(data_stack_N_o),	
		.mem_ren			(ex_mem_ren_o  ),		
		.mem_wen			(ex_mem_wen_o  ),		
	    .dout_b				(mem_T_m_o     )	
	);
	
	IF IF_inst
	(		
		.inst 				(mem_inst_o	),	
		.T_m				(mem_T_m_o	),	
		.pc	  				(mem_pc_o	),
		.jump_flag			(ex_jump_flag_o),	
		.inst_out			(if_inst_o	),		
		.T_m_o				(if_T_m_o)
	
	);
	
	IF_ID IF_ID_inst
	(	
		.clk 				(clk   			),	        
		.rst_n 				(rst_n			),	     
		.jump_flag_i		(ex_jump_flag_o	),		
		.pc_i				(pc_inst_addr_o	),	
		.inst_i				(if_inst_o		),	
		.T_m_i				(if_T_m_o		),		
		.inst_o				(if_id_inst_o	),	
		.T_m_o				(if_id_T_m_o 	),
		.pc_o				(if_id_inst_addr_o)
	);
	
	ID ID_inst
	(
		.inst_addr_i		(if_id_inst_addr_o),	 
		.inst_i    			(if_id_inst_o	),	 
		.T_m_i				(if_id_T_m_o	),
		
		.inst_o      		(id_inst_o		),	     
		.inst_addr_o 		(id_inst_addr_o	),		 
		.sel				(id_sel_o		),			
		.Immediate 			(id_Immediate_o ),	
		.return_alu			(id_return_alu_o),	
		.stack_alu 			(id_stack_alu_o ),	
		.funct_op    		(id_funct_op_o  ),	
		.mix_alu			(id_mix_alu_o	),		
		.target				(id_target_o	),	
		.enc_sel			(id_enc_sel_o  	),
		.T_m_o				(id_T_m_o		)
	);
	
	ID_EX ID_EX_inst
	(
		.clk            	(clk   			),	
		.rst_n          	(rst_n			),
		.jump_flag_i    	(ex_jump_flag_o	),
		.inst_i				(id_inst_o		),	
		.inst_addr_i	  	(id_inst_addr_o	),
		.sel_i				(id_sel_o		), 	
		.Immediate_i  		(id_Immediate_o ),
		.return_alu_i	 	(id_return_alu_o),
		.stack_alu_i  		(id_stack_alu_o ),
		.funct_op_i     	(id_funct_op_o  ),
		.mix_alu_i			(id_mix_alu_o	), 	
		.target_i			(id_target_o	),
		.enc_sel_i			(id_enc_sel_o   ),
		.T_m_i				(id_T_m_o		),
		
		.inst_o				(id_ex_inst_o		),
		.inst_addr_o		(id_ex_inst_addr_o 	),
		.sel_o				(id_ex_sel_o		),
		.Immediate_o 		(id_ex_Immediate_o 	),
		.return_alu_o		(id_ex_return_alu_o ), 		
//		.stack_alu_o 		(id_ex_stack_alu_o 	),
		.funct_op_o    		(id_ex_funct_op_o   ),
		.mix_alu_o			(id_ex_mix_alu_o	),
		.target_o			(id_ex_target_o		),
		.enc_sel_o			(id_ex_enc_sel_o	),
		.T_m_o				(id_ex_T_m_o		)
		
	);
	
	EX EX_inst
	(
		.inst    			(id_ex_inst_o		),
		.inst_addr			(id_ex_inst_addr_o 	),
		.sel       			(id_ex_sel_o		), 
		.Immediate 			(id_ex_Immediate_o 	), 
		.return_alu 		(id_ex_return_alu_o ),  
//		.stack_alu 			(id_ex_stack_alu_o 	), 
		.funct_op    		(id_ex_funct_op_o   ), 
		.mix_alu   			(id_ex_mix_alu_o	), 
		.target    			(id_ex_target_o		), 
		.enc_sel			(id_ex_enc_sel_o	),
		.T_m       			(id_ex_T_m_o		), 
		.dsp				(data_stack_dsp_o	),	
		.T					(data_stack_T_o		),
		.N					(data_stack_N_o		),
		.rsp				(retuen_stack_rsp_o ),	
		.R					(return_stack_R_o   ),
		
		.alu_type			(ex_alu_type_o		),
		.dsp_n				(ex_dsp_n_o			),
		.rsp_n				(ex_rsp_n_o			),
		.dsk_wen			(ex_dsk_wen_o		),	
		.rsk_wen			(ex_rsk_wen_o		),	
		.rsk_data			(ex_rsk_data_o		),
		.dsk_data			(ex_dsk_data_o		),
		.jump_addr			(ex_jump_addr_o		),
		.jump_flag			(ex_jump_flag_o		),
		.call_en			(ex_call_en_o		),	
		.mem_ren			(ex_mem_ren_o		),	
		.mem_wen			(ex_mem_wen_o		),
		.hold_flag			(ex_hold_flag_o		),
		
		.enc_sel_o			(ex_enc_sel_o		),
		.pre_start 			(ex_pre_start_o		),          
		.enc_start 			(ex_enc_start_o		),  
		.snn_start 			(ex_snn_start_o		), 
		.clear	  			(ex_clear_o			), 
		.wait_snn  			(ex_wait_snn_o		),   
		.output_snn			(ex_output_snn_o	)
	);
	
	EX_WB EX_WB_inst
	(
		.clk		 		(clk   			),	
		.rst_n				(rst_n			),
		.dsp_n_i	 		(ex_dsp_n_o		),	
		.rsp_n_i	 		(ex_rsp_n_o		),	
		.dsk_wen_i	 		(ex_dsk_wen_o	),
		.rsk_wen_i	 		(ex_rsk_wen_o	),
		.rsk_data_i	 		(ex_rsk_data_o	),
		.dsk_data_i	 		(ex_dsk_data_o	),
		.jump_addr_i 		(ex_jump_addr_o	),	
		.jump_flag_i 		(ex_jump_flag_o	),	
		.call_en_i	 		(ex_call_en_o	),
		.mem_ren_i	 		(ex_mem_ren_o	),
		.mem_wen_i	 		(ex_mem_wen_o	),
		.hold_flag_i 		(ex_hold_flag_o	),	
		
		.dsp_n_o	 		(ex_wb_dsp_n_o		),	
		.rsp_n_o	 		(ex_wb_rsp_n_o		),	
		.dsk_wen_o			(ex_wb_dsk_wen_o	),
		.rsk_wen_o	 		(ex_wb_rsk_wen_o	),
		.rsk_data_o			(ex_wb_rsk_data_o	),
		.dsk_data_o			(ex_wb_dsk_data_o	),
		.jump_addr_o 		(ex_wb_jump_addr_o	),	
		.jump_flag_o 		(ex_wb_jump_flag_o	),	
		.call_en_o	 		(ex_wb_call_en_o	),
		.mem_ren_o	 		(ex_wb_mem_ren_o	),
		.mem_wen_o	 		(ex_wb_mem_wen_o	),	
		.hold_flag_o 		(ex_wb_hold_flag_o	)
	);
	
	
	WB WB_inst
	(
		.dsk_data			(ex_wb_dsk_data_o),
		.rsk_data			(ex_wb_rsk_data_o),
		.dsp_n_i			(ex_wb_dsp_n_o),
		.rsp_n_i			(ex_wb_rsp_n_o),
		.dsk_wen 			(ex_wb_dsk_wen_o),	
		.rsk_wen 			(ex_wb_rsk_wen_o),	
		
		.dsp_n_o	 		(wb_dsp_o),	
		.rsp_n_o	 		(wb_rsp_o),	
		.T		 			(wb_T_o	),
		.R		 			(wb_R_o	)
	);
	
	return_stack return_stack_inst
	(
		.clk				(clk   ), 	  
		.rst_n				(rst_n),  
		.rsk_data			(ex_wb_rsk_data_o),
		.rsp_n				(ex_wb_rsp_n_o),
		.rsk_wen			(ex_wb_rsk_wen_o), 	 
		
		.R					(return_stack_R_o),
		.rsp    			(retuen_stack_rsp_o)
	); 
	
	data_stack data_stack_inst(
		.clk	 			(clk  ),
		.rst_n				(rst_n),
		.dsk_data			(ex_wb_dsk_data_o),
		.dsp_n				(ex_wb_dsp_n_o),
		.dsk_wen 			(ex_wb_dsk_wen_o),
		
		.T					(data_stack_T_o	),
		.N					(data_stack_N_o	),
		.dsp	 			(data_stack_dsp_o)
		
	);
	
	/*  pll_pll_clk_wiz inst
       (.clk_in1(clk_in1),
        .clk_out1(clk_out1
		),
        .locked(locked),
        .reset(reset));
		*/
		
		
		
endmodule


