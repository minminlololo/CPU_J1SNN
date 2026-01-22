module top_preprocess (
    input  wire         clk,
    input  wire         rst_n,

    input  wire         start,
    output wire         done,

    // DDR3 AXI（只写）
    output wire [31:0]  axi_awaddr,
    output wire [31:0]  axi_wdata,
    output wire         axi_wvalid
);

    /**********************************************
     * 0. Image BRAM（photo.coe）
     **********************************************/
    image_mem u_image_bram ( // <--- 你需要确保 "photo_input" 是你图像BRAM IP核的正确模块名
        .clka   (clk),
        .ena    (img_loader_bram_ena),
        .addra  (img_loader_bram_addr),
        .douta  (img_bram_dout_raw)
    );
	
	
	// -------------------------------------
    // 1. 实例化图像加载器 (Image Loader)
    // -------------------------------------
	image_loader u_image_loader#(
    // --- 用户可配置的逻辑参数 ---
    .P_NUM_INPUT_PIXELS       = 784, // 图像总像素数 (28x28)
    .P_PIXEL_INTENSITY_BITS   = 8,   // 单个像素的位宽

    // --- 描述 外部图像 BRAM IP核的固定特性 ---
    .P_IMAGE_BRAM_DATA_WIDTH  = 64,  // 图像BRAM的数据输出端口位宽
    .P_IMAGE_BRAM_DEPTH       = 98   // 图像BRAM的有效存储字数 (98个64位的字)
	) (
	   .clk					(clk				),	
	   .rst_n				(rst_n				),	
	   .i_load_image_start	(load_image_start	),		// 启动图像加载的脉冲信号
	   .i_bram_dout_raw		(bram_dout_raw		),	   	// 每一次从图像BRAM读出的数据
		 
	   .o_bram_addr			(bram_addr			),	    // 输出给图像BRAM的地址
	   .o_bram_ena			(bram_ena			),	 	// 输出给图像BRAM的使能信号
		 
	   .o_image_buffer_out	(image_buffer_out	),		// 完整	的图片数据数组
	   .o_loading_busy		(loading_busy		),		// 图像加载忙信号
	   .o_load_done         (load_done       	)	 	// 图像加载完成脉冲信号，单周期脉冲
	);                                          
	
    /**********************************************
     * 2. weight Loader
     **********************************************/
    wire [15:0] weight_data;
    wire [15:0] weight_addr;

    weight_bram u_weight_bram (
		.clka (clk),
		.ena  (1'b1),       //通过指令给
		.addra(weight_addr),
		.douta(weight_data)
		);
		
	/**********************************************
     * 3. BRAM_double_part 
     **********************************************/
	bram_double_part #(
		.DATA_WIDTH (8 ), 
		.ADDR_WIDTH (16)   // 能覆盖 2*IMG_W*IMG_H
		)(
		.clk	(),
		.rst_n	(),
		// -------- Port A : Read --------
		.rd_en	(rd_en),
		.rd_addr(rd_addr),
		.rd_data(rd_data),

		// -------- Port B : Write -------
		.wr_en	(gauss_valid),
		.wr_addr(),					//???
		.wr_data(gauss_out)
	);
	
	/**********************************************
     * bram_reader
    **********************************************/
	frame_reader #(
    .IMG_WIDTH (220),
    .IMG_HEIGHT(168),
    .ADDR_WIDTH(16 )
	)(
    .clk					(clk			),
    .rst_n					(rst_n			),
    .start					(ctrl_fsm_pre_start_o),
				
    // BRAM
   .rd_en					(rd_en			),
   .rd_addr					(rd_addr		),
   .rd_data					(rd_data		),

    // To Gaussian
    .pixel_out				(pixel_in		),
    .pixel_valid			(pixel_valid	),
    .line_end				(line_end		),
    .frame_end  			(frame_end		)
	);
	
	
	
    /**********************************************
     * 4.Preprocess
     **********************************************/
	gaussian u_gaussian (
		.clk				(clk			),
		.rst_n				(rst_n			),

		.pixel_in			(pixel_in		),
		.pixel_valid		(pixel_valid	),
		.line_end			(line_end		),
		.frame_end			(frame_end		),

		.pixel_out			(gauss_out		),
		.pixel_valid_out	(gauss_valid	),
		.line_end_out		(gauss_line_end	),
		.frame_end_out		(gauss_frame_end)
	);

    /**********************************************
     * 4. Ctrl Fsm
     **********************************************/
	 wire ctrl_fsm_pre_start_o  ;
	 wire ctrl_fsm_enc_start_o  ;
	 wire ctrl_fsm_snn_start_o  ;
	 wire ctrl_fsm_ctrl_busy_o  ;
	 wire ctrl_fsm_ctrl_done_o  ;
								;
	ctrl_fsm (
    . clk			(clk		),
    . rst_n			(rst_n		),
					 
    . ctrl_valid	(ctrl_valid	),
    . funct_op		(funct_op	),  
					 
	. enc_sel_o		(enc_sel_o	),
	. clear			(clear		), 
	. wait_snn 		(wait_snn 	),
	. output_snn   	(output_snn ),
					 
    . pre_done		(pre_done	),
    . enc_done		(enc_done	),
    . snn_done		(snn_done	),
	//output				 
    . pre_start		(ctrl_fsm_pre_start_o	),
    . enc_start		(ctrl_fsm_enc_start_o	),
    . snn_start		(ctrl_fsm_snn_start_o	),	 
    . ctrl_busy		(ctrl_fsm_ctrl_busy_o	),
    . ctrl_done	    (ctrl_fsm_ctrl_done_o	) 
);
	

endmodule

