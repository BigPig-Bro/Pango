//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           ecc
// Created by:          正点原子
// Created date:        2023年9月23日15:38:10
// Version:             V1.0
// Descriptions:        ECC校验
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ecc
(
    input                   clk     ,
    input                   rst_n   ,
    
    input                   data_en  ,  //数据有效使能信号
    input           [23:0]  data_in  ,  //待校验数据
    output  reg     [7:0]   data_out    //校验完成后的数据
);

//ECC校验
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        data_out <= 8'b00000000;
    else if(data_en == 1'b1) begin
        data_out[0] <= data_in[ 0] ^ data_in[ 1] ^ data_in[ 2] ^ data_in[ 4] ^ data_in[ 5] ^ data_in[ 7] ^ data_in[10] ^ data_in[11] ^ data_in[13] ^ data_in[16] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[23];
        data_out[1] <= data_in[ 0] ^ data_in[ 1] ^ data_in[ 3] ^ data_in[ 4] ^ data_in[ 6] ^ data_in[ 8] ^ data_in[10] ^ data_in[12] ^ data_in[14] ^ data_in[17] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[23];
        data_out[2] <= data_in[ 0] ^ data_in[ 2] ^ data_in[ 3] ^ data_in[ 5] ^ data_in[ 6] ^ data_in[ 9] ^ data_in[11] ^ data_in[12] ^ data_in[15] ^ data_in[18] ^ data_in[20] ^ data_in[21] ^ data_in[22];
        data_out[3] <= data_in[ 1] ^ data_in[ 2] ^ data_in[ 3] ^ data_in[ 7] ^ data_in[ 8] ^ data_in[ 9] ^ data_in[13] ^ data_in[14] ^ data_in[15] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[23];
        data_out[4] <= data_in[ 4] ^ data_in[ 5] ^ data_in[ 6] ^ data_in[ 7] ^ data_in[ 8] ^ data_in[ 9] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[22] ^ data_in[23];
        data_out[5] <= data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[21] ^ data_in[22] ^ data_in[23];
        data_out[6] <= 1'b0;
        data_out[7] <= 1'b0;
    end
end
    
endmodule