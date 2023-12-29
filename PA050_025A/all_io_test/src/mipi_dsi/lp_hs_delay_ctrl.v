//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�http://www.openedv.com/forum.php
//�Ա����̣�https://zhengdianyuanzi.tmall.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           lp_hs_delay_ctrl
// Created by:          ����ԭ��
// Created date:        2023��9��23��15:38:10
// Version:             V1.0
// Descriptions:        LPģʽ�л���HSģʽ��ʱ����
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lp_hs_delay_ctrl (
    input                clk,                  
    input                rst_n,
                         
    input                hs_en,        //��������ʹ���ź�
    input        [31:0]  hs_data_in,   //����32λ�������� 
                         
    output  reg  [1:0]   lp_data_hs,   //2����LP��������                        
    output               hs_out_en,    //�����ʱ��ĸ�������ʹ���ź�
    output       [31:0]  hs_data_out   //���32λ�������� 
);

//parameter define
localparam T_LPX        = 4'd5;    //LP10����ʱ������
localparam T_HS_PREPARE = 4'd2;    //LP00��HS_ZEROʱ������                
localparam T_HS_ZERO    = 4'd11;   //����HS-0ʱ������                   
localparam st_idle      = 5'b00001;//����״̬ 
localparam st_lpx       = 5'b00010;//����LP-10
localparam st_hs_prepare= 5'b00100;//����LP-00
localparam st_hs_zero   = 5'b01000;//����HS-0
localparam st_data_pkt  = 5'b10000;//�������ݰ�(����EoT)

//reg define
reg   [4:0]   cur_state;
reg   [4:0]   next_state;
reg           hs_en_d0;
reg           hs_en_d1;
reg   [3:0]   tx_cnt;     //���ͼ�����    
reg           rd_en_d0;

//wire define
wire          pos_hs_en;  //��������ʹ���ź�������         
wire          rd_en;      //��FIFOʹ���ź�
wire  [31:0]  rd_data;    //��FIFO����
wire          rd_empty;   //FIFO���ź�

//*****************************************************
//**                    main code
//*****************************************************

assign pos_hs_en = ~hs_en_d1 & hs_en_d0;  //�ɸ�������ʹ���ź������� 
assign rd_en = ~rd_empty & (cur_state == st_data_pkt);
assign hs_out_en = (cur_state == st_hs_zero) | (cur_state == st_data_pkt);
assign hs_data_out = rd_en_d0 ? rd_data  :  32'b0; 

//�Ĵ�hs_en�ź�,���ڲ���
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        hs_en_d0 <= 1'b0;
        hs_en_d1 <= 1'b0;
    end
    else begin
        hs_en_d0 <= hs_en;
        hs_en_d1 <= hs_en_d0;
    end
end

//�Ĵ��FIFOʹ���ź�
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rd_en_d0 <= 1'b0;
    else 
        rd_en_d0 <= rd_en;
end

//(����ʽ״̬��)ͬ��ʱ������״̬ת��
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;
    else
        cur_state <= next_state;
end

//����߼��ж�״̬ת������
always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle: begin                          
           if(pos_hs_en)
               next_state = st_lpx;
           else
               next_state = st_idle;
        end
        st_lpx : begin
            if(tx_cnt == T_LPX)
                next_state = st_hs_prepare;
            else
                next_state = st_lpx;
        end 
        st_hs_prepare : begin
            if(tx_cnt == T_HS_PREPARE)
                next_state = st_hs_zero;
            else
                next_state = st_hs_prepare;
        end 
        st_hs_zero : begin
            if(tx_cnt == T_HS_ZERO)
                next_state = st_data_pkt;
            else
                next_state = st_hs_zero;
        end 
        st_data_pkt : begin
            if(rd_empty)
                next_state = st_idle;
            else
                next_state = st_data_pkt;
        end
        default: next_state = st_idle;
    endcase
end        

//ʱ���·����״̬���
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        lp_data_hs <= 2'b11;
        tx_cnt <= 1'b0;
    end
    else begin
        case(cur_state)
            st_idle : lp_data_hs <= 2'b11;      //LP-11
            st_lpx  : begin
                lp_data_hs <= 2'b01;            //LP-10
                if(tx_cnt < T_LPX)
                    tx_cnt <= tx_cnt + 1'b1;
                else
                    tx_cnt <= 1'b0;
            end
            st_hs_prepare : begin
                lp_data_hs <= 2'b00;            //LP-00
                if(tx_cnt < T_HS_PREPARE)
                    tx_cnt <= tx_cnt + 1'b1;
                else
                    tx_cnt <= 1'b0;
            end
            st_hs_zero : begin                  //HS-0
                if(tx_cnt < T_HS_ZERO)
                    tx_cnt <= tx_cnt + 1'b1;
                else
                    tx_cnt <= 1'b0;
            end
            st_data_pkt : begin
                if(rd_empty)
                    lp_data_hs <= 2'b11;        //LP11
            end
            default :;
       endcase
    end
end

//ͬ��FIFO��������
sync_fifo_256x32b u_sync_fifo_256x32b(
    .clk           (clk),   
    .rst           (~rst_n),   

    .wr_en         (hs_en  ),
    .wr_data       (hs_data_in),
    .wr_full       (),   
    .rd_en         (rd_en),   
    .rd_data       (rd_data),   
    .almost_full   (),   
    .rd_empty      (rd_empty),
    .almost_empty  ()   
    );

endmodule
