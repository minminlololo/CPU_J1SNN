module ctrl_fsm (
    input  wire        clk,
    input  wire        rst_n,

    // 来自 CPU EX 的控制信号
    input  wire        ctrl_valid	,
    input  wire [2:0]  funct_op		,   // START_PRE / START_ENC / ...
	
	 input wire        enc_sel 		,
	 // input wire        pre_start	,
	 // input wire        enc_start	,
	 // input wire        snn_start	,
	 input wire        clear		, 
	 input wire        wait_snn 	,
	 input wire        output_snn   ,

    // 来自各硬件模块的完成信号
    input  wire        pre_done,
    input  wire        enc_done,
    input  wire        snn_done,

    // 输出到各模块的启动信号
    output reg         pre_start,
    output reg         enc_start,
    output reg         snn_start,
	output wire [1:0]  enc_sel_o,
    // 返回给 CPU
    output reg         ctrl_busy,
    output reg         ctrl_done
);
	
	localparam S_IDLE   = 3'd0;
	localparam S_PRE    = 3'd1;
	localparam S_ENC    = 3'd2;
	localparam S_SNN    = 3'd3;
	localparam S_DONE   = 3'd4;
	
	reg [2:0] state, state_n;

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			state <= S_IDLE;
		else
			state <= state_n;
	end
always @(*) begin
    state_n = state;

    case (state)
        S_IDLE: begin
            if (ctrl_valid) begin
                case (funct_op)
                    `START_PRE: state_n = S_PRE; // START_PRE
                    `START_ENC: state_n = S_ENC; // START_ENC
                    `START_SNN: state_n = S_SNN; // START_SNN
                    default: state_n = S_IDLE;
                endcase
            end
        end

        S_PRE:  if (pre_done)  state_n = S_DONE;
        S_ENC:  if (enc_done)  state_n = S_DONE;
        S_SNN:  if (snn_done)  state_n = S_DONE;

        S_DONE: state_n = S_IDLE;

        default: state_n = S_IDLE;
    endcase
end

always @(*) begin
    pre_start  = 0;
    enc_start  = 0;
    snn_start  = 0;
    ctrl_busy  = 0;
    ctrl_done  = 0;

    case (state)
        S_PRE: begin
            pre_start = 1'b1;
            ctrl_busy = 1'b1;
        end            
						
        S_ENC: begin   
            enc_start = 1'b1;
            ctrl_busy = 1'b1;
        end             
						
        S_SNN: begin    
            snn_start = 1'b1;
            ctrl_busy = 1'b1;
        end

        S_DONE: begin
            ctrl_done = 1'b1;
			ctrl_busy = 1'b0;
        end
    endcase
end

endmodule
