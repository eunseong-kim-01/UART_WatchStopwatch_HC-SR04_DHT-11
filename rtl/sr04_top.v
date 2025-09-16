`timescale 1ns / 1ps

module sr04_top (
    input        clk,
    input        rst,
    input        echo,
    input        Btn_R,
    input        rx,
    input        enable,
    output       trig,
    output [3:0] fnd_com,
    output [7:0] fnd,
    output       tx
);

    wire w_start;
    wire w_tick_1us;
    wire [11:0] w_o_dist;
    wire w_uart_start;
    wire w_tx_done;
    wire w_start_send;

    assign start_cmd = enable && (w_start || w_uart_start);

    uart_top u_uart_top (
        .clk(clk),
        .rst(rst | ~enable),
        .rx(rx),
        .start_send(w_start_send),
        .i_send_data(w_o_dist),
        .uart_start(w_uart_start),
        .tx(tx)
    );


    tick_gen_1us u_tick_gen_1us (
        .clk(clk),
        .rst(rst | ~enable),
        .o_tick_1us(w_tick_1us)
    );

    sr04_controller u_sr04_controller (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_1us),
        .start(start_cmd),
        .echo(echo),
        .o_trig(trig),
        .start_send(w_start_send),
        .o_dist(w_o_dist)
    );

    fnd_controller u_fnd_controller (
        .clk(clk),
        .reset(reset | ~enable),
        .counter(w_o_dist),
        .fnd_com(fnd_com),
        .fnd(fnd)
    );

    button_debounce u_button_debounce (
        .clk  (clk),
        .rst(rst | ~enable),
        .i_btn(Btn_R),
        .o_btn(w_start)
    );


endmodule


module sr04_controller (
    input         clk,
    input         rst,
    input         i_tick,
    input         start,
    input         echo,
    output        o_trig,
    output [11:0] o_dist,
    output        start_send
);
    reg [1:0] state, next;
    reg [15:0] tick_cnt_reg, tick_cnt_next;
    reg [$clog2(400*58)-1:0] dist_reg, dist_next;
    reg [11:0] dist_div_reg, dist_mul_reg;
    reg trig_reg, trig_next;
    reg start_send_reg, start_send_next;
    parameter IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, DIST = 2'b11;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            tick_cnt_reg <= 0;
            trig_reg <= 0;
            dist_reg <= 0;
            start_send_reg <= 0;
            dist_div_reg <= 0;
            dist_mul_reg <= 0;
        end else begin
            state <= next;
            trig_reg <= trig_next;
            dist_reg <= dist_next;
            dist_div_reg <= dist_reg / 58;
            tick_cnt_reg <= tick_cnt_next;
            start_send_reg <= start_send_next;
        end
    end

    assign o_dist = dist_div_reg;
    assign o_trig = trig_reg;
    assign start_send = start_send_reg;

    always @(*) begin
        next = state;
        dist_next = dist_reg;
        trig_next = trig_reg;
        tick_cnt_next = tick_cnt_reg;
        start_send_next = start_send_reg;
        case (state)
            IDLE: begin
                start_send_next = 0;
                tick_cnt_next   = 0;
                if (start) begin
                    next = START;
                end
            end
            START: begin
                trig_next = 1'b1;
                if (i_tick) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 10) begin
                        next = WAIT;
                        tick_cnt_next = 0;
                    end
                end
            end
            WAIT: begin
                trig_next = 1'b0;
                if (i_tick) begin
                    if (echo) begin
                        next = DIST;
                    end
                end
            end
            DIST: begin
                if (i_tick) begin
                    if (echo) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                    if (!echo) begin
                        dist_next = tick_cnt_reg;
                        start_send_next = 1'b1;
                        next = IDLE;
                    end
                end
            end
        endcase
    end
endmodule



module tick_gen_1us (
    input  clk,
    input  rst,
    output o_tick_1us
);

    localparam US_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(US_COUNT)-1:0] counter_reg;
    reg tick_1us;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_1us <= 0;
        end else begin
            if (counter_reg == US_COUNT - 1) begin
                counter_reg <= 0;
                tick_1us <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                tick_1us <= 1'b0;
            end
        end
    end

    assign o_tick_1us = tick_1us;

endmodule





