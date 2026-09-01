`timescale 1ns/1ps
import systolic_pkg::*;

module matrix_feeder #(
    parameter int N = 2,
    parameter int DATA_W = 16,
    parameter dataflow_t DATAFLOW = OS
)(
    input  logic clk,
    input  logic reset,
    input  logic start,

    input  logic signed [DATA_W-1:0] A [N][N],
    input  logic signed [DATA_W-1:0] B [N][N],

    output logic signed [DATA_W-1:0] a_out [N],
    output logic signed [DATA_W-1:0] b_out [N],

    output logic valid,
    output logic done,
    output logic preload_done
);

    logic running;
    integer cycle;
    int total_compute_cycles;

    assign total_compute_cycles = (3 * N) - 2;

    always_ff @(posedge clk) begin
        if (reset) begin
            running      <= 1'b0;
            cycle        <= 0;
            done         <= 1'b0;
            preload_done <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !running) begin
                running      <= 1'b1;
                cycle        <= 0;
                preload_done <= (DATAFLOW == OS) ? 1'b1 : 1'b0; 
            end else if (running) begin
                if (!preload_done) begin
                    if (cycle == N - 1) begin
                        preload_done <= 1'b1;
                        cycle        <= 0;
                    end else begin
                        cycle <= cycle + 1;
                    end
                end else begin
                    if (cycle == total_compute_cycles - 1) begin
                        running <= 1'b0;
                        done    <= 1'b1;
                    end else begin
                        cycle <= cycle + 1;
                    end
                end
            end
        end
    end

    assign valid = running && preload_done;

    always_comb begin
        for (int i = 0; i < N; i++) begin
            a_out[i] = '0;
            b_out[i] = '0;

            if (running) begin
                case (DATAFLOW)
                    OS: begin
                        if ((cycle - i >= 0) && (cycle - i < N)) begin
                            a_out[i] = A[i][cycle - i];
                            b_out[i] = B[cycle - i][i];
                        end
                    end

                    WS: begin
                        if (!preload_done) begin
                            b_out[i] = B[(N - 1) - cycle][i]; 
                        end else begin
                            if ((cycle - i >= 0) && (cycle - i < N)) begin
                                a_out[i] = A[cycle - i][i];   
                            end
                        end
                    end

                    IS: begin
                        if (!preload_done) begin
                            a_out[i] = A[i][(N - 1) - cycle]; 
                        end else begin
                            if ((cycle - i >= 0) && (cycle - i < N)) begin
                                b_out[i] = B[i][cycle - i];   
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule
