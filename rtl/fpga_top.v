module fpga_top (
    input        clk,
    input        rst,
    input  [4:0] sw,
    input        echo,
    input        Btn_R,
    input        Btn_L,
    input        Btn_U,
    input        Btn_D,
    input        rx,
    inout        dht_io,
    output       trig,
    output [3:0] fnd_com,
    output [7:0] fnd,
    output [4:0] led,
    output       tx
);

    wire start_watch, start_sr, start_dht;

    wire [3:0] sr04_fnd_com;
    wire [7:0] sr04_fnd;
    wire       sr04_tx;

    wire [3:0] watch_fnd_com;
    wire [7:0] watch_fnd;
    wire       watch_tx;

    wire [3:0] dht11_fnd_com;
    wire [7:0] dht11_fnd;
    wire [4:0] dht11_led;

    sr04_top U_SR04 (
        .clk(clk),
        .rst(rst),
        .enable(start_sr),
        .echo(echo),
        .Btn_R(Btn_R),
        .rx(rx),
        .trig(trig),
        .fnd_com(sr04_fnd_com),
        .fnd(sr04_fnd),
        .tx(sr04_tx)
    );

    dht11_top U_DHT11 (
        .clk(clk),
        .rst(rst),
        .enable(start_dht),
        .btn_L(Btn_L),
        .dht_io(dht_io),
        .fnd_com(dht11_fnd_com),
        .fnd_data(dht11_fnd),
        .led(dht11_led)
    );

    watch_stopwatch_top U_WATCH_STOPWATCH (
        .clk(clk),
        .rst(rst),
        .enable(start_watch),
        .Btn_L(Btn_L),
        .Btn_U(Btn_U),
        .Btn_D(Btn_D),
        .Btn_R(Btn_R),
        .sw(sw[1:0]),
        .rx(rx),
        .tx(watch_tx),
        .fnd(watch_fnd),
        .fnd_com(watch_fnd_com)
    );

    // Control Unit
    fpga_cu U_CU (
        .sw(sw),
        .start_watch(start_watch),
        .start_sr(start_sr),
        .start_dht(start_dht)
    );

    mux_out U_OUT (
        .start_sr(start_sr),
        .start_dht(start_dht),
        .start_watch(start_watch),
        .sr04_fnd_com(sr04_fnd_com),
        .sr04_fnd(sr04_fnd),
        .sr04_tx(sr04_tx),
        .dht11_fnd_com(dht11_fnd_com),
        .dht11_fnd(dht11_fnd),
        .dht11_led(dht11_led),
        .watch_fnd_com(watch_fnd_com),
        .watch_fnd(watch_fnd),
        .watch_tx(watch_tx),
        .fnd_com(fnd_com),
        .fnd(fnd),
        .led(led),
        .tx(tx)
    );


endmodule
