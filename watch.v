`timescale 1ns / 1ps

module watch (
    input        clk,
    input        rst,
    input        sw0,
    input        Btn_L,
    input        Btn_U,
    input        Btn_D,
    output [3:0] fnd_com,
    output [7:0] fnd
);

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;


    watch_dp u_watch_dp (
        .clk(clk),
        .rst(rst),
        .up_sec(Btn_D),
        .up_min(Btn_U),
        .up_hour(Btn_L),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

    w_sw_fnd_controller u_fnd_controller (
        .clk(clk),
        .reset(rst),
        .sw0(sw0),
        .i_time({w_hour, w_min, w_sec, w_msec}),
        .fnd_com(fnd_com),
        .fnd(fnd)
    );



endmodule