module uart_rx(
    clk     ,
    rst_n   ,
    uart_rx ,
    rx_vld  , 
    rx_data
    );

   
    parameter      CNT_BTL =     20'd2604;
    parameter      CNT_MID =     20'd1302;
    parameter      CNT_RX =         4'd9;
    parameter      DATA_W =         8;

    input               clk             ;
    input               rst_n           ;
    input               uart_rx         ;

    wire                uart_rx         ;
    output[DATA_W-1:0]  rx_data         ;
    output               rx_vld         ; 

    reg   [DATA_W-1:0]  rx_data         ;
    reg                 rx_vld          ;

    reg                 uart_rx_ff0     ;
    reg                 uart_rx_ff1     ;
    reg                 uart_rx_ff2     ;
    reg                 flag            ;
    reg   [19:0]        cnt0            ;
    wire                add_cnt0        ;
    wire                end_cnt0        ;

    reg   [3:0]         cnt1            ;
    wire                add_cnt1        ;
    wire                end_cnt1        ;
    wire                add_en          ;

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

    assign add_cnt0 = flag;
    assign end_cnt0 = add_cnt0 && cnt0== CNT_BTL-1;

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
    assign end_cnt1 = add_cnt1 && cnt1== CNT_RX-1;

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            uart_rx_ff0  <= 1'b1;
            uart_rx_ff1 <= 1'b1;
            uart_rx_ff2 <= 1'b1;
        end
        else begin
            uart_rx_ff0  <= uart_rx;
            uart_rx_ff1 <= uart_rx_ff0;
            uart_rx_ff2 <= uart_rx_ff1;
        end
    end
    assign  add_en = uart_rx_ff2&&~uart_rx_ff1;
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag <= 1'b0;
        end
        else if(add_en)begin
            flag <= 1'b1;
        end
        else if(end_cnt1)begin
            flag <= 1'b0;
        end
    end
   
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rx_vld <= 1'b0;
        end
        else if(end_cnt1)begin
            rx_vld <= 1'b1;
        end
        else begin
            rx_vld <= 1'b0;
        end    
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rx_data <= 8'b0;
        end
        else if(cnt1!=0&&add_cnt0&&cnt0==CNT_MID-1)begin
            rx_data[cnt1-1] <= uart_rx_r2;
        end
    end
    
endmodule

