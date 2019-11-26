/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module gs_filter(
        clk         ,
        rst_n       ,
        din         ,
        din_vld     ,
        din_sop     ,
        din_eop     ,
        dout        ,
        dout_vld    ,
        dout_sop    ,
        dout_eop     
    );

    input               clk     ;
    input               rst_n   ;
    input   [7:0]       din     ;
    input               din_vld ;
    input               din_sop ;
    input               din_eop ;

    output  [7:0]       dout    ;
    output              dout_vld;
    output              dout_sop;
    output              dout_eop;

    reg     [7:0]       dout    ;
    reg                 dout_vld;
    reg                 dout_sop;
    reg                 dout_eop;

    reg     [7:0]       taps0_fifo_0    ;
    reg     [7:0]       taps0_fifo_1    ;
    reg     [7:0]       taps1_fifo_0    ;
    reg     [7:0]       taps1_fifo_1    ;
    reg     [7:0]       taps2_fifo_0    ;
    reg     [7:0]       taps2_fifo_1    ;

    reg                 din_vld_fifo_0  ;
    reg                 din_vld_fifo_1  ;
    reg                 din_vld_fifo_2  ;
    reg                 din_sop_fifo_0  ;
    reg                 din_sop_fifo_1  ;
    reg                 din_sop_fifo_2  ;
    reg                 din_eop_fifo_0  ;
    reg                 din_eop_fifo_1  ;
    reg                 din_eop_fifo_2  ;

    reg     [15:0]      gs_0            ;
    reg     [15:0]      gs_1            ;
    reg     [15:0]      gs_2            ;

    wire    [7:0]       taps0           ;
    wire    [7:0]       taps1           ;
    wire    [7:0]       taps2           ;



    //姝ゆā鍧椾富瑕佺悊瑙ｇЩ浣岻P鏍哥殑宸ヤ綔鍘熺悊鍗冲彲
    my_shift_ram u1(
	    .clken      (din_vld    ),
	    .clock      (clk        ),
	    .shiftin    (din        ),
//	    .shiftout   (shiftout   ),
	    .taps0x     (taps0      ),
	    .taps1x     (taps1      ),
	    .taps2x     (taps2      ) 
    );

    //IP鏍稿嚭鏉ョ殑鏁版嵁鏄�3琛屽苟琛岀殑鍍忕礌鐐癸紝鎵�浠ョ敤2涓狥IFO缂撳瓨涓�涓嬶紝灏辫兘寰楀埌3*3鐭╅樀鏁版嵁
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            taps0_fifo_0 <= 8'd0;
            taps0_fifo_1 <= 8'd0;

            taps1_fifo_0 <= 8'd0;
            taps1_fifo_1 <= 8'd0;

            taps2_fifo_0 <= 8'd0;
            taps2_fifo_1 <= 8'd0;
        end
        else if(din_vld_fifo_0)begin//绗竴涓椂閽熷懆鏈熸槸鎶婃暟鎹瓨鍏P鏍革紝鎵�浠ヨ鍑烘槸绗簩涓椂閽熷懆鏈�
            taps0_fifo_0 <= taps0;
            taps0_fifo_1 <= taps0_fifo_0;

            taps1_fifo_0 <= taps1;
            taps1_fifo_1 <= taps1_fifo_0;

            taps2_fifo_0 <= taps2;
            taps2_fifo_1 <= taps2_fifo_0;            
        end
    end
    
    //din_vld
    //din_sop
    //din_sop
    //寤舵椂4涓椂閽熷懆鏈熻緭鍑�
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_vld_fifo_0 <= 1'b0;
            din_vld_fifo_1 <= 1'b0;
            din_vld_fifo_2 <= 1'b0;

            din_sop_fifo_0 <= 1'b0;
            din_sop_fifo_1 <= 1'b0;
            din_sop_fifo_2 <= 1'b0;     

            din_eop_fifo_0 <= 1'b0;
            din_eop_fifo_1 <= 1'b0;
            din_eop_fifo_2 <= 1'b0;      
        end
        else begin
            din_vld_fifo_0 <= din_vld;
            din_vld_fifo_1 <= din_vld_fifo_0;
            din_vld_fifo_2 <= din_vld_fifo_1;

            din_sop_fifo_0 <= din_sop;
            din_sop_fifo_1 <= din_sop_fifo_0;
            din_sop_fifo_2 <= din_sop_fifo_1;     

            din_eop_fifo_0 <= din_eop;
            din_eop_fifo_1 <= din_eop_fifo_0;
            din_eop_fifo_2 <= din_eop_fifo_1;      
        end
    end
    
    //婊ゆ尝閲囩敤2绾ф祦姘寸嚎鐨勬柟寮忥紝鎻愰珮杩愮畻棰戠巼
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_0 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//绗笁涓椂閽熷懆鏈熻繍绠楋紝绗竴绾ф祦姘寸嚎
            gs_0 <= taps0_fifo_1 + 2*taps1_fifo_1 + taps2_fifo_1;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_1 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//绗笁涓椂閽熷懆鏈熻繍绠楋紝绗竴绾ф祦姘寸嚎
            gs_1 <= 2*taps0_fifo_0 + 4*taps1_fifo_0 + 2*taps2_fifo_0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_2 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//绗笁涓椂閽熷懆鏈熻繍绠楋紝绗竴绾ф祦姘寸嚎
            gs_2 <= taps0 + 2*taps1 + taps2;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 8'd0;
        end
        else if(din_vld_fifo_2)begin//绗洓涓椂閽熷懆鏈熻繍绠楋紝绗簩绾ф祦姘寸嚎
            dout <= (gs_0 + gs_1 + gs_2) >> 4;
        end
    end
    
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dout_vld <= 1'b0;
    end
    else if(din_vld_fifo_2)begin
        dout_vld <= 1'b1;
    end
    else begin
        dout_vld <= 1'b0;
    end
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dout_sop <= 1'b0;
    end
    else if(din_sop_fifo_2)begin
        dout_sop <= 1'b1;
    end
    else begin
        dout_sop <= 1'b0;
    end
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dout_eop <= 1'b0;
    end
    else if(din_eop_fifo_2)begin
        dout_eop <= 1'b1;
    end
    else begin
        dout_eop <= 1'b0;
    end
end


    
    


endmodule
