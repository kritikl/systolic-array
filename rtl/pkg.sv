`timescale 1ns/1ps

package systolic_pkg;

    typedef enum logic [1:0] {
        OS = 2'd0,
        WS = 2'd1,
        IS  = 2'd2
    } dataflow_t;

endpackage
