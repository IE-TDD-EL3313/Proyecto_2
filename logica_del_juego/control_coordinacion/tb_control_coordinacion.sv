`timescale 1ns/1ps
// ============================================================================
// tb_control_coordinacion.sv
//
// Prueba el bloque Control y Coordinacion de forma AISLADA: la palabra y el
// resultado de cada letra se inyectan manualmente (no se instancia Gestion
// de Palabras ni Gestion del Tiempo), simulando una partida completa en
// modo Facil con la palabra ficticia "GATO" (longitud 4).
// ============================================================================
module tb_control_coordinacion;

    logic        clk = 0, rst_n;
    logic        tick_1s;
    logic        sel_pulse, ok_pulse, rst_pulse;
    logic [7:0]  letra_ascii;
    logic        nueva_letra;
    logic        palabra_lista;
    logic [3:0]  longitud_palabra;
    logic [11:0] mask_coincidencia;
    logic        pedir_palabra;
    logic [4:0]  letra_in;
    logic        validar;
    logic        tiempo_agotado;
    logic        tiempo_activo;
    logic        dificultad;
    logic [1:0]  estado_juego;
    logic [11:0] palabra_revelada;
    logic [2:0]  intentos_restantes;
    logic        resultado_final;
    logic [7:0]  partidas_ganadas_bcd;
    logic        enviar_trama;
    logic        evento_letra;
    logic [1:0]  resultado_letra;
    logic [1:0]  causa_final;
    logic [1:0]  evento_sonido;

    int errores = 0, pruebas = 0;

    control_coordinacion dut (.*);

    always #5 clk = ~clk;

    localparam SEL_MODO=2'b00, CARGANDO=2'b01, JUGANDO=2'b10, FIN_PARTIDA=2'b11;

    task automatic check(input bit cond, input string msg);
        pruebas++;
        if (!cond) begin
            errores++;
            $display("[FALLO] %s (t=%0t, estado_juego=%0d)", msg, $time, estado_juego);
        end
    endtask

    // Nota: se evita "ref" en argumentos de task (no soportado por algunas
    // versiones de Icarus Verilog); se definen tasks especificas por señal.
    task automatic pulso_ok();
        ok_pulse = 1'b1;
        @(posedge clk); #1;
        ok_pulse = 1'b0;
        @(posedge clk); #1;
    endtask

    task automatic pulso_rst();
        rst_pulse = 1'b1;
        @(posedge clk); #1;
        rst_pulse = 1'b0;
        @(posedge clk); #1;
    endtask

    task automatic pulso_tick();
        tick_1s = 1'b1;
        @(posedge clk); #1;
        tick_1s = 1'b0;
        @(posedge clk); #1;
    endtask

    // Simula que Gestion de Palabras responde con la palabra "GATO"
    // (G-A-T-O, longitud 4). mask_coincidencia se calcula a mano segun la
    // letra que se le "envie" al datapath via letra_ascii.
    function automatic [11:0] mask_para_letra(input [7:0] letra);
        // Posiciones: 0=G,1=A,2=T,3=O
        case (letra)
            "G": mask_para_letra = 12'b0000_0000_0001;
            "A": mask_para_letra = 12'b0000_0000_0010;
            "T": mask_para_letra = 12'b0000_0000_0100;
            "O": mask_para_letra = 12'b0000_0000_1000;
            default: mask_para_letra = 12'b0;
        endcase
    endfunction

    // evento_sonido y enviar_trama son de tipo Mealy: solo son validos
    // durante el UNICO ciclo en que estado==VALIDANDO. Se capturan aqui,
    // antes de que la FSM avance a JUGANDO/FIN_PARTIDA en el siguiente flanco.
    logic [1:0] evento_capturado;
    logic [1:0] resultado_letra_capturado;
    logic [1:0] causa_final_capturada;
    logic       evento_letra_capturado;
    logic       trama_capturada;

    task automatic simular_letra(input [7:0] letra);
        letra_ascii       = letra;
        mask_coincidencia = mask_para_letra(letra);
        nueva_letra       = 1'b1;
        @(posedge clk); #1;              // estado entra a VALIDANDO en este flanco
        nueva_letra       = 1'b0;
        evento_capturado  = evento_sonido; // capturado MIENTRAS estado==VALIDANDO
        evento_letra_capturado = evento_letra;
        resultado_letra_capturado = resultado_letra;
        causa_final_capturada = causa_final;
        trama_capturada   = enviar_trama;
        @(posedge clk); #1;              // VALIDANDO -> JUGANDO/FIN_PARTIDA
    endtask

    initial begin
        rst_n = 0; tick_1s = 0; sel_pulse = 0; ok_pulse = 0; rst_pulse = 0;
        letra_ascii = 0; nueva_letra = 0; palabra_lista = 0;
        longitud_palabra = 4'd4; mask_coincidencia = 0; tiempo_agotado = 0;
        repeat (3) @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        check(estado_juego == SEL_MODO, "No inicio en SEL_MODO");

        // --- Confirmar modo e iniciar partida ---
        pulso_ok();
        check(estado_juego == CARGANDO, "No paso a CARGANDO tras ok_pulse");
        check(pedir_palabra == 1'b1, "No se activo pedir_palabra en CARGANDO");

        // Simular que Gestion de Palabras entrega la palabra
        palabra_lista = 1'b1;
        @(posedge clk); #1;
        palabra_lista = 1'b0;
        @(posedge clk); #1;
        check(estado_juego == JUGANDO, "No paso a JUGANDO tras palabra_lista");

        // --- Letra correcta: G ---
        simular_letra("G");
        check(evento_capturado == 2'b01, "No sono acierto tras letra G correcta");
        check(evento_letra_capturado && resultado_letra_capturado == 2'b01,
              "UART no reporto el acierto");
        check(intentos_restantes == 3'd6, "Intentos no deberian bajar con acierto");

        // --- Letra incorrecta: X ---
        simular_letra("X");
        check(evento_capturado == 2'b10, "No sono error tras letra X incorrecta");
        check(resultado_letra_capturado == 2'b10, "UART no reporto el error");
        check(intentos_restantes == 3'd5, "Intentos no bajaron tras letra incorrecta");

        // --- Letra repetida: G otra vez ---
        simular_letra("G");
        check(evento_capturado == 2'b00, "Letra repetida no deberia sonar nada");
        check(resultado_letra_capturado == 2'b11, "UART no reporto letra repetida");
        check(intentos_restantes == 3'd5, "Letra repetida no deberia consumir intento");

        // --- Completar la palabra: A, T, O ---
        simular_letra("A");
        simular_letra("T");
        simular_letra("O");
        check(estado_juego == FIN_PARTIDA, "No paso a FIN_PARTIDA al completar palabra");
        check(resultado_final == 1'b1, "resultado_final deberia ser victoria (1)");
        check(trama_capturada == 1'b1, "enviar_trama no se activo al ganar");
        check(causa_final_capturada == 2'b01, "UART no reporto victoria");

        // --- Verificar que se incrementa partidas_ganadas_bcd exactamente 1 vez ---
        @(posedge clk); #1;
        check(partidas_ganadas_bcd == 8'h01, "partidas_ganadas_bcd no incremento a 1");
        @(posedge clk); #1;
        check(partidas_ganadas_bcd == 8'h01, "partidas_ganadas_bcd incremento mas de 1 vez");

        // --- Esperar 3 s de despliegue y regresar a SEL_MODO ---
        repeat (3) pulso_tick();
        check(estado_juego == SEL_MODO, "No regreso a SEL_MODO tras 3 s de despliegue");

        // ================== Segunda partida: derrota por intentos ==================
        pulso_ok();
        palabra_lista = 1'b1; @(posedge clk); #1; palabra_lista = 1'b0; @(posedge clk); #1;
        check(estado_juego == JUGANDO, "No inicio segunda partida en JUGANDO");

        // 6 letras incorrectas seguidas (usamos letras que no son G/A/T/O)
        simular_letra("B");
        simular_letra("C");
        simular_letra("D");
        simular_letra("E");
        simular_letra("F");
        check(intentos_restantes == 3'd1, "Deberia quedar 1 intento tras 5 errores");
        simular_letra("H"); // 6to error
        check(estado_juego == FIN_PARTIDA, "No paso a FIN_PARTIDA al agotar intentos");
        check(resultado_final == 1'b0, "resultado_final deberia ser derrota (0)");

        repeat (3) pulso_tick();
        check(estado_juego == SEL_MODO, "No regreso a SEL_MODO tras derrota");

        // --- No debio incrementar partidas_ganadas_bcd en la derrota ---
        check(partidas_ganadas_bcd == 8'h01, "partidas_ganadas_bcd cambio tras una derrota");

        // ================== Tercera partida: derrota por tiempo (sin letra) ========
        pulso_ok();
        palabra_lista = 1'b1; @(posedge clk); #1; palabra_lista = 1'b0; @(posedge clk); #1;
        check(estado_juego == JUGANDO, "No inicio tercera partida en JUGANDO");

        tiempo_agotado = 1'b1;
        @(posedge clk); #1;
        check(estado_juego == FIN_PARTIDA,
              "No paso a FIN_PARTIDA cuando tiempo_agotado sin nueva letra (ajuste 2)");
        tiempo_agotado = 1'b0;

        // --- rst_pulse debe regresar a SEL_MODO desde cualquier estado ---
        pulso_rst();
        check(estado_juego == SEL_MODO, "rst_pulse no regreso a SEL_MODO");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n", pruebas, pruebas);
        else
            $display("\n*** %0d DE %0d PRUEBAS FALLARON ***\n", errores, pruebas);

        $finish;
    end
endmodule
