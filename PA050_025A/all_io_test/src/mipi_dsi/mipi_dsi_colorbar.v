//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�http://www.openedv.com/forum.php
//�Ա����̣�https://zhengdianyuanzi.tmall.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           mipi_dsi_colorbar
// Created by:          ����ԭ��
// Created date:        2023��9��23��15:38:10
// Version:             V1.0
// Descriptions:        MIPI��������ʾ
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`include "param_define.h" 

module mipi_dsi_colorbar(
    input             sys_clk,
    input             sys_rst_n,
    //MIPI DSI��ʾ�ӿ�
    output            mipi_dsi_rst_n, //MIPI DSI��λ�ź�
    output            mipi_dsi_bl ,   //MIPI DSI�������ȿ����ź�
    inout    [3:0]    mipi_dsi_data_p,//�ĶԲ��������P
    inout    [3:0]    mipi_dsi_data_n,//�ĶԲ��������N
    inout             mipi_dsi_clk_p ,//һ�Բ��ʱ����P
    inout             mipi_dsi_clk_n  //һ�Բ��ʱ����N
); 

//parameter define
parameter LANE_WIDTH= 3'd4   ;     //����ͨ������
parameter BUS_WIDTH = 6'd32  ;     //�������߿�� LANE_WIDTH*8
parameter EOTP_EN = 1'b1     ;     //EoTp���ݰ���־ 1:����EoTp���ݰ�

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

//MIPI DSI���������
assign mipi_dsi_bl = 1'b1;                                   

//MIPI����ʼ�����ǰ�����͵����������ݣ���ʼ����ɺ󣬷��͸�������
assign tx_hs_c_flag = lcm_init_done; 
assign tx_lp_data_p = lcm_init_done ? {4{lp_data_hs[1]}} : {3'b000,{lp_d0_p}} ;
assign tx_lp_data_n = lcm_init_done ? {4{lp_data_hs[0]}} : {3'b000,{lp_d0_n}} ;
assign tx_hs_d_flag = lcm_init_done ? {4{hs_out_en}} : 4'h0;
assign tx_hs_data   = hs_data_out;

//����para_define.h�ļ�����Ĳ������ж��Ƿ����ڷ���
`ifdef MIPI_DSI_720P
     assign mipi_dsi_id = 2'd1;  //��720P��Ϊ�����з���
`else
    assign mipi_dsi_id = 2'd2;  //��1080P��Ϊ�����з���
`endif    


//ʱ�Ӳ���ģ��    
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

//MIPI LCD����ʼ��
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
    
//MIPI DSI HSģʽ�����ݷ�װ
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

//LPģʽ�л���HSģʽ��ʱ����    
lp_hs_delay_ctrl  u_lp_hs_delay_ctrl(
    .clk                  (tx_byte_clk),
    .rst_n                (rst_n),

    .hs_en                (hs_en),
    .hs_data_in           (hs_data),

    .lp_data_hs           (lp_data_hs),
    .hs_out_en            (hs_out_en),
    .hs_data_out          (hs_data_out)
    );  

//MIPIʱ�Ӻ�����ת������      
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

//MIPI����ʾ����(������������)
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
