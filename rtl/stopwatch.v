`timescale 1ns / 1ps
module stopwatch (
    input        clk,
    input        rst,
    input        sw_0,
    input        Btn_L,
    input        Btn_R,
    output [3:0] fnd_com,
    output [7:0] fnd
);

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;
    wire w_runstop, w_clear;


    w_sw_fnd_controller u_w_sw_fnd_controller (
        .clk(clk),
        .reset(rst),
        .sw0(sw_0),
        .i_time({w_hour, w_min, w_sec, w_msec}),
        .fnd_com(fnd_com),
        .fnd(fnd)
    );

    stopwatch_cu u_stopwatch_cu (
        .clk(clk),
        .rst(rst),
        .in_runstop(Btn_R),
        .in_clear(Btn_L),
        .out_runstop(w_runstop),
        .out_clear(w_clear)
    );

    stopwatch_dp u_stopwatch_dp (
        .clk(clk),
        .rst(rst),
        .i_runstop(w_runstop),
        .i_clear(w_clear),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );



endmodule


`timescale 1ns / 1ps

module w_sw_fnd_controller (
    input         clk,
    input         reset,
    input         sw0,
    input  [23:0] i_time,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd
);

    wire [3:0] w_msec_digit_1;
    wire [3:0] w_msec_digit_10;

    wire [3:0] w_sec_digit_1;
    wire [3:0] w_sec_digit_10;

    wire [3:0] w_min_digit_1;
    wire [3:0] w_min_digit_10;

    wire [3:0] w_hour_digit_1;
    wire [3:0] w_hour_digit_10;

    wire [3:0] w_counter0;
    wire [3:0] w_counter1;
    wire [3:0] w_counter;
    wire [2:0] w_sel;
    wire [3:0] w_dot_data;
    wire w_clk_1khz;

    w_sw_clk_div_1khz u_w_sw_clk_div_1khz (
        .clk(clk),
        .reset(reset),
        .o_clk_1khz(w_clk_1khz)
    );

    counter_8 u_counter_8 (
        .clk  (w_clk_1khz),
        .reset(reset),
        .sel  (w_sel)
    );

    w_sw_decorder_2x4 u_w_sw_decorder_2x4 (
        .sel(w_sel[2:0]),
        .fnd_com(fnd_com)
    );
    //우선순위, 경로의 길이 차이 존재
    //logic 부분에서는 차이X

    w_sw_digit_splitter #(
        .BIT_WIDTH(7)
    ) u_msec_ds (
        .bcd_data(i_time[6:0]),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    w_sw_digit_splitter #(
        .BIT_WIDTH(6)
    ) u_sec_ds (
        .bcd_data(i_time[12:7]),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

    w_sw_digit_splitter #(
        .BIT_WIDTH(6)
    ) u_min_ds (
        .bcd_data(i_time[18:13]),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );

    w_sw_digit_splitter #(
        .BIT_WIDTH(5)
    ) u_hour_ds (
        .bcd_data(i_time[23:19]),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    mux_8x1 u_mux_8x1_Msec_Sec (
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10),
        .digit_100(w_sec_digit_1),
        .digit_1000(w_sec_digit_10),
        .digit_5(4'hf),
        .digit_6(4'hf),
        .digit_7(w_dot_data),
        .digit_8(4'hf),
        .sel(w_sel),
        .bcd(w_counter0)
    );

    mux_8x1 u_mux_8x1_Min_Hour (
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10),
        .digit_100(w_hour_digit_1),
        .digit_1000(w_hour_digit_10),
        .digit_5(4'hf),
        .digit_6(4'hf),
        .digit_7(w_dot_data),
        .digit_8(4'hf),
        .sel(w_sel),
        .bcd(w_counter1)
    );

    mux_2x1 u_mux_2x1 (
        .mode0(w_counter0),
        .mode1(w_counter1),
        .sw0(sw0),
        .y(w_counter)
    );

    w_sw_bcd_decorder u_w_sw_bcd_decorder (
        .bcd(w_counter),
        .fnd(fnd)
    );

    comparator_msec u_comparator_msec(
        .msec(i_time[6:0]),
        .dot_data(w_dot_data)
    );

endmodule


module w_sw_clk_div_1khz (
    input  clk,
    input  reset,
    output o_clk_1khz
);  //counter 100,000
    reg [$clog2(100000)-1:0] r_counter;
    //$clog2는 system에서 제공하는 task(함수같은거 인듯)
    reg r_clk_1khz;
    assign o_clk_1khz = r_clk_1khz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            r_clk_1khz <= 1'b0;
        end else begin
            if (r_counter == 100000 - 1) begin
                r_counter  <= 0;
                r_clk_1khz <= 1'b1;
            end else begin
                r_counter  <= r_counter + 1;
                r_clk_1khz <= 1'b0;
            end
        end
    end

endmodule

module counter_8 (
    input        clk,
    input        reset,
    output [2:0] sel
);

    reg [2:0] counter;
    assign sel = counter;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            //initial
            counter <= 0;
        end else begin
            //operation
            counter <= counter + 1;
        end
    end

endmodule

module w_sw_digit_splitter #(
    parameter BIT_WIDTH = 7
) (

    input [BIT_WIDTH-1:0] bcd_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1  = bcd_data % 10;
    assign digit_10 = (bcd_data / 10) % 10;

endmodule

module w_sw_decorder_2x4 (
    input  [1:0] sel,
    output [3:0] fnd_com
);

    assign fnd_com = (sel==2'b00)?4'b1110:
                    (sel==2'b01)?4'b1101:
                    (sel==2'b10)?4'b1011:
                    (sel==2'b11)?4'b0111:4'b1111;

endmodule

module mux_8x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [3:0] digit_5,
    input  [3:0] digit_6,
    input  [3:0] digit_7, //dot display
    input  [3:0] digit_8,
    input  [2:0] sel,
    output [3:0] bcd
);

    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000:   r_bcd = digit_1;
            3'b001:   r_bcd = digit_10;
            3'b010:   r_bcd = digit_100;
            3'b011:   r_bcd = digit_1000;
            3'b100:   r_bcd = digit_5;
            3'b101:   r_bcd = digit_6;
            3'b110:   r_bcd = digit_7;
            3'b111:   r_bcd = digit_8;
            default: r_bcd = digit_1;
        endcase
    end

endmodule

module mux_2x1 (
    input  [3:0] mode0,
    input  [3:0] mode1,
    input        sw0,
    output [3:0] y
);
    assign y = (sw0 == 1) ? mode1 : mode0;
endmodule

module comparator_msec (
    input [6:0] msec,
    output [3:0] dot_data
 );
    assign dot_data = (msec <= 50) ? 4'hf :4'he;
    
endmodule

module w_sw_bcd_decorder (
    input [3:0] bcd,
    output reg [7:0] fnd
);

    always @(bcd) begin
        case (bcd)
            4'b0000: fnd = 8'hC0;
            4'b0001: fnd = 8'hF9;
            4'b0010: fnd = 8'hA4;
            4'b0011: fnd = 8'hB0;
            4'b0100: fnd = 8'h99;
            4'b0101: fnd = 8'h92;
            4'b0110: fnd = 8'h82;
            4'b0111: fnd = 8'hF8;
            4'b1000: fnd = 8'h80;
            4'b1001: fnd = 8'h90;
            4'b1010: fnd = 8'h88;
            4'b1011: fnd = 8'h83;
            4'b1100: fnd = 8'hC6;
            4'b1101: fnd = 8'hA1;
            4'b1110: fnd = 8'h7F; //only dot display
            4'b1111: fnd = 8'hFF; // all off
            default: fnd = 8'hFF;
        endcase
    end

endmodule

//sel 대신 자동 선택기를 만들기위해
