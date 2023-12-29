//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           esc_lpdt_tx
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        LPDT模式发送配置数据
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module esc_lpdt_tx (
    input                clk,
    input                rst_n,
    
    input                lpdt_tx_vld,    //发送数据有效信号
    input       [7:0]    lpdt_tx_data,   //8bit发送的数据    
                         
    output  reg          lpdt_tx_rdy,    //准备完成,高电平表示可以开始发送下一个字节
    output  reg          lpdt_tx_done,   //单次数据包发送完成
    output  reg          lp_d0_p,        //MIPI_DSI_D0_P LP模式下引脚驱动
    output  reg          lp_d0_n         //MIPI_DSI_D0_N LP模式下引脚驱动
);

//parameter define
localparam  LPDT_PATTERN =   8'h87; //LPDT Command pattern

//reg define
reg  [2:0]   entry_esc_cnt;   //开始进入Escape Mode计数器
reg  [3:0]   tx_esc_cnt;      //发送命令和数据计数器
reg  [7:0]   tx_esc_data;     //要发送的命令和数据
reg          tx_esc_flag;     //发送命令位和数据位的标志
reg          tx_esc_flag_d0;  //对tx_esc_flag延时一个时钟周期
reg          tx_esc_code;     //Spaced-One-Hot编码模式
reg          space_code_en;   //Space位使能信号
reg          exit_esc_flag;   //推出Escape Mode的标志

//*****************************************************
//**                    main code
//*****************************************************

//检测到输入数据有效信号,计数器累加,开始进入Escape模式
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        entry_esc_cnt <= 1'b0;
    else if(lpdt_tx_vld && entry_esc_cnt < 3'd6) 
        entry_esc_cnt <= entry_esc_cnt + 1'b1;
    else if(lpdt_tx_done)
        entry_esc_cnt <= 1'b0;
	else;	
end

//发送命令位和数据位的标志
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        tx_esc_flag <= 1'b0;
    else if(entry_esc_cnt == 3'd5)
        tx_esc_flag <= 1'b1;
    else if(~lpdt_tx_vld && tx_esc_cnt == 4'd15)    
        tx_esc_flag <= 1'b0;
	else;	
end

//对tx_esc_flag延时一个时钟周期
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        tx_esc_flag_d0 <= 1'b0;
    else
        tx_esc_flag_d0 <= tx_esc_flag;
end

//Escape模式下,计数器累加
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        tx_esc_cnt <= 1'b0;
    else if(tx_esc_flag)
        tx_esc_cnt <= tx_esc_cnt + 1'b1;
    else
        tx_esc_cnt <= 1'b0;
end

//选择发送的命令或者数据        
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        tx_esc_data <= 1'b0;
    else if(entry_esc_cnt == 3'd4)    
        tx_esc_data <= LPDT_PATTERN;
    else if(lpdt_tx_rdy && lpdt_tx_vld)
        tx_esc_data <= lpdt_tx_data;
	else;
end

//数据准备完成信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        lpdt_tx_rdy <= 1'b0;
    else if(lpdt_tx_rdy && lpdt_tx_vld)    
        lpdt_tx_rdy <= 1'b0;
    else if(lpdt_tx_vld && tx_esc_cnt == 4'd14)
        lpdt_tx_rdy <= 1'b1;
	else;	
end

//单包数据发送完成
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        lpdt_tx_done <= 1'b0;
    else if(~lpdt_tx_vld && tx_esc_cnt == 4'd15)
        lpdt_tx_done <= 1'b1;
    else 
        lpdt_tx_done <= 1'b0;
end

//退出Escape模式的标志
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        exit_esc_flag <= 1'b0;
    else 
        exit_esc_flag <= lpdt_tx_done;
end

//Spaced-One-Hot编码模式
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        tx_esc_code <= 1'b0;
    else if(tx_esc_flag)    
        tx_esc_code <= tx_esc_data[tx_esc_cnt[3:1]];
    else
        tx_esc_code <= 1'b0;
end

//Space位使能信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        space_code_en <= 1'b0;
    else 
        space_code_en <= tx_esc_cnt[0];
end

//进入和退出Escape模式:
//LP11→LP10→LP00→LP01→LP00→[Entry Command]→[lpdt_tx_data......]→LP10→LP11
//MIPI_DSI_D0_P LP模式下引脚驱动
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        lp_d0_p <= 1'b1;
    else if(entry_esc_cnt == 3'd0 || entry_esc_cnt == 3'd1)    
        lp_d0_p <= 1'b1;
    else if(tx_esc_code & tx_esc_flag_d0 & (~space_code_en)) 
        lp_d0_p <= 1'b1;
    else
        lp_d0_p <= 1'b0;
end

//MIPI_DSI_D0_N LP模式下引脚驱动
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        lp_d0_n <= 1'b1;
    else if((~exit_esc_flag && entry_esc_cnt == 3'd0) || entry_esc_cnt == 3'd3)    
        lp_d0_n <= 1'b1;
    else if(~tx_esc_code & tx_esc_flag_d0 & (~space_code_en)) 
        lp_d0_n <= 1'b1;
    else
        lp_d0_n <= 1'b0;
end

endmodule 
