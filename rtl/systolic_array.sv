`timescale 1ns/1ps
import systolic_pkg::*;

module systolic_array #(
    parameter int N = 2,
    parameter int DATA_W = 16,
    parameter int ACC_W  = 32,
    parameter dataflow_t DATAFLOW = OS
)(
    input  logic clk,
    input  logic reset,
    input  logic preload_done,

    input  logic signed [DATA_W-1:0] a_in [N],
    input  logic signed [DATA_W-1:0] b_in [N],

    output logic signed [DATA_W-1:0] a_out [N],
    output logic signed [DATA_W-1:0] b_out [N],
    output logic signed [ACC_W-1:0]  result [N][N],

    // for debugging
    output logic signed [DATA_W-1:0] dbg_a [N][N],
    output logic signed [DATA_W-1:0] dbg_b [N][N],
    output logic signed [ACC_W-1:0]  dbg_psum [N][N],
    output logic                      dbg_enable_mac [N][N]
);

    // interconnect
    logic signed [DATA_W-1:0] a_wire [N][N];
    logic signed [DATA_W-1:0] b_wire [N][N];
    logic signed [ACC_W-1:0]  psum_wire [N][N];

    // control tap matrix
    logic load_a [N][N];
    logic load_b [N][N];
    logic hold_a [N][N];
    logic hold_b [N][N];
    logic enable_mac [N][N];

    // storage accumulation buffers
    logic signed [ACC_W-1:0] pe_result [N][N];
    logic signed [ACC_W-1:0] result_reg [N][N];

    // array control
    controller #(
        .N(N),
        .DATAFLOW(DATAFLOW)
    ) ctrl (
        .clk(clk),
        .reset(reset),
        .preload_done(preload_done),
        .load_a(load_a),
        .load_b(load_b),
        .hold_a(hold_a),
        .hold_b(hold_b),
        .enable_mac(enable_mac)
    );

    // pe grid
    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin : ROWS
            for (j = 0; j < N; j++) begin : COLS
                
                logic signed [ACC_W-1:0] current_psum_in;
                
                // mux logic for tracking stationary accumulations
                always_comb begin
                    if (DATAFLOW == WS) begin
                        current_psum_in = (i == 0) ? 32'sd0 : psum_wire[i-1][j];
                    end else if (DATAFLOW == IS) begin
                        current_psum_in = (j == 0) ? 32'sd0 : psum_wire[i][j-1];
                    end else begin
                        current_psum_in = 32'sd0;
                    end
                end

                pe #(
                    .DATA_W(DATA_W),
                    .ACC_W(ACC_W),
                    .DATAFLOW(DATAFLOW)
                ) PE_INST (
                    .clk(clk),
                    .reset(reset),
                    .a_in((j == 0) ? a_in[i] : a_wire[i][j-1]),
                    .b_in((i == 0) ? b_in[j] : b_wire[i-1][j]),
                    .psum_in(current_psum_in),
                    
                    .a_out(a_wire[i][j]),
                    .b_out(b_wire[i][j]),
                    .psum_out(psum_wire[i][j]),
                    .result_out(pe_result[i][j]),

                    .load_a(load_a[i][j]),
                    .load_b(load_b[i][j]),
                    .hold_a(hold_a[i][j]),
                    .hold_b(hold_b[i][j]),
                    .enable_mac(enable_mac[i][j])
                );

                assign dbg_a[i][j] = a_wire[i][j];
                assign dbg_b[i][j] = b_wire[i][j];
                assign dbg_psum[i][j] = pe_result[i][j];
                assign dbg_enable_mac[i][j] = enable_mac[i][j];
            end
        end
    endgenerate

    // bound output driving links
    generate
        for (i = 0; i < N; i++) begin : OUTPUT_DRIVERS
            assign a_out[i] = a_wire[i][N-1];
            assign b_out[i] = b_wire[N-1][i];
        end
    endgenerate

    // active processing cycle meter
    int compute_cycle;
    always_ff @(posedge clk) begin
        if (reset || !preload_done) begin
            compute_cycle <= 0;
        end else begin
            compute_cycle <= compute_cycle + 1;
        end
    end

    // output matrix
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int r = 0; r < N; r++) begin
                for (int c = 0; c < N; c++) begin
                    result_reg[r][c] <= 32'sd0;
                end
            end
        end else begin
            for (int r = 0; r < N; r++) begin
                for (int c = 0; c < N; c++) begin
                    if (DATAFLOW == OS) begin
                        result_reg[r][c] <= pe_result[r][c];
                    end 
                    else if (DATAFLOW == WS) begin
                        if (preload_done && (compute_cycle == (r + c + N))) begin
                            result_reg[r][c] <= psum_wire[N-1][c];
                        end
                    end 
                    else if (DATAFLOW == IS) begin
                        if (preload_done && (compute_cycle == (r + c + N))) begin
                            result_reg[r][c] <= psum_wire[r][N-1];
                        end
                    end
                end
            end
        end
    end

    assign result = result_reg;

endmodule