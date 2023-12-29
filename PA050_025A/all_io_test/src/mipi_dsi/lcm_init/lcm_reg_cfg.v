//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           lcm_reg_cfg
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        LCD Module寄存器配置
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`include "../param_define.h" 

module lcm_reg_cfg (
    input                clk,
    input                rst_n,
    
    input        [1:0]   mipi_dsi_id,    //MIPI屏ID 1:720P  2:1080P    
    input                lpdt_tx_rdy,    //准备完成,高电平表示可以开始发送下一个字节
    input                lpdt_tx_done,   //单次数据包发送完成
    input        [15:0]  crc_result,     //CRC16校验值
    
    output  reg          lpdt_tx_vld,    //发送数据有效信号
    output  reg  [7:0]   lpdt_tx_data,   //8bit发送的数据
    output  reg          lcm_cfg_done,   //MIPI DSI屏寄存器配置完成
    output  reg          crc_en,         //CRC校验使能信号
    output  reg          crc_clr,        //CRC值恢复到初始值
    output  reg  [7:0]   crc_d8          //8位待校验数据
);

//parameter define
parameter  DCS_SW_NO_PARA = 8'h05;     //DCS短包写命令,不包含参数
parameter  DCS_SW_1_PARA  = 8'h15;     //DCS短包写命令,包含1个参数
parameter  DCS_LW         = 8'h39;     //DCS长包命令

`ifdef SIM
    localparam POWER_ON_WAIT  = 0;     //仿真时不做上电延时
`else
    localparam POWER_ON_WAIT  = 120;   //上电后延时120ms
`endif    

localparam ROM_START_ADDR_LCD0 = 0;    //720P参数的ROM起始地址
localparam ROM_NUM_DATA_LCD0 = 348;    //720P包含的参数地址个数
localparam ROM_START_ADDR_LCD1 = 348;  //1080P参数的ROM起始地址
localparam ROM_NUM_DATA_LCD1 = 351;    //1080P包含的参数地址个数
localparam st_idle      = 7'b000_0001; //空闲状态
localparam st_rd_ph     = 7'b000_0010; //读packet header
localparam st_ecc_calc  = 7'b000_0100; //ECC校验计算
localparam st_ph_tx     = 7'b000_1000; //发送packet header
localparam st_para_tx   = 7'b001_0000; //发送长包命令参数和CRC
localparam st_delay     = 7'b010_0000; //延时状态
localparam st_init_done = 7'b100_0000; //MIPI DSI初始化完成

//reg define
reg  [6:0]   cur_state;
reg  [6:0]   next_state;
reg          ms_cnt_en;     //毫秒计数器使能
reg  [7:0]   ms_cnt;        //毫秒计数器
reg  [13:0]  delay_cnt;     //延时计数器
reg          st_done;       //状态机开始跳转信号
reg  [9:0]   rom_addr;      //读ROM地址
reg  [9:0]   rom_end_addr;  //读ROM结束地址
reg  [3:0]   flow_cnt;      //流程计数器
reg          ecc_en;        //ECC计算使能信号
reg  [23:0]  ecc_in;        //ECC输入待校验数据
reg  [7:0]   ms_num;        //寄存发送完当前数据包的延时时间
reg  [7:0]   para_num;      //寄存要发送的参数总数
reg  [7:0]   para_num_cnt;  //发送的参数个数计数器

//wire define
wire [7:0]   ecc_out;       //ECC校验结果值
wire [7:0]   rom_data;      //读出的ROM数据

//*****************************************************
//**                    main code
//*****************************************************

//用于毫秒级延时计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        delay_cnt <= 14'b0;
        ms_cnt <= 8'b0;
    end    
    else if(ms_cnt_en) begin 
        delay_cnt <= delay_cnt + 14'b1;
        if(delay_cnt == 14'd10000 - 14'b1) begin
            delay_cnt <= 14'b0;
            ms_cnt <= ms_cnt + 8'b1;
        end                
    end    
    else begin
        delay_cnt <= 14'b0;
        ms_cnt <= 8'b0;    
    end
end

//(三段式状态机)同步时序描述状态转移
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;
    else
        cur_state <= next_state;
end

//组合逻辑判断状态转移条件
always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle: begin                          
           if(st_done) begin
               next_state = st_rd_ph;
           end
           else
               next_state = st_idle;
        end
        st_rd_ph : begin
            if(st_done)
                next_state = st_ecc_calc;
            else
                next_state = st_rd_ph;
        end
        st_ecc_calc : begin
            if(st_done)
                next_state = st_ph_tx;
            else
                next_state = st_ecc_calc;
        end
        st_ph_tx : begin
            if(st_done) begin
                if(ecc_in[7:0] == DCS_LW)       //当前命令包为长包命令
                    next_state = st_para_tx;
                else
                    next_state = st_delay;
            end
            else
                next_state = st_ph_tx;
        end        
        st_para_tx : begin
            if(st_done) 
                next_state = st_delay;
            else
                next_state = st_para_tx;
        end
        st_delay : begin
            if(st_done) begin
                if(rom_addr == rom_end_addr)    //读ROM地址结束
                    next_state = st_init_done;
                else
                    next_state = st_rd_ph;
            end
            else
                next_state = st_delay;
        end
        st_init_done : next_state = st_init_done;
        default : next_state = st_idle;
    endcase    
end    

//时序电路描述状态输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        st_done      <= 1'b0;
        rom_addr     <= 1'b0;
        rom_end_addr <= 1'b0;
        flow_cnt     <= 1'b0;
        ecc_en       <= 1'b0;
        ecc_in       <= 1'b0;
        ms_cnt_en    <= 1'b0;
        ms_num       <= 1'b0;
        para_num     <= 1'b0;
        para_num_cnt <= 1'b0;
        lpdt_tx_vld  <= 1'b0;
        lpdt_tx_data <= 1'b0;
        lcm_cfg_done <= 1'b0;
        crc_en       <= 1'b0;
        crc_clr      <= 1'b0;
        crc_d8       <= 1'b0;
    end
    else begin
        st_done <= 1'b0;
        crc_en <= 1'b0;
        crc_clr <= 1'b0;
        case(cur_state)
            st_idle : begin
                //上电延时完成
                if(ms_cnt == POWER_ON_WAIT && ms_cnt_en == 1'b1) begin
                    ms_cnt_en <= 1'b0;
                    st_done <= 1'b1;
                   if(mipi_dsi_id == 2'd1) begin //720P
                       rom_addr <= ROM_START_ADDR_LCD0;
                       rom_end_addr <= ROM_START_ADDR_LCD0 + ROM_NUM_DATA_LCD0;
                   end
                   else begin                    //1080P
                       rom_addr <= ROM_START_ADDR_LCD1;
                       rom_end_addr <= ROM_START_ADDR_LCD1 + ROM_NUM_DATA_LCD1;
                   end
                end    
                else    
                    ms_cnt_en <= 1'b1;           //上电延时计数
            end
            st_rd_ph : begin                     //根据长包和短包命令,从读取ROM中读取命令包头
                case(flow_cnt)
                    4'd0 : begin
                        ecc_in[7:0] <= rom_data;
                        rom_addr <= rom_addr + 1'b1;
                        flow_cnt <= flow_cnt + 1'b1;
                    end
                    4'd1 : flow_cnt <= flow_cnt + 1'b1;
                    4'd2 : begin
                        `ifdef SIM
                            ms_num <= 1'b0;      //仿真时不做延时
                        `else
                            ms_num <= rom_data;  //寄存发完数据包需要延时的时间
                        `endif
                        rom_addr <= rom_addr + 1'b1;
                        flow_cnt <= flow_cnt + 1'b1;
                    end
                    4'd3 : flow_cnt <= flow_cnt + 1'b1;
                    4'd4 : begin
                        para_num <= rom_data;
                        rom_addr <= rom_addr + 1'b1;
                        flow_cnt <= flow_cnt + 1'b1;
                        if(ecc_in[7:0] == DCS_LW) begin
                            ecc_in[23:8] <= {8'h00,rom_data};
                            st_done <= 1'b1;
                        end
						else;
                    end
                    4'd5 : begin
                        if(st_done)
                            flow_cnt <= 1'b0;
                        else
                            flow_cnt <= flow_cnt + 1'b1;
                    end        
                    4'd6 : begin
                        ecc_in[15:8] <= rom_data;
                        rom_addr <= rom_addr + 1'b1;
                        flow_cnt <= flow_cnt + 1'b1;
                        if(ecc_in[7:0] == DCS_SW_NO_PARA) begin
                            ecc_in[23:16] <= 8'h00;
                            st_done <= 1'b1;
                        end
						else;
                    end
                    4'd7 : begin
                        if(st_done)
                            flow_cnt <= 1'b0;
                        else begin
                            flow_cnt <= flow_cnt + 1'b1;
                            st_done <= 1'b1;
                        end
                     end    
                    4'd8 : begin
                        ecc_in[23:16] <= rom_data;
                        rom_addr <= rom_addr + 1'b1;
                        flow_cnt <= 1'b0;
                    end
                    default :;
                endcase    
            end    
            st_ecc_calc : begin                  //计算ECC校验值
                case(flow_cnt)
                    4'd0 : begin
                        ecc_en <= 1'b1;
                        flow_cnt <= flow_cnt + 1'b1;
                    end
                    4'd1 : begin
                        st_done <= 1'b1;
                        flow_cnt <= flow_cnt + 1'b1;
                    end                    
                    4'd2 : flow_cnt <= 1'b0;
                    default :;
                endcase
            end
            st_ph_tx : begin                     //发送命令包头,共4个字节
                case(flow_cnt)
                    4'd0 : begin
                        lpdt_tx_vld <= 1'b1;
                        lpdt_tx_data <= ecc_in[7:0];
                        flow_cnt <= flow_cnt + 1'b1;
                    end    
                    4'd1 : begin
                        if(lpdt_tx_rdy) begin
                            lpdt_tx_data <= ecc_in[15:8];
                            flow_cnt <= flow_cnt + 1'b1;
                        end
						else;
                    end
                    4'd2 : begin
                        if(lpdt_tx_rdy) begin
                            lpdt_tx_data <= ecc_in[23:16];
                            flow_cnt <= flow_cnt + 1'b1;
                        end
						else;
                    end
                    4'd3 : begin
                        if(lpdt_tx_rdy) begin
                            lpdt_tx_data <= ecc_out;
                            flow_cnt <= flow_cnt + 1'b1;
                        end
						else;
                    end
                    4'd4 : begin
                        if(lpdt_tx_rdy) begin
                            st_done <= 1'b1;
                            flow_cnt <= flow_cnt + 1'b1;
                            if(ecc_in[7:0] == DCS_LW) begin
                                lpdt_tx_data <= rom_data;
                                rom_addr <= rom_addr + 1'b1;
                                para_num_cnt <= para_num_cnt + 1'b1;
                                crc_en <= 1'b1;
                                crc_d8 <= rom_data;
                            end
                            else begin
                                lpdt_tx_data <= 1'b0;
                                lpdt_tx_vld <= 1'b0;
                            end
                        end
                    end
                    4'd5 : flow_cnt <= 1'b0;
                    default :;
                endcase    
            end
            st_para_tx : begin                   //发送长包命令的参数  
                case(flow_cnt)
                    4'd0 : begin
                        if(lpdt_tx_rdy) begin
                            if(para_num_cnt < para_num) begin
                                lpdt_tx_data <= rom_data;
                                rom_addr <= rom_addr + 1'b1;
                                para_num_cnt <= para_num_cnt + 1'b1;
                                crc_en <= 1'b1;
                                crc_d8 <= rom_data;
                            end
                            else begin
                                lpdt_tx_data <= crc_result[7:0];
                                para_num_cnt <= 1'b0;
                                flow_cnt <= flow_cnt + 1'b1;
                            end
                        end
                    end
                    4'd1 : begin
                        if(lpdt_tx_rdy) begin
                            lpdt_tx_data <= crc_result[15:8];
                            flow_cnt <= flow_cnt + 1'b1;
                        end
						else;
                    end
                    4'd2 : begin
                        if(lpdt_tx_rdy) begin
                            flow_cnt <= flow_cnt + 1'b1;
                            lpdt_tx_vld <= 1'b0;
                            lpdt_tx_data <= 1'b0;
                            st_done <= 1'b1;
                        end
						else;
                    end
                    4'd3 : flow_cnt <= 1'b0;
                    default : ;
                endcase    
            end    
            st_delay : begin                     //根据ROM中存储的延时参数,选择是否延时   
                case(flow_cnt) 
                    4'd0 : begin
                        if(lpdt_tx_done)
                            flow_cnt <= flow_cnt + 1'b1;
						else;	
                    end
                    4'd1 : begin
                        if(ms_num == 1'b0) begin //等于0表示不延时
                            st_done <= 1'b1;
                            flow_cnt <= flow_cnt + 1'b1;
                        end
                        else begin
                            ms_cnt_en <= 1'b1;
                            flow_cnt <= flow_cnt + 4'd2;
                        end
                    end    
                    4'd2 : begin
                        flow_cnt <= 1'b0;
                        ms_cnt_en <= 1'b0;
                        crc_clr <= 1'b1;
                    end
                    4'd3 : begin                  //等待延时完成 
                        if(ms_cnt == ms_num) begin
                            st_done <= 1'b1; 
                            flow_cnt <= 4'd2;
                        end 
                        else;						
                    end
                    default : ;                 
                endcase    
            end
            st_init_done : lcm_cfg_done <= 1'b1; //MIPI DSI屏幕初始化完成
        endcase
    end
end    

//例化ECC校验模块
ecc u0_ecc(
    .clk         (clk), 
    .rst_n       (rst_n),

    .data_en     (ecc_en ),
    .data_in     (ecc_in ),
    .data_out    (ecc_out)
    );

//例化ROM IP核，存储了不同MIPI DSI屏幕的参数    
rom_1024x8b_lcm_para u_rom_1024x8b_lcm_para(
    .addr        (rom_addr),
    .rd_data     (rom_data),
    .clk         (clk),
    .rst         (1'b0)
    );    

endmodule 
