`timescale 1ns / 1ps

module dht11_top (
    input        clk,
    input        rst,
    input        btn_L,
    input       enable,
    inout        dht_io,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [4:0] led
);

    wire w_tick;
    wire btn_bd;
    wire w_valid;
    wire [7:0] w_humidity;
    wire [7:0] w_temperature;
    wire [3:0] w_state;


    dht11_control_unit U_DHT11_CU (
        .clk(clk),
        .rst(rst | ~enable),
        .i_start(btn_bd),
        .i_tick(w_tick),
        .o_valid(w_valid),
        .humidity(w_humidity),
        .temperature(w_temperature),
        .led(w_state),
        .dht_io(dht_io)
    );

    dht11_fnd_controller dht11_U_FND_CNTL (
        .clk          (clk),
        .reset        (rst| ~enable),
        .i_humidity   (w_humidity),
        .i_temperature(w_temperature),
        .i_valid      (w_valid),
        .i_state      (w_state),
        .fnd_com      (fnd_com),
        .fnd_data     (fnd_data),
        .led          (led)
    );

    dht_tick_gen_1us U_TICKGEN (
        .clk(clk),
        .rst(rst| ~enable),
        .o_tick_1us(w_tick)
    );

    button_debounce U_BD (
        .clk  (clk),
        .rst  (rst| ~enable),
        .i_btn(btn_L),
        .o_btn(btn_bd)
    );

endmodule

module dht11_control_unit (
    input clk,
    input rst,
    input i_start,
    input i_tick,
    output o_valid,
    output [7:0] humidity,
    output [7:0] temperature,  
    output [3:0] led,  // debug
    inout dht_io  // sensor
);

    parameter  IDLE = 4'h0, START = 4'h1, WAIT = 4'h2, SYNCL = 4'h3, SYNCH = 4'h4, DATASYNC=4'h5, DATADETECT=4'h6, STOP=4'h7;
    reg [3:0] c_state, n_state;
    reg dht_io_enable_reg, dht_io_enable_next;  // to control for dht_out_reg
    reg dht_out_reg, dht_out_next;  // to dht11 sensor output
    reg [19:0] tick_cnt_reg, tick_cnt_next;
    reg [5:0] bit_cnt_reg, bit_cnt_next;
    reg [39:0] bit_data_reg, bit_data_next;
    reg valid_reg, valid_next;

    reg [9:0] check_sum_cal;

    assign humidity = bit_data_reg[39:32];
    assign temperature = bit_data_reg[23:16];

    assign o_valid = valid_reg;
    assign led = c_state;


    assign dht_io = (dht_io_enable_reg) ? dht_out_reg : 1'bz;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state           <= IDLE;
            dht_io_enable_reg <= 1'b1;
            dht_out_reg       <= 1'b1;
            tick_cnt_reg      <= 0;
            bit_cnt_reg       <= 0;
            bit_data_reg      <= 0;
            valid_reg         <= 0;

        end else begin
            c_state           <= n_state;
            dht_io_enable_reg <= dht_io_enable_next;
            dht_out_reg       <= dht_out_next;
            tick_cnt_reg      <= tick_cnt_next;
            bit_cnt_reg       <= bit_cnt_next;
            bit_data_reg      <= bit_data_next;
            valid_reg         <= valid_next;
        end
    end

    always @(*) begin
        n_state            = c_state;
        dht_io_enable_next = dht_io_enable_reg;
        dht_out_next       = dht_out_reg;
        tick_cnt_next      = tick_cnt_reg;
        bit_cnt_next       = bit_cnt_reg;
        bit_data_next      = bit_data_reg;
        valid_next         = valid_reg;
        case (c_state)
            IDLE: begin
                dht_io_enable_next = 1'b1;
                dht_out_next = 1'b1;
                if (i_start) begin
                    valid_next = 0;
                    tick_cnt_next = 0;
                    n_state = START;
                end
            end
            START: begin
                dht_out_next = 1'b0;
                if (i_tick) begin
                    if (tick_cnt_reg == 20000) begin
                        tick_cnt_next = 0;
                        dht_out_next = 1'b1;
                        n_state = WAIT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (i_tick) begin
                    if (tick_cnt_reg >= 30) begin
                        dht_io_enable_next = 1'b0;
                        tick_cnt_next = 0;
                        n_state = SYNCL;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin
                if (i_tick) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (dht_io) begin
                        tick_cnt_next = 0;
                        n_state = SYNCH;
                    end
                end
            end
            SYNCH: begin
                if (i_tick) begin
                    if (dht_io) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        tick_cnt_next = 0;
                        n_state = DATASYNC;
                        tick_cnt_next = 0;
                        bit_cnt_next = 0;
                        bit_data_next = 0;
                    end
                end
            end
            DATASYNC: begin
                if (i_tick) begin
                    if (dht_io) begin
                        n_state = DATADETECT;
                        tick_cnt_next = 0;
                    end
                end
            end
            DATADETECT: begin
                if (i_tick) begin
                    if (dht_io) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        if (tick_cnt_reg <= 50) begin
                            bit_data_next[39-bit_cnt_reg] = 0;
                        end else begin
                            bit_data_next[39-bit_cnt_reg] = 1;
                        end
                        if (bit_cnt_reg == 39) begin
                            tick_cnt_next = 0;
                            n_state = STOP;
                        end else begin
                            tick_cnt_next = 0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            n_state = DATASYNC;
                        end
                    end
                end
            end
            STOP: begin
                if (i_tick) begin
                    if (tick_cnt_reg == 50) begin
                        check_sum_cal = bit_data_reg[39:32]+bit_data_reg[31:24]+bit_data_reg[23:16]+bit_data_reg[15:8];
                        if (check_sum_cal[7:0] == bit_data_reg[7:0]) begin
                            valid_next = 1'b1;
                        end else begin
                            valid_next = 1'b0;
                        end
                        dht_io_enable_next = 1'b1;
                        n_state = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

        endcase
    end

endmodule

module dht_tick_gen_1us (
    input  clk,
    input  rst,
    output o_tick_1us
);
    // 
    parameter FCOUNT = 100_000_000 / 1_000_000;
    reg [$clog2(FCOUNT)-1 : 0] counter_reg;
    reg tick_1us;

    assign o_tick_1us = tick_1us;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_1us <= 1'b0;
        end else begin
            if (counter_reg == FCOUNT - 1) begin
                counter_reg <= 0;
                tick_1us <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                tick_1us <= 1'b0;
            end
        end
    end
endmodule


module dht11_fnd_controller (
    input        clk,
    input        reset,
    input  [7:0] i_humidity,
    input  [7:0] i_temperature,
    input        i_valid,
    input  [3:0] i_state,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [4:0] led
);
    wire [3:0] w_bcd, w_dot_data, w_temphumi;
    wire [3:0] w_humi_digit_1, w_humi_digit_10;
    wire [3:0] w_temp_digit_1, w_temp_digit_10;
    wire [2:0] w_sel;
    wire w_clk_1khz;

    assign led[4] = i_valid;
    assign led[3:0] = i_state;

    dht11_clk_div_1khz U_CLK_DIV_1KHZ (
        .clk(clk),
        .reset(reset),
        .o_clk_1khz(w_clk_1khz)
    );

    w_sw_counter_8 U_w_sw_counter_8 (
        .clk  (w_clk_1khz),
        .reset(reset),
        .sel  (w_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .sel(w_sel[1:0]),
        .fnd_com(fnd_com)
    );

    dht11_digit_splitter #(
        .BIT_WIDTH(8)
    ) U_HUMI_DS (
        .count_data(i_humidity),
        .digit_1(w_humi_digit_1),
        .digit_10(w_humi_digit_10)
    );

    dht11_digit_splitter #(
        .BIT_WIDTH(8)
    ) U_TEMP_DS (
        .count_data(i_temperature),
        .digit_1(w_temp_digit_1),
        .digit_10(w_temp_digit_10)
    );

    w_sw_mux_8x1 U_w_sw_mux_8x1_TEMPHUMI (
        .digit_1(w_temp_digit_1),
        .digit_10(w_temp_digit_10),
        .digit_100(w_humi_digit_1),
        .digit_1000(w_humi_digit_10),
        .digit_5(4'hf),
        .digit_6(4'hf),
        .digit_7(w_dot_data),
        .digit_8(4'hf),
        .sel(w_sel),
        .bcd(w_temphumi)
    );


    bcd_decoder U_BCD_DOCODER (
        .bcd(w_temphumi),
        .fnd_data(fnd_data)
    );
    
endmodule


module dht11_clk_div_1khz (
    input  clk,
    input  reset,
    output o_clk_1khz
);
    // counter 100_000
    // $clog2 는 system에서 제공하는 task
    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk_1khz;
    assign o_clk_1khz = r_clk_1khz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            r_clk_1khz <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter  <= 0;
                r_clk_1khz <= 1;
            end else begin
                r_counter  <= r_counter + 1;
                r_clk_1khz <= 1'b0;
            end
        end
    end

endmodule

module w_sw_counter_8 (
    input        clk,
    input        reset,
    output [2:0] sel
);

    reg [2:0] counter;
    assign sel = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            // intial
            counter <= 0;
        end else begin
            // operation
            counter <= counter + 1;
        end
    end

endmodule

module decoder_2x4 (
    input  [1:0] sel,
    output [3:0] fnd_com
);

    assign fnd_com = (sel == 2'b00) ? 4'b1110 :
                     (sel == 2'b01) ? 4'b1101 :
                     (sel == 2'b10) ? 4'b1011 :
                     (sel == 2'b11) ? 4'b0111 : 4'b1111;

endmodule


module w_sw_mux_8x1 (
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_5,
    input [3:0] digit_6,
    input [3:0] digit_7,  // dot display
    input [3:0] digit_8,
    input [2:0] sel,
    output [3:0] bcd
);

    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000:  r_bcd = digit_1;
            3'b001:  r_bcd = digit_10;
            3'b010:  r_bcd = digit_100;
            3'b011:  r_bcd = digit_1000;
            3'b100:  r_bcd = digit_5;
            3'b101:  r_bcd = digit_6;
            3'b110:  r_bcd = digit_7;
            3'b111:  r_bcd = digit_8;
            default: r_bcd = digit_1;
        endcase
    end
endmodule


module dht11_digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] count_data,
    output [          3:0] digit_1,
    output [          3:0] digit_10
);
    assign digit_1  = count_data % 10;
    assign digit_10 = (count_data / 10) % 10;
endmodule



module bcd_decoder (
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);
    always @(bcd) begin
        case (bcd)
            4'b0000: fnd_data = 8'hc0;
            4'b0001: fnd_data = 8'hF9;
            4'b0010: fnd_data = 8'hA4;
            4'b0011: fnd_data = 8'hB0;
            4'b0100: fnd_data = 8'h99;
            4'b0101: fnd_data = 8'h92;
            4'b0110: fnd_data = 8'h82;
            4'b0111: fnd_data = 8'hF8;
            4'b1000: fnd_data = 8'h80;
            4'b1001: fnd_data = 8'h90;
            4'b1010: fnd_data = 8'h88;
            4'b1011: fnd_data = 8'h83;
            4'b1100: fnd_data = 8'hc6;
            4'b1101: fnd_data = 8'hA1;
            4'b1110: fnd_data = 8'h7f;  // only dot display
            4'b1111: fnd_data = 8'hff;  // all off
            default: fnd_data = 8'hff;
        endcase
    end
endmodule
