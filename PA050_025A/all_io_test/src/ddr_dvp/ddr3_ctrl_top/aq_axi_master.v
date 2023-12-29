//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           aq_axi_master
// Created by:          正点原子
// Created date:        2023年2月3日14:17:02
// Version:             V1.0
// Descriptions:        aq_axi_master
//
//----------------------------------------------------------------------------------------
//****************************************************************************************///

module aq_axi_master(
    // Reset, Clock
    input                   rst_n,
    input                   clk,
    // Write Address
    output      [3:0]       m_axi_awid,                                                         	  
    output      [27:0]      m_axi_awaddr,                                                       	  
    output      [3:0]       m_axi_awlen,    // Burst Length: 0-15                              	                          	  
    output                  m_axi_awvalid,                                                      	  
    input                   m_axi_awready,                                                      	  
    // Write Data                                                              	  
    output      [127:0]     m_axi_wdata,                                                       	  
    output      [15:0]      m_axi_wstrb ,                                                       	                                                        	  
    input                   m_axi_wready ,                                                       	  
    input                   m_axi_wlast ,                                                                                    	                                                        	  
    // Read Address                                                            	  
    output      [3:0]       m_axi_arid ,                                                         	  
    output      [27:0]      m_axi_araddr ,                                                       	  
    output      [3:0]       m_axi_arlen ,                                                        	                                                         	  
    output                  m_axi_arvalid ,                                                      	  
    input                   m_axi_arready ,                                                      	  
    // Read Data 
    input       [127:0]     m_axi_rdata,
    input                   m_axi_rlast,
    input                   m_axi_rvalid,
    // Local Bus
    input                   wr_start,
    input       [27:0]      wr_adrs,
    input       [10:0]      wr_len, 
    output                  wr_ready,
    output                  wr_fifo_re,
    input                   wr_fifo_empty,
    input                   wr_fifo_aempty,
    input       [127:0]     wr_fifo_data,
    output                  wr_done,
    input                   rd_start,
    input       [27:0]      rd_adrs,
    input       [10:0]      rd_len, 
    output                  rd_ready,
    output                  rd_fifo_we,
    input                   rd_fifo_full,
    input                   rd_fifo_afull,
    output      [127:0]     rd_fifo_data,
    output                  rd_done
);
//localparam define
localparam S_WR_IDLE  = 3'd0;
localparam S_WA_START = 3'd1;
localparam S_WD_WAIT  = 3'd2;
localparam S_WR_WAIT  = 3'd3;
localparam S_WR_DONE  = 3'd4;

localparam S_RD_IDLE  = 3'd0;
localparam S_RA_START = 3'd1;
localparam S_RD_WAIT  = 3'd2; 
localparam S_RD_PROC  = 3'd3;
localparam S_RD_DONE  = 3'd4;

//reg define
reg [2:0]       wr_state;
reg [27:0]      reg_wr_adrs;
reg [10:0]      reg_wr_len;
reg [10:0]      reg_wr_len1;
reg             reg_awvalid;
reg [7:0]       reg_w_len;
reg             rd_first_data;
reg             rd_fifo_enable;
reg [7:0]       rd_fifo_cnt;
reg [2:0]       rd_state;
reg [27:0]      reg_rd_adrs;
reg [10:0]      reg_rd_len;
reg             reg_arvalid;
reg [7:0]       reg_r_len;
reg [7:0]       rd_addr_cnt;
reg [7:0]       data_valid_cnt;   
reg             reg_r_last;
reg             reg_w_finish; 
reg             rd_fifo_almost_end; 
reg             once_rd_num; 

//*****************************************************
//**                    main code
//***************************************************** 

// Master Read Address
assign m_axi_arid       = 1'b0;
assign m_axi_araddr     = reg_rd_adrs;
assign m_axi_arlen      = reg_r_len[3:0];
assign m_axi_arvalid    = reg_arvalid;
assign rd_ready         = (rd_state == S_RD_IDLE) ? 1'b1 : 1'b0;
assign rd_fifo_we       = m_axi_rvalid;
assign rd_fifo_data     = m_axi_rdata;
assign rd_done          = (rd_state == S_RD_DONE) ; 
assign m_axi_awid       = 4'b0;
assign m_axi_awaddr     = reg_wr_adrs;
assign m_axi_awlen      = reg_w_len[3:0];
assign m_axi_awvalid    = reg_awvalid;
assign m_axi_wdata      = wr_fifo_data;
assign m_axi_wstrb      = 16'hFFFF;
assign wr_ready         = (wr_state == S_WR_IDLE) ? 1'b1 : 1'b0;   
assign wr_done          = (wr_state == S_WR_DONE);
assign wr_fifo_re       = rd_first_data | (m_axi_wready && rd_fifo_enable) ;

//wfifo的读计数，计数128bit的次数
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rd_fifo_cnt <= 8'b0;
    else if(wr_fifo_re)
        rd_fifo_cnt <= rd_fifo_cnt + 1'b1;
    else if(wr_state == S_WR_IDLE)
        rd_fifo_cnt <= 8'b0;	
end

//wfifo的读使能
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rd_fifo_enable <= 1'b0;			
    else if(wr_state == S_WR_IDLE && wr_start)
        rd_fifo_enable <= 1'b1;
    else if(wr_fifo_re && (rd_fifo_cnt >= wr_len[10:3] - 1) )
        rd_fifo_enable <= 1'b0;
    else
        rd_fifo_enable <= rd_fifo_enable;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rd_fifo_almost_end <= 1'b0;
    else if(wr_fifo_re && (rd_fifo_cnt >= wr_len[10:3] - 2) )
        rd_fifo_almost_end <= 1'b1;				
    else if(wr_state == S_WR_IDLE )
        rd_fifo_almost_end <= 1'b0;
    else
        rd_fifo_almost_end <= rd_fifo_almost_end;
end

// Write State
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_state        <= S_WR_IDLE;
        reg_wr_adrs     <= 28'b0;
        reg_wr_len      <= 11'b0;
        reg_awvalid     <= 1'b0;
        reg_w_len       <= 8'd0;
        rd_first_data   <= 1'b0;
    end 
    else begin
        case(wr_state)
            S_WR_IDLE:begin
                reg_awvalid <= 1'b0;
                reg_w_len[3:0] <= 4'd0;
                reg_w_finish <= 1'b0;
                //写请求为高进入写地址开始状态
                if(wr_start) begin
                    wr_state    <= S_WA_START;
                    reg_wr_adrs <= wr_adrs;
                    reg_wr_len  <= wr_len - 1'b1;
                    reg_wr_len1 <= wr_len -1'b1;			
                    rd_first_data <= 1'b1;
                end
                else begin
                    wr_state <= S_WR_IDLE;
                end
            end
            S_WA_START: begin
                wr_state <= S_WD_WAIT;
                rd_first_data <= 1'b0;
                reg_awvalid <= 1'b1;
                //如果突发次数高四位不等于0，则将突发长度赋值为15；
                if(reg_wr_len[10:7] != 5'd0) begin                
                    reg_w_len[3:0] <= 4'hf;
                end 
                else begin
                    reg_w_len[3:0] <= reg_wr_len[6:3];
                end
            end  
            S_WD_WAIT:begin
                //读地址准备信号为高开始进行地址的突发写入
                if(m_axi_awready)begin
                    //突发长度高四位等于零，拉低写地址有效信号，进入读写等待状态
                    if(reg_wr_len[10:7] == 5'd0)begin
                        reg_w_len[3:0] <= reg_wr_len[6:3];
                        reg_awvalid <= 1'b0;	
                        wr_state <= S_WR_WAIT;
                        reg_wr_adrs <= reg_wr_adrs;
                    end
                    //突发长度高四位等于1，进行最后一次突发
                    else if(reg_wr_len[10:7] == 5'd1)begin
                            reg_w_len[3:0] <= reg_wr_len[6:3];
                            reg_awvalid <= reg_awvalid;	
                            wr_state <= S_WD_WAIT;
                            reg_wr_adrs <= reg_wr_adrs + 8'd128;
                            reg_wr_len[10:7] <= reg_wr_len[10:7] - 21'd1;
                        end
                    //突发长度高四位大于1，突发长度赋值15
                    else begin
                        reg_w_len[3:0] <= 4'hf;
                        reg_awvalid <= reg_awvalid;	
                        wr_state <= S_WD_WAIT;
                        reg_wr_adrs <= reg_wr_adrs + 8'd128;
                        reg_wr_len[10:7] <= reg_wr_len[10:7] - 21'd1;				
                    end
                end
                //读地址准备信号为低，进入写数据等待状态
                else begin
                    reg_w_len[3:0] <= reg_w_len[3:0] ;
                    reg_awvalid <= reg_awvalid;	
                    wr_state <= S_WD_WAIT;
                    reg_wr_adrs <= reg_wr_adrs ;
                    reg_wr_len[10:7] <= reg_wr_len[10:7];				
                end
            end		
            S_WR_WAIT:begin
                reg_awvalid <= 1'b0;
                if(rd_fifo_almost_end && m_axi_wlast && m_axi_wready)begin
                    wr_state <= S_WR_DONE;
                end 
                else if(reg_wr_len1[10:3] == 0 && m_axi_wlast && m_axi_wready)
                    wr_state <= S_WR_DONE;			
                else begin			
                    wr_state <= S_WR_WAIT;
                end
            end
            S_WR_DONE:begin
                wr_state <= S_WR_IDLE;
            end
            default:begin
                wr_state <= S_WR_IDLE;
            end
        endcase
    end
end

// The Read State
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_state <= S_RD_IDLE;
        reg_rd_adrs <= 28'd0;
        reg_rd_len <= 11'd0;
        reg_arvalid <= 1'b0;
        reg_r_len <= 8'd0;  
    end 
    else begin
        case(rd_state)
            S_RD_IDLE: begin
                reg_arvalid <= 1'b0;
                reg_r_len <= 8'd0;
                //读请求信号为高进入读地址开始状态
                if(rd_start) begin
                    rd_state <= S_RA_START;
                    reg_rd_adrs <= rd_adrs ;
                    reg_rd_len <= rd_len - 1'b1; 
                end
                else begin
                    rd_state <= S_RD_IDLE;
                end
                //读突发长度减一小于15，
                if(((rd_len[10:3] - 1'b1) <= 4'd15) && rd_start)
                    once_rd_num <= 1'b1;
                else
                    once_rd_num <= 1'b0;
            end
            S_RA_START: begin
                rd_state <= S_RD_WAIT;
                //一次读计数突发长度小于15，将突发长度直接赋值，
                if(once_rd_num)begin
                    reg_r_len[3:0] <= reg_rd_len[6:3];
                    reg_rd_len[10:7] <= 4'd0;
                    reg_arvalid <= 1'b1;				
                end
                //,突发长度高4位等于零，将突发长度直接赋值
                else if(reg_rd_len[10:7] == 4'd0)begin 
                    reg_r_len[3:0]  <=  reg_rd_len[6:3];
                    reg_rd_len[10:7] <= 4'd0;
                    reg_arvalid <= 1'b0;
                end	
                //一次读计数突发长度不小于15，将突发长度赋为15，
                else begin
                    reg_r_len[3:0] <= 4'd15;
                    reg_rd_len[10:7] <= reg_rd_len[10:7] - 1;
                    reg_arvalid <= 1'b1;
                end
            end
            S_RD_WAIT: begin
                //读地址准备信号为高，进入读数据状态
                if(m_axi_arready) begin
                    if(once_rd_num)begin
                        reg_r_len[3:0] <= reg_rd_len[6:3];
                        rd_state <= S_RD_PROC;		
                        reg_arvalid <= 1'b0;					
                    end
                    //突发长度高四位等于零，拉高读地址有效信号，进入读数据状态
                    else if(reg_rd_len[10:7] == 5'd0) begin
                        reg_r_len[3:0] <= reg_rd_len[6:3];
                        rd_state <= S_RD_PROC;
                        reg_rd_adrs <= reg_rd_adrs + 8'd128;					
                        reg_arvalid <= 1'b1;					
                    end else begin
                        reg_r_len[3:0] <= 4'd15;
                        reg_rd_adrs <= reg_rd_adrs + 8'd128;
                        rd_state <= S_RA_START;	
                        reg_arvalid <= 1'b0;					
                    end
                end
                //读地址准备信号为低，在读数据等待状态中循环
                else begin
                        reg_r_len[3:0] <= reg_r_len[3:0];
                        reg_rd_len[10:7] <= reg_rd_len[10:7] ;
                        reg_rd_adrs <= reg_rd_adrs ;
                        rd_state <= S_RD_WAIT;				
                end
            end  
            S_RD_PROC: begin
                rd_addr_cnt <= 1'b0;
                once_rd_num <= 1'b0;
                if(m_axi_arready)
                    reg_arvalid <= 1'b0;
                else
                    reg_arvalid <= reg_arvalid;
                if(reg_r_last) begin
                    rd_state <= S_RD_DONE;
                end 
                else begin
                    rd_state <= S_RD_PROC;
                end
            end
            S_RD_DONE:begin
                rd_state <= S_RD_IDLE;
            end 
        endcase
    end
end

 //从ddr3读出的有效数据使能进行计数
always @(posedge clk or negedge rst_n)  begin
    if(!rst_n)begin
        data_valid_cnt <= 8'b0;    
    end   
    else begin
        if((rd_state == S_RD_DONE) || (rd_state == S_RD_IDLE)) 
            data_valid_cnt <= 8'b0;     
        else if(m_axi_rvalid)
            data_valid_cnt <= data_valid_cnt + 1'b1;
        else
            data_valid_cnt <= data_valid_cnt;            
    end    
end  

 //从ddr3读出的有效数据使能进行计数
always @(posedge clk or negedge rst_n)  begin
    if(!rst_n)begin
        reg_r_last <= 1'b0;  
    end   
    else begin
        if((rd_state == S_RD_DONE) || (rd_state == S_RD_IDLE)) 
            reg_r_last <= 1'b0;     
        else if( (data_valid_cnt >= rd_len[10:3] - 1'b1) && m_axi_rvalid)
            reg_r_last <= 1'b1;
        else
            reg_r_last <= 1'b0;            
    end    
end 
 
endmodule

