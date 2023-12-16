module top(
    input               clk,

    output      [38:0]  exter_io_h1,exter_io_h4,
    output      [37:0]  exter_io_h2,exter_io_h3
);

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 			    测试时钟输入 	         /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
// 降低到hz，生成分频信号1hz A
reg [24:0] cnt;
always@(posedge clk)
    cnt <= cnt + 1;

logic clk_A ;
assign clk_A = cnt[24];
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//////////////////// 			    测试外部IO	            /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
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
assign exter_io_h1[34] = clk_A ;
assign exter_io_h1[35] = ~clk_A ;
assign exter_io_h1[36] = clk_A ;
assign exter_io_h1[37] = ~clk_A ;
assign exter_io_h1[38] = clk_A ;

assign exter_io_h4[0] = clk_A ;
assign exter_io_h4[1] = ~clk_A ;
assign exter_io_h4[2] = clk_A ;
assign exter_io_h4[3] = ~clk_A ;
assign exter_io_h4[4] = clk_A ;
assign exter_io_h4[5] = ~clk_A ;
assign exter_io_h4[6] = clk_A ;
assign exter_io_h4[7] = ~clk_A ;
assign exter_io_h4[8] = clk_A ;
assign exter_io_h4[9] = ~clk_A ;
assign exter_io_h4[10] = clk_A ;
assign exter_io_h4[11] = ~clk_A ;
assign exter_io_h4[12] = clk_A ;
assign exter_io_h4[13] = ~clk_A ;
assign exter_io_h4[14] = clk_A ;
assign exter_io_h4[15] = ~clk_A ;
assign exter_io_h4[16] = clk_A ;
assign exter_io_h4[17] = ~clk_A ;
assign exter_io_h4[18] = clk_A ;
assign exter_io_h4[19] = ~clk_A ;
assign exter_io_h4[20] = clk_A ;
assign exter_io_h4[21] = ~clk_A ;
assign exter_io_h4[22] = clk_A ;
assign exter_io_h4[23] = ~clk_A ;
assign exter_io_h4[24] = clk_A ;
assign exter_io_h4[25] = ~clk_A ;
assign exter_io_h4[26] = clk_A ;
assign exter_io_h4[27] = ~clk_A ;
assign exter_io_h4[28] = clk_A ;
assign exter_io_h4[29] = ~clk_A ;
assign exter_io_h4[30] = clk_A ;
assign exter_io_h4[31] = ~clk_A ;
assign exter_io_h4[32] = clk_A ;
assign exter_io_h4[33] = ~clk_A ;
assign exter_io_h4[34] = clk_A ;
assign exter_io_h4[35] = ~clk_A ;
assign exter_io_h4[36] = clk_A ;
assign exter_io_h4[37] = ~clk_A ;
assign exter_io_h4[38] = clk_A ;

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
assign exter_io_h2[36] = clk_A ;
assign exter_io_h2[37] = ~clk_A ;

assign exter_io_h3[0] = clk_A ;
assign exter_io_h3[1] = ~clk_A ;
assign exter_io_h3[2] = clk_A ;
assign exter_io_h3[3] = ~clk_A ;
assign exter_io_h3[4] = clk_A ;
assign exter_io_h3[5] = ~clk_A ;
assign exter_io_h3[6] = clk_A ;
assign exter_io_h3[7] = ~clk_A ;
assign exter_io_h3[8] = clk_A ;
assign exter_io_h3[9] = ~clk_A ;
assign exter_io_h3[10] = clk_A ;
assign exter_io_h3[11] = ~clk_A ;
assign exter_io_h3[12] = clk_A ;
assign exter_io_h3[13] = ~clk_A ;
assign exter_io_h3[14] = clk_A ;
assign exter_io_h3[15] = ~clk_A ;
assign exter_io_h3[16] = clk_A ;
assign exter_io_h3[17] = ~clk_A ;
assign exter_io_h3[18] = clk_A ;
assign exter_io_h3[19] = ~clk_A ;
assign exter_io_h3[20] = clk_A ;
assign exter_io_h3[21] = ~clk_A ;
assign exter_io_h3[22] = clk_A ;
assign exter_io_h3[23] = ~clk_A ;
assign exter_io_h3[24] = clk_A ;
assign exter_io_h3[25] = ~clk_A ;
assign exter_io_h3[26] = clk_A ;
assign exter_io_h3[27] = ~clk_A ;
assign exter_io_h3[28] = clk_A ;
assign exter_io_h3[29] = ~clk_A ;
assign exter_io_h3[30] = clk_A ;
assign exter_io_h3[31] = ~clk_A ;
assign exter_io_h3[32] = clk_A ;
assign exter_io_h3[33] = ~clk_A ;
assign exter_io_h3[34] = clk_A ;
assign exter_io_h3[35] = ~clk_A ;
assign exter_io_h3[36] = clk_A ;
assign exter_io_h3[37] = ~clk_A ;

endmodule

