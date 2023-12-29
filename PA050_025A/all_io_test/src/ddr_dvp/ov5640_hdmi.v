//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�http://www.openedv.com/forum.php
//�Ա����̣�https://zhengdianyuanzi.tmall.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           ov5640_hdmi
// Created by:          ����ԭ��
// Created date:        2023��9��12��17:52:55
// Version:             V1.0
// Descriptions:        OV5640����ͷHDMI��ʾʵ��
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ov5640_hdmi(
    input             sys_clk       ,
    input             sys_rst_n     ,
    //HDMI �ӿ�
    output            tmds_clk_p    ,  // TMDS ʱ��ͨ��
    output            tmds_clk_n    ,
    output [2:0]      tmds_data_p   ,  // TMDS ����ͨ��
    output [2:0]      tmds_data_n   ,
    //����ͷ�ӿ�                     
    input             cam_pclk      ,  //cmos ��������ʱ��
    input             cam_vsync     ,  //cmos ��ͬ���ź�
    input             cam_href      ,  //cmos ��ͬ���ź�
    input  [7:0]      cam_data      ,  //cmos ����
    output            cam_rst_n     ,  //cmos ��λ�źţ��͵�ƽ��Ч
    output            cam_pwdn      ,  //��Դ����ģʽѡ�� 0������ģʽ 1����Դ����ģʽ
    output            cam_scl       ,  //cmos SCCB_SCL��
    inout             cam_sda       ,  //cmos SCCB_SDA��
    //DDR3�ӿ�
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
parameter  V_CMOS_DISP = 11'd768;                  //CMOS�ֱ���--��
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS�ֱ���--��	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; 
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504; 
parameter  APP_ADDR_MAX = 28'd786432   ; 
//wire define
//PLL
wire        pixel_clk       ;  //����ʱ��75M
wire        pixel_clk_5x    ;  //5������ʱ��375M
wire        clk_50m         ;  //output 50M
wire        clk_locked      ;
//OV5640
wire        cmos_frame_vsync;  //֡��Ч�ź�
wire        cmos_frame_valid;  //������Чʹ���ź�
wire [15:0] wr_data         ;  //OV5640д��DDR3������ģ�������
//HDMI
wire        video_vs        ;  //��ͬ���ź�
wire [15:0] rd_data         ;  //DDR3������ģ������ݸ�HDMI
wire        rdata_req       ;  //DDR3������ģ���ʹ��
//DDR3
wire        fram_done       ; //DDR���Ѿ�����һ֡�����־
wire        ddr_init_done   ; //ddr3��ʼ�����

//*****************************************************
//**                    main code
//*****************************************************

//��ʱ�����������������λ�ź�
assign  rst_n = sys_rst_n  & clk_locked  ;

//����PLL IP��
pll_clk  u_pll_clk(
    .pll_rst          (~sys_rst_n  ),
    .clkin1           (sys_clk     ),
    .clkout0          (pixel_clk   ), //����ʱ��
    .clkout1          (pixel_clk_5x), //5������ʱ��
    .clkout2          (clk_50m     ), //output 50M
    .pll_lock         (clk_locked  )
);

//ov5640 ����
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

// ddr3����ģ��
ddr3_ctrl_top u_ddr3_ctrl_top(
    .clk              (clk_50m        ),
    .rst_n            (rst_n          ),
    .ddr3_init_done   (ddr_init_done  ),      //ddr��ʼ������ź�
    // �û��ӿ�           
    .wd_clk           (cam_pclk       ),      //дʱ��
    .rd_clk           (pixel_clk      ),      //��ʱ��
    .wd_en            (cmos_frame_valid),     //������Чʹ���ź�
    .wd_data          (wr_data        ),      //д��Ч����
    .rd_en            (rdata_req      ),      //DDR3 ��ʹ��
    .rd_data          (rd_data        ),      //rfifo�������
    .addr_rd_min      (28'b0   ),      //��DDR3����ʼ��ַ
    .addr_rd_max      (APP_ADDR_MAX   ),      //��DDR�Ľ�����ַ
    .rd_burst_len     (H_CMOS_DISP[10:3]),      //��DDR3�ж����ݵ�ͻ������
    .addr_wd_min      (28'b0   ),      //дDDR3����ʼ��ַ
    .addr_wd_max      (APP_ADDR_MAX   ),      //дDDR�Ľ�����ַ
    .wd_burst_len     (H_CMOS_DISP[10:3]),      //д��DDR3�����ݵ�ͻ������
    //�û��ӿ�            
    .wr_load          (cmos_frame_vsync),     //����Դ�����ź�
    .rd_load          (video_vs       ),      //���Դ�����ź�
    .ddr3_pingpang_en (1'b1),                //DDR3 ƹ�Ҳ���
    .ddr3_read_valid  (1'b1),                //������������
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

//HDMI����ģ��
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