`timescale 1ns/1ps
import systolic_pkg::*;

module controller #(
    parameter int N = 2,
    parameter dataflow_t DATAFLOW = OS
)(
    input logic clk,
    input logic reset,
    input logic preload_done,

    output logic load_a     [N][N],
    output logic load_b     [N][N],
    output logic hold_a     [N][N],
    output logic hold_b     [N][N],
    output logic enable_mac [N][N]
);

    integer i,j;

    always_comb begin

        for(i=0;i<N;i++) begin
            for(j=0;j<N;j++) begin
                load_a[i][j] = 0;
                load_b[i][j] = 0;
                hold_a[i][j] = 0;
                hold_b[i][j] = 0;
                enable_mac[i][j] = 0;
            end
        end

        case(DATAFLOW)

            OS: begin
                for(i=0;i<N;i++)
                    for(j=0;j<N;j++) begin
                        load_a[i][j] = 1;
                        load_b[i][j] = 1;
                        enable_mac[i][j] = 1;
                    end
            end

            WS: begin
                if(!preload_done) begin
                    // load weights (B)
                    for(i=0;i<N;i++)
                        for(j=0;j<N;j++) begin
                            load_b[i][j] = 1;
                            hold_b[i][j] = 0;
                            load_a[i][j] = 0;
                            hold_a[i][j] = 1;
                            enable_mac[i][j] = 0;
                        end
                end
                else begin
                    // stream activations (A)
                    for(i=0;i<N;i++)
                        for(j=0;j<N;j++) begin
                            load_a[i][j] = 1;
                            hold_a[i][j] = 0;
                            load_b[i][j] = 0;
                            hold_b[i][j] = 1;
                            enable_mac[i][j] = 1;
                        end
                end
            end

            IS: begin
                if(!preload_done) begin
                    // load activations (A)
                    for(i=0;i<N;i++)
                        for(j=0;j<N;j++) begin
                            load_a[i][j] = 1;
                            hold_a[i][j] = 0;
                            load_b[i][j] = 0;
                            hold_b[i][j] = 1;
                            enable_mac[i][j] = 0;
                        end
                end
                else begin
                    // stream weights (B)
                    for(i=0;i<N;i++)
                        for(j=0;j<N;j++) begin
                            load_b[i][j] = 1;
                            hold_b[i][j] = 0;
                            load_a[i][j] = 0;
                            hold_a[i][j] = 1;
                            enable_mac[i][j] = 1;
                        end
                end
            end

            default: begin
            end

        endcase
    end

endmodule