/////////////////////////////////////////////////////////
// MC14500B based softcore
// Created for research and archival purposes based on
// the 1977 Motorola specifications.
// I don't know copyright law but the patent expired
// so leave me alone I guess.
//
// Note that the efficiency and the beauty of the original
// implementation puts mine to shame, I don't do them
// justice. Check out Ken Shirrif's explaination or
// the patent.
//
// Elias Augusto, 2021
// References:
// (Links provided on github)
// - Manual - "MC14500B Industrial Control Unit Handbook"
// - Listing - "Industrial Control Unit MC14500B"
// - Patent - US4153942
// - RE Info - Ken Shirriff's blog
//
// Note: I didn't look into them much, but the folks at
// Linrus apparently did an FPGA implementation. It looks
// block based rather than verilog based, which is very
// smart in terms of hand-optimization and accuracy
// to the original.
//
/////////////////////////////////////////////////////////

module mc14500b(
    //Clock stuff
    input wire clk_in,
    input wire rst,
    output wire clk_out,

    //Instruction bits
    input wire [3:0] I,

    //Nop flags
    output reg FLGO, //NOP O
    output reg FLGF, //NOP F

    //Org flags
    output reg RTN, //Return flag
    output reg JMP, //Jump flag

    //Data I/O
    inout wire data,
    output reg RR, //result
    output reg write, //write pulse, basically a fancy write enable

    //Debug signal
    //Just exposes machine state
    output wire state_out,
    output wire SKP
  );

  //Note: The manual expects an operation frequency of around 1mhz
  //The silicon then was not what it is now.

  assign clk_out=clk_in;

  //Instruction codes
  parameter NOPO_INST=4'b0000;
  parameter LD_INST=4'b0001;
  parameter LDC_INST=4'b0010;
  parameter AND_INST=4'b0011;
  parameter ANDC_INST=4'b0100;
  parameter OR_INST=4'b0101;
  parameter ORC_INST=4'b0110;
  parameter XNOR_INST=4'b0111;
  parameter STO_INST=4'b1000;
  parameter STOC_INST=4'b1001;
  parameter IEN_INST=4'b1010;
  parameter OEN_INST=4'b1011;
  parameter JMP_INST=4'b1100;
  parameter RTN_INST=4'b1101;
  parameter SKZ_INST=4'b1110;
  parameter NOPF_INST=4'b1111;

  //Internal registers
  reg [3:0] INST_REG=NOPO_INST;
  reg skip; //Our instruction skipping tool, standin for SKP internal
  assign SKP=skip;
  wire comp_data; //Complement checker
  reg IEN; //Input enable
  reg OEN; //Output enable
  wire ien_data; //Our input enable checker
  reg data_reg;
  assign data=write? data_reg: 1'bz;
  assign ien_data=data&IEN;
  assign comp_data=(INST_REG==LDC_INST
                  || INST_REG==ANDC_INST
                  || INST_REG==ORC_INST
                  || INST_REG==STOC_INST
  )? ~ien_data : ien_data;
  //States
  parameter FETCH=1'b0;
  parameter DECODE_EXECUTE=1'b1;
  reg state=1'b0;
  assign state_out=state;

  always@(posedge clk_in or negedge rst) begin
    //I made my reset asynchronous because it appears
    //that was the designer's intent.
    if(~rst) begin
      data_reg<=1'b0;
      FLGO<=1'b0;
      FLGF=1'b0;
      RTN<=1'b0;
      JMP<=1'b0;
      write<=1'b0;
      RR<=1'b0;
      state<=FETCH;
      INST_REG<=4'b0000;
      skip<=1'b0;
      IEN<=1'b1;
      OEN<=1'b1;
    end
    else if(skip) begin
      case(state)
        FETCH: begin
          JMP<=1'b0;
          write<=1'b0;
          FLGO<=1'b0;
          FLGF=1'b0;
          state<=DECODE_EXECUTE;
        end
        DECODE_EXECUTE: begin
          skip<=1'b0;
          RTN<=1'b0; //More strictly matches requirements of signals
          state<=FETCH;
        end
      endcase
    end
    else begin
      case(state)
        FETCH: begin
          JMP<=1'b0;
          write<=1'b0;
          INST_REG<=I;
          FLGO<=1'b0;
          FLGF=1'b0;
          RTN<=1'b0;
          state<=DECODE_EXECUTE;
        end
        DECODE_EXECUTE: begin
          //Operations
          if( INST_REG==NOPO_INST) begin
            FLGO<=1'b1;
            RR<=RR;
          end
          else if( INST_REG==LD_INST || INST_REG==LDC_INST) begin
            RR<=comp_data;
          end
          else if( INST_REG==AND_INST || INST_REG==ANDC_INST) begin
            RR<=comp_data&RR;
          end
          else if( INST_REG==OR_INST || INST_REG==ORC_INST) begin
            RR<=comp_data|RR;
          end
          else if( INST_REG==XNOR_INST) begin
            RR<=~(comp_data^RR);
          end
          else if( INST_REG==XNOR_INST) begin
            RR<=~(comp_data^RR);
          end
          else if( INST_REG==STO_INST || INST_REG==STOC_INST) begin
            data_reg<=RR;
            write<=OEN;
          end
          else if(INST_REG==STOC_INST) begin
            data_reg<=~RR;
            write<=OEN;
          end
          else if( INST_REG==IEN_INST) begin
            IEN<=data;
          end
          else if( INST_REG==OEN_INST) begin
            OEN<=data;
          end
          else if( INST_REG==JMP_INST) begin
            JMP<=1'b1;
          end
          else if( INST_REG==RTN_INST) begin
            RTN<=1'b1;
            skip<=1'b1;
          end
          else if( INST_REG==SKZ_INST) begin
            if(RR==0) skip<=1'b1;
          end
          else if( INST_REG==NOPF_INST) begin
            FLGF<=1'b1;
            RR<=RR;
          end
          state<=FETCH;
        end
      endcase
    end
  end

endmodule

