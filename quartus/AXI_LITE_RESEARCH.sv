module AXI_LITE_RESEARCH (
    input wire CLOCK_50
);

    system u_system (
        .clk_clk       (CLOCK_50),
        .reset_reset_n (1'b1)
    );

endmodule
