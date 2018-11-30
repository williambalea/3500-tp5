## Clock signal
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];

##7 segment display
##set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { ca }];
##set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { cb }];
##set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { cc }];
##set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports { cd }];
##set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { ce }];
##set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { cf }];
##set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { cg }];
##set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports { dp }];
##set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports { an[0] }];
##set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports { an[1] }];
##set_property -dict { PACKAGE_PIN T9 IOSTANDARD LVCMOS33 } [get_ports { an[2] }];
##set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports { an[3] }];
##set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { an[4] }];
##set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { an[5] }];
##set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports { an[6] }];
##set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { an[7] }];

##USB-RS232 Interface
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports { uart_tx }];
## LEDs
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { led }];
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { led_err_f }];
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { led_err_P }];
##Buttons
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { rst }];
