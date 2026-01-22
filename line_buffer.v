module line_buffer #(
    parameter IMG_WIDTH  = 1920,
    parameter DATA_WIDTH = 8,
	parameter NUM_LINES  = 5 
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH-1:0] pixel_in,
    input  wire pixel_valid,
    input  wire line_end,

    output wire [DATA_WIDTH-1:0] line_out [0:NUM_LINES-1]
);

    reg [DATA_WIDTH-1:0] line_mem [0:NUM_LINES-1][0:IMG_WIDTH-1];
    reg [$clog2(IMG_WIDTH)-1:0] pixel_cnt;
    reg [2:0] line_cnt;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_cnt <= 0;
            line_cnt <= 0;
        end else if (pixel_valid) begin
            line_mem[line_cnt][pixel_cnt] <= pixel_in;

            if (line_end) begin
                pixel_cnt <= 0;
                line_cnt <= (line_cnt == NUM_LINES - 1) ? 0 : line_cnt + 1;
            end else begin
                pixel_cnt <= pixel_cnt + 1;
            end
        end
    end

    generate
        for (i = 0; i < NUM_LINES; i = i + 1) begin
            assign line_out[i] =
                line_mem[(line_cnt + i) % 5][pixel_cnt];
        end
    endgenerate

endmodule


/*
module line_buffer #(
    parameter IMG_WIDTH = 1920,
    parameter DATA_WIDTH = 8,
    parameter NUM_LINES = 5
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] pixel_in,
    input pixel_valid,
    input line_end,
    output [DATA_WIDTH-1:0] line_out [0:NUM_LINES-1]
);

    // 使用BRAM存储行数据
    reg [DATA_WIDTH-1:0] line_mem [0:NUM_LINES-1][0:IMG_WIDTH-1];
    reg [10:0] pixel_cnt;
    reg [2:0] line_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_cnt <= 0;
            line_cnt <= 0;
        end else if (pixel_valid) begin
            // 存储像素到当前行
            line_mem[line_cnt][pixel_cnt] <= pixel_in;
            
            if (pixel_cnt == IMG_WIDTH - 1) begin 
                pixel_cnt <= 0;
                if (line_cnt == NUM_LINES - 1)
                    line_cnt <= 0;
                else
                    line_cnt <= line_cnt + 1;
            end else begin
                pixel_cnt <= pixel_cnt + 1;
            end
        end
    end
    
    // 输出当前窗口的NUM_LINES行数据
    generate
        for (genvar i = 0; i < NUM_LINES; i++) begin
            assign line_out[i] = line_mem[i][pixel_cnt];
        end
    endgenerate
    
endmodule



*/