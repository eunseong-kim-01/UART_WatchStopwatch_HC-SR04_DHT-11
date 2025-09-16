`timescale 1ns / 1ps

module tb_fpga_top ();

    reg clk, rst, echo, Btn_R, Btn_L, Btn_U, Btn_D, rx;
    reg [4:0] sw;
    wire trig;
    wire [3:0] fnd_com;
    wire [7:0] fnd;
    wire [4:0] led;
    wire dht_io;
    wire tx;

    fpga_top dut (
        .clk    (clk),
        .rst    (rst),
        .sw     (sw),
        .echo   (echo),
        .Btn_R  (Btn_R),
        .Btn_L  (Btn_L),
        .Btn_U  (Btn_U),
        .Btn_D  (Btn_D),
        .rx     (rx),
        .dht_io (dht_io),
        .trig   (trig),
        .fnd_com(fnd_com),
        .fnd    (fnd),
        .led    (led),
        .tx     (tx)
    );

    parameter US = 1_000, MS = 1_000_000;
    reg dht11_sensor_reg, dht11_sensor_enable;
    reg [39:0] dht11_sensor_data;
    integer i;
    assign dht_io = (dht11_sensor_enable) ? dht11_sensor_reg : 1'bz;

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        dht11_sensor_enable = 0;
        Btn_L = 0;
        Btn_U = 0;
        Btn_R = 0;
        Btn_D = 0;
        dht11_sensor_reg = 0;
        i = 0;
        dht11_sensor_data = 40'b10101010_00001111_11000110_00000000_01111111;
        sw[0] = 0;
        sw[2] = 0;
        sw[3] = 0;
        sw[4] = 0;
        #10;
        rst = 0;
        #10;
        sw[4] = 1;
        Btn_L = 1;
        #20_000;
        Btn_L = 0;
        #(20 * MS);
        //start
        #(30 * US);
        //sensor is change in sensor for RX to TX
        dht11_sensor_enable = 1;
        #(80 * US);
        dht11_sensor_reg = 1;
        #(80 * US);
        //for sensor data 40bit
        for (i = 0; i < 40; i = i + 1) begin
            dht11_sensor_reg = 0;
            #(50 * US);
            dht11_sensor_reg = 1;
            if (dht11_sensor_data[39-i]) begin
                #(70 * US);
            end else begin
                #(28 * US);
            end
        end
        dht11_sensor_reg = 0;
        #(50 * US);
        dht11_sensor_enable = 0;
        #1000;
        sw[4] = 0;
        sw[3] = 1;
        #(10 * US);
        Btn_R = 1;
        #20_000;
        Btn_R = 0;
        //10us TTL delay time
        #11_000;
        //echo
        #10_000;
        echo = 1;
        #(1_000_000);
        echo = 0;
        #10_000;
        //$stop;

        // Watch & Stopwatch Test
        sw[3] = 0;
        // --- 1. Activate watch/stopwatch ---
        #100;
        sw[2] = 1;  // Activate watch/stopwatch
        sw[1] = 0;  // stopwatch mode

        // --- 2. Run (btn_r) ---
        #1_000;
        Btn_R = 1;
        #20000;
        Btn_R = 0;

        #(2 * 1_000_000_00);

        // --- 3. Stop (btn_r) ---
        Btn_R = 1;
        #20000;
        Btn_R = 0;

        #1_000_000;

        // --- 4. Clear (btn_l) ---
        #1_000;
        Btn_L = 1;
        #20000;
        Btn_L = 0;

        #1_000_000;

        sw[1] = 1;  // watch mode

        #100;
        Btn_U = 1;
        #20000;
        Btn_U = 0;
        #(2 * 1_000_000_00);

        $stop;
    end

endmodule