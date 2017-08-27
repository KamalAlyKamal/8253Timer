module ReadWrite(input RD, input WR, input A0, input A1, input CS, output [3:0]ReadSignal, output [3:0]WriteSignal);

/*ReadSignal	&	WriteSignal
	Bit 0 = Counter0
	Bit 1 = Counter1
	Bit 2 = Counter2
	Bit 3 = ControlReg
*/

//Read Signal
assign ReadSignal = 	(A1==0 && A0==0 && RD==0 && WR==1 && CS==0)?'b0001:
			(A1==0 && A0==1 && RD==0 && WR==1 && CS==0)?'b0010:
			(A1==1 && A0==0 && RD==0 && WR==1 && CS==0)?'b0100:
			//(A1==1 && A0==1 && RD==0 && WR==1 && CS==0)?'b1000:
			'b0000; 

//Write Signal
assign WriteSignal = 	(A1==0 && A0==0 && RD==1 && WR==0 && CS==0)?'b0001:
			(A1==0 && A0==1 && RD==1 && WR==0 && CS==0)?'b0010:
			(A1==1 && A0==0 && RD==1 && WR==0 && CS==0)?'b0100:
			(A1==1 && A0==1 && RD==1 && WR==0 && CS==0)?'b1000:
			'b0000; 

endmodule
