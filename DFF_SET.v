module DFF_SET 
#
(
	parameter DW = 16
)
(
	input  wire          clk        ,
	input  wire          rst_n      ,
	input  wire 		 hold_flag_i,
	input  wire [DW-1:0] set_data   ,
	input  wire [DW-1:0] data_i     ,
	output reg  [DW-1:0] data_o
);
	always@(posedge clk)
	begin
		if(!rst_n)
			data_o <= set_data;
		else if(hold_flag_i)
			data_o <= set_data;
		else
			data_o <= data_i;
	end

endmodule


