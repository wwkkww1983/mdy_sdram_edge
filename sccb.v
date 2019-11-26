/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module sccb(
        clk       ,
        rst_n     ,
        ren       ,
        wen       ,
        sub_addr  ,
        rdata     ,
        rdata_vld ,
        wdata     ,
        rdy       ,
        sio_c     ,
        sio_d_r   ,
        en_sio_d_w,
        sio_d_w         
    );

    //浣跨敤flag_sel鍋氱姸鎬佸瘎瀛樼殑鏃跺�欐渶濂界敤parameter 瀹氫箟 RD WR ,杩欐牱涓嶄細0锛�1鎼為敊锛屼笖鏇寸洿瑙�
    //娴嬭瘯绋嬪簭閲岄潰sub_addr wdata 鏁板�煎彧瀛樺湪涓�涓椂閽熷懆鏈燂紝鎵�浠ラ渶瑕佺紦瀛橈紝浣嗘槸瀹為檯搴旂敤涓� 搴旇锛� 鏄笉闇�瑕佺紦瀛樼殑


    //鍙傛暟瀹氫箟
    parameter      SIO_C  = 120 ; 
    parameter       WEN_SEL = 1;
    parameter       REN_SEL = 0;

    //杈撳叆淇″彿瀹氫箟
    input               clk             ;//25m
    input               rst_n           ;
    input               ren             ;
    input               wen             ;
    input   [7:0]       sub_addr        ;
    input   [7:0]       wdata           ;

    //杈撳嚭淇″彿瀹氫箟
    output  [7:0]       rdata           ;
    output              rdata_vld       ;
    output              sio_c           ;//208kHz
    output              rdy             ;

    input               sio_d_r         ;
    output              en_sio_d_w      ;
    output              sio_d_w         ;

    reg                 en_sio_d_w      ;
    reg                 sio_d_w         ;



    reg     [7:0]       rdata           ;
    reg                 rdata_vld       ;
    reg                 sio_c           ;//208kHz
    reg                 rdy             ;


    wire                add_count_sck   ;
    wire                end_count_sck   ;
    reg     [7:0]       count_sck       ; 

    wire                add_count_bit   ;
    wire                end_count_bit   ;
    reg     [7:0]       count_bit       ; 

    wire                add_count_duan  ;
    wire                end_count_duan  ;
    reg     [7:0]       count_duan      ; 

    reg                 flag_add        ;
    reg                 flag_sel        ;

    reg     [5:0]       bit_num         ;
    reg     [1:0]       duan_num        ;

    wire                sio_c_h2l       ;
    wire                sio_c_l2h       ;

    reg     [29:0]      out_data        ;

    wire    [7:0]       rd_com          ;

    wire                en_sio_d_w_h2l  ;
    wire                en_sio_d_w_l2h  ;

    wire                out_data_time   ;

    wire                rdata_time      ;


    reg     [7:0]       wdata_fifo      ;
    reg     [7:0]       sub_addr_fifo   ;  


    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            count_sck <= 0;
        end
        else if(add_count_sck)begin
            if(end_count_sck)
                count_sck <= 0;
            else
                count_sck <= count_sck + 1;
        end
    end
    assign add_count_sck = flag_add;
    assign end_count_sck = add_count_sck && count_sck == SIO_C - 1;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            count_bit <= 0;
        end
        else if(add_count_bit)begin
            if(end_count_bit)
                count_bit <= 0;
            else
                count_bit <= count_bit + 1;
        end
    end
    assign add_count_bit = end_count_sck;
    assign end_count_bit = add_count_bit && count_bit == bit_num + 2 - 1;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            count_duan <= 0;
        end
        else if(add_count_duan)begin
            if(end_count_duan)
                count_duan <= 0;
            else
                count_duan <= count_duan + 1;
        end
    end
    assign add_count_duan = end_count_bit;
    assign end_count_duan = add_count_duan && count_duan == duan_num - 1;
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 1'b0;
        end
        else if(ren || wen)begin
            flag_add <= 1'b1;
        end
        else if(end_count_duan)begin
            flag_add<= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sel <= 1'b0;
        end
        else if(wen)begin
            flag_sel <= WEN_SEL;
        end
        else if(ren)begin
            flag_sel <= REN_SEL;
        end
    end
    

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sub_addr_fifo <= 8'd0;
        end
        else if(ren || wen)begin
            sub_addr_fifo <= sub_addr;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wdata_fifo <= 8'd0;
        end
        else if(wen)begin
            wdata_fifo <= wdata;
        end
    end


    //娉ㄦ剰锛氬垎闅旂鏄病鏈夋椂閽熺殑锛屾墍浠ヤ笉鍚堝苟鍏ユ暟鎹綅
    always  @(*)begin
        if(flag_sel == WEN_SEL)begin
            bit_num = 30;//璧峰浣� + 鎸囦护浣� + X + 鍦板潃浣� + X + 鏁版嵁浣� + X + 缁撴潫浣�  = 30
            duan_num = 1;
        end
        else if(flag_sel == REN_SEL)begin
            bit_num = 21;//璧峰浣� + 鎸囦护浣� + X + 鍦板潃浣� + X + 缁撴潫浣� = 23
            duan_num = 2;//鍒� 璇绘 鍜� 鍐欐
        end
        else begin
            bit_num = 1;
            duan_num = 1;
        end
    end
    
    //sio_c = SIO_SCK
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sio_c <= 1'b1;
        end
        else if(sio_c_h2l)begin
            sio_c <= 1'b0;
        end
        else if(sio_c_l2h)begin
            sio_c <= 1'b1;
        end
    end
    //SCK鏄厛浣庡悗楂�
    //count_bit < bit_num - 2   -2鏄噺鍘�2涓仠姝綅
    assign sio_c_h2l = count_bit >= 0 && count_bit < (bit_num - 2) && add_count_sck && count_sck == SIO_C - 1;
    assign sio_c_l2h = count_bit >= 1 && count_bit < bit_num && add_count_sck && count_sck == SIO_C / 2 - 1;

    always  @(*)begin
        if(flag_sel == REN_SEL)begin
            //璇�
            //1'b0 ,   rd_com , 1'b1 , sub_addr_fifo , 1'b1 , 1'b0 , 1'b1 ,9'h0
            //璧峰浣�   鎸囦护浣�      X    鍦板潃浣�       X          缁撴潫浣�   瀵瑰叾琛ラ浂
            out_data = {1'b0 , rd_com , 1'b1 , sub_addr_fifo , 1'b1 , 1'b0 , 1'b1 ,9'h0};
        end
        else if(flag_sel == WEN_SEL)begin
            //鍐�
            //1'b0 , 8'h42 , 1'b1 , sub_addr_fifo , 1'b1 , wdata_fifo , 1'b1 , 1'b0 , 1'b1
            out_data = {1'b0 , 8'h42 , 1'b1 , sub_addr_fifo , 1'b1 , wdata_fifo , 1'b1 , 1'b0 , 1'b1};
        end
        else begin
            out_data = 0;
        end
    end
    //鍏堝啓鍐嶈
    //杩欓噷鍒嗘垚2娈碉紝绗竴娈垫槸鍐欙紝鎵�浠ュ彂0x42 绗簩娈垫槸璇伙紝鎵�浠ュ彂0x43
    assign rd_com = (flag_sel == REN_SEL && count_duan == 0) ? 8'h42 : 8'h43;//鍐欐槸0x42 璇绘槸0x43


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            en_sio_d_w <= 1'b0;
        end
        else if(ren || wen)begin//璇诲拰鍐欏紑濮嬬殑绗竴娈甸兘鏄� 杈撳嚭
            en_sio_d_w <= 1'b1;
        end
        else if(end_count_duan)begin//鍦ㄧ涓�锛屽拰 绗簩娈电粨鏉熺殑鏃跺�欓兘璁句负 杈撳叆
            en_sio_d_w <= 1'b0;
        end
        else if(en_sio_d_w_h2l)begin//鍦ㄨ鐨勭浜屾鐨勬椂鍊欒鍒囨崲涓鸿緭鍏� 璇绘ā鍧楃殑鏁版嵁
            en_sio_d_w <= 1'b0;
        end
        else if(en_sio_d_w_l2h)begin//鍦ㄨ鐨勭浜屾 璇绘ā鍧楃殑鏁版嵁 瀹屾垚鍚庡垏鎹负杈撳嚭 锛岃緭鍑哄仠姝綅鍜岄棿闅旂
            en_sio_d_w <= 1'b1;
        end
    end
    //绗竴涓娈� 鍜� 鍐欐 閮芥槸杈撳嚭 锛屽彧鏈夊湪绗簩涓娈典腑鐨勮8浣嶆暟鎹墠鏄緭鍏�   鍦ㄨ鏁板櫒0鐐瑰彉鍖� ?
    //娉ㄦ剰杩欓噷浣跨敤add_count_sck鑰岄潪add_count_bit鍒ゆ柇
    assign en_sio_d_w_h2l = flag_sel == REN_SEL && count_duan == 2-1  && count_bit == 11 - 1 && add_count_sck && count_sck == 1-1;
    assign en_sio_d_w_l2h = flag_sel == REN_SEL && count_duan == 2-1  && count_bit == 20 - 1 && add_count_sck && count_sck == 1-1;


    //sio_d_w= SIO_SDA
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sio_d_w <= 1'b1;
        end
        else if(out_data_time)begin
            sio_d_w <= out_data[30 - count_bit - 1];//楂樹綅鍏堝彂
        end
    end
    //bit_num < count_bit  鍒ゆ柇鏄惁 涓嶆槸 闂撮殧绗� 锛屽湪SCK浣庣數骞充腑鐐硅緭鍑烘暟鎹�
    assign out_data_time = (count_bit < bit_num) && add_count_sck && count_sck == SIO_C/4 - 1;
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rdata <= 8'd0;
        end
        else if(rdata_time)begin
            rdata[17 -count_bit] <= sio_d_r;  // rdata[7~0] = (18 - 1) - count_bit((11-1) ~ (18 - 1)) = 17 
        end
    end
    //鏄惁鍦ㄢ�滆鈥� 
    //鏄惁鍦ㄢ�滆鐨勭浜屾鈥� 
    //鏄惁鍦ㄢ�滆鐨勮寖鍥村唴鈥�
    //娉ㄦ剰杩欓噷浣跨敤add_count_sck鑰岄潪add_count_bit鍒ゆ柇
    assign rdata_time = flag_sel == REN_SEL && count_duan == 2-1 && (count_bit >= 11-1 && count_bit < 18) && add_count_sck &&count_sck == SIO_C/4*3 - 1;  
    

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rdata_vld <= 1'b0;
        end
        else if(flag_sel == REN_SEL && end_count_duan)begin//鍦ㄨ鐨勬椂鍊欙紝璇绘锛堣娈� = 2锛夌粨鏉燂紝
            rdata_vld <= 1'b1;
        end
        else begin
            rdata_vld <= 1'b0;
        end
    end
    
    //RDY鏄� 绌洪棽鐨勬椂鍊�=1 蹇欑殑鏃跺�� = 0
    always  @(*)begin
        if( ren || wen || flag_add)begin
            rdy = 1'b0;
        end
        else begin
            rdy = 1'b1;
        end
    end
    
    




endmodule
