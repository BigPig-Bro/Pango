module top(
    input               sys_clk,rst_n, // 核心板载的2个功能

    // 板载功能测试
    input      [ 3:0]   key, // 板载的4个按键
    output reg [ 3:0]   led, // 板载的4个LED

    input               uart_rx,
    output              uart_tx,

    //TF卡槽（SDIO，这里仅测试SPI模式）
	output                      sd_ncs,            //SD card chip select (SPI mode) SDIO D3
    output                      sd_dclk,           //SD card clock                  SDIO CLK
    output                      sd_mosi,           //SD card controller data output SDIO CMD
    input                       sd_miso,           //SD card controller data input  SDIO D0

    //MIPI CSI接口，官方都没给例程

    //MIPI DSI显示接口
    output              mipi_dsi_rst_n, //MIPI DSI复位信号
    output              mipi_dsi_bl ,   //MIPI DSI背光亮度控制信号
    inout    [3:0]      mipi_dsi_data_p,//四对差分数据线P
    inout    [3:0]      mipi_dsi_data_n,//四对差分数据线N
    inout               mipi_dsi_clk_p ,//一对差分时钟线P
    inout               mipi_dsi_clk_n,  //一对差分时钟线N   

    inout               cmos_scl,          //cmos i2c clock
    inout               cmos_sda,          //cmos i2c data
    input               cmos_vsync,        //cmos vsync
    input               cmos_href,         //cmos hsync refrence,data valid
    input               cmos_pclk,         //cmos pxiel clock
    input   [7:0]       cmos_data,           //cmos data
    output              cmos_rst_n,        //cmos reset 
    output              cmos_pwdn,         //cmos power down   
    
    //DDR3接口
    output              mem_rst_n     ,                       
    output              mem_ck        ,
    output              mem_ck_n      ,
    output              mem_cke       ,
    output              mem_ras_n     ,
    output              mem_cas_n     ,
    output              mem_we_n      , 
    output              mem_odt       ,
    output              mem_cs_n      ,
    output 	[14:0]      mem_a         ,   
    output 	[2:0]       mem_ba        ,   
    inout 	[1:0]       mem_dqs       ,
    inout 	[1:0]       mem_dqs_n     ,
    inout 	[15:0]      mem_dq        ,
    output 	[1:0]       mem_dm        ,

    //HDMI接口
    output  [2:0]       hdmi_data_p,
    output  [2:0]       hdmi_data_n,
    output              hdmi_clk_p,
    output              hdmi_clk_n,

    //拓展IO
    output      [33:0]  exter_io_h1,
    output      [35:0]  exter_io_h2
);

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 			    测试时钟输入 	         /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
// 降低到hz，生成分频信号1hz A
reg [24:0] cnt;
always@(posedge sys_clk)
    cnt <= cnt + 1;

logic clk_A ;
assign clk_A = !rst_n? 'd0 : cnt[24];

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 		        测试串口	            /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//现象：串口接收到的数据，会发送回去
assign uart_tx = uart_rx;

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 		        测试按键LED	            /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//现象：按键按下，对应的LED灭，否则 23闪烁 01如果TF卡初始化成功，闪烁，未成功常亮
always@* begin
    led[0] = ~key[0] ? 1'd1 : sd_init_done? cnt[24] : 1'd0;
    led[1] = ~key[1] ? 1'd1 : sd_init_done? cnt[24] : 1'd0;
    led[2] = ~key[2] ? 1'd1 : cnt[24];
    led[3] = ~key[3] ? 1'd1 : cnt[24];
end

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 		        测试TF卡读写	         /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//现象：TF卡初始化成功后，给出信号sd_init_done
wire sd_init_done;
sd_card_top  sd_card_top_m0(
	.clk                       (sys_clk                    ),
	.rst                       (~rst_n                     ),

	.SD_nCS                    (sd_ncs                     ),
	.SD_DCLK                   (sd_dclk                    ),
	.SD_MOSI                   (sd_mosi                    ),
	.SD_MISO                   (sd_miso                    ),

	.sd_init_done              (sd_init_done               ),
	.sd_sec_read               (                           ),
	.sd_sec_read_addr          (                           ),
	.sd_sec_read_data          (                           ),
	.sd_sec_read_data_valid    (                           ),
	.sd_sec_read_end           (                           ),
	.sd_sec_write              (                           ),
	.sd_sec_write_addr         (                           ),
	.sd_sec_write_data         (                           ),
	.sd_sec_write_data_req     (                           ),
	.sd_sec_write_end          (                           )
);

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 		        测试DSI	                /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//现象：DSI显示屏显示彩条
mipi_dsi_colorbar mipi_dsi_colorbar_m0(
    .sys_clk            (sys_clk            ),
    .sys_rst_n          (rst_n              ),
    
    .mipi_dsi_rst_n     (mipi_dsi_rst_n     ),
    .mipi_dsi_bl        (mipi_dsi_bl        ),
    .mipi_dsi_data_p    (mipi_dsi_data_p    ),
    .mipi_dsi_data_n    (mipi_dsi_data_n    ),
    .mipi_dsi_clk_p     (mipi_dsi_clk_p     ),
    .mipi_dsi_clk_n     (mipi_dsi_clk_n     )
);

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 		 测试DVP+DDR+HDMI	            /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//现象：HDMI显示屏显示彩条+DVP摄像头
ov5640_hdmi ov5640_hdmi_m0(
    .sys_clk            (sys_clk            ),
    .sys_rst_n          (rst_n              ),
    
    .tmds_clk_p         (hdmi_clk_p         ),
    .tmds_clk_n         (hdmi_clk_n         ),
    .tmds_data_p        (hdmi_data_p        ),
    .tmds_data_n        (hdmi_data_n        ),

    .cam_scl            (cmos_scl           ),
    .cam_sda            (cmos_sda           ),
    .cam_vsync          (cmos_vsync         ),
    .cam_href           (cmos_href          ),
    .cam_pclk           (cmos_pclk          ),
    .cam_data           (cmos_data          ),
    .cam_rst_n          (cmos_rst_n         ),
    .cam_pwdn           (cmos_pwdn          ),

    .mem_rst_n          (mem_rst_n          ),
    .mem_ck             (mem_ck             ),
    .mem_ck_n           (mem_ck_n           ),      
    .mem_cke            (mem_cke            ),
    .mem_ras_n          (mem_ras_n          ),
    .mem_cas_n          (mem_cas_n          ),
    .mem_we_n           (mem_we_n           ),
    .mem_odt            (mem_odt            ),
    .mem_cs_n           (mem_cs_n           ),
    .mem_a              (mem_a              ),
    .mem_ba             (mem_ba             ),
    .mem_dqs            (mem_dqs            ),
    .mem_dqs_n          (mem_dqs_n          ),
    .mem_dq             (mem_dq             ),
    .mem_dm             (mem_dm             )
);

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 			    测试外部IO	            /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//现象：外部IO闪烁
assign exter_io_h1[0] = clk_A ;
assign exter_io_h1[1] = ~clk_A ;
assign exter_io_h1[2] = clk_A ;
assign exter_io_h1[3] = ~clk_A ;
assign exter_io_h1[4] = clk_A ;
assign exter_io_h1[5] = ~clk_A ;
assign exter_io_h1[6] = clk_A ;
assign exter_io_h1[7] = ~clk_A ;
assign exter_io_h1[8] = clk_A ;
assign exter_io_h1[9] = ~clk_A ;
assign exter_io_h1[10] = clk_A ;
assign exter_io_h1[11] = ~clk_A ;
assign exter_io_h1[12] = clk_A ;
assign exter_io_h1[13] = ~clk_A ;
assign exter_io_h1[14] = clk_A ;
assign exter_io_h1[15] = ~clk_A ;
assign exter_io_h1[16] = clk_A ;
assign exter_io_h1[17] = ~clk_A ;
assign exter_io_h1[18] = clk_A ;
assign exter_io_h1[19] = ~clk_A ;
assign exter_io_h1[20] = clk_A ;
assign exter_io_h1[21] = ~clk_A ;
assign exter_io_h1[22] = clk_A ;
assign exter_io_h1[23] = ~clk_A ;
assign exter_io_h1[24] = clk_A ;
assign exter_io_h1[25] = ~clk_A ;
assign exter_io_h1[26] = clk_A ;
assign exter_io_h1[27] = ~clk_A ;
assign exter_io_h1[28] = clk_A ;
assign exter_io_h1[29] = ~clk_A ;
assign exter_io_h1[30] = clk_A ;
assign exter_io_h1[31] = ~clk_A ;
assign exter_io_h1[32] = clk_A ;
assign exter_io_h1[33] = ~clk_A ;

assign exter_io_h2[0] = clk_A ;
assign exter_io_h2[1] = ~clk_A ;
assign exter_io_h2[2] = clk_A ;
assign exter_io_h2[3] = ~clk_A ;
assign exter_io_h2[4] = clk_A ;
assign exter_io_h2[5] = ~clk_A ;
assign exter_io_h2[6] = clk_A ;
assign exter_io_h2[7] = ~clk_A ;
assign exter_io_h2[8] = clk_A ;
assign exter_io_h2[9] = ~clk_A ;
assign exter_io_h2[10] = clk_A ;
assign exter_io_h2[11] = ~clk_A ;
assign exter_io_h2[12] = clk_A ;
assign exter_io_h2[13] = ~clk_A ;
assign exter_io_h2[14] = clk_A ;
assign exter_io_h2[15] = ~clk_A ;
assign exter_io_h2[16] = clk_A ;
assign exter_io_h2[17] = ~clk_A ;
assign exter_io_h2[18] = clk_A ;
assign exter_io_h2[19] = ~clk_A ;
assign exter_io_h2[20] = clk_A ;
assign exter_io_h2[21] = ~clk_A ;
assign exter_io_h2[22] = clk_A ;
assign exter_io_h2[23] = ~clk_A ;
assign exter_io_h2[24] = clk_A ;
assign exter_io_h2[25] = ~clk_A ;
assign exter_io_h2[26] = clk_A ;
assign exter_io_h2[27] = ~clk_A ;
assign exter_io_h2[28] = clk_A ;
assign exter_io_h2[29] = ~clk_A ;
assign exter_io_h2[30] = clk_A ;
assign exter_io_h2[31] = ~clk_A ;
assign exter_io_h2[32] = clk_A ;
assign exter_io_h2[33] = ~clk_A ;
assign exter_io_h2[34] = clk_A ;
assign exter_io_h2[35] = ~clk_A ;

endmodule

