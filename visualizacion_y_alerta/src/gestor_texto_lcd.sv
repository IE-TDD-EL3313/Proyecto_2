module gestor_texto_lcd (
    input logic clk_i, rst_i, 
    input logic [2:0] pantalla_sel_i, 
    input logic actualizar_i,
    input logic [95:0] patron_i, 
    input logic [2:0] errores_i,
    input logic [6:0] tiempo_i, victorias_i, 
    input logic [95:0] palabra_secreta_i,
    output logic write_enable_o, 
    output logic [1:0] addr_o, 
    output logic [31:0] wdata_o,
    input logic [31:0] rdata_i
);
    import alertas_pkg::*;
    typedef enum logic [2:0] {ESPERAR_INIT, REPOSO, HOME, ESP_HOME, DATO, START, ESP_DATO} st_t;
    st_t estado_q;
    logic pendiente_q;
    logic [2:0] pantalla_q, errores_q;
    logic [95:0] patron_q, palabra_q;
    logic [6:0] tiempo_q, victorias_q;
    logic [5:0] indice_q;

    function automatic logic [7:0] digito(input logic [3:0] n);
        digito = "0" + n;
    endfunction
    function automatic logic [7:0] caracter(input logic [5:0] pos);
        logic [6:0] decenas, unidades;
        begin
            decenas = tiempo_q / 10; unidades = tiempo_q % 10;
            caracter = " ";
            case (pantalla_q)
                PANTALLA_MODO: begin
                    case(pos) 0:caracter="A";1:caracter="H";2:caracter="O";3:caracter="R";4:caracter="C";5:caracter="A";6:caracter="D";7:caracter="O";
                    16:caracter="S";17:caracter="E";18:caracter="L";19:caracter="E";20:caracter="C";21:caracter="C";22:caracter="I";23:caracter="O";24:caracter="N"; default:; endcase
                end
                PANTALLA_PARTIDA: begin
                    if (pos < 12) caracter = patron_q[95-(pos*8) -: 8];
                    else case(pos) 13:caracter="E";14:caracter=":";15:caracter=digito(errores_q); 16:caracter="T";17:caracter=":";
                    18:caracter=digito(decenas[3:0]);19:caracter=digito(unidades[3:0]);21:caracter="V";22:caracter=":";
                    23:caracter=digito((victorias_q/10));24:caracter=digito((victorias_q%10)); default:; endcase
                end
                PANTALLA_VICTORIA: begin
                    case(pos) 2:caracter="V";3:caracter="I";4:caracter="C";5:caracter="T";6:caracter="O";7:caracter="R";8:caracter="I";9:caracter="A"; default:; endcase
                    if (pos >= 16 && pos < 28) caracter = palabra_q[95-((pos-16)*8) -: 8];
                end
                default: begin
                    case(pos) 3:caracter="D";4:caracter="E";5:caracter="R";6:caracter="R";7:caracter="O";8:caracter="T";9:caracter="A"; default:; endcase
                    if (pos >= 16 && pos < 28) caracter = palabra_q[95-((pos-16)*8) -: 8];
                end
            endcase
        end
    endfunction

    // always @(*) evita una advertencia de compatibilidad de Icarus Verilog
    // con los part-selects usados al formar los caracteres del LCD.
    always @(*) begin
        write_enable_o = 0; addr_o = 0; wdata_o = 0;
        if (estado_q == HOME) begin write_enable_o=1; addr_o=0; wdata_o[3]=1; end
        if (estado_q == DATO) begin write_enable_o=1; addr_o=1; wdata_o[7:0]=caracter(indice_q); end
        if (estado_q == START) begin write_enable_o=1; addr_o=0; wdata_o[1:0]=2'b11; end
    end
    always_ff @(posedge clk_i) begin
        if (rst_i) begin estado_q<=ESPERAR_INIT; pendiente_q<=1; indice_q<=0; pantalla_q<=PANTALLA_MODO; errores_q<=0; patron_q<='0; palabra_q<='0; tiempo_q<=0; victorias_q<=0; end
        else begin
            if (actualizar_i) begin pendiente_q<=1; pantalla_q<=pantalla_sel_i; errores_q<=errores_i; patron_q<=patron_i; palabra_q<=palabra_secreta_i; tiempo_q<=tiempo_i; victorias_q<=victorias_i; end
            case(estado_q)
                ESPERAR_INIT: if (!rdata_i[8]) estado_q<=REPOSO;
                REPOSO: if (pendiente_q) begin pendiente_q<=0; estado_q<=HOME; end
                HOME: estado_q<=ESP_HOME;
                ESP_HOME: if (!rdata_i[8]) begin indice_q<=0; estado_q<=DATO; end
                DATO: estado_q<=START;
                START: estado_q<=ESP_DATO;
                ESP_DATO: if (!rdata_i[8]) begin if (indice_q==31) estado_q<=REPOSO; else begin indice_q<=indice_q+1; estado_q<=DATO; end end
                default: estado_q<=ESPERAR_INIT;
            endcase
        end
    end
endmodule
