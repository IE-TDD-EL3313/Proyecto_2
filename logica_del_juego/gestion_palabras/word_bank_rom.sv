// ============================================================================
// word_bank_rom.sv
//
// Banco de 50 palabras (A-Z, sin tildes ni ni, 4-12 letras), organizado asi:
//   direcciones  0-29 : palabras de cualquier longitud valida (4-12)  -> Facil
//   direcciones 30-49 : solo palabras de 6-12 letras                  -> Dificil
// (Facil elige de toda la ROM 0-49; Dificil elige solo del subrango 30-49)
//
// Formato de cada entrada (64 bits):
//   [63:60] longitud real (4-12)
//   [59:0]  12 grupos de 5 bits, letra_1..letra_12 (A=00001 .. Z=11010),
//           relleno con 00000 si la palabra es mas corta que 12 letras.
//
// NOTA IMPORTANTE: los valores hexadecimales se PRECALCULARON fuera de la
// herramienta (con un script) y se escriben aqui como constantes literales,
// en vez de construirse en tiempo de elaboracion a partir de "string" y una
// funcion de empaquetado. Esto es obligatorio porque Vivado (synth_1) NO
// sintetiza el tipo "string" -- error "[Synth 8-27] string type not
// supported" -- aunque funcione perfectamente en simulacion (Icarus/XSim).
// Si se necesita cambiar el banco de palabras, se debe regenerar esta tabla
// con el script (ver docs/, script gen_rom.py) y volver a pegar los valores.
// ============================================================================
module word_bank_rom #(
    parameter bit          MODO_PRUEBA    = 1'b0,
    parameter logic [63:0] PALABRA_PRUEBA = 64'h4000000000093DA1 // AMOR
) (
    input  logic [7:0]  direccion,     // indice ya ajustado (0-49)
    output logic [63:0] palabra_rom
);
    localparam int NUM_PALABRAS = 50;

    logic [63:0] rom [0:NUM_PALABRAS-1];

    initial begin
        rom[0]  = 64'h4000000000009E06; // FPGA (4)
        rom[1]  = 64'h4000000000082503; // CHIP (4)
        rom[2]  = 64'h400000000002D322; // BYTE (4)
        rom[3]  = 64'h500000000132CEA2; // BUSES (5)
        rom[4]  = 64'h5000000000B1BD83; // CLOCK (5)
        rom[5]  = 64'h500000000142CCB2; // RESET (5)
        rom[6]  = 64'h500000000081D02C; // LATCH (5)
        rom[7]  = 64'h6000000024531AA2; // BUFFER (6)
        rom[8]  = 64'h600000003327B4AD; // MEMORY (6)
        rom[9]  = 64'h600000000ACA91ED; // MODULE (6)
        rom[10] = 64'h6000000018171D33; // SIGNAL (6)
        rom[11] = 64'h600000001A5A4F33; // SYSTEM (6)
        rom[12] = 64'h600000001C74CCA4; // DESIGN (6)
        rom[13] = 64'h6000000024FA0CB6; // VECTOR (6)
        rom[14] = 64'h600000001F2A3126; // FILTRO (6)
        rom[15] = 64'h70000003E651BE50; // PROCESO (7)
        rom[16] = 64'h700000039E91BAA6; // FUNCION (7)
        rom[17] = 64'h8000002B0414C836; // VARIABLE (8)
        rom[18] = 64'h8000007CA9349CB2; // REGISTRO (8)
        rom[19] = 64'h80000093C81A39E3; // CONTADOR (8)
        rom[20] = 64'h8000007D1351C923; // CIRCUITO (8)
        rom[21] = 64'h700000048A478CA4; // DECODER (7)
        rom[22] = 64'h700000048A478DC5; // ENCODER (7)
        rom[23] = 64'h5000000001229081; // ADDER (5)
        rom[24] = 64'h700000048B4755E3; // COUNTER (7)
        rom[25] = 64'h700000048A44D924; // DIVIDER (7)
        rom[26] = 64'h700000048A73A654; // TRIGGER (7)
        rom[27] = 64'h600000000AC39DF4; // TOGGLE (6)
        rom[28] = 64'h500000000059B2B0; // PULSE (5)
        rom[29] = 64'h600000000AC83433; // SAMPLE (6)
        rom[30] = 64'hB049E40B1F2A39E3; // CONTROLADOR (11)
        rom[31] = 64'hA0024FA4D3370654; // TRANSISTOR (10)
        rom[32] = 64'hA0024F20641835E3; // COMPARADOR (10)
        rom[33] = 64'hB049F82B209A32AD; // MULTIPLEXOR (11)
        rom[34] = 64'h8000007B9F21B933; // SINCRONO (8)
        rom[35] = 64'h90000F73E4372661; // ASINCRONO (9)
        rom[36] = 64'hC93C81D264F834B4; // TEMPORIZADOR (12)
        rom[37] = 64'h90000F63C6FA3E50; // PROTOCOLO (9)
        rom[38] = 64'h700000010244C830; // PARIDAD (7)
        rom[39] = 64'h70000004DE925422; // BAUDIOS (7)
        rom[40] = 64'h90000E7A4632C924; // DIRECCION (9)
        rom[41] = 64'h70000003E45A3AB0; // PUNTERO (7)
        rom[42] = 64'hA0024F206651BE50; // PROCESADOR (10)
        rom[43] = 64'hA001CF48C2CAB533; // SIMULACION (10)
        rom[44] = 64'hA001CF48D3370654; // TRANSICION (10)
        rom[45] = 64'h700000005C9AC42D; // MAQUINA (7)
        rom[46] = 64'h800000450300D024; // DATAPATH (8)
        rom[47] = 64'h90000F4B5EE4B1F0; // POLINOMIO (9)
        rom[48] = 64'h8000000A64FA0D36; // VICTORIA (8)
        rom[49] = 64'h7000000068F948A4; // DERROTA (7)
    end

    always_comb begin
        if (MODO_PRUEBA)
            palabra_rom = PALABRA_PRUEBA;
        else
            palabra_rom = rom[direccion[5:0]];
    end
endmodule
