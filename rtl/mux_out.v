`timescale 1ns / 1ps

module mux_out (
    input        start_sr,
    input        start_dht,
    input        start_watch,
    input  [3:0] sr04_fnd_com,
    input  [7:0] sr04_fnd,
    input        sr04_tx,
    input  [3:0] dht11_fnd_com,
    input  [7:0] dht11_fnd,
    input  [4:0] dht11_led,
    input  [3:0] watch_fnd_com,
    input  [7:0] watch_fnd,
    input        watch_tx,
    output [3:0] fnd_com,
    output [7:0] fnd,
    output [4:0] led,
    output       tx
);

    assign fnd_com = start_sr    ? sr04_fnd_com  :
                     start_dht   ? dht11_fnd_com :
                     start_watch ? watch_fnd_com :
                                   4'b1111;

    assign fnd     = start_sr    ? sr04_fnd      :
                     start_dht   ? dht11_fnd     :
                     start_watch ? watch_fnd     :
                                   8'b11111111;

    assign led     = start_sr    ? 5'b01000      :
                     start_dht   ? dht11_led     :
                     start_watch ? 5'b00100      :
                                   5'b00000;

    assign tx = start_sr ? sr04_tx : start_watch ? watch_tx : 1'b1;

endmodule
