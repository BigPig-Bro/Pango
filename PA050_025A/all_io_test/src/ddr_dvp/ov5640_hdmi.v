//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           ov5640_hdmi
// Created by:          正点原子
// Created date:        2023年9月12日17:52:55
// Version:             V1.0
// Descriptions:        OV5640摄像头HDMI显示实验
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ov5640_hdmi(
    input             sys_clk       ,
    input             sys_rst_n     ,
    //HDMI 接口
    output            tmds_clk_p    ,  // TMDS 时钟通道
    output            tmds_clk_n    ,
    output [2:0]      tmds_data_p   ,  // TMDS 数据通道
    output [2:0]      tmds_data_n   ,
    //摄像头接口                     
    input             cam_pclk      ,  //cmos 数据像素时钟
    input             cam_vsync     ,  //cmos 场同步信号
    input             cam_href      ,  //cmos 行同步信号
    input  [7:0]      cam_data      ,  //cmos 数据
    output            cam_rst_n     ,  //cmos 复位信号，低电平有效
    output            cam_pwdn      ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output            cam_scl       ,  //cmos SCCB_SCL线
    inout             cam_sda       ,  //cmos SCCB_SDA线
    //DDR3接口
    output            mem_rst_n     ,                       
    output            mem_ck        ,
    output            mem_ck_n      ,
    output            mem_cke       ,
    output            mem_ras_n     ,
    output            mem_cas_n     ,
    output            mem_we_n      , 
    output            mem_odt       ,
    output            mem_cs_n      ,
    output 	[14:0]    mem_a         ,   
    output 	[2:0]     mem_ba        ,   
    inout 	[1:0]     mem_dqs       ,
    inout 	[1:0]     mem_dqs_n     ,
    inout 	[15:0]    mem_dq        ,
    output 	[1:0]     mem_dm
    
);
//parameter define                                
parameter  V_CMOS_DISP = 11'd768;                  //CMOS分辨率--行
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS分辨率--列	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; 
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504; 
parameter  APP_ADDR_MAX = 28'd786432   ; 
//wire define
//PLL
wire        pixel_clk       ;  //像素时钟75M
wire        pixel_clk_5x    ;  //5倍像素时钟375M
wire        clk_50m         ;  //output 50M
wire        clk_locked      ;
//OV5640
wire        cmos_frame_vsync;  //帧有效信号
wire        cmos_frame_valid;  //数据有效使能信号
wire [15:0] wr_data         ;  //OV5640写入DDR3控制器模块的数据
//HDMI
wire        video_vs        ;  //场同步信号
wire [15:0] rd_data         ;  //DDR3控制器模块读数据给HDMI
wire        rdata_req       ;  //DDR3控制器模块读使能
//DDR3
wire        fram_done       ; //DDR中已经存入一帧画面标志
wire        ddr_init_done   ; //ddr3初始化完成

//*****************************************************
//**                    main code
//*****************************************************

//待时钟锁定后产生结束复位信号
assign  rst_n = sys_rst_n  & clk_locked  ;

//例化PLL IP核
pll_clk  u_pll_clk(
    .pll_rst          (~sys_rst_n  ),
    .clkin1           (sys_clk     ),
    .clkout0          (pixel_clk   ), //像素时钟
    .clkout1          (pixel_clk_5x), //5倍像素时钟
    .clkout2          (clk_50m     ), //output 50M
    .pll_lock         (clk_locked  )
);

//ov5640 驱动
ov5640_dri u_ov5640_dri(
    .clk              (clk_50m      ),
    .rst_n            (rst_n        ),

    .cam_pclk         (cam_pclk     ),
    .cam_vsync        (cam_vsync    ),
    .cam_href         (cam_href     ),
    .cam_data         (cam_data     ),
    .cam_rst_n        (cam_rst_n    ),
    .cam_pwdn         (cam_pwdn     ),
    .cam_scl          (cam_scl      ),
    .cam_sda          (cam_sda      ),
    
    .capture_start    (ddr_init_done),
    .cmos_h_pixel     (H_CMOS_DISP  ),
    .cmos_v_pixel     (V_CMOS_DISP  ),
    .total_h_pixel    (TOTAL_H_PIXEL),
    .total_v_pixel    (TOTAL_V_PIXEL),
    .cmos_frame_vsync (cmos_frame_vsync),
    .cmos_frame_href  ( ),
    .cmos_frame_valid (cmos_frame_valid),
    .cmos_frame_data  (wr_data      )
); 

// ddr3控制模块
ddr3_ctrl_top u_ddr3_ctrl_top(
    .clk              (clk_50m        ),
    .rst_n            (rst_n          ),
    .ddr3_init_done   (ddr_init_done  ),      //ddr初始化完成信号
    // 用户接口           
    .wd_clk           (cam_pclk       ),      //写时钟
    .rd_clk           (pixel_clk      ),      //读时钟
    .wd_en            (cmos_frame_valid),     //数据有效使能信号
    .wd_data          (wr_data        ),      //写有效数据
    .rd_en            (rdata_req      ),      //DDR3 读使能
    .rd_data          (rd_data        ),      //rfifo输出数据
    .addr_rd_min      (28'b0   ),      //读DDR3的起始地址
    .addr_rd_max      (APP_ADDR_MAX   ),      //读DDR的结束地址
    .rd_burst_len     (H_CMOS_DISP[10:3]),      //从DDR3中读数据的突发长度
    .addr_wd_min      (28'b0   ),      //写DDR3的起始地址
    .addr_wd_max      (APP_ADDR_MAX   ),      //写DDR的结束地址
    .wd_burst_len     (H_CMOS_DISP[10:3]),      //写到DDR3中数据的突发长度
    //用户接口            
    .wr_load          (cmos_frame_vsync),     //输入源更新信号
    .rd_load          (video_vs       ),      //输出源更新信号
    .ddr3_pingpang_en (1'b1),                //DDR3 乒乓操作
    .ddr3_read_valid  (1'b1),                //请求数据输入
    //DDR3 interface
    .mem_rst_n        (mem_rst_n      ),
    .mem_ck           (mem_ck         ),
    .mem_ck_n         (mem_ck_n       ),
    .mem_cke          (mem_cke        ),
    .mem_ras_n        (mem_ras_n      ),
    .mem_cas_n        (mem_cas_n      ),
    .mem_we_n         (mem_we_n       ),
    .mem_odt          (mem_odt        ),
    .mem_cs_n         (mem_cs_n       ),
    .mem_a            (mem_a          ),
    .mem_ba           (mem_ba         ),
    .mem_dqs          (mem_dqs        ),
    .mem_dqs_n        (mem_dqs_n      ),
    .mem_dq           (mem_dq         ),
    .mem_dm           (mem_dm         )
);

//HDMI顶层模块
hdmi_top u_hdmi_top(
    .hdmi_clk         (pixel_clk      ),
    .hdmi_clk_5       (pixel_clk_5x   ),
    // .sys_rst_n        (rst_n&ddr_init_done),
    .sys_rst_n        (rst_n),
    //HDMI interface  
    .tmds_clk_p       (tmds_clk_p     ),
    .tmds_clk_n       (tmds_clk_n     ),
    .tmds_data_p      (tmds_data_p    ),
    .tmds_data_n      (tmds_data_n    ),
    //user interface  
    .rd_data          (rd_data        ),
    .rd_en            (rdata_req      ),
    .video_vs         (video_vs       ),
    .pixel_xpos       ( ),
    .pixel_ypos       ( )
);

endmodule