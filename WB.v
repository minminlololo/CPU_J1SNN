module WB
(	
	//from ex_wb
	input wire [15:0]		dsk_data,
	input wire [15:0]		rsk_data,
	input wire [7:0]		dsp_n_i	,
	input wire [7:0]		rsp_n_i	,
	input wire 				dsk_wen	,
	input wire 				rsk_wen	,
	
	//to stack	
	output reg [7:0]	   	dsp_n_o		,
	output reg [7:0] 	   	rsp_n_o		,
	output reg [15:0]		T		,
	output reg [15:0]   	R		
	
);	

	
	always@(*)
	begin
		if(dsk_wen)
			T = dsk_data;
		else 
			T = T;
	end

	always@(*)
	begin
		if(rsk_wen)
			R = rsk_data;
		else 
			R = R;
	end

	always@(*)
	begin
		if(dsk_wen)
			dsp_n_o = dsp_n_i;
		else 
			dsp_n_o = dsp_n_o;
	end
	
	always@(*)
	begin
		if(rsk_wen)
			rsp_n_o = rsp_n_i;
		else 
			rsp_n_o = rsp_n_o;
	end
	

endmodule


