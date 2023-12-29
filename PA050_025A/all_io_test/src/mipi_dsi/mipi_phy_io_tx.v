//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           mipi_phy_io_tx
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        MIPI时钟和数据转差分输出
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module mipi_phy_io_tx #(
    parameter LANE_WIDTH     = 4,
    parameter BUS_WIDTH      = 32) 
    (
    input                       clk_hs_c    , //for clk lane   clock 
    input                       clk_hs_d    , //for data lane  clock  90phase    
                                              
    input                       tx_iol_rst  , //reset for iol
    input                       tx_div_rst_n, //reset for clkdiv
    input                       tx_gate_en  , //reset for ioclkbuf
                                              
    input                       tx_hs_c_flag, //tx_hs_c_flag : =1, HS mode; =0, LP mode
    input                       tx_lp_clk_p , //clock lane lp data p    
    input                       tx_lp_clk_n , //clock lane lp data n
                                              
    input    [LANE_WIDTH-1:0]   tx_lp_data_p, //lp data out to  port
    input    [LANE_WIDTH-1:0]   tx_lp_data_n, //lp data out to  port
    input    [LANE_WIDTH-1:0]   tx_hs_d_flag, //tx_hs_d_flag : =1, HS mode; =0, LP mode
    input    [ BUS_WIDTH-1:0]   tx_hs_data  , //parallel data
    output                      tx_byte_clk , //parallel clock
    
    //MIPI差分时钟和数据
    inout   [LANE_WIDTH-1:0]    mipi_dsi_data_p ,
    inout   [LANE_WIDTH-1:0]    mipi_dsi_data_n ,
    inout                       mipi_dsi_clk_p  ,
    inout                       mipi_dsi_clk_n   
);

//wire define
wire                    ioclk_hs_c;   
wire                    ioclk_hs_d;
wire                    ioclkdiv_hs_c;
wire                    ioclkdiv_hs_d;
wire                    tx_clk_o;
wire                    tx_clk_t;
wire [LANE_WIDTH-1:0]   tx_data_t;
wire [LANE_WIDTH-1:0]   tx_data_o;
wire [7:0]              tx_clk_hs_di;
wire [LANE_WIDTH-1:0]   tx_hs_data_di;

//*****************************************************
//**                    main code
//*****************************************************

assign tx_clk_hs_di[7:6] = tx_hs_c_flag ? {1'b1,1'b0} : {tx_lp_clk_p,1'b0};
assign tx_clk_hs_di[5:0] = {1'b1,1'b0,1'b1,1'b0,1'b1,1'b0};
assign tx_byte_clk = ioclkdiv_hs_d;  //输出并行时钟

//例化GTP_IOCLKBUF原语
GTP_IOCLKBUF #(
    .GATE_EN    ("TRUE")
    )
    inst_ioclk_i
    (
    .CLKOUT     (ioclk_hs_c),
    .CLKIN      (clk_hs_c),
    .DI         (tx_gate_en)
    ); 

//例化GTP_IOCLKBUF原语
GTP_IOCLKBUF #(
    .GATE_EN    ("TRUE")
    )
    inst_ioclk_q
    (
    .CLKOUT     (ioclk_hs_d),
    .CLKIN      (clk_hs_d),
    .DI         (tx_gate_en)
    );

//例化GTP_IOCLKDIV原语
GTP_IOCLKDIV #(
    .DIV_FACTOR ("4"), 
    .GRS_EN     ("FALSE") 
    )
    u_hs_i_io_clk
    (
    .CLKDIVOUT  (ioclkdiv_hs_c),
    .CLKIN      (ioclk_hs_c ),
    .RST_N      (tx_div_rst_n)
    );

//例化GTP_IOCLKDIV原语
GTP_IOCLKDIV #(
    .DIV_FACTOR ("4"), 
    .GRS_EN     ("FALSE") 
    )
    u_hs_q_io_clk
    (
    .CLKDIVOUT  (ioclkdiv_hs_d),
    .CLKIN      (ioclk_hs_d),
    .RST_N      (tx_div_rst_n)
    );

//例化GTP_OSERDES原语
GTP_OSERDES #(
    .OSERDES_MODE ("OSER8"),
    .WL_EXTEND    ("FALSE"),
    .GRS_EN       ("TRUE" ),
    .LRS_EN       ("TRUE" ),
    .TSDDR_INIT   (1'b0   )
    )
    GTP_OGSER8_inst0
    (
    .DI         (tx_clk_hs_di ),
    .TI         (4'h0         ),
    .RCLK       (ioclkdiv_hs_c),
    .SERCLK     (ioclk_hs_c),
    .OCLK       (1'b0         ),
    .RST        (tx_iol_rst   ),
    .DO         (tx_clk_o     ),
    .TQ         (tx_clk_t     )
    );

//例化GTP_IOBUF_TX_MIPI原语,输出MIPI差分时钟
GTP_IOBUF_TX_MIPI #( 
    .IOSTANDARD     ( "DEFAULT"),
    .DRIVE_STRENGTH ( "2"      ),
    .SLEW_RATE      ( "FAST"   ),
    .TERM_DIFF      ( "ON"     )
    )
    inst_clk_mipi
    (
    .O_LP   (               ),
    .OB_LP  (               ),
    .IO     ( mipi_dsi_clk_p),
    .IOB    ( mipi_dsi_clk_n),
    .I_HS   ( tx_clk_o      ),
    .I_LP   ( tx_clk_hs_di[7]),  
    .IB_LP  ( tx_lp_clk_n   ),
    .T      ( tx_clk_t      ),
    .TB     ( tx_hs_c_flag  ),
    .M      ( tx_hs_c_flag  )
    );

genvar i;          
//输出MIPI差分数据
generate for(i=0;i<LANE_WIDTH;i=i+1) begin :data_lane          
    assign tx_hs_data_di[i] = tx_hs_d_flag ? tx_hs_data[8*i+7] : tx_lp_data_p[i];
    
    GTP_OSERDES #(
        .OSERDES_MODE ( "OSER8"  ),
        .WL_EXTEND    ( "FALSE"  ),
        .GRS_EN       ( "TRUE"   ),
        .LRS_EN       ( "TRUE"   ),
        .TSDDR_INIT   (  1'b0    )
    )
    GTP_OGSER8_inst0
    (
        .DI         ({tx_hs_data_di[i],tx_hs_data[i*8+6:i*8]} ),
        .TI         (1'b0          ),
        .RCLK       (ioclkdiv_hs_d   ),
        .SERCLK     (ioclk_hs_d),
        .OCLK       (1'b0          ),
        .RST        (tx_iol_rst    ),
        .DO         (tx_data_o[i]  ),
        .TQ         (tx_data_t[i]  )
    );

    GTP_IOBUF_TX_MIPI #( 
        .IOSTANDARD     ( "DEFAULT"),
        .DRIVE_STRENGTH ( "2"      ),
        .SLEW_RATE      ( "FAST"   ),
        .TERM_DIFF      ( "ON"     )
    )
    inst_data_mipi(
        .O_LP   (),
        .OB_LP  (),
        .IO     (mipi_dsi_data_p[i]),
        .IOB    (mipi_dsi_data_n[i]),
        .I_HS   (tx_data_o[i]      ),
        .I_LP   (tx_hs_data_di[i]  ),
        .IB_LP  (tx_lp_data_n[i]   ),
        .T      (tx_data_t[i]      ),
        .TB     (tx_hs_d_flag[i]   ),
        .M      (tx_hs_d_flag[i]   )
    );
end
endgenerate

endmodule 
