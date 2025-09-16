`timescale 1ns / 1ps

module clock_top (
    input        clk,
    input        rst,
    input        sw0,
    input        sw1,
    input        Btn_L_sw,
    input        Btn_L_watch,
    input        Btn_U,
    input        Btn_D,
    input        Btn_R,
    input        uart_mode,
    output [3:0] fnd_com,
    output [7:0] fnd
);
    wire [3:0] sw_fnd_com, watch_fnd_com;
    wire [7:0] sw_fnd, watch_fnd;
    reg mode_reg;

    stopwatch u_stopwatch (
        .clk    (clk),
        .rst    (rst),
        .sw_0   (sw0),
        .Btn_L  (Btn_L_sw),
        .Btn_R  (Btn_R),
        .fnd_com(sw_fnd_com),
        .fnd    (sw_fnd)
    );


    watch u_watch (
        .clk    (clk),
        .rst    (rst),
        .sw0    (sw0),
        .Btn_L  (Btn_L_watch),
        .Btn_U  (Btn_U),
        .Btn_D  (Btn_D),
        .fnd_com(watch_fnd_com),
        .fnd    (watch_fnd)
    );



    assign fnd_com = (uart_mode) ? watch_fnd_com : sw_fnd_com;
    assign fnd     = (uart_mode) ? watch_fnd : sw_fnd;

endmodule
