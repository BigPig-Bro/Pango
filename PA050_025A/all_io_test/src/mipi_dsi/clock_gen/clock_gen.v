//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�http://www.openedv.com/forum.php
//�Ա����̣�https://zhengdianyuanzi.tmall.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           clock_gen
// Last modified Date:  2022��11��27��14:52:46
// Last Version:        V1.0
// Descriptions:        ʱ�Ӳ���ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2022��11��27��14:52:46
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module clock_gen(
    input              sys_clk,        //����ϵͳʱ��
    input              sys_rst_n,      //����ϵͳ��λ
    
    output             rst_n,          //�����λ�ź�
    output             iodiv_rst_n,    //GTP_IOCLKDIV��λ�ź�,�͵�ƽ��Ч
    output             iogate_rst_n ,  //GTP_IOCLKBUF��λ�ź�,�͵�ƽ��Ч
    
    output             pixel_clk,      //����ʱ��
    output             clk_10m,        //10Mhzʱ��
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

//PLL IP��,��������ʱ��
pll_clk_pixel u_pll_clk_pixel (
  .pll_rst     (1'b0),     
  .clkin1      (sys_clk),      
  .pll_lock    (pll_lock_pixel),    
  .clkout0     (pixel_clk),     
  .clkout1     (clk_10m)      
);    

//PLL IP��,����MIPI���ʱ��    
pll_clk_hs u_pll_clk_hs (
  .pll_rst    (pll_hs_rst),  
  .clkin1     (pixel_clk),      
  .pll_lock   (pll_lock_hs),    
  .clkout0    (clk_hs),     
  .clkout1    (),     
  .clkout5    (clk_hs_90deg)      
);    

//������������ģ��
key_debounce u_key_debounce(
    .sys_clk        (clk_10m),
    .sys_rst_n      (1'b1),
    
    .key            (sys_rst_n),
    .key_flag       (),
    .key_value      (key_value)
    );    

//��λʱ�����,ʹʱ��������ȶ�
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

