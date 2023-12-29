//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           lp_to_hs_clk
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        LP模式下mipi_clk,到高速模式下的mipi_clk切换
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lp_to_hs_clk (
    input                clk,
    input                rst_n,
    
    input                lcm_cfg_done,   //DSI屏幕寄存器配置完成
    output               lp_clk_p,       //LP模式下mipi_clk
    output               lp_clk_n,    
    output   reg         lcm_init_done   //DSI屏幕初始化完成信号
);

//reg define
reg  [3:0]   delay_cnt;    //延时计数器

//*****************************************************
//**                    main code
//*****************************************************

//clock lane send  lp11→01→00 
assign lp_clk_p = delay_cnt > 4'd4  ?  1'b1  :  1'b0;
assign lp_clk_n = delay_cnt > 4'd8  ?  1'b1  :  1'b0;

//延时计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        delay_cnt <= 4'b0;
    else if(lcm_cfg_done && delay_cnt < 4'd15) 
        delay_cnt <= delay_cnt + 4'b1;
end

//DSI屏幕初始化完成
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        lcm_init_done <= 1'b0;
    else if(delay_cnt == 4'd15) 
        lcm_init_done <= 1'b1;
    else
        lcm_init_done <= 1'b0;
end

endmodule 
