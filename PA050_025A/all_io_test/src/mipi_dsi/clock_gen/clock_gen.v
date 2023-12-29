//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           clock_gen
// Last modified Date:  2022年11月27日14:52:46
// Last Version:        V1.0
// Descriptions:        时钟产生模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2022年11月27日14:52:46
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module clock_gen(
    input              sys_clk,        //输入系统时钟
    input              sys_rst_n,      //输入系统复位
    
    output             rst_n,          //输出复位信号
    output             iodiv_rst_n,    //GTP_IOCLKDIV复位信号,低电平有效
    output             iogate_rst_n ,  //GTP_IOCLKBUF复位信号,低电平有效
    
    output             pixel_clk,      //像素时钟
    output             clk_10m,        //10Mhz时钟
    output             clk_hs,         //MIPI DSI Clock lane
    output             clk_hs_90deg    //MIPI DSI Data lane
    );

//wire define
wire              pll_lock_pixel;
wire              pll_lock_hs;
wire              key_value;
wire              pll_hs_rst;
wire              pll_hs_rstodiv;

//*****************************************************
//**                    main code
//*****************************************************

//PLL IP核,产生像素时钟
pll_clk_pixel u_pll_clk_pixel (
  .pll_rst     (1'b0),     
  .clkin1      (sys_clk),      
  .pll_lock    (pll_lock_pixel),    
  .clkout0     (pixel_clk),     
  .clkout1     (clk_10m)      
);    

//PLL IP核,产生MIPI相关时钟    
pll_clk_hs u_pll_clk_hs (
  .pll_rst    (pll_hs_rst),  
  .clkin1     (pixel_clk),      
  .pll_lock   (pll_lock_hs),    
  .clkout0    (clk_hs),     
  .clkout1    (),     
  .clkout5    (clk_hs_90deg)      
);    

//例化按键消抖模块
key_debounce u_key_debounce(
    .sys_clk        (clk_10m),
    .sys_rst_n      (1'b1),
    
    .key            (sys_rst_n),
    .key_flag       (),
    .key_value      (key_value)
    );    

//复位时序控制,使时钟输出更稳定
rst_ctrl u_rst_ctrl(
    .clk            (clk_10m),
    .key_value      (key_value),  

    .pll_lock_pixel (pll_lock_pixel),
    .pll_lock_hs    (pll_lock_hs),

    .rst_n          (rst_n         ),
    .pll_hs_rst     (pll_hs_rst    ),
    .pll_hs_rstodiv (pll_hs_rstodiv),
    .iodiv_rst_n    (iodiv_rst_n   ),
    .iogate_rst_n   (iogate_rst_n  )
    );    
    
endmodule

