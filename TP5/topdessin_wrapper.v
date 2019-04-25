//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
//Date        : Fri Nov 30 14:13:16 2018
//Host        : L3714-14 running 64-bit major release  (build 9200)
//Command     : generate_target topdessin_wrapper.bd
//Design      : topdessin_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module topdessin_wrapper
   (clk,
    led,
    led_eff_P,
    led_eff_f,
    rst,
    uart_rx,
    uart_tx);
  input clk;
  output led;
  output led_eff_P;
  output led_eff_f;
  input rst;
  input uart_rx;
  output uart_tx;

  wire clk;
  wire led;
  wire led_eff_P;
  wire led_eff_f;
  wire rst;
  wire uart_rx;
  wire uart_tx;

  topdessin topdessin_i
       (.clk(clk),
        .led(led),
        .led_eff_P(led_eff_P),
        .led_eff_f(led_eff_f),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx));
endmodule
