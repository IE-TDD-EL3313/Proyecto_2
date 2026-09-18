package alertas_pkg;
    // Fases entregadas por la FSM principal.
    localparam logic [1:0] FASE_SELECCION = 2'd0;
    localparam logic [1:0] FASE_PARTIDA   = 2'd1;
    localparam logic [1:0] FASE_RESULTADO = 2'd2;
    localparam logic [1:0] FASE_RESET     = 2'd3;

    localparam logic [1:0] TONO_SILENCIO = 2'd0;
    localparam logic [1:0] TONO_ACIERTO  = 2'd1;
    localparam logic [1:0] TONO_ERROR    = 2'd2;
    localparam logic [1:0] TONO_FINAL    = 2'd3;

    // Seleccion de textos que debe presentar el controlador LCD superior.
    localparam logic [2:0] PANTALLA_MODO     = 3'd0;
    localparam logic [2:0] PANTALLA_PARTIDA  = 3'd1;
    localparam logic [2:0] PANTALLA_VICTORIA = 3'd2;
    localparam logic [2:0] PANTALLA_DERROTA  = 3'd3;

    localparam logic [1:0] LED_APAGADO   = 2'd0;
    localparam logic [1:0] LED_ENCENDIDO = 2'd1;
    localparam logic [1:0] LED_PARPADEO  = 2'd2;
endpackage
