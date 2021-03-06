module Counter(	input ReadSignal, input WriteSignal, input clkinput, input gate, output reg out,
		input [5:0] ControlWord, input EnableCounterLatch, input EnableStatusLatch,
		inout [7:0] Data
);


/*
statusRead = EnableStatusLatch
statusLatch = StatusByteLatch[7]	//OUT flag
statusLatch3 = StatusByteLatch[6]	//Null Flag Wire
statusLatch1 = StatusByteReg[6]		//NULL flag Reg
statusLatch2[5:0] = StatusByteLatch[5:0] / StatusByteReg

statusReadr = StatusByteReadCheck
outbus = DataOutput
count = CEoutput

CRSignal = CRloaded	
CRFlag = CRNullControl
	//Reason for having  2 diff variables is that initial value is not always moved to
	//the CE on the spot. Might take time to be moved, thus Null counter wont change. But
	//Can ask to change initial value again earlier (Change CRloaded).

CR = CRM + CRL
controlWord = ControlWord
latchcount = CountLatchCheck
readback = EnableCounterLatch

m0 = mode0
initialization = Start

gateFlag = gateTrigger
*/

//Initialization/////
wire [2:0] mode;
reg  [7:0] DataOutput;				//Data bus output
reg	   SimpleRead=0;			//Used in simple reading 2 bytes format to pause clk. 0=continue. 1=pause clk
wire	   clk;					//Clk after changing

reg  [7:0] CRM;
reg  [7:0] CRL;
reg	   CRloaded;				//signal = 1 if CR is waiting to be read, has a value.
reg	   CRNullControl=0;			//0= CR->CE,	1= initial value still in CR

reg  [7:0] StatusByteReg;			//6=NULL.  7=OUT
wire [7:0] StatusByteLatch;			//6=NULL.  7=OUT
reg 	   StatusByteReadCheck = 0;		//Check that you have read the status. 1 = waiting to be read. 0 = Empty

wire [7:0] OLM;
wire [7:0] OLL;
reg	   CountLatchCheck = 0;			//0=No latch. 1=Latched OLs

reg  [1:0] WriteState = 'd3;			//Initial write Value. Used in wirte CR
reg  [1:0] ReadState  = 'd3;

reg  [15:0] CEoutput = 'hzzzz; //AWAL 7AGA

reg  [4:0]  State_Reg;
reg  [4:0]  State_Next;
reg         gateTrigger = 'b0; 			//Posedge of gate. 0=no trigger. 1=trigger 
reg  [15:0] LimitValue;					//Used in mode 3 for even count and even count
reg  [15:0] CR;						//HERE*********////////    //Contains vlue of CRM,CRL. used in mode 3

reg         LoadFlag = 0;			//HERE////////////	//Represents written from Written to CR
							//1 = CRM and CRL written successfully. 0 = Data is not written to CR. 
//Modes
localparam mode0  = 'b00000;
localparam mode1  = 'b00001;
localparam mode2  = 'b00010;
localparam mode3  = 'b00011;
localparam mode4  = 'b00100;
localparam mode5  = 'b00101;

localparam Start  = 'b00110;

localparam mode00 = 'b00111;
localparam mode01 = 'b01000;
localparam mode02 = 'b01001;

localparam mode10 = 'b01010;
localparam mode11 = 'b01011;
localparam mode12 = 'b01100;

localparam mode20 = 'b01101;
localparam mode21 = 'b01110;
localparam mode22 = 'b01111;

localparam mode30 = 'b10000;
localparam mode31 = 'b10001;
localparam mode320 ='b10011;
localparam mode32 = 'b10010;
/////////////////////
localparam mode40 = 'b10100;
localparam mode41 = 'b10101;
localparam mode42 = 'b10111;
/////////////////////
localparam mode50= 'b11000;
localparam mode51= 'b11001;
localparam mode52= 'b11010;


assign mode = ControlWord[3:1];
assign Data=(ReadSignal == 1)?DataOutput:8'bz;
assign clk = (SimpleRead==0)?clkinput:1;

assign StatusByteLatch[7]=(EnableStatusLatch==1 && StatusByteReadCheck==0)?StatusByteReg[7]:StatusByteLatch[7];
assign StatusByteLatch[6]=(EnableStatusLatch==1 && StatusByteReadCheck==0)?StatusByteReg[6]:StatusByteLatch[6];
assign StatusByteLatch[5:0]=(EnableStatusLatch==1 && StatusByteReadCheck==0)?StatusByteReg[5:0]:StatusByteLatch[5:0];

assign OLM[7:0] = (CountLatchCheck=='b0)?CEoutput[15:8]:OLM[7:0];
assign OLL[7:0] = (CountLatchCheck=='b0)?CEoutput[7:0]:OLL[7:0];





/////Assigning Status Byte Reg////////
always@(ControlWord)
begin
	if(ControlWord[5:4]!=00) 
	begin
		StatusByteReg[5:0]  = ControlWord;
	end
end
//////////////////////////////////////



/////Latching Status From Read Back Command/////////
always @(posedge EnableStatusLatch)
begin
	StatusByteReadCheck='b1;
end
////////////////////////////////////////////////////



///////////////////Latching Count ///////////////////
//From Counter Latch Command
always @(ControlWord)
begin
	if (ControlWord[5:4]==2'b00)
		begin
		CountLatchCheck=1'b1;
		end
end

//From Read Back Command
always @(posedge EnableCounterLatch)
begin
	CountLatchCheck=1'b1;
end
/////////////////////////////////////////////////////




/////////////Writing to CR////////////////////////////
always @(posedge WriteSignal)
begin
	if (WriteState=='d3)
		begin
		if (StatusByteReg[5:4]==2'b01) 
			begin
			WriteState=2'd2;
			CRM[7:0]='b0;
			end
		else if (StatusByteReg[5:4]==2'b10)
			begin
			WriteState=2'd1;
			CRL[7:0]=8'b0;
			end
		else if (StatusByteReg[5:4]==2'b11)
			WriteState=2'd0;
		end

		if (WriteState==2'd0)
			begin
			CRL[7:0]=Data[7:0];
			WriteState=2'd1;
			end
		else if (WriteState==2'd1)
			begin
			CRM[7:0]=Data[7:0];
			WriteState=2'd3;
			CRloaded=1'b1;
			LoadFlag = 1; //HERE//
			end
		else if (WriteState==2'd2)
			begin
			CRL[7:0]=Data[7:0];
			WriteState=2'd3;
			CRloaded=1'b1;
			LoadFlag = 1;
			end
end
////////////////////////////////////////////////////



/////////////Reading From OL M/L////////////////////
always @(posedge ReadSignal)
begin
	if (StatusByteReadCheck==1'b1)
		begin
		DataOutput[7:0]=StatusByteReg[7:0];
		StatusByteReadCheck=1'b0;
		end
	else
		begin
		if (ReadState==2'd3)
			begin
			if (StatusByteReg[5:4]==2'b01)
				ReadState=2'd2;
			else if (StatusByteReg[5:4]==2'b10)
				ReadState=2'd1;
			else if (StatusByteReg[5:4]==2'b11)
				ReadState=2'd0;
			end 

		if (ReadState==2'd0)
			begin
			DataOutput[7:0]=OLL[7:0];
			ReadState=2'd1;
			if(CountLatchCheck==0)
				SimpleRead=1;	//Pause Clk
			end
		else if (ReadState==2'd1)
			begin
			DataOutput[7:0]=OLM[7:0];
			ReadState=2'd3;
			CountLatchCheck=1'b0;
			SimpleRead=0;		//Cnt Clk
			end
		else if (ReadState==2'd2)
			begin
			DataOutput[7:0]=OLL[7:0];
			ReadState=2'd3;
			CountLatchCheck=1'b0;
			end
		end
end
////////////////////////////////////////////////////



/////Assigning Null Counter Flag//////////
//To 1 after putting value in CR
always @(posedge CRloaded)
begin
	CRNullControl = 1'b1;
	StatusByteReg[6]=1'b1;
	CRloaded = 1'b0;
end

//To 0 After putting value from CR to CE
always @(negedge CRNullControl)
begin
	StatusByteReg[6]=1'b0;
end
//////////////////////////////////////////
always @(out)
begin
	StatusByteReg[7] = out;
end

/***********************CE*********************************/

/////Mode: Initializing OUT and GATE////
always @(mode)
begin
	case(mode)
		mode0: 
			out = 1'b0;
		mode1: 
			begin
			out = 1'b1;
			gateTrigger='b0;
			end
		mode2:
			begin
			out=1'b1;
			//gateTrigger='b0;
			end
   		mode3:
			out=1'b1;

   		mode4: 
			out = 1'b1;
		mode5:
			begin
    			out = 1'b1;
    			gateTrigger=1'b0;
   			end

 	endcase
end
////////////////////////////////////////


////If initial value changed////////////
always @(negedge clk,CRNullControl)
begin
	if(CRNullControl==1)
		begin 
    		if(/*(State_Reg===mode11)||(State_Reg===mode12) ||*/ (State_Reg===mode21) || (State_Reg==mode30)||  (State_Reg==mode320)/*(State_Reg==mode31)|| (State_Reg==mode32)*/ /*|| (state_reg===m5_3) || (state_reg===m5_1)*/)
    			State_Reg <= State_Next;
		else	//For Mode 0 
			State_Reg = Start;
		
		end
	else
		State_Reg <= State_Next;
end
/////////////////////////////////////////



///////Putting gate wire to a reg to be used/////////
always @(posedge gate)
begin
	gateTrigger = 'b1;
end
//////////////////////////////////////////////////////


///////////Finite State Machine///////////////////////
always @(CEoutput,gateTrigger,State_Reg,mode,CRNullControl)
begin
	/*
	if (gateTrigger=='b1 && mode=='d1)	//Getting a trigger will reset counter
		begin
		State_Next=Start;
		end
	*/
/*
	else if (gateFlag==1'b1 && mode==3'd5)
		begin
		state_next=m5_1;
		count=CR;
		end
*/
	//else
		//begin
		case(State_Reg)
			Start:
				begin
				case(mode)
				mode0:
					State_Next = mode00;
				mode1:
					begin
					State_Next = mode10;
					end
				mode2:
					begin
					State_Next = mode20;
					//gateTrigger=0;
					end
	   			mode3:
					begin
					State_Next = mode30;
					gateTrigger=0;
					end
				mode4:
					State_Next = mode40;
				
				mode5: 
					begin
					State_Next = mode50;
					
					end

				endcase
				end

			/******************Mode 0*******************/
			mode00:
				if(mode==3'b000)
					State_Next = mode01;
   			mode01:
				if((mode==3'b000) && (CRNullControl==1'b1) && LoadFlag==1)	//Wants to put a value from CR to CE
					begin
					State_Next = mode00;
					LoadFlag = 0;
					end
				else if(CEoutput>'d0)
					State_Next = mode01;
				else
				State_Next = mode02;
   			mode02:
				if (mode=='b000 && CRNullControl==1'b1 && LoadFlag==1)
					State_Next=mode00;
				else 
					State_Next = mode02;	
			/********************************************/

			/*******************Mode 1*******************/
			mode10:
				if(mode=='d1 && (gateTrigger=='b1))
				begin
					//gateTrigger= 0;
					State_Next = mode11;
				end
				else if(mode=='d1 && (gateTrigger=='b0))
					State_Next = mode10;
			mode11:
				if((mode=='d1) && (gateTrigger==1'b1))
					State_Next = mode10;
				else  if(mode=='d1 && CEoutput>0/* && (gateTrigger==1'b0)*/)
       						State_Next = mode11;
				else
						State_Next = mode12;
			mode12:
				if(mode=='d1)
					State_Next = mode11;
			/********************************************/

			/*******************Mode 2*******************/
			mode20:
				begin
				/*if(mode==3'b010 && gate=='b1 && gateTrigger==1)
					begin
					State_Next=mode20;
					gateTrigger = 0;
					end
				else*/ 
				if((mode==3'b010) && (gate=='b1))
					State_Next=mode21;
				else if(mode==3'b010 && (gate=='b0))
					State_Next=mode20;
				//gateTrigger = 0;
				end
					
			mode21:
				if((mode==3'b010) && (gate=='b1) && gateTrigger==1 /*&& LoadFlag==1*/)
					State_Next=mode20;	
				else if((mode==3'b010) && (gate=='b1) && (CEoutput >16'd2))
					State_Next=mode21;
				else if ((mode==3'b010) && (gate=='b1) && (CEoutput  == 16'd2))
					State_Next=mode22;
				/*else if ((mode==3'b010) && (gate=='b0))
					State_Next=mode21; //mode21*/
			mode22:
				if((mode==3'b010) && (gate=='b1))
					State_Next=mode20; 
				else if((mode==3'b010) && (gate=='b0))
					State_Next=mode22;
			/********************************************/

			/*******************Mode 3*******************/
			//Mode 3 states
			mode30:
				begin
				gateTrigger = 'b0;
				if (mode==3'b011 && gate==1'b1)
					State_Next=mode31;
				else if(mode==3'b011 && gate==0)
					State_Next=mode30;
				end
			mode31:
				begin
				if(mode=='b011 && gateTrigger==1'b1 && CEoutput  == LimitValue && gate == 1 && CRNullControl==1)		//time to restart cuz initial changed
					State_Next=Start;
				else if((mode==3'b011) && (gate==1'b1) && (CEoutput > LimitValue))	//Continue counting here
					State_Next=mode31;
				else if ((mode==3'b011) && (gate==1'b1) && (CEoutput  == LimitValue))	//Time for -ve edge
					begin
					State_Next=mode320;
					//CEoutput = {CRM,CRL};
					end
				else if ((mode==3'b011) && (gate==1'b0))				//Pause State
					State_Next=mode31;
				end
			mode320:
				begin
				gateTrigger = 'b0;
				if (mode==3'b011 && gate==1'b1)
					State_Next=mode32;
				else if(mode==3'b011 && gate==0)
					State_Next=mode320;
				end
   			mode32:
				begin
				if(mode=='b011 && gateTrigger==1 && CEoutput  == 2 && gate==1 && CRNullControl==1)		//time to restart cuz initial value changed
					State_Next=Start;
				else if((mode==3'b011) && (gate==1'b1) && (CEoutput > 2))		//Continue Countomg
					State_Next=mode32;
				else if ((mode==3'b011) && (gate==1'b1) && (CEoutput  == 2))		//Time for +ve edge
					begin
					State_Next=mode30;
					end
				else if ((mode==3'b011) && (gate==1'b0))				//Pause State
					State_Next=mode32;
				end
			/********************************************/


			/******************Mode 4*******************/
			mode40://Mode 4 states
				if(mode==3'b100 && CEoutput>0 && CRNullControl==1'b0)
					State_Next = mode41;
			mode41:
				if((mode==3'b100) && (CRNullControl==1'b1))
					State_Next = Start;
				else if(CEoutput>16'd1)
					State_Next = mode41;
     				else
		       			State_Next = mode42;   
   			mode42:
				if(mode==3'b100)
					State_Next = mode41;	
			/********************************************/

			/******************Mode 5*******************/
			mode50:
				
				if((mode==3'b101) && (gateTrigger==1'b1))
					begin
					State_Next = mode51;
					//gateTrigger= 1'b0;
					end
				else if((mode==3'b101) && (gateTrigger==1'b0))
					State_Next = mode50;
				
			mode51:
				if((mode==3'b101) && (gateTrigger==1'b1))
					begin	
					State_Next = mode50;
					//ygateTrigger= 1'b0;
					end
				else if(CEoutput>1)
					State_Next = mode51;
				else
					State_Next = mode52;
			mode52:
				if(mode==3'b101)
					State_Next = mode51;
			/********************************************/
/*
			m4_0://Mode 4 states
				if(mode==3'b100)
					state_next = m4_1;
			m4_1:
				if((mode==3'b100) && (CRFlag==1'b1))
					state_next = initialization;
				else if(count>16'd0)
					state_next = m4_1;
     				else
		       			state_next = m4_2;   
   			m4_2:
				if(mode==3'b100)
					state_next = m4_3;
			m4_3:
				if(mode==3'b100)
					if(CRFlag==1'b0)
						state_next = m4_3;
					else
						state_next = initialization;

			//Mode 5 states
   			m5_0:
				if((mode==3'b101) && (gateFlag==1'b1))
					state_next = m5_1;
				else
					state_next = m5_0;
			m5_1:
				if((mode==3'b101) && (gateFlag==1'b1))
					state_next = m5_0;
				else if(count>0)
					state_next = m5_1;
				else
					state_next = m5_2;
			m5_2:
				if(mode==3'b101)
					state_next = m5_3;
			m5_3:
				if(mode==3'b101)
					if(gateFlag==1'b1)
						state_next = m5_0;
					else
						state_next = m5_3;
/*			
*/
			default: ;
		endcase
		//end
end
///////////////////////////////////////////////////////////////




//////Changing Count + OUT. (Moore's way)///////////////////////////////
always @(State_Reg,negedge clk)
begin
	case(State_Reg)
		Start:
			begin
			case(mode)
				mode0:
					begin
					out=1'b0;
					CRNullControl = 'b0;
					end
      				mode1: 
					begin
					CRNullControl = 'b0;
					out = 1'b1;
					end

				mode2: 
					begin
					out=1'b1;
					CRNullControl = 1'b0;
      					end
				mode3:
					begin
					out=1'b1;
					CR = {CRM,CRL};
					CRNullControl = 1'b0;
	
					if(CRL[0]==1)		//odd
						LimitValue = 0;
					else if(CRL[0]==0)	//even
						LimitValue = 2;
					end
				mode4:
					begin
       						out=1'b1;
       						CRNullControl = 1'b0;
      					end
				mode5:
					begin
						out=1'b1;
						CRNullControl = 1'b0;
					end
/*
						if(StatusByteReg[0]==1'b0)			//binary
							LimitValue=((CR-1)>>>1)+1;
						else						//BCD
							LimitValue=(((CR[15:12]*1000+CR[11:8]*100+CR[7:4]*10+CR[3:0])-1)>>>1)+1;
					else
						if(StatusByteReg[0]==1'b0)			
							LimitValue=((CR)>>>1)+1;
						else
							LimitValue=((CR[15:12]*1000+CR[11:8]*100+CR[7:4]*10+CR[3:0])>>>1)+1;
*/
					//end
	
/*
					m4:
					begin
       					out=1'b1;
       						CRFlag = 1'b0;
      					end
					m5:
					begin
						out=1'b1;
						CRFlag = 1'b0;
					end
*/
				default: ;
			endcase
		end
		
		/**************Mode0************************************/ 
		mode00:
			begin
			CEoutput = {CRM,CRL};
    			out = 1'b0;
			end
		mode01:
			begin
			//out=1'b0;
			if(gate)
				begin
				if(StatusByteReg[0]==1'b0)	//Binary Count
					CEoutput = CEoutput-1;

				else if(StatusByteReg[0]==1'b1)
					begin			//BCD
					if(CEoutput[3:0]>'h0)
						CEoutput[3:0]=CEoutput[3:0]-1;

					else if (CEoutput[3:0]=='h0 && CEoutput[7:4]>4'h0)
						begin
						CEoutput[3:0]='h9;
						CEoutput[7:4]=CEoutput[7:4]-1;
						end

					else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]>4'h0)
						begin
						CEoutput[3:0]='h9;
						CEoutput[7:4]=4'h9;
						CEoutput[11:8]=CEoutput[11:8]-1;
						end

					else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]==4'h0 && CEoutput[15:12]>'h0)
						begin
						CEoutput[3:0]='h9;
						CEoutput[7:4]=4'h9;
						CEoutput[11:8]=4'h9;
						CEoutput[15:12]=CEoutput[15:12]-1;
						end
					else if(CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]==4'h0 && CEoutput[15:12]==0)
						CEoutput = 'h9999;
					end
				end
			end
		mode02:
			out = 1'b1;
		/*******************************************************/

		/**************Mode1************************************/ 
		mode10:
			begin
			CEoutput = {CRM,CRL};
			out = 1'b1;
			end
  		mode11:
			begin
			//gateTrigger= 0;
   			out=1'b0;
			//////////counting///////////////////////////////////////
			if(StatusByteReg[0]==1'b0 /*&& CEoutput>0*/)	//Binary Count
				CEoutput = CEoutput-1;
			/*else if(StatusByteReg[0]==1'b0 && CEoutput==0)
				CEoutput = 'hFFFF;*/

			else if (StatusByteReg[0]==1'b0)
				begin			//BCD
				if(CEoutput[3:0]>'h0)
					CEoutput[3:0]=CEoutput[3:0]-1;

					else if (CEoutput[3:0]=='h0 && CEoutput[7:4]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=CEoutput[7:4]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=CEoutput[11:8]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]==4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=4'h9;
					CEoutput[15:12]=CEoutput[15:12]-1;
					end

				else if (CEoutput[15:0]=='h0)
					begin
					CEoutput[15:0]='d9999;
					end
				end
			///////////////////////////////////////////////////////////
			gateTrigger = 'b0;
			end
		mode12:
			begin
			//////////counting///////////////////////////////////////
			/*
			if(StatusByteReg[0]==1'b0 && out== 0)	//Binary Count
				CEoutput = 'hFFFF;
			else if (StatusByteReg[0]==1'b0 && out== 1)
				CEoutput = CEoutput-1;
			*

			/*else if(StatusByteReg[0]==1'b0 && CEoutput==0)
				CEoutput = 'hFFFF;*/

			/*
			else if(StatusByteReg[0]==1'b1)
				begin			//BCD
				if(CEoutput[3:0]>'h0)
					CEoutput[3:0]=CEoutput[3:0]-1;

					else if (CEoutput[3:0]=='h0 && CEoutput[7:4]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=CEoutput[7:4]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=CEoutput[11:8]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]==4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=4'h9;
					CEoutput[15:12]=CEoutput[15:12]-1;
					end

				else if (CEoutput[15:0]=='h0)
					begin
					CEoutput[15:0]='h9999;
					end
				end
			///////////////////////////////////////////////////////////
			*/
			out = 1'b1;
			end
		/*******************************************************


		/**************Mode2************************************/ 
		mode20:
		begin
			//if(LoadFlag == 1)
				//begin
				CEoutput = {CRM,CRL};
				//LoadFlag = 0;
				//end
			out=1'b1; 
		end
		mode21:
			begin
			out=1'b1; 
    			if(gate)
				begin
				if(StatusByteReg[0]==1'b0)
					CEoutput = CEoutput-1;
				else
					begin
					if(CEoutput[3:0]>4'h0)
						CEoutput[3:0]=CEoutput[3:0]-1;
					else
						begin
						CEoutput[3:0]=4'h9;
						if(CEoutput[7:4]>4'h0)
							CEoutput[7:4]=CEoutput[7:4]-1;
						else
							begin
							CEoutput[7:4]=4'h9;
							if(CEoutput[11:8]>4'h0)
								CEoutput[11:8]=CEoutput[11:8]-1;
							else
								begin
								CEoutput[11:8]=4'h9;
								CEoutput[15:12]=CEoutput[15:12]-1;
								end
							end
						end
					end
				end
			gateTrigger=0;
			end
		mode22:
			begin
				out=1'b0;
			end
		/*******************************************************/


		/**************Mode3************************************/ 
		mode30:
			begin
			if(CRL[0]==1)   //odd
				CEoutput = {CRM,CRL}-1;
			else		//even
				CEoutput = {CRM,CRL};
			out=1'b1; 
  			end
		mode31:
			begin
   			out=1'b1;
			if(gate==1 && (CEoutput  > LimitValue))
				begin
				if(StatusByteReg[0]==1'b0)		//binary
					CEoutput = CEoutput-2;
				else					//BCD
					begin
					if(CEoutput[3:0]>4'h0)
						CEoutput[3:0]=CEoutput[3:0]-1;
					else
						begin
						////// - 1 BCD  ////////////
						CEoutput[3:0]=4'h9;
						if(CEoutput[7:4]>4'h0)
							CEoutput[7:4]=CEoutput[7:4]-1;
						else
							begin
							CEoutput[7:4]=4'h9;
							if(CEoutput[11:8]>4'h0)
								CEoutput[11:8]=CEoutput[11:8]-1;
							else
								begin
								CEoutput[11:8]=4'h9;
								CEoutput[15:12]=CEoutput[15:12]-1;
								end
							end
						////////////////////////////////////

						////// - 1 BCD  ////////////
						CEoutput[3:0]=4'h9;
						if(CEoutput[7:4]>4'h0)
							CEoutput[7:4]=CEoutput[7:4]-1;
						else
							begin
							CEoutput[7:4]=4'h9;
							if(CEoutput[11:8]>4'h0)
								CEoutput[11:8]=CEoutput[11:8]-1;
							else
								begin
								CEoutput[11:8]=4'h9;
								CEoutput[15:12]=CEoutput[15:12]-1;
								end
							end
						////////////////////////////////////
						end
					end
				end
			end
		mode320:
			begin
			if(CRL[0]==1)   //odd
				CEoutput = {CRM,CRL}-1;
			else		//even
				CEoutput = {CRM,CRL};
			out=1'b0; 
  			end
		mode32:
			begin
   			out=1'b0;
			if(gate==1 && (CEoutput  > 2))
				begin
				if(StatusByteReg[0]==1'b0)		//binary
					CEoutput = CEoutput-2;
				else					//BCD
					begin
					if(CEoutput[3:0]>4'h0)
						CEoutput[3:0]=CEoutput[3:0]-1;
					else
						begin
						////// - 1 BCD  ////////////
						CEoutput[3:0]=4'h9;
						if(CEoutput[7:4]>4'h0)
							CEoutput[7:4]=CEoutput[7:4]-1;
						else
							begin
							CEoutput[7:4]=4'h9;
							if(CEoutput[11:8]>4'h0)
								CEoutput[11:8]=CEoutput[11:8]-1;
							else
								begin
								CEoutput[11:8]=4'h9;
								CEoutput[15:12]=CEoutput[15:12]-1;
								end
							end
						////////////////////////////////////

						////// - 1 BCD  ////////////
						CEoutput[3:0]=4'h9;
						if(CEoutput[7:4]>4'h0)
							CEoutput[7:4]=CEoutput[7:4]-1;
						else
							begin
							CEoutput[7:4]=4'h9;
							if(CEoutput[11:8]>4'h0)
								CEoutput[11:8]=CEoutput[11:8]-1;
							else
								begin
								CEoutput[11:8]=4'h9;
								CEoutput[15:12]=CEoutput[15:12]-1;
								end
							end
						////////////////////////////////////
						end
					end
				end
			end
			
		/*******************************************************/


		/**************Mode4************************************/
		mode40:
			begin		
			CEoutput = {CRM,CRL};
			out = 1'b1;
			end
		mode41:
			begin
			out=1'b1;
			if(gate)
			begin
				if(StatusByteReg[0]==1'b0)
					CEoutput = CEoutput-1;
				else if(StatusByteReg[0]==1'b1)
				begin			//BCD
				if(CEoutput[3:0]>'h0)
					CEoutput[3:0]=CEoutput[3:0]-1;

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=CEoutput[7:4]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=CEoutput[11:8]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]==4'h0 && CEoutput[15:12]>'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=4'h9;
					CEoutput[15:12]=CEoutput[15:12]-1;
					end

				else if (CEoutput[15:0]=='h0)
					begin
					CEoutput[15:0]=16'h9999;
					end
				
				end	
			end
			end
		mode42:
			out = 1'b0;
		//mode43:
		//	out = 1'b1;
		/*******************************************************/


		/**************Mode5************************************/
		mode50:
			begin
			CEoutput = {CRM,CRL};
			out = 1'b1;
			end
		mode51:
			begin
				
				out = 1'b1;
				if(StatusByteReg[0]==1'b0)
					CEoutput = CEoutput-1;
				else if(StatusByteReg[0]==1'b1)
				begin			//BCD
				if(CEoutput[3:0]>'h0)
					CEoutput[3:0]=CEoutput[3:0]-1;

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=CEoutput[7:4]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]>4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=CEoutput[11:8]-1;
					end

				else if (CEoutput[3:0]=='h0 && CEoutput[7:4]==4'h0 && CEoutput[11:8]==4'h0)
					begin
					CEoutput[3:0]='h9;
					CEoutput[7:4]=4'h9;
					CEoutput[11:8]=4'h9;
					CEoutput[15:12]=CEoutput[15:12]-1;
					end

				else if (CEoutput[15:0]=='h0)
					begin
					CEoutput[15:0]=16'h9999;
					end
				
				end	
				gateTrigger = 'b0;
			end	
		mode52:
			out = 1'b0;
		//mode53:
		//	out = 1'b1;
		/*******************************************************/
/*

		//Mode 4
		m4_0:
			begin
			count = CR;
			out = 1'b1;
			end
		m4_1:
			begin
			out=1'b1;
			if(gate)
				begin
				if(statusLatch2[0]==1'b0)
					count = count-1;
				else
					begin
					if(count[3:0]>4'h0)
						count[3:0]=count[3:0]-1;
					else
						begin
						count[3:0]=4'h9;
						if(count[7:4]>4'h0)
							count[7:4]=count[7:4]-1;
						else
							begin
							count[7:4]=4'h9;
							if(count[11:8]>4'h0)
								count[11:8]=count[11:8]-1;
							else
								begin
								count[11:8]=4'h9;
								count[15:12]=count[15:12]-1;
								end
							end
						end
					end
				end
			end
		m4_2:
			out = 1'b0; 
		m4_3: 
			out = 1'b1;
		//Mode 5
		m5_0:
			begin
			count = CR;
			out = 1'b1;
			end
		m5_1:
			begin
			gateFlag = 1'b0;
			out = 1'b1;
			begin
				if(statusLatch2[0]==1'b0)
					count = count-1;
				else
					begin
					if(count[3:0]>4'h0)
						count[3:0]=count[3:0]-1;
					else
						begin
						count[3:0]=4'h9;
						if(count[7:4]>4'h0)
							count[7:4]=count[7:4]-1;
						else
							begin
							count[7:4]=4'h9;
							if(count[11:8]>4'h0)
								count[11:8]=count[11:8]-1;
							else
								begin
								count[11:8]=4'h9;
								count[15:12]=count[15:12]-1;
								end
							end
						end
					end
				end
			end
		m5_2:
			out = 1'b0;
		m5_3:
			out = 1'b1;
*/
		
	/*	
*/
		endcase
	end
//////////////////////////////////////////////////////////////////////////////////


endmodule

