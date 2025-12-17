# Clock input (100 MHz oscillator)
set_property PACKAGE_PIN Y9 [get_ports {clk_in}] ; # 100 MHz oscillator
set_property IOSTANDARD LVCMOS33 [get_ports {clk_in}]
create_clock -name sys_clk -period 10.000 [get_ports {clk_in}]

# Reset button (BTNC)
set_property PACKAGE_PIN P16 [get_ports {arst_n}] ; # BTNC
set_property IOSTANDARD LVCMOS33 [get_ports {arst_n}]

# Alarm button (BTNU)
set_property PACKAGE_PIN T18 [get_ports {alarm_in}] ; # BTNU
set_property IOSTANDARD LVCMOS33 [get_ports {alarm_in}]

# Speed controller buttons (BTNL, BTNR)
set_property PACKAGE_PIN N15 [get_ports {speed_in[0]}] ; # BTNL
set_property IOSTANDARD LVCMOS33 [get_ports {speed_in[0]}]

set_property PACKAGE_PIN R18 [get_ports {speed_in[1]}] ; # BTNR
set_property IOSTANDARD LVCMOS33 [get_ports {speed_in[1]}]

# Loop control button (BTND)
set_property PACKAGE_PIN R16 [get_ports {loop_ctrl_in}] ; # BTND
set_property IOSTANDARD LVCMOS33 [get_ports {loop_ctrl_in}]



# RGB LEDs
set_property PACKAGE_PIN T22 [get_ports {led_r}] ; # LD0
set_property IOSTANDARD LVCMOS33 [get_ports {led_r}]

set_property PACKAGE_PIN T21 [get_ports {led_g}] ; # LD1
set_property IOSTANDARD LVCMOS33 [get_ports {led_g}]

set_property PACKAGE_PIN U22 [get_ports {led_b}] ; # LD2
set_property IOSTANDARD LVCMOS33 [get_ports {led_b}]
