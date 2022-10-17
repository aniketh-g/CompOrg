module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);
    
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [31:0] iaddr_new;
    reg [31:0] reg_write;
    reg [3:0]  dwe;
    reg jump;    
    reg rf_we;

    wire[6:0] opcode;
    wire[4:0] rd;
    wire[2:0] funct3;
    wire[4:0] rs1;
    wire[4:0] rs2;
    wire[6:0] funct7;
    wire[11:0] imm;
    wire[11:0] offset_load;
    wire[11:0] offset_store;

    assign opcode = idata[6:0];
    assign rd = idata[11:7];
    assign funct3 = idata[14:12];
    assign rs1 = idata[19:15];
    assign rs2 = idata[24:20];
    assign funct7 = idata[31:25];
    assign imm = idata[31:20];
    assign offset_load = idata[31:20];
    assign offset_store = {idata[31:25], idata[11:7]};

    wire [31:0] rv1;
    wire [31:0] rv2;
    wire [31:0] alu_out;

    initial begin
        dwe = 4'b0000;
        jump = 1'b0;
        rf_we = 1;
    end

    register_file RF(.clk(clk), .reset(reset), .reg1_address(rs1), .reg2_address(rs2), .write_enable(rf_we), .write_address(rd), .write_data(reg_write), .reg1_data(rv1), .reg2_data(rv2));
    alu A(.funct7(funct7), .funct3(funct3), .imm(imm), .rv1(rv1), .rv2(rv2), .opcode(opcode), .shamt(rs2), .valout(alu_out));
    //dmem D(.clk(clk), .daddr(daddr), .dwdata(dwdata), .dwe(dwe), .drdata(drdata));

    always @(*) begin
        if(opcode != 7'b0100011) dwe = 4'b0000;
        if((opcode != 7'b1100011) && (opcode != 7'b1101111) && (opcode != 7'b1100111)) jump = 1'b0;
        if((opcode != 7'b1100011) && (opcode != 7'b0100011)) rf_we = 1;
        case (opcode)
            7'b1100011: // BRANCH
                begin
                    rf_we = 0;
                    case(funct3)
                        3'b000 : begin //BEQ
                            if(rv1 == rv2) begin
                                jump = 1'b1;
                                iaddr_new = iaddr + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0 };    
                            end
                        end
                        3'b001 : begin //BNE
                            if(rv1 != rv2) begin
                                jump = 1'b1;
                                iaddr_new = iaddr + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0 };    
                            end
                        end
                        3'b100 : begin // BLT
                            if(rv1 < $signed(rv2)) begin
                                jump = 1'b1;
                                iaddr_new = iaddr + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0 };    
                            end
                        end
                        3'b101 : begin //BGE
                            if(rv1 >= $signed(rv2)) begin
                                jump = 1'b1;
                                iaddr_new = iaddr + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0 };    
                            end
                        end
                        3'b110 : begin //BLTU
                            if(rv1 < rv2) begin
                                jump = 1'b1;
                                iaddr_new = iaddr + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0 };    
                            end
                        end
                        3'b111 : begin //BGEU
                            if(rv1 >= rv2) begin
                                jump = 1'b1;
                                iaddr_new = iaddr + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0 };    
                            end
                        end
                    endcase
                end            
            7'b1101111: //JAL
                begin
                    reg_write = iaddr + 3'b100;
                    jump = 1'b1;
                    iaddr_new = iaddr + {{12{idata[31]}}, idata[19:12], idata[20], idata[30:21], 1'b0};
                end

			

            7'b1100111: //JALR
                begin
                    reg_write = iaddr + 3'b100;
                    jump = 1'b1;
                    iaddr_new = (rv1 + { {20{imm[11]}},imm}) & (~32'b1);
                end




            7'b0110111: reg_write = {idata[31:12], {12'd0}}; //LUI
            7'b0010111: reg_write = {idata[31:12], {12'd0}} + iaddr; //AUIPC
            7'b0010011: reg_write = alu_out;
            7'b0110011: reg_write = alu_out;
            7'b0000011: //LOAD
                begin
                    //daddr = {{20{offset_load[11]}}, offset_load} + {{27{1'b0}}, rs1};
                    daddr = {{20{offset_load[11]}}, offset_load} + rv1;
                    //$display("LOAD idata = %31b \t drdata = %31b", idata, drdata);
                    case (funct3)
                        3'b000: //LB
                            begin
                                if     (daddr%4 == 0) reg_write = {{24{drdata[ 7]}}, drdata[ 7: 0]};
                                else if(daddr%4 == 1) reg_write = {{24{drdata[15]}}, drdata[15: 8]};
                                else if(daddr%4 == 2) reg_write = {{24{drdata[23]}}, drdata[23:16]};
                                else if(daddr%4 == 3) reg_write = {{24{drdata[31]}}, drdata[31:24]};
                            end
                        3'b001: //LH
                            begin
                                if     (daddr%4 == 0) reg_write = {{16{drdata[15]}}, drdata[15: 0]};
                                else if(daddr%4 == 2) reg_write = {{16{drdata[31]}}, drdata[31:16]};
                            end
                        3'b010: //LW
                            begin
                                reg_write = drdata;
                            end
                        3'b100: //LBU
                            begin
                                if     (daddr%4 == 0) reg_write = {{24{1'b0}}, drdata[ 7: 0]};
                                else if(daddr%4 == 1) reg_write = {{24{1'b0}}, drdata[15: 8]};
                                else if(daddr%4 == 2) reg_write = {{24{1'b0}}, drdata[23:16]};
                                else if(daddr%4 == 3) reg_write = {{24{1'b0}}, drdata[31:24]};
                            end
                        3'b101: //LHU
                            begin
                                if     (daddr%4 == 0) reg_write = {{16{1'b0}}, drdata[15: 0]};
                                else if(daddr%4 == 2) reg_write = {{16{1'b0}}, drdata[31:16]};
                            end
                    endcase
                end
            7'b0100011: //STORE                
                begin
                    rf_we = 0;
                    //daddr = {{20{offset_store[11]}}, offset_store} + {{27{1'b0}}, rs1};
                    daddr = {{20{offset_store[11]}}, offset_store} + rv1;
                    case (funct3)
                        3'b000: //SB
                            begin
                                if     (daddr%4 == 0) begin
                                    dwe = 4'b0001;
                                    dwdata = {{24{1'b0}}, rv2[7:0]};
                                end
                                else if(daddr%4 == 1) begin
                                    dwe = 4'b0010;
                                    dwdata = {{16{1'b0}}, rv2[7:0], {8{1'b0}}};
                                end
                                else if(daddr%4 == 2) begin
                                    dwe = 4'b0100;
                                    dwdata = {{ 8{1'b0}}, rv2[7:0], {16{1'b0}}};
                                end
                                else if(daddr%4 == 3) begin
                                    dwe = 4'b1000;
                                    dwdata = {rv2[7:0], {24{1'b0}}};
                                end
                            end
                        3'b001: //SH
                            begin
                                if     (daddr%4 == 0) begin
                                    dwe = 4'b0011;
                                    dwdata = {{16{1'b0}}, rv2[15:0]};
                                end
                                else if(daddr%4 == 2) begin
                                    dwe = 4'b1100;
                                    dwdata = {rv2[15:0], {16{1'b0}}};
                                end
                            end
                        3'b010: //SW
                            begin
                                dwe = 4'b1111;
                                dwdata = rv2;
                            end
                    endcase
                end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            iaddr <= 0;
            daddr <= 0;
            dwdata <= 0;
            dwe <= 0;
            jump <= 0;
            iaddr_new <= 0;
        end else begin 
            if(jump == 0) iaddr <= iaddr + 4;
            else begin //For jump instructions
                iaddr <= iaddr_new;
                jump <= 1'b0; 
            end 
        end
    end

endmodule