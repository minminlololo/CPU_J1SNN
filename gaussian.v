module gaussian_filter #(
    parameter IMG_WIDTH  = 1920,
    parameter IMG_HEIGHT = 1080,
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,

    input  wire [DATA_WIDTH-1:0] pixel_in,
    input  wire pixel_valid,
    input  wire line_end,
    input  wire frame_end,

    output wire [DATA_WIDTH-1:0] pixel_out,
    output wire pixel_valid_out,
    output wire line_end_out,
    output wire frame_end_out
);

    // -------------------------
    // x / y 计数器
    // -------------------------
    reg [$clog2(IMG_WIDTH)-1:0]  x_cnt;
    reg [$clog2(IMG_HEIGHT)-1:0] y_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= 0;
            y_cnt <= 0;
        end else if (pixel_valid) begin
            if (line_end) begin
                x_cnt <= 0;
                y_cnt <= y_cnt + 1;
            end else begin
                x_cnt <= x_cnt + 1;
            end
        end
    end

    // -------------------------
    // 行缓存
    // -------------------------
    wire [DATA_WIDTH-1:0] line_pix [0:4];

    line_buffer #(
        .IMG_WIDTH(IMG_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_line_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .line_end(line_end),
        .line_out(line_pix)
    );

    // -------------------------
    // 5x5 窗口拼接
    // -------------------------
    wire [DATA_WIDTH-1:0] window [0:24];
    genvar r, c;
    generate
        for (r = 0; r < 5; r = r + 1) begin
            for (c = 0; c < 5; c = c + 1) begin
                assign window[r*5+c] = line_pix[r];
            end
        end
    endgenerate

    // -------------------------
    // 窗口是否有效
    // -------------------------
    wire window_valid =pixel_valid && (x_cnt >= 4) && (y_cnt >= 4);

    // -------------------------
    // 卷积
    // -------------------------
    wire [23:0] conv_result;

    convolution_5x5 u_conv (
        .clk(clk),
        .rst_n(rst_n),
        .window_in(window),
        .conv_out(conv_result)
    );

    // -------------------------
    // 输出
    // -------------------------
    assign pixel_out       = conv_result[15:8];
    assign pixel_valid_out = window_valid;
    assign line_end_out    = window_valid && line_end;
    assign frame_end_out   = window_valid && frame_end;

endmodule
