`timescale 1ns/1ps
import systolic_pkg::*;

module pe #(
    parameter int DATA_W = 16,
    parameter int ACC_W  = 32,
    parameter dataflow_t DATAFLOW = OS
)(
    input  logic clk,
    input  logic reset,
    
    // data streams
    input  logic signed [DATA_W-1:0] a_in,
    input  logic signed [DATA_W-1:0] b_in,
    input  logic signed [ACC_W-1:0]  psum_in, 

    output logic signed [DATA_W-1:0] a_out,
    output logic signed [DATA_W-1:0] b_out,
    output logic signed [ACC_W-1:0]  psum_out, 
    output logic signed [ACC_W-1:0]  result_out,

    // control paths
    input  logic load_a,
    input  logic load_b,
    input  logic hold_a,
    input  logic hold_b,
    input  logic enable_mac
);

    logic signed [DATA_W-1:0] a_reg;
    logic signed [DATA_W-1:0] b_reg;
    logic signed [ACC_W-1:0]  psum_reg;

    logic signed [DATA_W-1:0] mult_a;
    logic signed [DATA_W-1:0] mult_b;

    assign mult_a = hold_a ? a_reg : a_in;
    assign mult_b = hold_b ? b_reg : b_in;

    always_ff @(posedge clk) begin
        if (reset) begin
            a_reg    <= '0;
            b_reg    <= '0;
            psum_reg <= '0;
        end else begin
            if (load_a && !hold_a) a_reg <= a_in;
            if (load_b && !hold_b) b_reg <= b_in;

            if (enable_mac) begin
                if (DATAFLOW == WS || DATAFLOW == IS) begin
                    // spatial modes use the incoming partial sum bus
                    psum_reg <= psum_in + (ACC_W'(mult_a) * ACC_W'(mult_b));
                end else begin
                    // OS mode accumulates locally over time
                    psum_reg <= psum_reg + (ACC_W'(mult_a) * ACC_W'(mult_b));
                end
            end
        end
    end

    assign a_out      = a_reg;
    assign b_out      = b_reg;
    assign psum_out   = psum_reg;
    assign result_out = psum_reg;

endmodule
