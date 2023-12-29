//****************************************Copyright (c)***********************************//
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡFPGA & STM32���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved	                               
//----------------------------------------------------------------------------------------
// File name:           key_debounce
// Last modified Date:  2018/4/24 9:56:36
// Last Version:        V1.1
// Descriptions:        ��������
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2018/3/29 10:55:56
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
// Modified by:		    ����ԭ��
// Modified date:	    2018/4/24 9:56:36
// Version:			    V1.1
// Descriptions:	    ͨ������������е��������
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module key_debounce(
    input            sys_clk,          //�ⲿ50Mʱ��
    input            sys_rst_n,        //�ⲿ��λ�źţ�����Ч
    
    input            key,              //�ⲿ��������
    output reg       key_flag,         //����������Ч�ź�
    output reg       key_value = 1         //���������������  
    );

//reg define    
reg [31:0] delay_cnt = 1'b0;
reg        key_reg0 = 1'b1;
reg        key_reg1 = 1'b1;

//*****************************************************
//**                    main code
//*****************************************************
always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (!sys_rst_n) begin 
        key_reg0   <= 1'b1;
        key_reg1   <= 1'b1;
        delay_cnt <= 32'd0;
    end
    else begin
        key_reg0 <= key;                     //������ֵ�ӳ�һ��
        key_reg1 <= key_reg0;                //������ֵ�ӳ�����
        if(key_reg1 != key_reg0)             //һ����⵽����״̬�����仯(�а��������»��ͷ�)
            delay_cnt <= 32'd1000000;        //����ʱ����������װ�س�ʼֵ������ʱ��Ϊ20ms��
        else if(key_reg1 == key_reg0) begin  //�ڰ���״̬�ȶ�ʱ���������ݼ�����ʼ20ms����ʱ
                 if(delay_cnt > 32'd0)
                     delay_cnt <= delay_cnt - 1'b1;
                 else
                     delay_cnt <= delay_cnt;
             end           
    end   
end

always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (!sys_rst_n) begin 
        key_flag  <= 1'b0;
        key_value <= 1'b1;          
    end
    else begin
        if(delay_cnt == 32'd1) begin   //���������ݼ���1ʱ��˵�������ȶ�״̬ά����20ms
            key_flag  <= 1'b1;         //��ʱ�������̽���������һ��ʱ�����ڵı�־�ź�
            key_value <= key_reg1;          //���Ĵ��ʱ������ֵ
        end
        else begin
            key_flag  <= 1'b0;
            key_value <= key_value; 
        end  
    end   
end
    
endmodule 