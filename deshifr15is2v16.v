//из двочики в 16ричку на семисегментный индикатор
module deshifr15is2v16 ( 
input [3:0] binary_in,
output reg [6:0] decoder_out
);
always @ (*)
begin
decoder_out = 0;
case (binary_in)
4'b0000 : decoder_out = ~7'b0111111;
4'b0001 : decoder_out = ~7'b0000110;
4'b0010 : decoder_out = ~7'b1011011;
4'b0011 : decoder_out = ~7'b1001111;
4'b0100 : decoder_out = ~7'b1100110;
4'b0101 : decoder_out = ~7'b1101101;
4'b0110 : decoder_out = ~7'b1111101;
4'b0111 : decoder_out = ~7'b0000111;
4'b1000 : decoder_out = ~7'b1111111;
4'b1001 : decoder_out = ~7'b1101111;
4'b1010 : decoder_out = ~7'b1110111;
4'b1011 : decoder_out = ~7'b1111100;
4'b1100 : decoder_out = ~7'b0111001;
4'b1101 : decoder_out = ~7'b1011110;
4'b1110 : decoder_out = ~7'b1111011;
4'b1111 : decoder_out = ~7'b1110001;
endcase
end
endmodule
