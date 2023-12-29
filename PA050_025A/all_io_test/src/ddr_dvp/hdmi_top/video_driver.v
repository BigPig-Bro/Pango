//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           video_driver
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        ��Ƶ��ʾ����ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module video_driver(
    input           	pixel_clk	,
    input           	sys_rst_n	,
		
    //RGB�ӿ�	
    output          	video_hs	,    //��ͬ���ź�
    output          	video_vs	,    //��ͬ���ź�
    output          	video_de	,    //����ʹ��
    output  	[15:0]  video_rgb	,    //RGB565��ɫ����
    output	reg			data_req 	,
	output      [10:0]  h_disp,       //���ص������
    output      [10:0]  v_disp,       //���ص������� 
    input   	[15:0]  pixel_data	,   //���ص�����
    output  reg	[10:0]  pixel_xpos	,   //���ص������
    output  reg	[10:0]  pixel_ypos      //���ص�������
);

//parameter define
/*
//1280*720 �ֱ���ʱ�����,60fps

parameter  H_SYNC   =  11'd40;  //��ͬ��
parameter  H_BACK   =  11'd220;  //����ʾ����
parameter  H_DISP   =  11'd1280; //����Ч����
parameter  H_FRONT  =  11'd110;   //����ʾǰ��
parameter  H_TOTAL  =  11'd1650; //��ɨ������

parameter  V_SYNC   =  11'd5;    //��ͬ��
parameter  V_BACK   =  11'd20;   //����ʾ����
parameter  V_DISP   =  11'd720;  //����Ч����
parameter  V_FRONT  =  11'd5;    //����ʾǰ��
parameter  V_TOTAL  =  11'd750;  //��ɨ������
*/
//1024*768 �ֱ���ʱ�����,60fps
parameter  H_SYNC   =  11'd136;  //��ͬ��
parameter  H_BACK   =  11'd160;  //����ʾ����
parameter  H_DISP   =  11'd1024; //����Ч����
parameter  H_FRONT  =  11'd24;   //����ʾǰ��
parameter  H_TOTAL  =  11'd1344; //��ɨ������

parameter  V_SYNC   =  11'd6;    //��ͬ��
parameter  V_BACK   =  11'd29;   //����ʾ����
parameter  V_DISP   =  11'd768;  //����Ч����
parameter  V_FRONT  =  11'd3;    //����ʾǰ��
parameter  V_TOTAL  =  11'd806;  //��ɨ������

//reg define
reg  [11:0] cnt_h;
reg  [11:0] cnt_v;
reg       	video_en;

//*****************************************************
//**                    main code
//*****************************************************

//�г��ֱ���
assign h_disp = H_DISP;
assign v_disp = V_DISP;

assign video_de  = video_en;
assign video_hs  = ( cnt_h < H_SYNC ) ? 1'b0 : 1'b1;  //��ͬ���źŸ�ֵ
assign video_vs  = ( cnt_v < V_SYNC ) ? 1'b0 : 1'b1;  //��ͬ���źŸ�ֵ

//ʹ��RGB�������
always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		video_en <= 1'b0;
	else
		video_en <= data_req;
end

//RGB565�������
assign video_rgb = video_de ? pixel_ypos < V_DISP / 2 ? 
pixel_xpos < (H_DISP / 16  *  1)? 16'B10000_000000_00000: pixel_xpos < (H_DISP / 16  *  2)? 16'B01000_000000_00000:
pixel_xpos < (H_DISP / 16  *  3)? 16'B00100_000000_00000: pixel_xpos < (H_DISP / 16  *  4)? 16'B00010_000000_00000:
pixel_xpos < (H_DISP / 16  *  5)? 16'B00001_000000_00000: pixel_xpos < (H_DISP / 16  *  6)? 16'B00000_100000_00000:

pixel_xpos < (H_DISP / 16  *  7)? 16'B00000_010000_00000: pixel_xpos < (H_DISP / 16  *  8)? 16'B00000_001000_00000:
pixel_xpos < (H_DISP / 16  *  9)? 16'B00000_000100_00000: pixel_xpos < (H_DISP / 16  * 10)? 16'B00000_000010_00000:
pixel_xpos < (H_DISP / 16  * 11)? 16'B00000_000001_00000: pixel_xpos < (H_DISP / 16  * 12)? 16'B00000_000000_10000:

pixel_xpos < (H_DISP / 16  * 13)? 16'B00000_000000_01000: pixel_xpos < (H_DISP / 16  * 14)? 16'B00000_000000_00100:
pixel_xpos < (H_DISP / 16  * 15)? 16'B00000_000000_00010:                                 16'B00000_000000_00001    
:  pixel_data : 16'd0;

//�������ص���ɫ��������
always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		data_req <= 1'b0;
	else if(((cnt_h >= H_SYNC + H_BACK - 2'd2) && (cnt_h < H_SYNC + H_BACK + H_DISP - 2'd2))
                  && ((cnt_v >= V_SYNC + V_BACK) && (cnt_v < V_SYNC + V_BACK+V_DISP)))
		data_req <= 1'b1;
	else
		data_req <= 1'b0;
end

//���ص�x����
always@ (posedge pixel_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        pixel_xpos <= 11'd0;
    else if(data_req)
        pixel_xpos <= cnt_h + 2'd2 - H_SYNC - H_BACK ;
    else 
        pixel_xpos <= 11'd0;
end
    
//���ص�y����	
always@ (posedge pixel_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        pixel_ypos <= 11'd0;
    else if((cnt_v >= (V_SYNC + V_BACK)) && (cnt_v < (V_SYNC + V_BACK + V_DISP)))
        pixel_ypos <= cnt_v + 1'b1 - (V_SYNC + V_BACK) ;
    else 
        pixel_ypos <= 11'd0;
end

//�м�����������ʱ�Ӽ���
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_h <= 11'd0;
    else begin
        if(cnt_h < H_TOTAL - 1'b1)
            cnt_h <= cnt_h + 1'b1;
        else 
            cnt_h <= 11'd0;
    end
end

//�����������м���
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_v <= 11'd0;
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)
            cnt_v <= cnt_v + 1'b1;
        else 
            cnt_v <= 11'd0;
    end
end

endmodule