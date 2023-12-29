//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�http://www.openedv.com/forum.php
//�Ա����̣�https://zhengdianyuanzi.tmall.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           ddr3_ctrl_top
// Created by:          ����ԭ��
// Created date:        2023��2��3��14:17:02
// Version:             V1.0
// Descriptions:        ddr3_ctrl_top
//
//----------------------------------------------------------------------------------------
//****************************************************************************************///

module ddr3_ctrl_top(
    input                   clk             ,
    input                   wd_clk          ,
    input                   rd_clk          ,
    input                   rst_n           ,
    // �ⲿ���ݽӿ�   
    input                   wd_en           ,   //дʹ��
    input       [15:0]      wd_data         ,   //д����
    input                   rd_en           ,   //��ʹ��
    output      [15:0]      rd_data         ,   //������
    input                   wr_load         ,   //����Դ�����ź�
    input                   rd_load         ,   //���Դ�����ź�
    input                   ddr3_pingpang_en,   //DDR3ƹ�Ҳ���
    input                   ddr3_read_valid ,
    // ddr��ַ���ȿ��ƽӿ�                  
    input       [27:0]      addr_rd_min     ,
    input       [27:0]      addr_rd_max     ,
    input       [9:0]       rd_burst_len    ,
    input       [27:0]      addr_wd_min     ,
    input       [27:0]      addr_wd_max     ,
    input       [9:0]       wd_burst_len    ,
    output  reg             ddr3_init_done  ,   //ddr3��ʼ����ɱ�־
    //DDR�������ӿ�
    output                  mem_rst_n       ,                       
    output                  mem_ck          ,
    output                  mem_ck_n        ,
    output                  mem_cke         ,
    output                  mem_ras_n       ,
    output                  mem_cas_n       ,
    output                  mem_we_n        , 
    output                  mem_odt         ,
    output                  mem_cs_n        ,
    output 	    [14:0]      mem_a           ,   
    output 	    [2:0]       mem_ba          ,   
    inout 	    [1:0]       mem_dqs         ,
    inout 	    [1:0]       mem_dqs_n       ,
    inout 	    [15:0]      mem_dq          ,
    output 	    [1:0]       mem_dm               
);
//wire define
wire            ui_clk          ;
wire [10:0]     rfifo_wcount    ;
wire [10:0]     wfifo_rcount    ;
wire [27:0]     wd_addr         ;
wire [27:0]     rd_addr         ;
wire [9:0]      wd_len          ;
wire [9:0]      rd_len          ;
wire [127:0]    rfifo_wdata     ;
wire            rfifo_wen       ;
wire [127:0]    wfifo_rdata     ;
wire            wfifo_ren       ;
wire            rd_finish       ;
wire            wd_finish       ;
wire            rd_req          ;
wire            wd_req          ;
// Write Address                
wire [3:0]     axi_awid         ;
wire [27:0]    axi_awaddr       ;
wire [3:0]     axi_awlen        ;
wire           axi_awvalid      ;
wire           axi_awready      ;
// write data
wire [127:0]   axi_wdata        ;
wire [15:0]    axi_wstrb        ;
wire           axi_wlast        ;
wire           axi_wready       ;
// read address                 
wire [3:0]     axi_arid         ;
wire [27:0]    axi_araddr       ;
wire [3:0]     axi_arlen        ;
wire           axi_arvalid      ;
wire           axi_arready      ;
wire           ddr_init_done    ;
// read data                    
wire [3:0]     axi_rid          ;
wire [127:0]   axi_rdata        ;
wire           axi_rlast        ;
wire           axi_rvalid       ;

reg            ddr3_init_done_c0;
reg            ddr3_init_done_c1;

//*****************************************************
//**                    main code
//*****************************************************

// �ȶ���ʼ���ź�
always@ (posedge ui_clk or negedge rst_n ) begin
    if(!rst_n)begin
        ddr3_init_done_c0 <= 1'b0;
        ddr3_init_done_c1 <= 1'b0;
    end
	else begin
        ddr3_init_done_c0 <= ddr_init_done;
        ddr3_init_done_c1 <= ddr3_init_done_c0;
    end
end
always@(posedge ui_clk or negedge rst_n)begin
    if(!rst_n)
        ddr3_init_done <= 1'b0;
    else if(ddr3_init_done_c0 && ~ddr3_init_done_c1)	
		ddr3_init_done <= 1'b1;
    else
        ddr3_init_done <= ddr3_init_done;
end

// DDR3��д����ģ�� 
ddr3_rw_ctrl u_ddr3_rw_ctrl(
    .rst_n                  (rst_n      ),
    .clk                    (ui_clk     ),
    .addr_rd_min            (addr_rd_min),
    .addr_rd_max            (addr_rd_max),
    .rd_burst_len           (rd_burst_len),
    .addr_wd_min            (addr_wd_min),
    .addr_wd_max            (addr_wd_max),
    .wd_burst_len           (wd_burst_len),
    .rfifo_wcount           (rfifo_wcount),
    .wfifo_rcount           (wfifo_rcount),
    .ddr3_init_done         (ddr3_init_done),
    .wd_finish              (wd_finish  ),
    .wd_req                 (wd_req     ),
    .wd_addr                (wd_addr    ),
    .wd_len                 (wd_len     ),
    .rd_finish              (rd_finish  ),
    .rd_req                 (rd_req     ),
    .rd_addr                (rd_addr    ),
    .rd_len                 (rd_len     ),
    .rd_load                (rd_load    ),
    .wr_load                (wr_load    ),
    .ddr3_pingpang_en       (ddr3_pingpang_en),
    .ddr3_read_valid        (ddr3_read_valid)
);

// axi ����ģ��
aq_axi_master u_aq_axi_master
	(
	.rst_n                  (rst_n  && ddr3_init_done),
	.clk                    (ui_clk        ),
    // Write address channel
	.m_axi_awid             (axi_awid      ),                             
	.m_axi_awaddr           (axi_awaddr    ),                             
	.m_axi_awlen            (axi_awlen     ),                                                         
	.m_axi_awvalid          (axi_awvalid   ),                             
	.m_axi_awready          (axi_awready   ),
    // Write data channel
	.m_axi_wdata            (axi_wdata     ),//O                             
	.m_axi_wstrb            (axi_wstrb     ),                             
	.m_axi_wlast            (axi_wlast     ),                                                         
	.m_axi_wready           (axi_wready    ),
    // Read address channel
	.m_axi_arid             (axi_arid      ),                             
	.m_axi_araddr           (axi_araddr    ),                             
	.m_axi_arlen            (axi_arlen     ),                                                     
	.m_axi_arvalid          (axi_arvalid   ),                             
	.m_axi_arready          (axi_arready   ),
    // Read data channel
	.m_axi_rdata            (axi_rdata     ), //I                                                        
	.m_axi_rlast            (axi_rlast     ),                                                          
	.m_axi_rvalid           (axi_rvalid    ),
    // User control interface
	.wr_start               (wd_req        ),      
	.wr_adrs                ({wd_addr,3'd0}),         
	.wr_len                 ({wd_len,3'd0} ),         
	.wr_ready               ( ),         
	.wr_fifo_re             (wfifo_ren     ),         
	.wr_fifo_empty          (1'b0          ),         
	.wr_fifo_aempty         (1'b0          ),
	.wr_fifo_data           (wfifo_rdata   ),//I
	.wr_done                (wd_finish     ),
	.rd_start               (rd_req        ),	  
	.rd_adrs                ({rd_addr,3'd0}),
	.rd_len                 ({rd_len,3'd0} ),
	.rd_ready               ( ),
	.rd_fifo_we             (rfifo_wen     ),
	.rd_fifo_full           (1'b0          ),
	.rd_fifo_afull          (1'b0          ),
	.rd_fifo_data           (rfifo_wdata   ),//O
	.rd_done                (rd_finish     )
);

// DDR3 IP�� 
ddr3_ip u_ddr3_ip(
    .ref_clk                (clk          ),
    .resetn                 (rst_n        ),
    .ddr_init_done          (ddr_init_done),
    .ddrphy_clkin           (ui_clk       ),
    .pll_lock               ( ),
    
    .axi_awaddr             (axi_awaddr   ),               
    .axi_awuser_ap          (1'b0),                        
    .axi_awuser_id          (4'b0),             
    .axi_awlen              (axi_awlen    ),            
    .axi_awready            (axi_awready  ),             
    .axi_awvalid            (axi_awvalid  ),
    
    .axi_wdata              (axi_wdata    ),            
    .axi_wstrb              (axi_wstrb    ),            
    .axi_wready             (axi_wready   ),            
    .axi_wusero_id          ( ),            
    .axi_wusero_last        (axi_wlast    ),
    
    .axi_araddr             (axi_araddr   ),            
    .axi_aruser_ap          (1'b0),                        
    .axi_aruser_id          (4'b0),             
    .axi_arlen              (axi_arlen    ),            
    .axi_arready            (axi_arready  ),            
    .axi_arvalid            (axi_arvalid  ),
    
    .axi_rdata              (axi_rdata    ),            
    .axi_rid                ( ),           
    .axi_rlast              (axi_rlast    ),                
    .axi_rvalid             (axi_rvalid   ),
    
    .apb_clk                (0),
    .apb_rst_n              (0),
    .apb_sel                (0),
    .apb_enable             (0),
    .apb_addr               (0),
    .apb_write              (0),
    .apb_ready              ( ),
    .apb_wdata              (0),
    .apb_rdata              ( ),
    .apb_int                ( ),  
    .debug_data             (debug_data       ),
    .debug_slice_state      (debug_slice_state),
    .debug_calib_ctrl       (debug_calib_ctrl ),   
    .ck_dly_set_bin         (8'h14),//8��h14
    .dll_step               (dll_step     ),
    .dll_lock               (dll_lock     ),
    .init_read_clk_ctrl     (0),                                                 
    .init_slip_step         (0), 
    .force_read_clk_ctrl    (0), 
    .ddrphy_gate_update_en  (0),
    .update_com_val_err_flag( ),
    .rd_fake_stop           (0),   
    .mem_rst_n              (mem_rst_n    ),
    .mem_ck                 (mem_ck       ),
    .mem_ck_n               (mem_ck_n     ),
    .mem_cke                (mem_cke      ),
    .mem_ras_n              (mem_ras_n    ),
    .mem_cs_n               (mem_cs_n     ),
    .mem_cas_n              (mem_cas_n    ),
    .mem_we_n               (mem_we_n     ),
    .mem_odt                (mem_odt      ),
    .mem_a                  (mem_a        ),
    .mem_ba                 (mem_ba       ),
    .mem_dqs                (mem_dqs      ),
    .mem_dqs_n              (mem_dqs_n    ),
    .mem_dq                 (mem_dq       ),
    .mem_dm                 (mem_dm       )
);
 
// FIFO����ģ��
ctrl_fifo u_ctrl_fifo(
    .rst_n                  (rst_n      ),
    .wd_clk                 (wd_clk     ),
    .rd_clk                 (rd_clk     ),
    .clk_100                (ui_clk     ),        
    .wfifo_wr_en            (wd_en      ),
    .wfifo_wr_data          (wd_data    ),
    .wfifo_rd_en            (wfifo_ren  ),
    .rd_load                (rd_load    ),
    .wr_load                (wr_load    ),
    .wfifo_rd_data          (wfifo_rdata),
    .wfifo_rcount           (wfifo_rcount),               
    .rfifo_wr_en            (rfifo_wen  ),
    .rfifo_wr_data          (rfifo_wdata),
    .rfifo_wcount           (rfifo_wcount),
    .rfifo_rd_en            (rd_en      ),
    .rfifo_rd_data          (rd_data    )
);
endmodule