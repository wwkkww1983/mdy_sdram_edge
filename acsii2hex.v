/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module acsii2hex(
    clk     ,
    rst_n   ,
    din     ,
    din_vld ,
    
    dout    ,
    dout_vld    
    );

    parameter      DIN_W =         8;
    parameter      DOUT_W =        4;
    
    input               clk         ;
    input               rst_n       ;
    input [DIN_W-1:0]   din         ;
    input               din_vld     ;

    wire  [DIN_W-1:0]   din         ;
    wire                din_vld     ;

    output[DOUT_W-1:0]  dout        ;
    output              dout_vld    ;

    reg   [DOUT_W-1:0]  dout        ;
    reg                 dout_vld    ;

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 0;
        end
        else if(din_vld&&((din>=8'd48&&din<8'd58)||(din>=8'd65&&din<8'd71)||(din>=8'd97&&din<8'd103)))begin
            dout_vld <= 1;
        end
        else begin
            dout_vld <= 0;
        end
    end


    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 0;
        end
        else if(din>=8'd48&&din<8'd58) begin
            dout <= din - 8'd48;
        end
        else if(din>=8'd65&&din<8'd71) begin
            dout <= din - 8'd55;
        end
        else if(din>=8'd97&&din<8'd103) begin
            dout <= din - 8'd87;
        end
        else begin
            dout <= 0;
        end    
    end

    endmodule


