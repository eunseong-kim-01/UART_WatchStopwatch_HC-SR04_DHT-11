`timescale 1ns / 1ps

module stopwatch_cu (
    input  clk,
    input  rst,
    input  in_runstop,
    input  in_clear,
    output out_runstop,
    output out_clear
);
    //state define
    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;
    reg [1:0] cur_state, next_state;
    reg runstop_reg, runstop_next;
    reg clear_reg, clear_next;

    //state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cur_state   <= STOP;
            runstop_reg <= 1'b0;
            clear_reg   <= 1'b0;
        end else begin
            cur_state   <= next_state;
            runstop_reg <= runstop_next;
            clear_reg   <= clear_next;
        end
    end

    assign out_runstop = runstop_reg;
    assign out_clear   = clear_reg;

    //next combinational logic
    always @(*) begin
        next_state   = cur_state;
        runstop_next = runstop_reg;
        clear_next   = clear_reg;
        case (cur_state)
            STOP: begin
                //moore output
                runstop_next = 1'b0;
                clear_next   = 1'b0;
                //next state
                if (in_clear == 1) begin
                    next_state = CLEAR;
                end else if (in_runstop == 1) begin
                    next_state = RUN;
                end
            end
            RUN: begin
                runstop_next = 1'b1;
                if (in_runstop == 1) begin
                    next_state = STOP;
                end
            end
            CLEAR: begin
                clear_next = 1'b1;
                next_state = STOP;
            end
        endcase
    end


endmodule
