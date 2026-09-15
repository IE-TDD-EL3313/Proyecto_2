`timescale 1ns/1ps

module tb_formador_patron_ascii;
    logic [59:0] palabra_codificada_i = '0;
    logic [11:0] palabra_revelada_i = '0;
    logic [3:0] longitud_i = 4;
    logic [95:0] patron_ascii_o;
    int pruebas = 0;

    formador_patron_ascii dut (.*);

    task automatic comprobar(input logic condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            $error("FALLO: %s", mensaje);
            $finish;
        end
    endtask

    initial begin
        palabra_codificada_i[0  +: 5] = 5'd1;  // A
        palabra_codificada_i[5  +: 5] = 5'd13; // M
        palabra_codificada_i[10 +: 5] = 5'd15; // O
        palabra_codificada_i[15 +: 5] = 5'd18; // R
        #1;

        for (int i = 0; i < 4; i++)
            comprobar(patron_ascii_o[(i*8)+:8] == "_", "inicio oculto");
        comprobar(patron_ascii_o[(4*8)+:8] == " ", "fuera de longitud usa espacio");

        palabra_revelada_i = 12'b000000000101;
        #1;
        comprobar(patron_ascii_o[0  +: 8] == "A", "debe revelar A");
        comprobar(patron_ascii_o[8  +: 8] == "_", "M debe seguir oculta");
        comprobar(patron_ascii_o[16 +: 8] == "O", "debe revelar O");
        comprobar(patron_ascii_o[24 +: 8] == "_", "R debe seguir oculta");

        palabra_revelada_i = 12'h00F;
        #1;
        comprobar(patron_ascii_o[0  +: 8] == "A", "patron final A");
        comprobar(patron_ascii_o[8  +: 8] == "M", "patron final M");
        comprobar(patron_ascii_o[16 +: 8] == "O", "patron final O");
        comprobar(patron_ascii_o[24 +: 8] == "R", "patron final R");

        $display("OK: patron ASCII completo, %0d pruebas superadas", pruebas);
        $finish;
    end
endmodule
