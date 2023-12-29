//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           crc16_d8
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        CRC16_D8校验
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module crc16_d8(
    input                 clk     ,  //时钟信号
    input                 rst_n   ,  //复位信号，低电平有效
    input         [7:0]   data    ,  //输入待校验8位数据
    input                 crc_en  ,  //crc使能，开始校验标志
    input                 crc_clr ,  //crc数据复位信号            
    output   reg  [15:0]  crc_data,  //CRC校验数据
    output        [15:0]  crc_next   //CRC下次校验完成数据
    );

//*****************************************************
//**                    main code
//*****************************************************

//输入待校验8位数据,需要先将高低位互换
wire    [7:0]  data_t;

assign data_t = {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]};

//CRC16的生成多项式为：G(x)= x^16 + x^12 + x^5 + 1

assign crc_next[0] = data_t[4] ^ data_t[0] ^ crc_data[8] ^ crc_data[12];
assign crc_next[1] = data_t[5] ^ data_t[1] ^ crc_data[9] ^ crc_data[13];
assign crc_next[2] = data_t[6] ^ data_t[2] ^ crc_data[10] ^ crc_data[14];
assign crc_next[3] = data_t[7] ^ data_t[3] ^ crc_data[11] ^ crc_data[15];
assign crc_next[4] = data_t[4] ^ crc_data[12];
assign crc_next[5] = data_t[5] ^ data_t[4] ^ data_t[0] ^ crc_data[8] ^ crc_data[12] ^ crc_data[13];
assign crc_next[6] = data_t[6] ^ data_t[5] ^ data_t[1] ^ crc_data[9] ^ crc_data[13] ^ crc_data[14];
assign crc_next[7] = data_t[7] ^ data_t[6] ^ data_t[2] ^ crc_data[10] ^ crc_data[14] ^ crc_data[15];
assign crc_next[8] = data_t[7] ^ data_t[3] ^ crc_data[0] ^ crc_data[11] ^ crc_data[15];
assign crc_next[9] = data_t[4] ^ crc_data[1] ^ crc_data[12];
assign crc_next[10] = data_t[5] ^ crc_data[2] ^ crc_data[13];
assign crc_next[11] = data_t[6] ^ crc_data[3] ^ crc_data[14];
assign crc_next[12] = data_t[7] ^ data_t[4] ^ data_t[0] ^ crc_data[4] ^ crc_data[8] ^ crc_data[12] ^ crc_data[15];
assign crc_next[13] = data_t[5] ^ data_t[1] ^ crc_data[5] ^ crc_data[9] ^ crc_data[13];
assign crc_next[14] = data_t[6] ^ data_t[2] ^ crc_data[6] ^ crc_data[10] ^ crc_data[14];
assign crc_next[15] = data_t[7] ^ data_t[3] ^ crc_data[7] ^ crc_data[11] ^ crc_data[15];

//寄存输出CRC校验后的数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        crc_data <= 32'hff_ff_ff_ff;
    else if(crc_clr)                             //CRC校验值复位
        crc_data <= 32'hff_ff_ff_ff;
    else if(crc_en)
        crc_data <= crc_next;
end

endmodule
