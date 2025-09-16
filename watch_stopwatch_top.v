`timescale 1ns / 1ps

module watch_stopwatch_top (
    input        clk,
    input        rst,
    input        enable,
    input        Btn_L,
    input        Btn_U,
    input        Btn_D,
    input        Btn_R,
    input  [1:0] sw,
    input        rx,
    output       tx,
    output [7:0] fnd,
    output [3:0] fnd_com
);
    wire cmd_runstop_w, cmd_clear_w;
    wire cmd_s_up, cmd_m_up, cmd_h_up;
    wire cmd_mode;

    wire w_btn_u_w, w_btn_d_w, w_btn_l_w;
    wire w_btn_r_s, w_btn_l_s;

    assign Btn_L_sw   = w_btn_l_s | cmd_clear_w;
    assign Btn_R_sw   = w_btn_r_s | cmd_runstop_w;

    assign watch_s_up = w_btn_d_w | cmd_s_up;
    assign watch_m_up = w_btn_u_w | cmd_m_up;
    assign watch_h_up = w_btn_l_w | cmd_h_up;

    w_sw_uart_top u_w_sw_uart_top (
        .clk    (clk),
        .rst    (rst | ~enable),
        .rx     (rx),
        .runstop(cmd_runstop_w),
        .clear  (cmd_clear_w),
        .tx     (tx),
        .s_up   (cmd_s_up),
        .m_up   (cmd_m_up),
        .h_up   (cmd_h_up),
        .mode   (cmd_mode)
    );


    clock_top u_clock_top (
        .clk        (clk),
        .rst        (rst | ~enable),
        .sw0        (enable ? sw[0] : 1'b0),
        .sw1        (enable ? sw[1] : 1'b0),
        .Btn_L_watch(enable ? watch_h_up : 1'b0),
        .Btn_L_sw   (enable ? Btn_L_sw : 1'b0),
        .Btn_U      (enable ? watch_m_up : 1'b0),
        .Btn_D      (enable ? watch_s_up : 1'b0),
        .Btn_R      (enable ? Btn_R_sw : 1'b0),
        .uart_mode  (enable ? (cmd_mode | sw[1]) : 1'b0),
        .fnd_com    (fnd_com),
        .fnd        (fnd)
    );

    w_sw_button_debounce u_button_debounce_R (
        .clk  (clk),
        .rst  (rst | ~enable),
        .i_btn(Btn_R),
        .o_btn(w_btn_r_s)
    );

    w_sw_button_debounce u_button_debounce_L_stopwatch (
        .clk  (clk),
        .rst  (rst | ~enable),
        .i_btn(Btn_L),
        .o_btn(w_btn_l_s)
    );

    w_sw_button_debounce u_button_debounce_U (
        .clk  (clk),
        .rst  (rst | ~enable),
        .i_btn(Btn_U),
        .o_btn(w_btn_u_w)
    );

    w_sw_button_debounce u_button_debounce_D (
        .clk  (clk),
        .rst  (rst | ~enable),
        .i_btn(Btn_D),
        .o_btn(w_btn_d_w)
    );

    w_sw_button_debounce u_button_debounce_L_watch (
        .clk  (clk),
        .rst  (rst | ~enable),
        .i_btn(Btn_L),
        .o_btn(w_btn_l_w)
    );

endmodule



module w_sw_uart_top (
    input  clk,
    input  rst,
    input  rx,
    output runstop,
    output clear,
    output s_up,
    output m_up,
    output h_up,
    output mode,
    output tx
);

    wire w_b_tick, w_start;
    wire rx_done;
    wire [7:0] w_rx_data, w_rx_fifo_popdata, w_tx_fifo_popdata;
    wire w_rx_empty;
    wire w_tx_fifo_full;
    wire w_tx_fifo_empty;
    wire w_tx_busy;


    fifo U_RX_FIFO (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_data),
        .push     (rx_done),
        .pop      (~w_tx_fifo_full),
        .pop_data (w_rx_fifo_popdata),
        .full     (),
        .empty    (w_rx_empty)
    );

    fifo U_TX_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(w_rx_fifo_popdata),
        .push(~w_rx_empty),
        .pop(~w_tx_busy),
        .pop_data(w_tx_fifo_popdata),
        .full(w_tx_fifo_full),
        .empty(w_tx_fifo_empty)
    );


    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .start_trigger(~w_tx_fifo_empty),
        .tx_data(w_tx_fifo_popdata),
        .b_tick(w_b_tick),
        .tx(tx),
        .tx_busy(w_tx_busy)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(rx_done)
    );

    w_sw_baud_tick_gen U_w_sw_baud_tick_gen (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );

    w_sw_command_cu u_w_sw_command_cu (
        .clk(clk),
        .rst(rst),
        .rx_trigger(~w_rx_empty),
        .rx_fifo_data(w_rx_fifo_popdata),
        .runstop(runstop),
        .clear(clear),
        .s_up(s_up),
        .m_up(m_up),
        .h_up(h_up),
        .mode(mode)
    );


endmodule

module w_sw_baud_tick_gen (
    input  clk,
    input  rst,
    output b_tick
);

    // baudrate
    parameter BAUDRATE = 9600 * 16;

    localparam BAUD_count = 100_000_100 / BAUDRATE;
    reg [$clog2(BAUD_count)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    // output
    assign b_tick = tick_reg;

    //SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg    <= tick_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        tick_next    = tick_reg;
        if (counter_reg == BAUD_count - 1) begin
            counter_next = 0;
            tick_next = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next = 1'b0;

        end
    end


endmodule


`timescale 1ns / 1ps

module w_sw_command_cu (
    input        clk,
    input        rst,
    input  [7:0] rx_fifo_data,
    input        rx_trigger,
    output       runstop,
    output       clear,
    output       s_up,
    output       m_up,
    output       h_up,
    output       mode
);

    reg runstop_reg, runstop_next;
    reg clear_reg, clear_next;
    reg s_up_reg, s_up_next;
    reg m_up_reg, m_up_next;
    reg h_up_reg, h_up_next;
    reg mode_reg, mode_next;

    assign runstop = runstop_reg;
    assign clear   = clear_reg;
    assign s_up    = s_up_reg;
    assign m_up    = m_up_reg;
    assign h_up    = h_up_reg;
    assign mode    = mode_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            runstop_reg <= 1'b0;
            clear_reg   <= 1'b0;
            s_up_reg    <= 1'b0;
            m_up_reg    <= 1'b0;
            h_up_reg    <= 1'b0;
            mode_reg    <= 1'b0;
        end else begin
            runstop_reg <= runstop_next;
            clear_reg <= clear_next;
            s_up_reg <= s_up_next;
            m_up_reg <= m_up_next;
            h_up_reg <= h_up_next;
            mode_reg <= mode_next;
        end
    end

    always @(*) begin
        runstop_next = 1'b0;
        clear_next   = 1'b0;
        s_up_next    = 1'b0;
        m_up_next    = 1'b0;
        h_up_next    = 1'b0;
        mode_next    = mode_reg;
        if (rx_trigger) begin
            case (rx_fifo_data)
                8'h52: begin  //stopwatch_start
                    runstop_next = 1'b1;
                end
                8'h43: begin  //stopwatch_clear
                    clear_next = 1'b1;
                end
                8'h73: begin  //watch_sex
                    s_up_next = 1'b1;
                end
                8'h6D: begin  //watch_min
                    m_up_next = 1'b1;
                end
                8'h68: begin  //watch_hour
                    h_up_next = 1'b1;
                end
                8'h4D: begin
                    mode_next  = ~mode_reg;
                    clear_next = 1'b1;
                end
            endcase
        end
    end
endmodule


module w_sw_button_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);

    reg [$clog2(100)-1:0] counter_reg;
    reg clk_reg;
    reg [7:0] q_reg, q_next;
    reg  edge_reg;
    wire debounce;

    //clock divider
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            clk_reg <= 1'b0;
        end else begin
            if (counter_reg == 99) begin
                counter_reg <= 0;
                clk_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                clk_reg <= 1'b0;
            end
        end
    end

    //debounce, shift register
    always @(posedge clk_reg, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end
    // serial input, paraller output shift register
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};
    end
    // 4input AND
    assign debounce = &q_reg;
    //Q5 output
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    //edge output
    assign o_btn = ~edge_reg & debounce;

endmodule
