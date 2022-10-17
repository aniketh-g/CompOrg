module register_file(
    input clk,
    input reset,

    input [4:0] reg1_address,
    input [4:0] reg2_address,

    input write_enable,
    input [4:0] write_address,
    input [31:0] write_data,

    output [31:0] reg1_data,
    output [31:0] reg2_data
);
    reg[31:0] registers[31:0];

    assign reg1_data = registers[reg1_address];
    assign reg2_data = registers[reg2_address];
    
    integer i;

    initial begin
        for (i = 0; i < 32 ; i++) begin
            registers[i] = 32'd0;
        end
    end

    always @(posedge clk ) begin
        if (reset) begin
            for (i = 0; i < 32 ; i++) begin
                registers[i] <= 32'd0;
            end
        end
        else begin
            if(write_enable && write_address != 32'd0) begin
                registers[write_address] <= write_data;
            end
        end
    end
    
endmodule