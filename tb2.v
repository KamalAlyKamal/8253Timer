
`timescale 1ns/10ps
`include "Chip.v"
module TestBench_tb2();

reg RD;
reg WR;
reg CS;
reg A0;
reg A1;
reg clk1,clk2,clk3,gate0,gate1,gate2;
wire out1,out2,out3;
reg  [7:0] Datai;
wire [7:0] DataO;
assign DataO = (~WR) ?Datai :'bz ;

Chip8254 c( DataO, RD,WR, CS, A0, A1, clk1, clk2, clk3, gate0, gate1, gate2, out1, out2,out3);

localparam period=10;

always
begin
	#(period/2) clk1 = ~clk1;
	#(period/2) clk2 = ~clk2;
	#(period/2) clk3 = ~clk3;
end

initial begin
CS=0;
clk1=0;
clk2=0;
clk3=0;

gate0=0;
gate1=0;
gate2=0;

A0=1;A1=1;		//Control Word Register
#(1*period)
	WR=0;		//Writes control word
	RD=1;
	Datai='b01011001 ;     //send to control register : mode0 , binary ,least signficant byte , counter0 
	
#(1*period) 
	WR=1;
#(1*period)
	A0=1;
	A1=0;	//Counter 0
	WR=0;
	RD=1;
	Datai = 'h15;   // send to counter 0 10 decimal 

#(1*period) 
	WR = 1;
	gate1=1;

#(1*period) 
	
#(30*period) 

	//WR = 0;
	//Datai = 'd5;
#(1*period) 
	//WR = 1;
	//gate1 = 1;
#(1*period) 
	//gate1 = 0;
#(50*period) 

//////////////////////////////////==================>>>>>>>>>>

//read//
A0 = 1;
A1 = 0;
WR = 1;
RD = 0;
#(1*period)
RD = 1;

#(20*period)
////////
/*

#(2*period)
	WR = 0;
	Datai = 'd20;
#(1*period)
	WR = 1;
#(2*period)
	gate1 = 0;
#(2*period)
	gate1 = 1;
#(10*period)
*/
/*
A0 = 1;
A1 = 0;
RD=0;
#(1*period)
RD = 1;
#(1*period)
RD = 0;
#(1*period)
RD = 1;
*/
#(1*period)


////////////////////////////////////////////////////////////////
//gate0 = 1; //Start counting

//#(5*period)	

//gate0 = 1; //Start counting

#(10*period)	
	A0=1;	//Send control word
	A1=1;
	WR=0;
	RD=1;
	Datai='b11000100; // send Read back status and count of counter 0
	
#(5*period)	
	A0=1;	//Select Counter0
	A1=0;
	WR=1;
	RD=0; //Read status from counter0

#(1*period)
	RD = 1;
#(1*period)
	RD=0;	//Read count from counter0
#(1*period)
	RD = 1;

#(10*period)	
////////////////////////////////////////////////////////////////////////////////////////////
#(1*period)	
	A0=1;	//Send Control Word
	A1=1;
	WR=0;
	RD=1;
	Datai='b01111010;	//Send new configuration to counter 1 mode 5 binary LSB then MSB
	
#(1*period) 
	A0 =1;	//Counter 1
	A1 =0 ;
	WR =0 ;
	RD =1 ;
	Datai = 'd16 ; //send 16 decimal as LSB which is  to counter 1
		
#(1*period)
	WR=1;
#(1*period)		
 	WR = 0;
	Datai = 'd0;	//send 0 as MSB
#(1*period)	
	WR = 1;
	gate1 = 1;
#(5*period)
	A0=1;	//send Control Word
	A1=1;
	WR=0;
	RD=1;
	Datai='b00000000;	//Send Counter Latch Command to Counter 1

#(4*period)
	A0=1;			//Counter 1
	A1=0;
	WR=1;
	RD=0;			//Send a read signal to counter 1 to read the latch
#(1*period)
	RD=1;
#(1*period) 
	A0=1;			//Control Register
	A1=1;
	WR=0;
	RD=1;
	Datai='b00010010;	//Change mode of counter 0 to 1
#(1*period)
	A0=0;			//Counter 0
	A1=0;
	WR=0;
	RD=1;
	Datai='d5;		//Send initial count as LSB to Counter 0
	gate0 = 0;
#(1*period)
	WR = 1;
	gate0 = 1;
#(7*period)		// - Full Run, then Reactivate -->
	gate0 = 0;	// - Stop gate and activate again -->
#(1*period)		
	gate0 = 1;	//
#(7*period)
	gate0 = 0;
#(1*period)
	gate0 = 1;
#(4*period)
	gate0 = 0;
#(1*period)
	gate0 = 1;
#(1*period)
	WR = 0;
	Datai = 'd10;	// - Add count while counting -->
#(1*period)
	WR = 1;
#(15*period)
	



	
	gate0 = 0;
	A0=1;
	A1=1;
	WR=0;
	RD=1;
	Datai='b00010100;	//change mode of counter 0 to 2
#(1*period)
	A0=0;
	A1=0;
	WR=0;
	RD=1;
	Datai='d5;		//Send initial count as LSB to Counter 0
#(1*period)
	WR = 1;
	gate0 = 1;
#(7*period)		// - Full Run, then Reactivate -->
	WR = 0;		// - Stop gate and acivate again -->
#(1*period)		// - Add count while counting -->
	WR = 1;	//
#(7*period)
	gate0 = 0;
#(1*period)
	gate0 = 1;
#(1*period)
	WR = 0;
	Datai = 'd10;
#(1*period)
	WR = 1;
#(15*period)
	

	gate0 = 0;
	A0=1;
	A1=1;
	WR=0;
	RD=1;
	Datai='b00010100;	//change mode of counter 0 to 3
#(1*period)
	A0=0;
	A1=0;
	WR=0;
	RD=1;
	Datai='d5;		//Send initial count as LSB to Counter 0
#(1*period)
	WR = 1;
	gate0 = 1;
#(7*period)		// - Full Run, then Reactivate -->
	WR = 0;		// - Stop gate and acivate again -->
#(1*period)		// - Add count while counting -->
	WR = 1;	//
#(7*period)
	gate0 = 0;
#(1*period)
	gate0 = 1;
#(1*period)
	WR = 0;
	Datai = 'd10;
#(1*period)
	WR = 1;
#(15*period)



	gate0 = 0;
	A0=1;
	A1=1;
	WR=0;
	RD=1;
	Datai='b00010100;	//change mode of counter 0 to 4
#(1*period)
	A0=0;
	A1=0;
	WR=0;
	RD=1;
	Datai='d5;		//Send initial count as LSB to Counter 0
#(1*period)
	WR = 1;
	gate0 = 1;
#(7*period)		// - Full Run, then Reactivate -->
	WR = 0;		// - Stop gate and acivate again -->
#(1*period)		// - Add count while counting -->
	WR = 1;	//
#(7*period)
	gate0 = 0;
#(1*period)
	gate0 = 1;
#(1*period)
	WR = 0;
	Datai = 'd10;
#(1*period)
	WR = 1;
#(15*period)


	gate0 = 0;
	A0=1;
	A1=1;
	WR=0;
	RD=1;
	Datai='b00010100;	//Send new configuraton to Counter 0 (Mode 5)
#(1*period)
	A0=0;
	A1=0;
	WR=0;
	RD=1;
	Datai='d5;		//Send initial count as LSB to Counter 0
#(1*period)
	WR = 1;
	gate0 = 1;
#(7*period)		// - Full Run, then Reactivate -->
	gate0 = 0;		// - Stop gate and acivate again -->
#(1*period)		// - Add count while counting -->
	gate0 = 1;	//
#(7*period)
	gate0 = 0;
#(1*period)
	gate0 = 1;
#(1*period)
	WR = 0;
	gate0 = 0;
	Datai = 'd10;
#(1*period)
	gate0 = 1;
#(15*period)
$finish;
end

endmodule
