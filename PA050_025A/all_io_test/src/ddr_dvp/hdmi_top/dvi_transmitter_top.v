//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           dvi_transmitter_top
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        HDMI����ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module dvi_transmitter_top(
    input        pclk,           // pixel clock
    input        pclk_x5,        // pixel clock x5
    input        reset_n,        // reset
    
    input [23:0] video_din,      // RGB888 video in
    input        video_hsync,    // hsync data
    input        video_vsync,    // vsync data
    input        video_de,       // data enable
    
    output       tmds_clk_p,     // TMDS ʱ��ͨ��
    output       tmds_clk_n,
    output [2:0] tmds_data_p,    // TMDS ����ͨ��
    output [2:0] tmds_data_n
   );
    
//wire define
wire        reset;
    
//��������
wire [9:0]  red_10bit;
wire [9:0]  green_10bit;
wire [9:0]  blue_10bit;
wire [9:0]  clk_10bit;
  
//��������
wire [2:0]  tmds_data_serial;
wire        tmds_clk_serial;

//*****************************************************
//**                    main code
//***************************************************** 

assign clk_10bit = 10'b1111100000;

//�첽��λ��ͬ���ͷ�
asyn_rst_syn reset_syn(
    .reset_n    (reset_n),
    .clk        (pclk),
    
    .syn_reset  (reset)    //����Ч
    );
  
//��������ɫͨ�����б���
dvi_encoder encoder_b (
    .clkin      (pclk),
    .rstin      (reset),
    
    .din        (video_din[7:0]),
    .c0         (video_hsync),
    .c1         (video_vsync),
    .de         (video_de),
    .dout       (blue_10bit)
    );

dvi_encoder encoder_g (
    .clkin      (pclk),
    .rstin      (reset),
    
    .din        (video_din[15:8]),
    .c0         (1'b0),
    .c1         (1'b0),
    .de         (video_de),
    .dout       (green_10bit)
    );
    
dvi_encoder encoder_r (
    .clkin      (pclk),
    .rstin      (reset),
    
    .din        (video_din[23:16]),
    .c0         (1'b0),
    .c1         (1'b0),
    .de         (video_de),
    .dout       (red_10bit)
    );

//�Ա��������ݽ��в���ת��
serializer_10_to_1 serializer_b(
    .serial_clk_5x      (pclk_x5),              // ���봮������ʱ��
    .paralell_data      (blue_10bit),           // ���벢������
    .reset_n            (reset),
    .serial_data_p      (tmds_data_p[0]),       // �����������P
    .serial_data_n      (tmds_data_n[0])        // �����������N
    );

serializer_10_to_1 serializer_g(
    .serial_clk_5x      (pclk_x5),              // ���봮������ʱ��
    .paralell_data      (green_10bit),          // ���벢������
    .reset_n            (reset),
    .serial_data_p      (tmds_data_p[1]),       // �����������P
    .serial_data_n      (tmds_data_n[1])        // �����������N
    );

serializer_10_to_1 serializer_r(
    .serial_clk_5x      (pclk_x5),              // ���봮������ʱ��
    .paralell_data      (red_10bit),            // ���벢������
    .reset_n            (reset),
    .serial_data_p      (tmds_data_p[2]),       // �����������P
    .serial_data_n      (tmds_data_n[2])        // �����������N
    );

serializer_10_to_1 serializer_clk(
    .serial_clk_5x      (pclk_x5),
    .paralell_data      (clk_10bit),
    .reset_n            (reset),
    .serial_data_p      (tmds_clk_p),           // �������ʱ��P
    .serial_data_n      (tmds_clk_n)            // �������ʱ��N
    );

endmodule