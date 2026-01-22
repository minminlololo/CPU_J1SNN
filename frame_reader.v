module frame_reader #(
    parameter IMG_WIDTH  = 220,
    parameter IMG_HEIGHT = 168,
    parameter ADDR_WIDTH = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    // BRAM
    output reg                   rd_en,
    output reg [ADDR_WIDTH-1:0]  rd_addr,
    input  wire [7:0]            rd_data,

    // To Gaussian
    output wire [7:0] pixel_out,
    output wire       pixel_valid,
    output wire       line_end,
    output wire       frame_end
);

    // 坐标计数（对应读请求拍）
    reg [$clog2(IMG_WIDTH)-1:0]  x_cnt;
    reg [$clog2(IMG_HEIGHT)-1:0] y_cnt;
    reg running;

    // ----------- 原始控制信号（未延迟）-----------
    wire raw_line_end;
    wire raw_frame_end;

    assign raw_line_end  = rd_en && (x_cnt == IMG_WIDTH-1);
    assign raw_frame_end = rd_en &&
                           (x_cnt == IMG_WIDTH-1) &&
                           (y_cnt == IMG_HEIGHT-1);

    // ----------- 延迟一拍，与 rd_data 对齐 ----------
    reg rd_en_d;
    reg line_end_d;
    reg frame_end_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_d      <= 1'b0;
            line_end_d  <= 1'b0;
            frame_end_d <= 1'b0;
        end else begin
            rd_en_d      <= rd_en;
            line_end_d  <= raw_line_end;
            frame_end_d <= raw_frame_end;
        end
    end

    // ----------- 输出到 Gaussian -------------------
    assign pixel_in    = rd_data;
    assign pixel_valid = rd_en_d;
    assign line_end    = line_end_d;
    assign frame_end   = frame_end_d;

    // ----------- 读控制 FSM ------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en   <= 1'b0;
            rd_addr <= 0;
            x_cnt   <= 0;
            y_cnt   <= 0;
            running <= 1'b0;
        end else begin
            if (start) begin
                running <= 1'b1;
                rd_en   <= 1'b1;
            end

            if (running) begin
                rd_addr <= rd_addr + 1;

                if (x_cnt == IMG_WIDTH-1) begin
                    x_cnt <= 0;
                    if (y_cnt == IMG_HEIGHT-1) begin
                        y_cnt   <= 0;
                        running <= 1'b0;
                        rd_en   <= 1'b0;
                    end else begin
                        y_cnt <= y_cnt + 1;
                    end
                end else begin
                    x_cnt <= x_cnt + 1;
                end
            end
        end
    end

endmodule
