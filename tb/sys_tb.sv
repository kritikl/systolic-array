`timescale 1ns/1ps
import systolic_pkg::*;

module sys_tb;


    localparam int N      = 4;  
    localparam int DATA_W = 16;
    localparam int ACC_W  = 32;
    
    localparam dataflow_t FLOW_MODE = OS; 

    logic clk;
    logic reset;
    logic start;
    logic done;
    logic valid;
    logic preload_done;

    logic signed [DATA_W-1:0] A [N][N];
    logic signed [DATA_W-1:0] B [N][N];
    logic signed [ACC_W-1:0]  expected_result [N][N];

    logic signed [DATA_W-1:0] a_stream [N];
    logic signed [DATA_W-1:0] b_stream [N];

    logic signed [DATA_W-1:0] a_out [N];
    logic signed [DATA_W-1:0] b_out [N];
    logic signed [ACC_W-1:0]  result [N][N];

    logic signed [DATA_W-1:0] dbg_a [N][N];
    logic signed [DATA_W-1:0] dbg_b [N][N];
    logic signed [ACC_W-1:0]  dbg_psum [N][N];
    logic                     dbg_enable_mac [N][N];

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    int fd;
    int cycle_count;
    string rel_path = "../../../../../logs/simulation_log.csv";

    initial begin
        fd = $fopen(rel_path,"w");
        if (fd) begin
            $fdisplay(fd, "cycle,row,col,active,op_a,op_b,psum");
        end else begin
            $display("ERROR: Could not open simulation_log.csv ");
        end
        cycle_count = 0;
    end

    always @(posedge clk) begin
        if (fd) begin
            for (int r = 0; r < N; r++) begin
                for (int c = 0; c < N; c++) begin
                    $fdisplay(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                        cycle_count,
                        r,
                        c,
                        dbg_enable_mac[r][c],
                        dbg_a[r][c],
                        dbg_b[r][c],
                        dbg_psum[r][c]
                    );
                end
            end
            cycle_count++;
        end
    end

    matrix_feeder #(
        .N(N),
        .DATA_W(DATA_W),
        .DATAFLOW(FLOW_MODE)
    ) feeder (
        .clk(clk),
        .reset(reset),
        .start(start),
        .A(A),
        .B(B),
        .a_out(a_stream),
        .b_out(b_stream),
        .valid(valid),
        .done(done),
        .preload_done(preload_done)
    );

    systolic_array #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .DATAFLOW(FLOW_MODE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .preload_done(preload_done),
        .a_in(a_stream),
        .b_in(b_stream),
        .a_out(a_out),
        .b_out(b_out),
        .result(result),
        .dbg_a(dbg_a),
        .dbg_b(dbg_b),
        .dbg_psum(dbg_psum),
        .dbg_enable_mac(dbg_enable_mac)
    );

    initial begin
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                A[i][j] = $urandom_range(1, 4);
                B[i][j] = $urandom_range(1, 4);
            end
        end

        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                expected_result[i][j] = '0;
                for (int k = 0; k < N; k++) begin
                    expected_result[i][j] += A[i][k] * B[k][j];
                end
            end
        end

        reset = 1'b1;
        start = 1'b0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        @(posedge clk);

        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait(done);
        
        repeat (N + 2) @(posedge clk);   
        
        $display("CURRENT MODE: %s", FLOW_MODE.name());
        
        $display("Result Matrix:");
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                $write("%0d ", result[i][j]);
            end
            $display("");
        end

        $display("\nExpected Output Matrix:");
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                $write("%0d ", expected_result[i][j]);
            end
            $display("");
        end

        $fclose(fd);
        $finish;
    end

endmodule