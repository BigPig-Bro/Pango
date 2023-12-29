//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           mipi_dsi_colorbar
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        MIPI屏彩条显示
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`include "param_define.h" 

module mipi_dsi_colorbar(
    input             sys_clk,
    input             sys_rst_n,
    //MIPI DSI显示接口
    output            mipi_dsi_rst_n, //MIPI DSI复位信号
    output            mipi_dsi_bl ,   //MIPI DSI背光亮度控制信号
    inout    [3:0]    mipi_dsi_data_p,//四对差分数据线P
    inout    [3:0]    mipi_dsi_data_n,//四对差分数据线N
    inout             mipi_dsi_clk_p ,//一对差分时钟线P
    inout             mipi_dsi_clk_n  //一对差分时钟线N
); 

//parameter define
parameter LANE_WIDTH= 3'd4   ;     //数据通道个数
parameter BUS_WIDTH = 6'd32  ;     //数据总线宽度 LANE_WIDTH*8
parameter EOTP_EN = 1'b1     ;     //EoTp数据包标志 1:发送EoTp数据包

//wire define
wire                    rst_n        ;
wire                    locked       ;
wire                    clk_hs       ;
wire                    clk_hs_90deg ; 
wire                    pixel_clk    ;
wire                    tx_byte_clk  ;
wire                    clk_10m      ; 
wire  [1:0]             dsi_id       ;
wire  [1:0]             mipi_dsi_id  ;                        
wire                    lp_d0_p      ;
wire                    lp_d0_n      ;
wire                    lp_clk_p     ;
wire                    lp_clk_n     ;
wire                    lcm_init_done;                       
wire  [23:0]            rgb_data     ;
wire  [10:0]            pixel_xpos   ;
wire  [10:0]            pixel_ypos   ;
wire                    rgb_data_req ;
wire  [10:0]            h_active     ;
wire  [10:0]            v_active     ;
wire                    hs_en        ;
wire  [31:0]            hs_data      ;
wire                    hs_out_en    ;
wire  [1:0]             lp_data_hs   ;
wire  [31:0]            hs_data_out  ;
wire  [LANE_WIDTH-1:0]  tx_hs_d_flag ;
wire                    tx_hs_c_flag ;
wire  [BUS_WIDTH-1:0 ]  tx_hs_data   ;
wire  [LANE_WIDTH-1:0]  tx_lp_data_p ;
wire  [LANE_WIDTH-1:0]  tx_lp_data_n ;

//*****************************************************
//**                    main code
//*****************************************************

//MIPI DSI屏背光控制
assign mipi_dsi_bl = 1'b1;                                   

//MIPI屏初始化完成前，发送低速配置数据；初始化完成后，发送高速数据
assign tx_hs_c_flag = lcm_init_done; 
assign tx_lp_data_p = lcm_init_done ? {4{lp_data_hs[1]}} : {3'b000,{lp_d0_p}} ;
assign tx_lp_data_n = lcm_init_done ? {4{lp_data_hs[0]}} : {3'b000,{lp_d0_n}} ;
assign tx_hs_d_flag = lcm_init_done ? {4{hs_out_en}} : 4'h0;
assign tx_hs_data   = hs_data_out;

//根据para_define.h文件定义的参数，判断是否用于仿真
`ifdef MIPI_DSI_720P
     assign mipi_dsi_id = 2'd1;  //以720P屏为例进行仿真
`else
    assign mipi_dsi_id = 2'd2;  //以1080P屏为例进行仿真
`endif    


//时钟产生模块    
clock_gen u_clock_gen(
    .sys_clk         (sys_clk     ),
    .sys_rst_n       (sys_rst_n   ),
                      
    .rst_n           (rst_n       ), 
    .iodiv_rst_n     (iodiv_rst_n ), 
    .iogate_rst_n    (iogate_rst_n), 
    .pixel_clk       (pixel_clk),   
    .clk_10m         (clk_10m  ),   
    .clk_hs          (clk_hs   ),   
    .clk_hs_90deg    (clk_hs_90deg) 
);

//MIPI LCD屏初始化
lcm_init u_lcm_init(
    .clk            (clk_10m),
    .rst_n          (rst_n),
    .mipi_dsi_id    (mipi_dsi_id),

    .lp_d0_p        (lp_d0_p ),
    .lp_d0_n        (lp_d0_n ),
    .lp_clk_p       (lp_clk_p),
    .lp_clk_n       (lp_clk_n),
    .dsi_rst_n      (mipi_dsi_rst_n),
    .lcm_init_done  (lcm_init_done)
    );   
    
//MIPI DSI HS模式下数据封装
mipi_dsi_hs_pkt  u_mipi_dsi_hs_pkt(
    .pixel_clk        (pixel_clk),
    .tx_byte_clk      (tx_byte_clk),
    .rst_n            (rst_n),
    
    .mipi_dsi_id      (mipi_dsi_id ),
    .eotp_en          (EOTP_EN     ),
    .rgb_data         (rgb_data), 
    .pixel_xpos       (pixel_xpos  ),
    .pixel_ypos       (pixel_ypos  ),
    .rgb_data_req     (rgb_data_req),    
    .h_active         (h_active),
    .v_active         (v_active),

    .hs_en            (hs_en  ),
    .hs_data          (hs_data)
    );

//LP模式切换至HS模式延时控制    
lp_hs_delay_ctrl  u_lp_hs_delay_ctrl(
    .clk                  (tx_byte_clk),
    .rst_n                (rst_n),

    .hs_en                (hs_en),
    .hs_data_in           (hs_data),

    .lp_data_hs           (lp_data_hs),
    .hs_out_en            (hs_out_en),
    .hs_data_out          (hs_data_out)
    );  

//MIPI时钟和数据转差分输出      
mipi_phy_io_tx #(
    .LANE_WIDTH    (LANE_WIDTH),
    .BUS_WIDTH     (BUS_WIDTH )
    )    
    u_mipi_phy_io_tx(
    .tx_iol_rst       (~rst_n     ),
    .tx_div_rst_n     (iodiv_rst_n ),
    .tx_gate_en       (iogate_rst_n),

    .clk_hs_c         (clk_hs   ),
    .clk_hs_d         (clk_hs_90deg),

    .tx_hs_c_flag     (tx_hs_c_flag),
    .tx_lp_clk_p      (lp_clk_p),  
    .tx_lp_clk_n      (lp_clk_n),  

    .tx_lp_data_p     (tx_lp_data_p),
    .tx_lp_data_n     (tx_lp_data_n),
    .tx_hs_d_flag     (tx_hs_d_flag),
    .tx_hs_data       (tx_hs_data  ),
    .tx_byte_clk      (tx_byte_clk ),

    .mipi_dsi_data_p  (mipi_dsi_data_p),
    .mipi_dsi_data_n  (mipi_dsi_data_n),
    .mipi_dsi_clk_p   (mipi_dsi_clk_p ),
    .mipi_dsi_clk_n   (mipi_dsi_clk_n )
    );

//MIPI屏显示控制(产生彩条数据)
mipi_display    u_mipi_display(
    .clk            (pixel_clk),
    .rst_n          (rst_n),
    .pixel_xpos     (pixel_xpos),
    .pixel_ypos     (pixel_ypos),
    .h_disp         (h_active),
    .v_disp         (v_active),
    .pixel_data     (rgb_data) 
); 

endmodule
