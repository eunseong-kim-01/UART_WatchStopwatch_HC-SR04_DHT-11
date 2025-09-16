module fpga_cu (
    input [4:0] sw,
    output reg start_watch,
    output reg start_sr,
    output reg start_dht
);

    always @(*) begin
        start_watch = 0;
        start_sr = 0;
        start_dht = 0;

        if (sw[4]) begin
            start_dht = 1;
        end else if (sw[3]) begin
            start_sr  = 1;
        end else if (sw[2]) begin
            start_watch = 1;
        end
    end
endmodule
// module fpga_cu (
//     input        clk,
//     input        rst,
//     input  [4:0] sw,
//     output       start_watch,
//     output       start_sr,
//     output       start_dht
// );

//     reg start_watch_reg, start_watch_next;
//     reg start_sr_reg, start_sr_next;
//     reg start_dht_reg, start_dht_next;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             start_watch_reg <= 0;
//             start_sr_reg <= 0;
//             start_dht_reg <= 0;
//         end else begin
//             start_watch_reg <= start_watch_next;
//             start_sr_reg <= start_sr_next;
//             start_dht_reg <= start_dht_next;
//         end
//     end

//     always @(*) begin
//         start_watch_next = start_watch_reg;
//         start_sr_next = start_sr_reg;
//         start_dht_next = start_dht_reg;
//         if (sw[4]) begin
//             start_dht_next = 1'b1;
//         end else if (sw[3]) begin
//             start_sr_next = 1'b1;
//         end else if (sw[2]) begin
//             start_watch_next = 1'b1;
//         end
//     end

//     assign start_watch = start_watch_reg;
//     assign start_sr = start_sr_reg;
//     assign start_dht = start_dht_reg;

// endmodule
