module Chip8254(

inout [7:0]  Data,
input RD,
input WR,
input CS,
input A0,
input A1,
input clk0,
input clk1,
input clk2,
input gate0,
input gate1,
input gate2,
output  out0,
output  out1,
output  out2                                    
);


wire [3:0] Read_Enable;
wire [3:0] Write_Enable;
//wire [2:0] readback;
wire [5:0] cw0_i,cw1_i,cw2_i,cw0_o,cw1_o,cw2_o;
wire [2:0] EnabStatusLatches_i;
wire [2:0] EnabStatusLatches_o;
wire [2:0] EnabCounterLatches_i;
wire [2:0] EnabCounterLatches_o;


ReadWrite RWM(RD,WR,A0,A1,CS,Read_Enable,Write_Enable);


Counter c0(Read_Enable[0],Write_Enable[0],clk0,gate0,out0,cw0_o,EnabCounterLatches_o[0],EnabStatusLatches_o[0],Data);
Counter c1(Read_Enable[1],Write_Enable[1],clk1,gate1,out1,cw1_o,EnabCounterLatches_o[1],EnabStatusLatches_o[1],Data);
Counter c2(Read_Enable[2],Write_Enable[2],clk2,gate2,out2,cw2_o,EnabCounterLatches_o[2],EnabStatusLatches_o[2],Data);

assign cw0_i=cw0_o;
assign cw1_i=cw1_o;	//Output from Control Word Register to the counters then it is assigned as an input again for the control word register
assign cw2_i=cw2_o;

assign EnabStatusLatches_i=EnabStatusLatches_o;
assign EnabCounterLatches_i=EnabCounterLatches_o;

ControlWordRegister CRG(Data,Write_Enable[3],cw0_i,cw1_i,cw2_i,cw0_o,cw1_o,cw2_o,EnabCounterLatches_i,EnabCounterLatches_o,EnabStatusLatches_i,EnabStatusLatches_o);


endmodule

