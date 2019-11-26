/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module vga_driver(
        clk         ,
        rst_n       ,
        radius      ,

        din_1       ,
        din_vld_1   ,
        din_sop_1   ,
        din_eop_1   ,
        dout_usedw_1,
        b_rdy_1     ,

        din_2       ,
        din_vld_2   ,
        din_sop_2   ,
        din_eop_2   ,
        dout_usedw_2,
        b_rdy_2     ,
        

        vga_hys     ,
        vga_vys     ,
        vga_rgb     ,

        cnt2,
        add_cnt2
    );
   
    output      [18:0]      cnt2            ;
    output                  add_cnt2        ;


   
    parameter       CIRCLE_X    = 320;//X鍧愭爣 琛屽潗鏍�
    parameter       CIRCLE_Y    = 240;//Y鍧愭爣 鍒楀潗鏍�
    parameter       CIRCLE_R2   = 22500;//鍗婂緞鐨勫钩鏂�  鍦嗗崐寰�100 鍍忕礌鐐�



  
    parameter       TIME_HYS    = 800;//琛� 鑴夊啿鏁�
    parameter       TIME_VYS    = 525;//鍨傜洿 鑴夊啿鏁�


  
    input                   clk             ;
    input                   rst_n           ;
    input   [7:0]           radius          ;


    input       [15:0]      din_1           ;//褰╄壊鍥惧儚
    input                   din_vld_1       ;
    input                   din_sop_1       ;
    input                   din_eop_1       ;
    input       [ 8:0]      dout_usedw_1    ;


    input       [15:0]      din_2           ;//浜屽�煎浘鍍�
    input                   din_vld_2       ;
    input                   din_sop_2       ;
    input                   din_eop_2       ;
    input       [ 8:0]      dout_usedw_2    ;

    output                  vga_hys         ;
    output                  vga_vys         ;
    output      [15:0]      vga_rgb         ;

    output                  b_rdy_1         ;
    output                  b_rdy_2         ;

    reg                     vga_hys         ;
    reg                     vga_vys         ;
    reg         [15:0]      vga_rgb         ;
	 reg         [15:0]      din_2_ff0       ;
	 reg         [15:0]      din_1_ff0       ;
           
    wire                    b_rdy_1         ;
    wire                    b_rdy_2         ;
    reg         [16:0]      rr              ;
    reg         [16:0]      distance        ;/*synthesis keep */


    reg                     flag_add        ;

    wire                    add_cnt0        ;
    wire                    end_cnt0        ;
    reg         [ 9:0]      cnt0            ;

    wire                    add_cnt1        ;
    wire                    end_cnt1        ;
    reg         [ 9:0]      cnt1            ;

    wire                    display_area    ;/*synthesis keep */
	 reg                    display_area_ff0;
    reg                     data_sw         ;
    wire        [ 15:0]      circle_x_tmp    ;
    wire        [ 15:0]      circle_y_tmp    ;



   
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 0;
        end
        else if(dout_usedw_1 > 200 && dout_usedw_2 >200)begin
            flag_add <= 1;
        end
    end

    //琛岃鏁板櫒
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt0 <= 0;
        end
        else if(add_cnt0)begin
            if(end_cnt0)
                cnt0 <= 0;
            else
                cnt0 <= cnt0 + 1;
        end
    end
    assign add_cnt0 = flag_add;
    assign end_cnt0 = add_cnt0 && cnt0 == TIME_HYS-1;//琛屽悓姝�
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt1 <= 0;
        end
        else if(add_cnt1)begin
            if(end_cnt1)
                cnt1 <= 0;
            else
                cnt1 <= cnt1 + 1;
        end
    end
    assign add_cnt1 = end_cnt0;
    assign end_cnt1 = add_cnt1 && cnt1 == TIME_VYS-1;//鍨傜洿鍚屾


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            vga_hys <= 1'b0;
        end
        else if(add_cnt0 && cnt0 == 96-1)begin
            vga_hys <= 1'b1;
        end
        else if(end_cnt0)begin
            vga_hys <= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            vga_vys <= 1'b0;
        end
        else if(add_cnt1 && cnt1 == 2-1)begin
            vga_vys <= 1'b1;
        end
        else if(end_cnt1)begin
            vga_vys <= 1'b0;
        end
    end
   

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            vga_rgb <= 16'd0;
        end
        else if(display_area)begin
            if(data_sw == 0)begin
                    vga_rgb <= din_2;
            end
            else begin
                    vga_rgb <= din_1;
            end
        end
        else begin
            vga_rgb <= 0;
        end
    end

assign b_rdy_1 = add_cnt0 && (cnt0>=(144-1-1) && cnt0<(144+640-1-1)) && (cnt1>=(35-1) && cnt1<(35+480-1));

    assign b_rdy_2 = add_cnt0 && (cnt0>=(144-1-1-2) && cnt0<(144+640-1-1-2)) && (cnt1>=(35-1-2) && cnt1<(35+480-1-2));//淇鍥惧儚鍋忕Щ锛屽彲鑳芥湁闂 锛侊紒锛侊紒


    assign display_area = add_cnt0 && (cnt0>=(144-1) && cnt0<(144+640-1)) && (cnt1>=(35-1) && cnt1<(35+480-1));




	 always  @(posedge clk or negedge rst_n)begin
	 if (rst_n==0) begin
	 rr <= 0;
	 end
	 else begin
	 rr <= radius * radius;
	 end
	 end


    reg data_sw_ff0;
    reg data_sw_ff1;
always  @(*)begin
		  data_sw = rr < (cnt0-144+1 - CIRCLE_X) * (cnt0-144+1 - CIRCLE_X)+(cnt1-35+1 - CIRCLE_Y)  * (cnt1-35+1 - CIRCLE_Y) ;
;
    end



    wire        add_cnt2;
    wire        end_cnt2;
    reg [18:0]  cnt2    ;

    reg         flag    ;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt2 <= 0;
        end
        else if(add_cnt2)begin
            if(end_cnt2)
                cnt2 <= 0;
            else
                cnt2 <= cnt2 + 1;
        end
    end
    assign add_cnt2 = din_vld_1 && (flag || din_sop_1);
    assign end_cnt2 = add_cnt2 && cnt2 == 307200 - 1;
    
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag <= 0;
        end
        else if(din_vld_1 && din_sop_1)begin
            flag <= 1;
        end
        else if(din_vld_1 && din_eop_1)begin
            flag <= 0;
        end
    end
    
    







endmodule

