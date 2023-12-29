//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           mipi_dsi_rst_ctrl
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        MIPI DSI复位信号控制
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module mipi_dsi_rst_ctrl
(
    input           clk,           
    input           rst_n,
    output  reg     dsi_rst_n    //DSI屏幕复位信号,低电平有效
);

//parameter define
parameter HIGH_TIME_MS = 100;    //高电平持续100ms
parameter LOW_TIME_MS  = 80 ;    //低电平持续80ms
parameter HIGN_DELAY_MS = 120;   //高电平持续120ms

//reg define  
reg     [1:0]   flow_cnt;
reg     [15:0]  delay_cnt;
reg             delay_en;
reg     [9:0]   ms_cnt;

//*****************************************************
//**                    main code
//*****************************************************

//延时计数,用于产生1ms的使能信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        delay_cnt <= 16'b0;
        delay_en <= 1'b0;
    end
    else begin
        if(delay_cnt == 16'd10000 - 1'b1) begin
            delay_cnt <= 16'd0;
            delay_en <= 1'd1;        
        end
        else begin
            delay_cnt <= delay_cnt + 16'b1;
            delay_en <= 1'd0;
        end        
    end
end

//先保持100ms高电平,再拉低80ms的低电平,最后拉高dsi_rst_n信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        flow_cnt <= 2'b0;
        ms_cnt <= 10'b0;
        dsi_rst_n <= 1'b1;
    end
    else begin
        case(flow_cnt)
            2'd0 : begin
                      dsi_rst_n <= 1'b1;
                      flow_cnt <= flow_cnt + 2'b1;
                  end    
            2'd1 : begin
                if(delay_en) begin 
                    ms_cnt <= ms_cnt + 10'd1;
                    if(ms_cnt == HIGH_TIME_MS - 1'b1) begin
                        dsi_rst_n <= 1'b0;
                        flow_cnt <= flow_cnt + 2'b1;
                        ms_cnt <= 0;
                    end 
                    else;					
                end    
            end
            2'd2 : begin
                if(delay_en) begin 
                    ms_cnt <= ms_cnt + 10'd1;
                    if(ms_cnt == LOW_TIME_MS - 1'b1) begin
                        flow_cnt <= flow_cnt + 2'b1;
                        ms_cnt <= 10'd0;
                    end 
                    else;					
                end 
                else;				
            end            
            2'd3 : dsi_rst_n <= 1'b1;
            default:;
        endcase            
    end    
end

endmodule 
