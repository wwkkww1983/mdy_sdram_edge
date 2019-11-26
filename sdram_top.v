/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module sdram_top(
        clk         ,
        clk_100M    ,
        rst_n       ,

        din_1       ,//褰╄壊鍥惧儚
        din_vld_1   ,
        din_sop_1   ,
        din_eop_1   ,

        din_2       ,//浜屽�煎浘鍍�
        din_vld_2   ,
        din_sop_2   ,
        din_eop_2   ,

        dout_1      ,//褰╄壊鍥惧儚
        dout_vld_1  ,
        dout_sop_1  ,
        dout_eop_1  ,
        dout_usedw_1,
        b_rdy_1     ,

        dout_2      ,//浜屽�煎浘鍍�
        dout_vld_2  ,
        dout_sop_2  ,
        dout_eop_2  ,
        dout_usedw_2,
        b_rdy_2     ,
        key_vld     ,

        //纭欢鎺ュ彛
        sd_clk      ,
        cke         ,
        cs          ,
        ras         ,
        cas         ,
        we          ,
        dqm         ,
        sd_addr     ,
        sd_bank     ,

        dq_in       ,
        dq_out      ,
        dq_out_en   ,

        //娴嬭瘯鎺ュ彛锛岀敤鍚庡垹闄�
        flag_sel    ,    
        end_cnt0    ,
        end_cnt1    ,
        add_cnt0    ,
        add_cnt1    ,

        
        wr_color_en ,
        wr_sobel_en ,
        rd_color_en ,
        rd_sobel_en ,

        rd_sobel_end,
        rd_color_end,
        wr_sobel_end,
        wr_color_end
    );
    //浣跨敤鏂规硶锛�
    //din_1锛坰op,eop,vld锛� 杈撳叆 16浣嶇殑褰╄壊鏁版嵁娴� 锛屽浘鍍忓浐瀹氫负640*480锛侊紒锛�
    //din_2锛坰op,eop,vld锛� 杈撳叆 16浣嶄簩鍊煎浘鍍忔暟鎹祦 锛屽浘鍍忓浐瀹氫负640*480锛侊紒锛�

    //dout_1锛坰op,eop,vld锛� 杈撳嚭 16浣嶇殑褰╄壊鏁版嵁娴� 锛屽浘鍍忓浐瀹氫负640*480锛侊紒锛�
    //dout_2锛坰op,eop,vld锛� 杈撳嚭 16浣嶄簩鍊煎浘鍍忔暟鎹祦 锛屽浘鍍忓浐瀹氫负640*480锛侊紒锛�
    //sop 鎸囩ず绗竴骞呭浘鍍忕殑绗竴涓暟鎹�
    //eop 鎸囩ず绗竴鍓浘鍍忕殑鏈�鍚庝竴涓暟鎹�
    //vld 鎸囩ず鏈夋晥鏁版嵁

    //涓婄數鍚庯紝闇�瑕佸垽鏂璬out_usedw_1鍜宒out_usedw_2澶т簬200涓箣鍚庯紝鎵嶈兘鎷夐珮b_rdy_1 锛宐_rdy_2锛岃姹傝緭鍑烘暟鎹�
    // b_rdy_1 鍜� b_rdy_2 闇�瑕佸悓鏃舵媺楂� 锛屼互纭繚鍚屾椂缁撴潫锛侊紒锛侊紒


    //宸ヤ綔娴佺▼
    //1銆佽緭鍏ョ殑16浣嶆暟鎹祦杩涘叆鈥滄�荤嚎浣嶅杞崲妯″潡鈥濇妸16浣嶆暟鎹浆鎹㈡垚48浣嶆暟鎹紝
    //   骞朵笖杩涜鈥滃ご鍒ゆ柇鈥濆嵆鏀跺埌sop鎵嶅紑濮嬬紦瀛樻暟鎹洿鍒癳op,涔嬪悗涓嶅啀鍐欏叆鏁版嵁锛岀洿鍒版帴鏀垛�滃垏鎹AM鈥濓紙flag_sw_ff3锛� 淇″彿鎵嶈兘鍐嶆鍐欏叆

    //2銆佸垽鏂�滃啓鍏IFO鈥濋噷闈㈢殑鏁伴噺锛屽鏋�>256锛圫DRAM涓�椤电殑鏁版嵁閲忥級灏辫鍑烘暟鎹苟涓斿啓鍏DRAM

    //3銆�4璺疐IFO鐨勪紭鍏堢骇鏄� wr_color > wr_sobel > rd_color > rd_sobel
    //   褰撳啓鍏ユ垨鑰呰鍑哄畬涓�椤碉紙256涓暟鎹級鍚庡啀杩涜浼樺厛绾у垽鏂�
    //

    //4銆佸綋鈥滆鍑篎IFO鈥濆唴鐨勬暟鎹噺  < 256锛圫DRAM涓�椤电殑鏁版嵁閲忥級 灏辫鍑篠DRAM鐨勬暟鎹啓鍏IFO

    //5銆佽緭鍏ョ殑鍥惧儚鏄�30HZ锛岃�岃緭鍑虹殑鍥惧儚鏄�60HZ
    //   褰撹緭鍏ュ畬鎴愪竴鍓浘鍍忎箣鍚庯紝灏变笉鍐嶅啓鍏ュ浘鍍忥紝绛夊埌璇诲嚭瀹屾垚涓�骞呭浘鍍忎箣鍚庯紝杩涜鍒囨崲RAM鍦板潃锛屾墠鑳藉啀娆″啓鍏ワ紝骞朵笖鎶婂垰鎵嶅啓鍏ョ殑鍥惧儚杈撳嚭

    //6銆佸啓鍏ュ畬鎴愭爣蹇椾綅锛屽彧鑳藉湪鍒囨崲RAM鐨勪娇鐢ㄦ竻闆讹紝浣嗘槸璇诲嚭瀹屾垚鏍囧織浣嶏紝鍦ㄤ笅涓�娆″紑濮嬬殑鏃跺�欐竻闆讹紙color_new_start锛� 鎴栬�� 鍦ㄥ垏鎹AM鐨勬椂鍊欐竻闆讹紙ping_pong_end锛�
    //   鍒囨崲RAM鐨勬潯浠舵槸 4涓暟鎹祦閮戒紶杈撳畬鎴� ping_pong_end 


    //娴嬭瘯鎺ュ彛锛岀敤鍚庡垹闄�
    output wr_color_en;
    output wr_sobel_en;
    output rd_color_en;
    output rd_sobel_en;

    output rd_sobel_end;
    output rd_color_end; 
    output wr_sobel_end;
    output wr_color_end;



    //瀹氫箟4鐗囧唴瀛樺潡鐨勫湴鍧� 鐢ㄦ潵瀛樻斁 鈥滆鈥濆僵鑹插拰浜屽��   鍜�   鈥滃啓鈥濆僵鑹插拰浜屽��
    //杩涜涔掍箵鎿嶄綔
    //[13:12] = bank 鍦板潃
    //[11: 0] = 璧峰鍦板潃
    parameter BANK_1 = 14'b00_000000000000;//鍐呭瓨鍧� 1
    parameter BANK_2 = 14'b01_000000000000;//鍐呭瓨鍧� 2
    parameter BANK_3 = 14'b10_000000000000;//鍐呭瓨鍧� 3
    parameter BANK_4 = 14'b11_000000000000;//鍐呭瓨鍧� 4

    //姣忎釜鐢婚潰鏈夊灏戣
    //640*480*16bit / 256 / 48 
    parameter PIC_ROW = 400;//姣忓箙鐢婚潰 鍗燬DRAM 400琛岋紙椤碉級
    parameter SD_PAGE = 256;//SDRAM 涓�椤垫槸256涓�


    output      [ 1:0]          flag_sel    ;
    output                      end_cnt0    ;
    output                      end_cnt1    ;
    output                      add_cnt0    ;
    output                      add_cnt1    ;


    input                       clk         ;
    input                       clk_100M    ;
    input                       rst_n       ;
    input       [3:0]           key_vld     ;

    //纭欢鎺ュ彛
    input       [47:0]          dq_in       ;

    output                      sd_clk      ;//SDRAM鏃堕挓  鍙栧弽杈撳叆鏃堕挓寰楀埌
    output                      cke         ;
    output                      cs          ;
    output                      ras         ;
    output                      cas         ;
    output                      we          ;
    output      [ 5:0]          dqm         ;
    output      [11:0]          sd_addr     ;
    output      [ 1:0]          sd_bank     ;
    output      [47:0]          dq_out      ;//鍏ㄩ儴SDRAM閮界敤涓�
    output                      dq_out_en   ;

    wire                        sd_clk      ;//SDRAM鏃堕挓  鍙栧弽杈撳叆鏃堕挓寰楀埌
    wire                        cke         ;
    wire                        cs          ;
    wire                        ras         ;
    wire                        cas         ;
    wire                        we          ;
    wire        [ 5:0]          dqm         ;
    wire        [11:0]          sd_addr     ;
    wire        [ 1:0]          sd_bank     ;
    wire        [47:0]          dq_out      ;//鍏ㄩ儴SDRAM閮界敤涓�
    wire                        dq_out_en   ;


    //鏁版嵁杈撳叆鎺ュ彛
    input       [15:0]      din_1           ;//褰╄壊鍥惧儚
    input                   din_vld_1       ;
    input                   din_sop_1       ;
    input                   din_eop_1       ;

    input       [15:0]      din_2           ;//浜屽�煎浘鍍�
    input                   din_vld_2       ;
    input                   din_sop_2       ;
    input                   din_eop_2       ;

    input                   b_rdy_1         ;
    input                   b_rdy_2         ;

    //鏁版嵁杈撳嚭鎺ュ彛
    output      [15:0]      dout_1          ;//褰╄壊鍥惧儚
    output                  dout_vld_1      ;
    output                  dout_sop_1      ;
    output                  dout_eop_1      ;
    output      [ 8:0]      dout_usedw_1    ;

    output      [15:0]      dout_2          ;//浜屽�煎浘鍍�
    output                  dout_vld_2      ;
    output                  dout_sop_2      ;
    output                  dout_eop_2      ;
    output      [ 8:0]      dout_usedw_2    ;

    wire        [15:0]      dout_1          ;//褰╄壊鍥惧儚
    wire                    dout_vld_1      ;
    wire                    dout_sop_1      ;
    wire                    dout_eop_1      ;
    wire        [ 8:0]      dout_usedw_1    ;

    wire        [15:0]      dout_2          ;//浜屽�煎浘鍍�
    wire                    dout_vld_2      ;
    wire                    dout_sop_2      ;
    wire                    dout_eop_2      ;
    wire        [ 8:0]      dout_usedw_2    ;

    //涓棿淇″彿
    wire        [47:0]      color_in        ;
    wire                    color_in_sop    ;
    wire                    color_in_eop    ;
    wire                    color_in_vld    ;

    wire        [47:0]      sobel_in        ;
    wire                    sobel_in_sop    ;
    wire                    sobel_in_eop    ;
    wire                    sobel_in_vld    ;   

    wire        [ 8:0]      wr_usedw_color  ;
    wire        [ 8:0]      wr_usedw_sobel  ;
    wire        [ 8:0]      rd_usedw_color  ;
    wire        [ 8:0]      rd_usedw_sobel  ;

    
    reg                     wr_color_rdy_start;
    reg                     wr_sobel_rdy_start;
    wire                    wr_color_rdy    ;
    wire                    wr_sobel_rdy    ;
    wire                    rd_color_rdy    ;
    wire                    rd_sobel_rdy    ;

    reg         [ 1:0]      rw_bank         ;
    reg         [11:0]      rw_addr         ;
	 reg                     stop            ;

    wire        [47:0]      wdata           ; 
    wire                    wr_ack          ;
    reg                     wr_req          ;

    reg                     rd_req          ;
    wire                    rd_ack          ;
    wire        [47:0]      rdata           ;

    reg                     flag_sw_ff0     ;
    reg                     flag_sw_ff1     ;
    reg                     flag_sw_ff2     ;
    reg                     flag_sw_ff3     ;

    reg                     work_flag       ;
    reg         [ 1:0]      flag_sel        ;
    wire                    work_flag_start ;
    wire                    work_flag_stop  ;
    wire                    wr_color_en     ;
    wire                    wr_sobel_en     ;    
    wire                    rd_color_en     ;
    wire                    rd_sobel_en     ;

    wire                    ping_pong_end   ;
    reg                     rw_addr_sel     ;
    reg                     wr_color_end    ;
    reg                     wr_sobel_end    ;
    reg                     rd_color_end    ;
    reg                     rd_sobel_end    ;
    wire                    sobel_new_start ;
    wire                    color_new_start ;

    reg                     wr_flag         ;

    wire                    add_cnt0        ;
    wire                    end_cnt0        ;
    reg         [ 8:0]      cnt0            ;

    wire                    add_cnt1        ;
    wire                    end_cnt1        ;
    reg         [ 9:0]      cnt1            ;

    wire                    add_cnt2        ;
    wire                    end_cnt2        ;
    reg         [ 9:0]      cnt2            ;

    wire                    add_cnt3        ;
    wire                    end_cnt3        ;
    reg         [ 9:0]      cnt3            ;

    wire                    add_cnt4        ;
    wire                    end_cnt4        ;
    reg         [ 9:0]      cnt4            ;

    wire                    add_cnt5        ;
    wire                    end_cnt5        ;
    reg         [ 2:0]      cnt5            ;

    reg                     color_out_vld   ;
    reg                     color_out_sop   ;
    reg                     color_out_eop   ;

    reg                     sobel_out_vld   ;
    reg                     sobel_out_sop   ;
    reg                     sobel_out_eop   ;

    reg         [47:0]      color_out       ;
    reg         [47:0]      sobel_out       ;

    wire                    rd_vld          ;



    //褰╄壊鍥惧儚 
    bus_conv_16_to_48 color_in_fifo(
        .clk                (clk            ),
        .clk_out            (clk_100M       ),
        .rst_n              (rst_n          ),

        .din                (din_1          ),
        .din_sop            (din_sop_1      ),
        .din_eop            (din_eop_1      ),
        .din_vld            (din_vld_1      ),

        .dout               (color_in       ),
        .dout_sop           (color_in_sop   ),
        .dout_eop           (color_in_eop   ),
        .dout_vld           (color_in_vld   ),
        .dout_mty           (),

        .b_rdy              (wr_color_rdy   ),
        .rd_usedw           (wr_usedw_color ),
        .flag_sw            (flag_sw_ff3    )//25M  鏃堕挓鍩�
    );


    bus_conv_16_to_48 sobel_in_fifo(
        .clk                (clk            ),
        .clk_out            (clk_100M       ),
        .rst_n              (rst_n          ),

        .din                (din_2          ),
        .din_sop            (din_sop_2      ),
        .din_eop            (din_eop_2      ),
        .din_vld            (din_vld_2      ),

        .dout               (sobel_in       ),
        .dout_sop           (sobel_in_sop   ),
        .dout_eop           (sobel_in_eop   ),
        .dout_vld           (sobel_in_vld   ),
        .dout_mty           (),

        .b_rdy              (wr_sobel_rdy   ),
        .rd_usedw           (wr_usedw_sobel ),
        .flag_sw            (flag_sw_ff3    )//25M  鏃堕挓鍩�
    );

    bus_conv_48to_16 color_out_fifo(
        .clk                (clk_100M       ),
        .clk_out            (clk            ),
        .rst_n              (rst_n          ),

        .din                (color_out      ),
        .din_sop            (color_out_sop  ),
        .din_eop            (color_out_eop  ),
        .din_vld            (color_out_vld  ),
        .din_mty            (3'h0           ),
        .wr_usedw           (rd_usedw_color ),

        .dout               (dout_1         ),
        .dout_sop           (dout_sop_1     ),
        .dout_eop           (dout_eop_1     ),
        .dout_vld           (dout_vld_1     ),
        .dout_mty           (),
        .rd_usedw           (dout_usedw_1   ),
        .b_rdy              (b_rdy_1        )
    );

    bus_conv_48to_16 sobel_out_fifo(
        .clk                (clk_100M       ),
        .clk_out            (clk            ),
        .rst_n              (rst_n          ),

        .din                (sobel_out      ),
        .din_sop            (sobel_out_sop  ),
        .din_eop            (sobel_out_eop  ),
        .din_vld            (sobel_out_vld  ),
        .din_mty            (3'h0           ),

        .dout               (dout_2         ),
        .dout_sop           (dout_sop_2     ),
        .dout_eop           (dout_eop_2     ),
        .dout_vld           (dout_vld_2     ),
        .dout_mty           (),
        .rd_usedw           (dout_usedw_2   ),
        .b_rdy              (b_rdy_2        ),


        .wr_usedw           (rd_usedw_sobel )
    );


    sdram sdram_1(
        .clk                (clk_100M       ),
        .rst_n              (rst_n          ),

        .rw_addr            (rw_addr        ),//璇诲啓鍦板潃
        .rw_bank            (rw_bank        ),//璇诲啓鐨刡ank

        .wdata              (wdata          ),//鍐欐暟鎹�
        .wr_ack             (wr_ack         ),//鍐欒姹傜殑搴旂瓟
        .wr_req             (wr_req         ),//鍐欒姹�

        .rd_vld             (rd_vld         ),//璇绘湁鏁�
        .rdata              (rdata          ),//璇绘暟鎹�
        .rd_ack             (rd_ack         ),//璇昏姹傚緱鍒板簲绛�
        .rd_req             (rd_req         ),//璇昏姹�
    
        .sd_clk             (sd_clk         ),
        .cke                (cke            ),
        .cs                 (cs             ),
        .ras                (ras            ),
        .cas                (cas            ),
        .we                 (we             ),
        .dqm                (dqm            ),
        .sd_addr            (sd_addr        ),
        .sd_bank            (sd_bank        ),
       // .key_vld            (key_vld        ),
        
        .dq_in              (dq_in          ),
        .dq_out             (dq_out         ),
        .dq_out_en          (dq_out_en      )
    );



    //flag_sw   璺ㄦ椂閽熷煙澶勭悊 100M鍒�25MHZ
    //鏂规硶锛氭妸 ping_pong_end 寤堕暱鍒�8涓椂閽熷懆鏈� 鐒跺悗閭�25M鐨勫幓閲囨牱锛屽苟涓旀墦3鎷嶉槻姝簹绋虫��
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            cnt5 <= 0;
        end
        else if(add_cnt5)begin
            if(end_cnt5)
                cnt5 <= 0;
            else
                cnt5 <= cnt5 + 1;
        end
    end
    assign add_cnt5 = flag_sw_ff0;
    assign end_cnt5 = add_cnt5 && cnt5 == 8-1;
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sw_ff0 <= 0;
        end
        else if(ping_pong_end)begin
            flag_sw_ff0 <= 1;
        end
        else if(end_cnt5)begin
            flag_sw_ff0 <= 0;
        end
    end
    
    //flag_sw_ff3 浣跨敤
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sw_ff1 <= 0;
            flag_sw_ff2 <= 0;
            flag_sw_ff3 <= 0;
        end
        else begin
            flag_sw_ff1 <= flag_sw_ff0;
            flag_sw_ff2 <= flag_sw_ff1;
            flag_sw_ff3 <= flag_sw_ff2;
        end
    end
    
    

 


    //鏍规嵁FIFO鍐呭墿浣欐暟鎹殑鏁伴噺鏉ュ喅瀹氬摢涓狥IFO鍐欏叆鎴栬鍑�
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            work_flag <= 0;
        end
        else if(work_flag_start)begin
            work_flag <= 1;
        end
        else if(work_flag_stop)begin
            work_flag <= 0;
        end
    end

    assign work_flag_start = work_flag == 0 && (wr_color_en || wr_sobel_en || rd_color_en || rd_sobel_en);
    assign work_flag_stop =  work_flag == 1 && end_cnt0;

    //flag_sel 閫夋嫨璇绘垨鑰呭啓 4涓唴瀛樺潡涓殑涓�涓�
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sel <= 0;
        end
        else if(work_flag_start)begin
            //閫夋嫨鍐呭瓨鍧楃殑鏍囧織浣�
            if(wr_color_en)
                flag_sel <= 0;
            else if(wr_sobel_en)
                flag_sel <= 1;
            else if(rd_color_en)
                flag_sel <= 2;
            else if(rd_sobel_en)
                flag_sel <= 3;
        end
    end
    //鍐橣IFO 澶т簬256涓暟鎹氨寮�濮嬪啓鍏DRAM
    assign wr_color_en = wr_usedw_color >= SD_PAGE && wr_color_end == 0;
    assign wr_sobel_en = (wr_usedw_sobel >= SD_PAGE && wr_sobel_end == 0) && wr_color_en == 0;


    //assign wr_sobel_en = wr_usedw_color < SD_PAGE && wr_usedw_sobel >= SD_PAGE && wr_sobel_end == 0;

    //璇籉IFO 灏忎簬256涓暟鎹氨寮�濮嬭鍙朣DRAM
    //鍒ゆ柇rd_usedw_color rd_usedw_sobel 闇�瑕佸噺2 鍥犱负usedw 鏈夊欢鏃讹紝2鏄皟鍑烘潵鐨�
    //assign rd_color_en = rd_usedw_color < SD_PAGE-2 && wr_usedw_color < SD_PAGE && wr_usedw_sobel < SD_PAGE;
    assign rd_color_en = (rd_usedw_color < SD_PAGE-2 && wr_color_en == 0) && wr_sobel_en == 0;



    //娉ㄦ剰锛氳繖閲� 鍒ゆ柇 杈撳嚭 color FIFO鏁伴噺瑕佷娇鐢╮d_usedw_color >= SD_PAGE 浣跨敤 >= !!!!
    //assign rd_sobel_en = rd_usedw_sobel < SD_PAGE-2 && rd_usedw_color >= SD_PAGE && wr_usedw_color < SD_PAGE && wr_usedw_sobel < SD_PAGE;
    assign rd_sobel_en = (rd_usedw_sobel < SD_PAGE-2) && rd_color_en == 0;



    //鏍规嵁flag_sel 璁剧疆 璇诲啓鐨刡ank 鍦板潃
    //鏍规嵁flag_sel 璁剧疆 璇诲啓鐨刟ddr 鍦板潃
    //rw_addr_sel 鍒囨崲 RAM鍦板潃
    always  @(*)begin
        if (rw_addr_sel) begin  //A  涔掍箵鎿嶄綔
            if(flag_sel == 0)begin
                rw_bank = BANK_1[13:12];
                rw_addr = BANK_1[11:0] + cnt1;
            end
            else if(flag_sel == 1)begin
                rw_bank = BANK_2[13:12];
                rw_addr = BANK_2[11:0] + cnt2;
            end
            else if(flag_sel == 2)begin
                rw_bank = BANK_3[13:12];
                rw_addr = BANK_3[11:0] + cnt3;
            end
            else begin
                rw_bank = BANK_4[13:12];
                rw_addr = BANK_4[11:0] + cnt4; 
            end       
        end 
        else begin              //B
            if(flag_sel == 0)begin
                rw_bank = BANK_3[13:12];
                rw_addr = BANK_3[11:0] + cnt1;
            end
            else if(flag_sel == 1)begin
                rw_bank = BANK_4[13:12];
                rw_addr = BANK_4[11:0] + cnt2;
            end
            else if(flag_sel == 2)begin
                rw_bank = BANK_1[13:12];
                rw_addr = BANK_1[11:0] + cnt3;
            end
            else begin
                rw_bank = BANK_2[13:12];   
                rw_addr = BANK_2[11:0] + cnt4;   
            end
        end
    end
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            stop <= 1;
        end
        else if(key_vld[2])begin
            stop <= 0;
        end
        else if(key_vld[3])begin
            stop <= 1;
        end
    end
    
    //鍒囨崲RAM
    //涔掍箵鎿嶄綔
    //涔掍箵鎿嶄綔鐨勭粨鏉熸潯浠讹細鍐欏叆SDRAM瀹屾垚锛岃鍑篠DRAM瀹屾垚
    //assign ping_pong_end = rd_sobel_end && rd_color_end && wr_sobel_end && wr_color_end;
	
    assign ping_pong_end = rd_color_end && wr_sobel_end && wr_color_end && stop;//淇浜屽�煎浘鍍忓亸绉� 淇鍥惧儚鍋忕Щ锛屽彲鑳芥湁闂 锛侊紒锛侊紒
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rw_addr_sel <= 0;
        end
        else if(ping_pong_end)begin
            rw_addr_sel <= ~rw_addr_sel;
        end
    end

/********************************************************************/
    //浼犺緭瀹屾垚鏍囧織浣�
    //鍐欏叆锛�
    //鍐欏叆瀹屾垚涓�甯у浘鍍忎箣 绛夊埌 鍒囨崲RAM涔嬪悗鎵嶄細缁х画鍐欏叆鏁版嵁
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_color_end <= 0;
        end
        else if(end_cnt1)begin
            wr_color_end <= 1;
        end
        else if(ping_pong_end)begin
            wr_color_end <= 0;
        end
    end
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_sobel_end <= 0;
        end
        else if(end_cnt2)begin
            wr_sobel_end <= 1;
        end
        else if(ping_pong_end)begin
            wr_sobel_end <= 0;
        end
    end


    //璇诲嚭瀹屾垚涔嬪悗鏍囧織浣� 缃竴 濡傛灉 鈥滃叏閮ㄢ�� 鍐欏叆瀹屾垚 鍜� 璇诲嚭瀹屾垚 鍒欏垏鎹AM 锛屽惁鍒欏湪 涓嬩竴娆″紑濮嬪彂閫佺殑鏃跺�欐竻闆� 
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_color_end <= 0;
        end
        else if(end_cnt3)begin
            rd_color_end <= 1;
        end
        else if(ping_pong_end || color_new_start)begin
            rd_color_end <= 0;
        end
    end
    assign color_new_start = rd_color_end && work_flag && flag_sel == 2;

    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_sobel_end <= 0;
        end
        else if(end_cnt4)begin
            rd_sobel_end <= 1;
        end
        else if(ping_pong_end || sobel_new_start)begin
            rd_sobel_end <= 0;
        end
    end
    assign sobel_new_start = rd_sobel_end && work_flag && flag_sel == 3;

/********************************************************************/   
    //                                                   SDRAM 鍐欏叆閮ㄥ垎
    //wr_color_rdy  wr_color_rdy  涓婂崌娌垮拰 wr_ack 涓婂崌娌垮榻�

    //娉ㄦ剰锛氫娇鐢╳r_color_rdy_start 浣胯兘璁℃暟鍣� 瀵归綈鏃跺簭锛侊紒锛侊紒锛�
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_color_rdy_start <= 0;
        end
        else if(wr_color_rdy)begin
            wr_color_rdy_start <= 1;
        end
        else begin
            wr_color_rdy_start <= 0;
        end
    end
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_sobel_rdy_start <= 0;
        end
        else if(wr_sobel_rdy)begin
            wr_sobel_rdy_start <= 1;
        end
        else begin
            wr_sobel_rdy_start <= 0;
        end
    end
    assign wr_color_rdy = (wr_flag || wr_ack) && flag_sel == 0 && work_flag && end_cnt0 == 0;//璇锋眰璇诲嚭FIFO鍐呯殑 褰╄壊鍥惧儚 璇锋眰 
    assign wr_sobel_rdy = (wr_flag || wr_ack) && flag_sel == 1 && work_flag && end_cnt0 == 0;//璇锋眰璇诲嚭FIFO鍐呯殑 浜屽�煎浘鍍� 璇锋眰

    assign wdata = (flag_sel == 0) ? color_in : sobel_in;//鍐欏叆SDRAM鐨勬暟閫氭簮閫夋嫨

    //浜х敓鍐欒姹�
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_req <= 0;
        end
        else if(work_flag_start && (wr_color_en || wr_sobel_en))begin
            wr_req <= 1;
        end
        else if(wr_ack) 
            wr_req <= 0;
    end

    //鏀跺埌SDRAM鐨� wr_ack 涔嬪悗寮�濮嬪啓鍏ユ暟鎹�
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_flag <= 0;
        end
        else if(wr_ack && wr_flag == 0)begin
            wr_flag <= 1;
        end
        else if(end_cnt0 && wr_flag == 1)begin
            wr_flag <= 0;
        end
    end

    //璇诲啓 涓暟 璁℃暟鍣�
    always @(posedge clk_100M or negedge rst_n)begin
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
    assign add_cnt0 = wr_color_rdy_start || wr_sobel_rdy_start || rd_color_rdy || rd_sobel_rdy;
    assign end_cnt0 = add_cnt0 && cnt0 == SD_PAGE -1;
    
    // always  @(posedge clk or negedge rst_n)begin
    //     if(rst_n==1'b0)begin
    //         flag_add <= 0;
    //     end
    //     else if(wr_color_busy || wr_sobel_busy || rd_color_busy || rd_sobel_busy)begin
    //         flag_add <= 1;
    //     end
    //     else if(end_cnt0)begin
    //         flag_add <= 0;
    //     end
    // end
    

    //鍐欏叆 褰╄壊鍥惧儚 鍦板潃鈥滆鈥濆湴鍧�璁℃暟鍣�
    always @(posedge clk_100M or negedge rst_n)begin
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
    assign add_cnt1 = end_cnt0 && flag_sel == 0 && work_flag;
    assign end_cnt1 = add_cnt1 && cnt1 == PIC_ROW - 1;
    

    //鍐欏叆 浜屽�煎浘鍍� 鍦板潃鈥滆鈥濆湴鍧�璁℃暟鍣�
    always @(posedge clk_100M or negedge rst_n)begin
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
    assign add_cnt2 = end_cnt0 && flag_sel == 1 && work_flag;
    assign end_cnt2 = add_cnt2 && cnt2 == PIC_ROW - 1;
    
    //璇诲嚭 褰╄壊鍥惧儚 鍦板潃鈥滆鈥濆湴鍧�璁℃暟鍣�
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            cnt3 <= 0;
        end
        else if(add_cnt3)begin
            if(end_cnt3)
                cnt3 <= 0;
            else
                cnt3 <= cnt3 + 1;
        end
    end
    assign add_cnt3 = end_cnt0 && flag_sel == 2 && work_flag;
    assign end_cnt3 = add_cnt3 && cnt3 == PIC_ROW - 1;
    
    //璇诲嚭 浜屽�煎浘鍍� 鍦板潃鈥滆鈥濆湴鍧�璁℃暟鍣�
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            cnt4 <= 0;
        end
        else if(add_cnt4)begin
            if(end_cnt4)
                cnt4 <= 0;
            else
                cnt4 <= cnt4 + 1;
        end
    end
    assign add_cnt4 = end_cnt0 && flag_sel == 3 && work_flag;
    assign end_cnt4 = add_cnt4 && cnt4 == PIC_ROW - 1;
    
    
/********************************************************************/   
    //                                                   SDRAM 璇诲彇閮ㄥ垎    
    //杈撳嚭鏁版嵁閫夋嫨
    //娉ㄦ剰锛氳繖閲岃浣跨敤鏃跺簭閫昏緫锛屽拰VLD SOP EOP 瀵归綈
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out <= 0;
        end
        else begin
            color_out <= rdata;
        end
    end
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out <= 0;
        end
        else begin
            sobel_out <= rdata;
        end
    end


    //浜х敓璇昏姹�
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_req <= 0;
        end
        else if(work_flag_start && (rd_color_en || rd_sobel_en))begin
            rd_req <= 1;
        end
        else if(rd_ack)begin
            rd_req <= 0;
        end
    end
    
    assign rd_color_rdy = rd_vld && flag_sel == 2 && work_flag;
    assign rd_sobel_rdy = rd_vld && flag_sel == 3 && work_flag;

    //                                              褰╄壊鍥惧儚杈撳嚭淇″彿
    //color_out_vld 
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out_vld <= 0;
        end
        else if(add_cnt0 && flag_sel == 2)begin
            color_out_vld <= 1;
        end
        else begin
            color_out_vld <= 0;
        end
    end

    //color_out_sop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out_sop <= 0;
        end
        else if(add_cnt0 && cnt0 == 1-1 && cnt3 == 1-1 && flag_sel == 2)begin
            color_out_sop <= 1;
        end
        else begin
            color_out_sop <= 0;
        end
    end
    
    //color_out_eop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out_eop <= 0;
        end
        else if(end_cnt3)begin
            color_out_eop <= 1;
        end
        else begin
            color_out_eop <= 0;
        end
    end
    
    

    //                                              浜屽�煎浘鍍忚緭鍑轰俊鍙�
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out_vld <= 0;
        end
        else if(add_cnt0 && flag_sel == 3)begin
            sobel_out_vld <= 1;
        end
        else begin
            sobel_out_vld <= 0;
        end
    end

    //sobel_out_sop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out_sop <= 0;
        end
        else if(add_cnt0 && cnt0 == 1-1 && cnt4 == 1-1 && flag_sel == 3)begin
            sobel_out_sop <= 1;
        end
        else begin
            sobel_out_sop <= 0;
        end
    end
    
    //sobel_out_eop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out_eop <= 0;
        end
        else if(end_cnt4)begin
            sobel_out_eop <= 1;
        end
        else begin
            sobel_out_eop <= 0;
        end
    end
    
    

endmodule
