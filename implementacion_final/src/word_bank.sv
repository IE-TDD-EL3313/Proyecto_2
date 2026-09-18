module word_bank (
    input  logic [5:0]  index,
    output logic [95:0] word,
    output logic [3:0]  length
);

    localparam logic [95:0] WORDS [0:49] = '{
        "CASA        ","MESA        ","GATO        ","LUNA        ","ROCA        ",
        "NUBE        ","PATO        ","RANA        ","FLOR        ","CAFE        ",
        "LIBRO       ","PERRO       ","PLAYA       ","ARBOL       ","RELOJ       ",
        "CAMPO       ","FUEGO       ","NIEVE       ","BARCO       ","QUESO       ",
        "CAMINO      ","MONEDA      ","TIERRA      ","PUERTA      ","VERANO      ",
        "PLANETA     ","ESCUELA     ","TECLADO     ","PANTALLA    ","CIRCUITO    ",
        "SISTEMA     ","DIGITAL     ","SENSOR      ","MEMORIA     ","CONTROL     ",
        "VOLTAJE     ","CORRIENTE   ","RESISTOR    ","TRANSISTOR  ","PROCESADOR  ",
        "COMPUTADOR  ","ALGORITMO   ","VARIABLE    ","FUNCION     ","MATRIZ      ",
        "VECTOR      ","FRECUENCIA  ","POTENCIA    ","ENERGIA     ","ELECTRONICA "
    };

    localparam logic [3:0] LENGTHS [0:49] = '{
        4,4,4,4,4, 4,4,4,4,4,
        5,5,5,5,5, 5,5,5,5,5,
        6,6,6,6,6, 7,7,7,8,8,
        7,7,6,7,7, 7,9,8,10,10,
        10,9,8,7,6, 6,10,8,7,11
    };

    always_comb begin
        if (index < 50) begin
            word   = WORDS[index];
            length = LENGTHS[index];
        end else begin
            word   = WORDS[0];
            length = LENGTHS[0];
        end
    end

endmodule