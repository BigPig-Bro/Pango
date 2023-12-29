//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           rst_ctrl
// Last modified Date:  2022年11月27日14:52:46
// Last Version:        V1.0
// Descriptions:        复位时序控制
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2022年11月27日14:52:46
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module rst_ctrl(
    input            clk,             
    input            key_value,        
    
    input            pll_lock_pixel,  //PLL IP核(pll_clk_pixel) Lock信号
    input            pll_lock_hs,     //PLL IP核(pll_clk_hs) Lock信号
    
    output           rst_n,           //复位信号
    output           iodiv_rst_n,     //GTP_IOCLKDIV复位信号,低电平有效
    output           iogate_rst_n,    //GTP_IOCLKBUF复位信号,低电平有效    
    output  reg      pll_hs_rst,      //PLL IP核(pll_clk_hs)复位信号
    output  reg      pll_hs_rstodiv   //PLL IP核(pll_clk_hs) rstodiv信号
    );

//reg define    
reg   [10:0]  pll_hs_rst_cnt;
reg   [13:0]  pll_hs_rstodiv_cnt;
reg   [7:0]   rst_delay_cnt;
reg           pll_lock_hs_d0;
reg           pll_lock_hs_d1;

//wire define
wire          pll_lost;

//*****************************************************
//**                    main code
//*****************************************************

//pll_lock_hs信号才下降沿,PLL IP核失锁后重新执行初始化
assign pll_lost = pll_lock_hs_d1 & (~pll_lock_hs_d0);

assign rst_n = key_value & pll_lock_pixel & (~pll_lost);

//复位释放顺序：先释放GTP_IOCLKDIV复位信号,再释放GTP_IOCLKBUF复位信号
assign iodiv_rst_n = (rst_delay_cnt >= 100) ?  1'b1  :  1'b0;
assign iogate_rst_n = (rst_delay_cnt >= 200) ?  1'b1  :  1'b0;

//pgl22g需要按照按下下面的复位时序复位pll,相位差才能稳定
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        pll_hs_rst_cnt <= 1'b0;
        pll_hs_rst <= 1'b1;
    end
    else if(~pll_hs_rstodiv) begin
        if(pll_hs_rst_cnt == 1500)   //150us结束复位
            pll_hs_rst <= 1'b0;
        else begin
            pll_hs_rst <= 1'b1;
            pll_hs_rst_cnt <= pll_hs_rst_cnt + 1'b1;
        end
    end
end    

always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) 
        pll_hs_rstodiv_cnt <= 1'b0;
    else if(~pll_hs_rst && pll_hs_rstodiv_cnt < 5600)
        pll_hs_rstodiv_cnt <= pll_hs_rstodiv_cnt + 1'b1;
	else;	
end

always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) 
        pll_hs_rstodiv <= 1'b1;
    else if(pll_hs_rstodiv_cnt >= 5500 && pll_hs_rstodiv_cnt <5600)
        pll_hs_rstodiv <= 1'b1;
    else
        pll_hs_rstodiv <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) 
        rst_delay_cnt <= 1'b0;
    else if(pll_hs_rstodiv_cnt == 5600) begin
        if(rst_delay_cnt < 200)
            rst_delay_cnt <= rst_delay_cnt + 1'b1;
    end
    else;	
end

//对pll_lock_hs信号打拍采沿
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        pll_lock_hs_d0 <= 1'b0;
        pll_lock_hs_d1 <= 1'b0;
    end    
    else begin
        pll_lock_hs_d0 <= pll_lock_hs;
        pll_lock_hs_d1 <= pll_lock_hs_d0;
    end        
end
    
endmodule 
