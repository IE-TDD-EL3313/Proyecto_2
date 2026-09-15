// Forma los 12 caracteres que se incluyen en los mensajes hacia la PC.
module formador_patron_ascii (
    input  logic [59:0] palabra_codificada_i,
    input  logic [11:0] palabra_revelada_i,
    input  logic [3:0]  longitud_i,
    output logic [95:0] patron_ascii_o
);
    logic [4:0] codigo;

    always_comb begin
        patron_ascii_o = '0;
        for (int i = 0; i < 12; i++) begin
            codigo = palabra_codificada_i[(i*5) +: 5];
            if (i >= longitud_i)
                patron_ascii_o[(i*8) +: 8] = " ";
            else if (!palabra_revelada_i[i])
                patron_ascii_o[(i*8) +: 8] = "_";
            else if (codigo >= 5'd1 && codigo <= 5'd26)
                patron_ascii_o[(i*8) +: 8] = 8'd64 + {3'b000, codigo};
            else
                patron_ascii_o[(i*8) +: 8] = "?";
        end
    end
endmodule
