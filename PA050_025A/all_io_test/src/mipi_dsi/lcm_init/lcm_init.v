//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           lcm_init
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        LCD Module初始化
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`include "../param_define.h" 

module lcm_init (
    input                clk,
    input                rst_n,
    input        [1:0]   mipi_dsi_id,    //MIPI屏ID 1:720P  2:1080P
    
    output               lp_d0_p,        //MIPI_DSI_D0_P LP模式下引脚驱动
    output               lp_d0_n,        //MIPI_DSI_D0_N LP模式下引脚驱动
    output               lp_clk_p,       //MIPI_DSI_CLK_P LP模式下引脚驱动
    output               lp_clk_n,       //MIPI_DSI_CLK_N LP模式下引脚驱动
    output               dsi_rst_n,      //MIPI DSI复位信号
    output               lcm_init_done   //DSI屏幕初始化完成
);

//wire define
wire          init_rst_n  ;
wire          lpdt_tx_rdy ;
wire          lpdt_tx_done;
wire          lpdt_tx_vld ;
wire  [7:0]   lpdt_tx_data;
wire          lcm_cfg_done;
wire          crc_en      ;
wire          crc_clr     ;
wire  [7:0]   crc_d8      ;
wire  [15:0]  crc_result  ;
wire  [15:0]  crc_data    ;

//*****************************************************
//**                    main code
//*****************************************************

`ifdef SIM
    assign init_rst_n = rst_n;
`else
    assign init_rst_n = dsi_rst_n;
`endif    

//调换CRC计算结果值的高低位
assign crc_result = {crc_data[0],crc_data[1],crc_data[2],crc_data[3],
                     crc_data[4],crc_data[5],crc_data[6],crc_data[7],
                     crc_data[8],crc_data[9],crc_data[10],crc_data[11],
                     crc_data[12],crc_data[13],crc_data[14],crc_data[15]};

//MIPI DSI复位信号控制
mipi_dsi_rst_ctrl u_mipi_dsi_rst_ctrl(
    .clk               (clk),
    .rst_n             (rst_n),
    .dsi_rst_n         (dsi_rst_n)
    );                     

//LCD Module寄存器配置
lcm_reg_cfg  u_lcm_reg_cfg(
    .clk              (clk          ),
    .rst_n            (init_rst_n   ),
    
    .mipi_dsi_id      (mipi_dsi_id  ),
                       
    .lpdt_tx_rdy      (lpdt_tx_rdy  ),
    .lpdt_tx_done     (lpdt_tx_done ),
    .crc_result       (crc_result   ),
                       
    .lpdt_tx_vld      (lpdt_tx_vld  ),
    .lpdt_tx_data     (lpdt_tx_data ),
    .lcm_cfg_done     (lcm_cfg_done ),
    .crc_en           (crc_en       ),
    .crc_clr          (crc_clr      ),
    .crc_d8           (crc_d8       )
    );

//LPDT模式发送配置数据,并行数据转串行数据
esc_lpdt_tx u_esc_lpdt_tx(
    .clk              (clk  ),
    .rst_n            (init_rst_n),

    .lpdt_tx_vld      (lpdt_tx_vld ),
    .lpdt_tx_data     (lpdt_tx_data),

    .lpdt_tx_rdy      (lpdt_tx_rdy ),
    .lpdt_tx_done     (lpdt_tx_done),
    .lp_d0_p          (lp_d0_p   ),
    .lp_d0_n          (lp_d0_n   )
    );

//CRC16 D8计算模块  
crc16_d8  u_crc16_d8(
    .clk            (clk     ),
    .rst_n          (init_rst_n),
    .data           (crc_d8  ),
    .crc_en         (crc_en  ),
    .crc_clr        (crc_clr ),
    .crc_data       (crc_data),
    .crc_next       ()
    );  

//LP模式下mipi_clk,到高速模式下的mipi_clk切换    
lp_to_hs_clk   u_lp_to_hs_clk(
    .clk            (clk  ),
    .rst_n          (init_rst_n),

    .lcm_cfg_done   (lcm_cfg_done),
    .lp_clk_p       (lp_clk_p     ),
    .lp_clk_n       (lp_clk_n     ),
    .lcm_init_done  (lcm_init_done)
    ); 
    
endmodule 
