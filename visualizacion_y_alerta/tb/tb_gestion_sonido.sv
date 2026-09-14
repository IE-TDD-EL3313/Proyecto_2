`timescale 1ns/1ps
module tb_gestion_sonido;
    import alertas_pkg::*;
    logic clk_i = 1'b0;
    logic rst_i;
    logic tono_start_i;
    logic buzzer_o;
    logic [1:0] tono_sel_i;
    int edges;
    gestion_sonido #(
        .CLK_HZ(1_000_000), .FREQ_ACIERTO_HZ(100_000), .FREQ_ERROR_HZ(50_000),
        .FREQ_FINAL_HZ(25_000), .DUR_ACIERTO_MS(1), .DUR_ERROR_MS(1), .DUR_FINAL_MS(1)
    ) dut (.*);
    always #5 clk_i = ~clk_i;
    always @(buzzer_o) if (buzzer_o) edges++;
    initial begin
        rst_i = 1; tono_start_i = 0; tono_sel_i = TONO_SILENCIO; edges = 0;
        repeat(2) @(posedge clk_i);
        rst_i = 0;
        @(negedge clk_i);
        tono_sel_i = TONO_ACIERTO; tono_start_i = 1;
        @(negedge clk_i);
        tono_start_i = 0;
        repeat(1_100) @(posedge clk_i);
        if (edges == 0 || buzzer_o !== 0) $fatal(1,"No se genero o termino el tono");
        $display("PASS: tb_gestion_sonido");
        $finish;
    end
endmodule
