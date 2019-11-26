/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module bus_conv_16_to_48(
        clk     ,
        clk_out ,
        rst_n   ,

        din     ,
        din_sop ,
        din_eop ,
        din_vld ,

        dout    ,
        dout_sop,
        dout_eop,
        dout_vld,
        dout_mty,

        b_rdy   ,
        flag_sw ,
        rd_usedw
    );

    //浣跨敤鏂规硶锛�
    //娉ㄦ剰: 姣忓抚鐨勬暟鎹槸 640*480 涓� 16bit
    //鎶�16浣嶇殑鏁版嵁杈撳叆杩涙潵
    //鍦ㄦ绾ф暟鎹�>=256锛堜换鎰忓�硷級鏃� b_rdy = 1 鍙戦�佹暟鎹�
    //鍦ㄦ敹鍒颁竴涓畬鏁寸殑鍖呮枃鍚� 鍙湁flag_sw = 1 鎵嶈兘鍐欏叆鏂扮殑鍖呮枃

    //鍔熻兘锛�
    //1銆佸疄鐜�16浣嶈浆48浣�
    //2銆佸啓鍏IFO鐨勬暟鎹繀椤绘槸涓�涓寘鏂囷紝鍗砈OP寮�澶达紝EOP缁撳熬锛屽啓瀹屽悗锛岀洿鍒� flag_sw = 1 鎵嶈兘鍐嶆鍐欏叆鏂扮殑鍖呮枃
    //3銆佸疄鐜拌法鏃堕挓鍩�
    //4銆佽緭鍑哄綋鍓岶IFO鍐呯殑鏁版嵁鐨勪釜鏁� rd_usedw

    //640 * 480 = 307200 鐨勫儚绱犵偣鎬绘暟 16bit  307200
    //307200 / 3 = 102400 涓�48bit 
    //parameter PIC_NUM = 102400; //48bit
    parameter PIC_NUM = 102400; //48bit
    


    //杈撳叆
    input                   clk     ;
    input                   clk_out ;
    input                   rst_n   ;

    input       [15:0]      din     ;
    input                   din_vld ;
    input                   din_sop ;
    input                   din_eop ;
    
    input                   b_rdy   ;
    input                   flag_sw ;

    //杈撳嚭
    output      [47:0]      dout    ;
    output                  dout_vld;
    output                  dout_eop;   
    output                  dout_sop;
    output      [ 2:0]      dout_mty;
    output      [ 8:0]      rd_usedw;

    //杈撳嚭 reg
    reg         [47:0]      dout    ;
    reg                     dout_vld;
    reg                     dout_eop;   
    reg                     dout_sop;
    reg         [ 2:0]      dout_mty;
    wire        [ 8:0]      rd_usedw;



    //涓棿淇″彿
    wire                    add_cnt0;
    wire                    end_cnt0;
    reg         [ 2:0]      cnt0    ;

    wire                    add_cnt1;
    wire                    end_cnt1;
    reg         [18:0]      cnt1    ;

    reg                    wait_sw ;
    reg                     flag_add;

    reg                     wr_en   ;
    reg         [47:0]      din_ff0 ;
    reg                     din_sop_ff0;
    reg                     din_eop_ff0;
    reg         [ 2:0]      din_mty_ff0;     
    wire        [52:0]      wdata   ;

    wire        [52:0]      q       ;
    wire                    rd_empty;
    wire                    rd_en   ;
    wire                    dout_eop_tmp;
    wire                    dout_sop_tmp;
    wire        [ 2:0]      dout_mty_tmp;



    /**************************************************************/
    //鍐欎晶

    //鎶�3涓�16浣嶇殑鏁版嵁鍚堝苟鎴�1涓�48浣嶆暟鎹�
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt0 <= 0;
        end
        else if(wait_sw == 1)begin
            cnt0 <= 0;
        end
        else if(add_cnt0)begin
            if(end_cnt0)
                cnt0 <= 0;
            else
                cnt0 <= cnt0 + 1;
        end
    end
//    assign add_cnt0 = wait_sw == 0 && din_vld && (flag_add || din_sop);//瑕佸姞涓奷in_sop 涓嶇劧浼氫涪澶辩涓�涓暟鎹�
    assign add_cnt0 = din_vld && (flag_add || flag_add_stat); 
    
    assign end_cnt0 = add_cnt0 && (cnt0 == 3-1 || din_eop);
//    assign end_cnt0 = add_cnt0 && cnt0 == 3-1;
    
    //鍐欏叆瀹屾垚鍚庣瓑寰呭垏鎹� 鎵嶈兘鍐嶆鍐欏叆
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wait_sw <= 0;
        end
        else if(end_cnt1 && wait_sw == 0)begin
            wait_sw <= 1;
        end
        else if(flag_sw && wait_sw == 1)begin
            wait_sw <= 0;
        end
    end

    //璁℃暟鍐欏叆FIFO鐨勬暟鎹暟閲�
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
    assign end_cnt1 = add_cnt1 && cnt1 == PIC_NUM - 1;


    
    //鍙湪 SOP 鐨勬椂鍊欐墠寮�濮嬭鏁�
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 0;
        end
        else if(flag_add_stat)begin
            flag_add <= 1;
        end
        else if((din_vld && din_eop) || end_cnt1)begin
            flag_add <= 0;
        end
    end

    assign flag_add_stat = din_vld && din_sop && wait_sw == 0;


    //浜х敓鍐欏叆FIFO鎵�闇�鐨勪俊鍙�


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_en <= 0;
        end
        else begin
            wr_en <= end_cnt0;
        end
    end


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_ff0 <= 0;
        end
        else if(add_cnt0)begin
            din_ff0[47 - 16*cnt0 -: 16] <= din;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_sop_ff0 <= 0;
        end
        else if(add_cnt0 && cnt0 == 1-1)begin
            din_sop_ff0 <= din_sop;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_eop_ff0 <= 0;
        end
        else if(end_cnt0)begin
            din_eop_ff0 <= din_eop;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_mty_ff0 <= 0;
        end
        else if(end_cnt0)begin
            din_mty_ff0[2:1] <= 2 - cnt0;//宸︾Щ涓�浣嶏紝璧峰埌*2 鐨勬晥鏋�
        end
    end

    assign wdata = {din_sop_ff0 , din_eop_ff0 , din_mty_ff0 , din_ff0};



    /**************************************************************/
    //FIFO
    my_fifo#(.DATA_W(53), .DEPT_W(512)) uuu_t(
	    .aclr           (~rst_n     ),

        .wrclk          (clk        ),
	    .data           (wdata      ),
        .wrreq          (wr_en      ),
        .wrempty        (           ),
	    .wrfull         (           ),
	    .wrusedw        (           ),

	    .rdclk          (clk_out    ),
        .q              (q          ),
	    .rdreq          (rd_en      ),
	    .rdempty        (rd_empty   ),
	    .rdfull         (           ),
	    .rdusedw        (rd_usedw   )
    );
    /**************************************************************/
    //璇讳晶

    assign rd_en = b_rdy && rd_empty == 0;


    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 0;
        end
        else begin
            dout <= q[47:0];
        end
    end

    assign dout_sop_tmp = q[52];
    assign dout_eop_tmp = q[51];
    assign dout_mty_tmp = q[50:48];

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_sop <= 0;
        end
        else if(rd_en)begin
            dout_sop <= dout_sop_tmp;
        end
        else begin
            dout_sop <= 0;
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_eop <= 0;
        end
        else if(rd_en)begin
            dout_eop <= dout_eop_tmp;
        end
        else begin
            dout_eop <= 0;
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_mty <= 0;
        end
        else if(rd_en)begin
            dout_mty <= dout_mty_tmp;
        end
        else begin
            dout_mty <= 0;
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 0;
        end
        else begin
            dout_vld <= rd_en;
        end
    end









endmodule // bus_conv_16_to_48
