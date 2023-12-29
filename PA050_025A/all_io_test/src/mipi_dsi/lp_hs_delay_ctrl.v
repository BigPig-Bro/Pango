//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           lp_hs_delay_ctrl
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        LP模式切换至HS模式延时控制
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lp_hs_delay_ctrl (
    input                clk,                  
    input                rst_n,
                         
    input                hs_en,        //高速数据使能信号
    input        [31:0]  hs_data_in,   //输入32位高速数据 
                         
    output  reg  [1:0]   lp_data_hs,   //2比特LP低速数据                        
    output               hs_out_en,    //输出延时后的高速数据使能信号
    output       [31:0]  hs_data_out   //输出32位高速数据 
);

//parameter define
localparam T_LPX        = 4'd5;    //LP10持续时钟周期
localparam T_HS_PREPARE = 4'd2;    //LP00至HS_ZERO时钟周期                
localparam T_HS_ZERO    = 4'd11;   //发送HS-0时钟周期                   
localparam st_idle      = 5'b00001;//空闲状态 
localparam st_lpx       = 5'b00010;//发送LP-10
localparam st_hs_prepare= 5'b00100;//发送LP-00
localparam st_hs_zero   = 5'b01000;//发送HS-0
localparam st_data_pkt  = 5'b10000;//发送数据包(包含EoT)

//reg define
reg   [4:0]   cur_state;
reg   [4:0]   next_state;
reg           hs_en_d0;
reg           hs_en_d1;
reg   [3:0]   tx_cnt;     //发送计数器    
reg           rd_en_d0;

//wire define
wire          pos_hs_en;  //高速数据使能信号上升沿         
wire          rd_en;      //读FIFO使能信号
wire  [31:0]  rd_data;    //读FIFO数据
wire          rd_empty;   //FIFO空信号

//*****************************************************
//**                    main code
//*****************************************************

assign pos_hs_en = ~hs_en_d1 & hs_en_d0;  //采高速数据使能信号上升沿 
assign rd_en = ~rd_empty & (cur_state == st_data_pkt);
assign hs_out_en = (cur_state == st_hs_zero) | (cur_state == st_data_pkt);
assign hs_data_out = rd_en_d0 ? rd_data  :  32'b0; 

//寄存hs_en信号,用于采沿
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        hs_en_d0 <= 1'b0;
        hs_en_d1 <= 1'b0;
    end
    else begin
        hs_en_d0 <= hs_en;
        hs_en_d1 <= hs_en_d0;
    end
end

//寄存读FIFO使能信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rd_en_d0 <= 1'b0;
    else 
        rd_en_d0 <= rd_en;
end

//(三段式状态机)同步时序描述状态转移
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;
    else
        cur_state <= next_state;
end

//组合逻辑判断状态转移条件
always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle: begin                          
           if(pos_hs_en)
               next_state = st_lpx;
           else
               next_state = st_idle;
        end
        st_lpx : begin
            if(tx_cnt == T_LPX)
                next_state = st_hs_prepare;
            else
                next_state = st_lpx;
        end 
        st_hs_prepare : begin
            if(tx_cnt == T_HS_PREPARE)
                next_state = st_hs_zero;
            else
                next_state = st_hs_prepare;
        end 
        st_hs_zero : begin
            if(tx_cnt == T_HS_ZERO)
                next_state = st_data_pkt;
            else
                next_state = st_hs_zero;
        end 
        st_data_pkt : begin
            if(rd_empty)
                next_state = st_idle;
            else
                next_state = st_data_pkt;
        end
        default: next_state = st_idle;
    endcase
end        

//时序电路描述状态输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        lp_data_hs <= 2'b11;
        tx_cnt <= 1'b0;
    end
    else begin
        case(cur_state)
            st_idle : lp_data_hs <= 2'b11;      //LP-11
            st_lpx  : begin
                lp_data_hs <= 2'b01;            //LP-10
                if(tx_cnt < T_LPX)
                    tx_cnt <= tx_cnt + 1'b1;
                else
                    tx_cnt <= 1'b0;
            end
            st_hs_prepare : begin
                lp_data_hs <= 2'b00;            //LP-00
                if(tx_cnt < T_HS_PREPARE)
                    tx_cnt <= tx_cnt + 1'b1;
                else
                    tx_cnt <= 1'b0;
            end
            st_hs_zero : begin                  //HS-0
                if(tx_cnt < T_HS_ZERO)
                    tx_cnt <= tx_cnt + 1'b1;
                else
                    tx_cnt <= 1'b0;
            end
            st_data_pkt : begin
                if(rd_empty)
                    lp_data_hs <= 2'b11;        //LP11
            end
            default :;
       endcase
    end
end

//同步FIFO缓存数据
sync_fifo_256x32b u_sync_fifo_256x32b(
    .clk           (clk),   
    .rst           (~rst_n),   

    .wr_en         (hs_en  ),
    .wr_data       (hs_data_in),
    .wr_full       (),   
    .rd_en         (rd_en),   
    .rd_data       (rd_data),   
    .almost_full   (),   
    .rd_empty      (rd_empty),
    .almost_empty  ()   
    );

endmodule
