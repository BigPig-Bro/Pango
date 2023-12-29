//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�http://www.openedv.com/forum.php
//�Ա����̣�https://zhengdianyuanzi.tmall.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           rst_ctrl
// Last modified Date:  2022��11��27��14:52:46
// Last Version:        V1.0
// Descriptions:        ��λʱ�����
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2022��11��27��14:52:46
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module rst_ctrl(
    input            clk,             
    input            key_value,        
    
    input            pll_lock_pixel,  //PLL IP��(pll_clk_pixel) Lock�ź�
    input            pll_lock_hs,     //PLL IP��(pll_clk_hs) Lock�ź�
    
    output           rst_n,           //��λ�ź�
    output           iodiv_rst_n,     //GTP_IOCLKDIV��λ�ź�,�͵�ƽ��Ч
    output           iogate_rst_n,    //GTP_IOCLKBUF��λ�ź�,�͵�ƽ��Ч    
    output  reg      pll_hs_rst,      //PLL IP��(pll_clk_hs)��λ�ź�
    output  reg      pll_hs_rstodiv   //PLL IP��(pll_clk_hs) rstodiv�ź�
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

//pll_lock_hs�źŲ��½���,PLL IP��ʧ��������ִ�г�ʼ��
assign pll_lost = pll_lock_hs_d1 & (~pll_lock_hs_d0);

assign rst_n = key_value & pll_lock_pixel & (~pll_lost);

//��λ�ͷ�˳�����ͷ�GTP_IOCLKDIV��λ�ź�,���ͷ�GTP_IOCLKBUF��λ�ź�
assign iodiv_rst_n = (rst_delay_cnt >= 100) ?  1'b1  :  1'b0;
assign iogate_rst_n = (rst_delay_cnt >= 200) ?  1'b1  :  1'b0;

//pgl22g��Ҫ���հ�������ĸ�λʱ��λpll,��λ������ȶ�
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        pll_hs_rst_cnt <= 1'b0;
        pll_hs_rst <= 1'b1;
    end
    else if(~pll_hs_rstodiv) begin
        if(pll_hs_rst_cnt == 1500)   //150us������λ
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

//��pll_lock_hs�źŴ��Ĳ���
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
