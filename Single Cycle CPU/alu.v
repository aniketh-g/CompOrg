module alu(
    input [6:0] funct7,
    input [2:0] funct3,
    input [11:0] imm,
    input [31:0] rv1,
    input [31:0] rv2,
    input [6:0] opcode,
    input [4:0] shamt,

    output [31:0] valout
);

    wire [31:0] imm_ext = {{20{imm[11]}}, imm}; //sign extension
    reg [31:0] valout;

    wire [31:0] slti_check; assign slti_check = rv1 - imm_ext; //for SLTI
    wire [31:0] slt_check; assign slt_check = rv1 - rv2; //for SLT

    /*integer shamt_int;
    always @(shamt) begin
        shamt_int = shamt;
    end
    integer rv2_int;
    always @(rv2) begin
        rv2_int = rv2;
    end*/

    always @(*) begin
        case (opcode)
            7'b0010011: //I-type
                begin
                    case (funct3)
                        3'b000: valout = imm_ext + rv1; //ADDI
                        3'b010: valout = slti_check[31] == 1 ? 32'd1 : 32'd0; //SLTI
                        3'b011: valout = (rv1 < imm_ext) ? 32'd1 : 32'd0; //SLTIU
                        3'b100: valout = rv1 ^ imm_ext; //XORI
                        3'b110: valout = rv1 | imm_ext; //ORI
                        3'b111: valout = rv1 & imm_ext; //ANDI
                        3'b001: valout = rv1 << shamt; //SLLI
                        3'b101:
                            begin
                                case (funct7)
                                    7'b0000000: valout = rv1 >> shamt; //SRLI                                
                                    7'b0100000: valout = rv1 >>> shamt; //SRAI
                                endcase 
                            end
                    endcase
                end
            7'b0110011: //R-type
                begin
                    case (funct3)
                        3'b000:
                            case (funct7)
                                7'b0000000: valout = rv1 + rv2; //ADD
                                7'b0100000: valout = rv1 - rv2; //SUB
                            endcase
                        3'b001: valout = rv1 << rv2[4:0]; //SLL
                        3'b010: valout = slt_check[31] == 1 ? 32'd1 : 32'd0; //SLT
                        3'b011: valout = rv1 < rv2 ? 32'd1 : 32'd0; //SLTU
                        3'b100: valout = rv1 ^ rv2; //XOR
                        3'b101:
                            case (funct7)
                                7'b0000000: valout = rv1 >> rv2[4:0]; //SRL
                                7'b0100000: valout = rv1 >>> rv2[4:0]; //SRA
                            endcase
                        3'b110: valout = rv1 | rv2; //OR
                        3'b111: valout = rv1 & rv2; //AND
                    endcase
                end
        endcase
    end
endmodule