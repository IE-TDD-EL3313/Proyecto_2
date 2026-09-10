// ============================================================================
// temporizador_partida.sv
//
// FSM de 2 estados: IDLE / CONTANDO.
//   IDLE -> CONTANDO: con tiempo_activo=1 (carga limite segun dificultad)
//   CONTANDO -> IDLE: unica condicion tiempo_activo=0
// tiempo_restante==0 NO regresa a IDLE por si solo; solo activa
// tiempo_agotado, permaneciendo en CONTANDO hasta que Control baje
// tiempo_activo (el Temporizador solo cuenta y reporta).
// ============================================================================
module temporizador_partida (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tick_1s,
    input  logic       dificultad,       // 0=Facil(60s), 1=Dificil(45s)
    input  logic       tiempo_activo,
    output logic [7:0] tiempo_restante_bcd, // {decenas[7:4], unidades[3:0]}
    output logic       tiempo_agotado
);
    typedef enum logic {IDLE, CONTANDO} estado_t;
    estado_t estado, estado_next;

    logic [6:0] tiempo_restante; // 0-99
    logic [6:0] limite;
    assign limite = dificultad ? 7'd45 : 7'd60;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) estado <= IDLE;
        else        estado <= estado_next;
    end

    always_comb begin
        estado_next = estado;
        case (estado)
            IDLE:     if (tiempo_activo)  estado_next = CONTANDO;
            CONTANDO: if (!tiempo_activo) estado_next = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tiempo_restante <= 7'd0;
        else if (estado == IDLE && estado_next == CONTANDO)
            tiempo_restante <= limite;                       // carga al entrar
        else if (estado == CONTANDO && tick_1s && tiempo_restante != 7'd0)
            tiempo_restante <= tiempo_restante - 7'd1;
    end

    assign tiempo_agotado = (estado == CONTANDO) && (tiempo_restante == 7'd0);

    // Conversion binario -> BCD (rango pequeno 0-99, division/modulo directos)
    always_comb begin
        tiempo_restante_bcd[7:4] = tiempo_restante / 7'd10;
        tiempo_restante_bcd[3:0] = tiempo_restante % 7'd10;
    end
endmodule
