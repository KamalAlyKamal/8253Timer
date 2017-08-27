//Mode 5 tb
`timescale 1ns/10ps
`include "Counter.v"
module Counter_tb2();


reg [5:0] ControlWord1;
reg EnableCounterLatch1;
reg EnableStatusLatch1;
reg ReadSignal1;
reg WriteSignal1;
reg clkinput1;
reg gate1;

reg  [7:0] Data1i;
wire [7:0] Data1O;

wire out1;
wire  [15:0] CEoutput1;

//reg mem_oe;
//assign Data1O = (/*mem_oe*/1) ? Data1i : 7'hz;
assign Data1O = (WriteSignal1) ?Data1i :'bz ;


Counter UUT(ReadSignal1,WriteSignal1,clkinput1,
	    gate1,out1,ControlWord1,EnableCounterLatch1,
	    EnableStatusLatch1,Data1O
);

localparam period=10;

always
	#(period/2) clkinput1 = ~clkinput1;

initial begin
clkinput1 = 0;
ReadSignal1 =0;
WriteSignal1 = 1;
gate1 = 0;
ControlWord1 = 'b011010;
EnableCounterLatch1=0;
EnableStatusLatch1=0;
Data1i = 'd30;

#(1*period) 
	WriteSignal1 = 0;

#(2*period) 

#(1*period) 
	gate1 = 1;

#(1*period/2) 
	gate1 = 0;



//#(2*period)

 ///        gate1= 1;
#(5*period)
	WriteSignal1 = 1;
	Data1i = 'd5;

#(1*period)
	WriteSignal1 = 0;
	gate1 = 1;
#(1*period)
	gate1 = 0;

//#(1*period)
//	gate1= 1;

#(20*period)
$finish;
end

endmodule
