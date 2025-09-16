`timescale 1ns / 1ps

module uart_tx (
    input        clk,
    input        rst,
    input        start_trigger,
    input  [7:0] tx_data,
    input        b_tick,
    output       tx,
    output       tx_busy
);
    //FSM
    localparam [2:0] IDLE = 3'h0, WAIT = 3'h1, START = 3'h2, DATA = 3'h3, STOP = 3'h4;

    reg [2:0] cur_state, next_state;
    reg tx_reg, tx_next;
    reg [2:0] bit_count, bit_count_next;
    reg [3:0] b_tick_cnt, b_tick_cnt_next;
    //tx internal buffer
    reg [7:0] data_reg, data_next;
    // Tx_busy
    reg tx_busy_reg, tx_busy_next;

    //state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cur_state <= IDLE;
            tx_reg <= 1'b1;  //idle output high
            bit_count <= 3'h0;
            data_reg <= 0;
            tx_busy_reg <= 0;
            b_tick_cnt <= 0;
        end else begin
            cur_state <= next_state;
            tx_reg <= tx_next;
            bit_count <= bit_count_next;
            data_reg <= data_next;
            tx_busy_reg <= tx_busy_next;
            b_tick_cnt <= b_tick_cnt_next;
        end
    end

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;

    always @(*) begin
        next_state = cur_state;
        tx_next = tx_reg;
        bit_count_next = bit_count;
        data_next = data_reg;
        tx_busy_next = tx_busy_reg;
        b_tick_cnt_next = b_tick_cnt;
        case (cur_state)
            IDLE: begin
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                if (start_trigger == 1) begin
                    tx_busy_next = 1'b1;
                    data_next = tx_data;
                    next_state   = WAIT;
                end
            end
            WAIT: begin
                if (b_tick == 1) begin
                    b_tick_cnt_next = 0;
                    next_state = START;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (b_tick == 1) begin
                    if (b_tick_cnt == 15) begin
                        bit_count_next = 0;
                        b_tick_cnt_next = 0;
                        next_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_reg[0];
                if (b_tick == 1) begin
                    if (b_tick_cnt == 15) begin
                        b_tick_cnt_next = 0;
                        if (bit_count == 7) begin
                            next_state = STOP;
                        end else begin
                            b_tick_cnt_next = 0;
                            bit_count_next = bit_count + 1;
                            data_next = data_reg >> 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (b_tick == 1) begin
                    if (b_tick_cnt == 15) begin
                        tx_busy_next = 1'b0;
                        next_state   = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
        endcase
    end

endmodule
