/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module sobel_edge_dection(
        clk         ,
        rst_n       ,       

        key_in      ,
        vsync       ,
        href        ,
        din         ,
		  uart_rx     ,

        pclk        ,

        xclk        ,
        pwdn        ,
        sio_c       ,
        sio_d       ,

        vga_hys     ,
        vga_vys     ,
        vga_rgb     ,

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

        dq
    );

    input                       pclk        ;//鎽勫儚澶�
    //纭欢鎺ュ彛
    output                      sd_clk      ;//SDRAM鏃堕挓  鍙栧弽杈撳叆鏃堕挓寰楀埌
    output                      cke         ;
    output                      cs          ;
    output                      ras         ;
    output                      cas         ;
    output                      we          ;
    output      [ 5:0]          dqm         ;
    output      [11:0]          sd_addr     ;
    output      [ 1:0]          sd_bank     ;

    inout       [47:0]          dq          ;

    assign dq = dq_out_en ? dq_out : 48'hz;
    assign dq_in = dq;

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
    wire        [47:0]          dq_in       ;


    input                       clk         ;
    input                       rst_n       ;   
    input       [3:0]           key_in      ;
    input                       vsync       ;
    input                       href        ;
    input       [7:0]           din         ;

    output                      xclk        ;
    output                      pwdn        ;

    output                      vga_hys     ;
    output                      vga_vys     ;
    output      [15:0]          vga_rgb     ;

    wire                        pwdn        ;

    wire                        vga_hys     ;
    wire                        vga_vys     ;
    wire    [15:0]              vga_rgb     ;


    output                      sio_c       ;
    inout                       sio_d       ;
    wire                        en_sio_d_w  ;              
    wire                        sio_d_w     ;
    wire                        sio_d_r     ;

    assign sio_d = en_sio_d_w ? sio_d_w : 1'dz;
    assign sio_d_r = sio_d;

    wire                        xclk        ;
    wire        [3:0]           key_in      ;
    wire        [3:0]           key_vld     ;

    wire                        rdy         ;
    wire        [7:0]           rdata       ;     
    wire                        rdata_vld   ;
    wire        [7:0]           wdata       ;      
    wire        [7:0]           sub_addr    ; 

    wire                        wen         ;
    wire                        ren         ;        
    wire                        en_capture  ;      

    wire        [15:0]          coms_dout       ;
    wire                        coms_dout_vld   ;
    wire                        coms_dout_sop   ;
    wire                        coms_dout_eop   ;

    wire        [7:0]           gray_dout       ;          
    wire                        gray_dout_vld   ;
    wire                        gray_dout_sop   ;
    wire                        gray_dout_eop   ;

    wire        [7:0]           gs_dout         ;
    wire                        gs_dout_vld     ;
    wire                        gs_dout_sop     ;
    wire                        gs_dout_eop     ;

    wire                        bit_dout        ;
    wire                        bit_dout_vld    ;
    wire                        bit_dout_sop    ;
    wire                        bit_dout_eop    ;

    wire                        sobel_dout      ;
    wire                        sobel_dout_vld  ;
    wire                        sobel_dout_sop  ;
    wire                        sobel_dout_eop  ;


    wire        [15:0]          dout_1          ;
    wire                        dout_vld_1      ;
    wire                        dout_sop_1      ;
    wire                        dout_eop_1      ;
    wire        [ 8:0]          dout_usedw_1    ;
    wire                        b_rdy_1         ;



    wire        [15:0]          dout_2          ;
    wire                        dout_vld_2      ;
    wire                        dout_sop_2      ;
    wire                        dout_eop_2      ;
    wire        [ 8:0]          dout_usedw_2    ;
    wire                        b_rdy_2         ;

 wire   [15:0]  gamma_dout    ;
   wire            gamma_dout_sop; 
   wire            gamma_dout_eop; 
   wire            gamma_dout_vld; 
     input          uart_rx       ;
    wire   [7:0]   rx_dout       ;
    wire           rx_dout_vld   ;
    wire    [3:0]   a2h_dout      ;
    wire            a2h_dout_vld  ;
    wire    [7:0]   op_dout       ;
    wire            op_dout_vld   ;
    wire            c_config_en     ;
    wire    [7:0]   gray_value    ;
    wire      [7:0]  radius       ;
 

 


    wire        [7:0]           add_5           ;

    wire                        clk_100M        ;
    wire                        clk_25M         ;

    

    //鏃堕挓鍒嗛厤 FPAG杈撳嚭涓�涓� 25MHZ鏃堕挓缁欐憚鍍忓ご
    //鎽勫儚澶磋繑鍥炰竴涓�25MHZ鏃堕挓锛屼娇鐢ㄨ繖涓椂閽熶綔涓虹▼搴忕殑涓绘椂閽�
    pll_ipcore u0(
        .inclk0         (clk            ),
        .c0             (xclk           )
    );

    pll_25_to_100 uu(
        .inclk0         (pclk           ),
        .c0             (clk_25M        ),
        .c1             (clk_100M       )           
    );
	 
	 uart_rx u14(
	 .clk          (clk_25M),
	 .rst_n        (rst_n),
	 .uart_rx      (uart_rx),
	 .rx_vld       (rx_dout_vld),
	 .rx_data      (rx_dout)
	 );
	 



  acsii2hex u15(
        .clk       (clk_25M),
        .rst_n     (rst_n),
        .din       (rx_dout),
        .din_vld   (rx_dout_vld),
        .dout      (a2h_dout),
        .dout_vld  (a2h_dout_vld)
    );

    opcode_dect u16(
        .clk       (clk_25M),
        .rst_n     (rst_n),
        .din       (a2h_dout),
        .din_vld   (a2h_dout_vld),
        .dout      (op_dout),
        .dout_vld   (op_dout_vld)
    );
 

    control u27(
        .clk       (clk_25M),
        .rst_n     (rst_n),
        .din       (op_dout),
        .din_vld   (op_dout_vld),
        .config_en (c_config_en),
        .radius    (radius     ),
        .gray_value(gray_value)
    );


    key_module #(.KEY_W(4) ) U_key_module(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .key_in         (key_in         ),
        .key_vld        (key_vld        )
    );

    ov7670_config U1(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .config_en      (c_config_en    ),
        //.config_en      (1'b1   ),
        .rdy            (rdy            ),
        .rdata          (rdata          ),
        .rdata_vld      (rdata_vld      ),
        .wdata          (wdata          ),
        .addr           (sub_addr       ),
        .wr_en	        (wen            ),
        .rd_en          (ren            ),
        .cmos_en        (en_capture     ),
        .pwdn           (pwdn           )
    );

    sccb u5(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .ren            (ren            ),
        .wen            (wen            ),
        .sub_addr       (sub_addr       ),
        .rdata          (rdata          ),
        .rdata_vld      (rdata_vld      ),
        .wdata          (wdata          ),
        .rdy            (rdy            ),
        .sio_c          (sio_c          ),
        .sio_d_r        (sio_d_r        ),
        .en_sio_d_w     (en_sio_d_w     ),
        .sio_d_w        (sio_d_w        )
    );

    cmos_capture u6(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .en_capture     (en_capture     ),
        .vsync          (vsync          ),
        .href           (href           ),
        .din            (din            ),
        .dout           (coms_dout      ),
        .dout_vld       (coms_dout_vld  ),
        .dout_sop       (coms_dout_sop  ),
        .dout_eop       (coms_dout_eop  ) 
    );
	 
       mdyGamma u17(
        .clk           (clk_25M), 
        .rst_n         (rst_n),
        .din0          (coms_dout),
        .din0_sop      (coms_dout_sop),
        .din0_eop      (coms_dout_eop),
        .din0_vld      (coms_dout_vld),
        .dout          (gamma_dout),
        .dout_sop      (gamma_dout_sop),
        .dout_eop      (gamma_dout_eop),
        .dout_vld      (gamma_dout_vld),
    );

    rgb565_gray u7(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .din            (gamma_dout      ),
        .din_vld        (gamma_dout_vld  ),
        .din_sop        (gamma_dout_sop  ),
        .din_eop        (gamma_dout_eop  ),
        .dout           (gray_dout      ),
        .dout_vld       (gray_dout_vld  ),
        .dout_sop       (gray_dout_sop  ),
        .dout_eop       (gray_dout_eop  ) 
    );

    gs_filter u8(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .din            (gray_dout      ),
        .din_vld        (gray_dout_vld  ),
        .din_sop        (gray_dout_sop  ),
        .din_eop        (gray_dout_eop  ),
        .dout           (gs_dout        ),
        .dout_vld       (gs_dout_vld    ),
        .dout_sop       (gs_dout_sop    ),
        .dout_eop       (gs_dout_eop    ) 
    );

    gray_bit u9(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .value          (gray_value          ),
        .din            (gs_dout        ),
        .din_vld        (gs_dout_vld    ),
        .din_sop        (gs_dout_sop    ),
        .din_eop        (gs_dout_eop    ),
        .dout           (bit_dout       ),
        .dout_vld       (bit_dout_vld   ),
        .dout_sop       (bit_dout_sop   ),
        .dout_eop       (bit_dout_eop   )    
    );

    sobel u10(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .din            (bit_dout       ),
        .din_vld        (bit_dout_vld   ),
        .din_sop        (bit_dout_sop   ),
        .din_eop        (bit_dout_eop   ),
        .dout           (sobel_dout     ),
        .dout_vld       (sobel_dout_vld ),
        .dout_sop       (sobel_dout_sop ),
        .dout_eop       (sobel_dout_eop )     
    );

    sdram_top u11(
        .clk                (clk_25M        ),//25MHZ
        .clk_100M           (clk_100M       ),
        .rst_n              (rst_n          ),

        .din_1              (coms_dout      ),//褰╄壊鍥惧儚
        .din_vld_1          (coms_dout_vld  ),
        .din_sop_1          (coms_dout_sop  ),
        .din_eop_1          (coms_dout_eop  ),

        .din_2              (sobel_dout ?  16'h0 : 16'hffff ),//浜屽�煎浘鍍�
        .din_vld_2          (sobel_dout_vld ),
        .din_sop_2          (sobel_dout_sop ),
        .din_eop_2          (sobel_dout_eop ),

        .dout_1             (dout_1         ),//褰╄壊鍥惧儚
        .dout_vld_1         (dout_vld_1     ),
        .dout_sop_1         (dout_sop_1     ),
        .dout_eop_1         (dout_eop_1     ),
        .dout_usedw_1       (dout_usedw_1   ),
        .b_rdy_1            (b_rdy_1        ),

        .dout_2             (dout_2         ),//浜屽�煎浘鍍�
        .dout_vld_2         (dout_vld_2     ),
        .dout_sop_2         (dout_sop_2     ),
        .dout_eop_2         (dout_eop_2     ),
        .dout_usedw_2       (dout_usedw_2   ),
        .b_rdy_2            (b_rdy_2        ),
        .key_vld            (key_vld        ),

        //纭欢鎺ュ彛
        .sd_clk             (sd_clk         ),
        .cke                (cke            ),
        .cs                 (cs             ),
        .ras                (ras            ),
        .cas                (cas            ),
        .we                 (we             ),
        .dqm                (dqm            ),
        .sd_addr            (sd_addr        ),
        .sd_bank            (sd_bank        ),

        .dq_in              (dq_in          ),
        .dq_out             (dq_out         ),
        .dq_out_en          (dq_out_en      )

    );

    vga_driver u12(
        .clk                (clk_25M        ),
        .rst_n              (rst_n          ),
        .radius             (radius         ),

        .din_1              (dout_1         ),//褰╄壊鍥惧儚
        .din_vld_1          (dout_vld_1     ),
        .din_sop_1          (dout_sop_1     ),
        .din_eop_1          (dout_eop_1     ),
        .dout_usedw_1       (dout_usedw_1   ),
        .b_rdy_1            (b_rdy_1        ),

        .din_2              (dout_2         ),//浜屽�煎浘鍍�
        .din_vld_2          (dout_vld_2     ),
        .din_sop_2          (dout_sop_2     ),
        .din_eop_2          (dout_eop_2     ),
        .dout_usedw_2       (dout_usedw_2   ),
        .b_rdy_2            (b_rdy_2        ),
        
        .vga_hys            (vga_hys        ),
        .vga_vys            (vga_vys        ),
        .vga_rgb            (vga_rgb        )
    );

    add_5 u13(
        .clk            (clk_25M        ),
        .rst_n          (rst_n          ),
        .din_vld        (key_vld[0]     ),
        .dout           (add_5          )
    );


endmodule // sobel_edge_dection
