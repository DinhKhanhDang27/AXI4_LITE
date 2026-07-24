transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog -sv rtl/avalon_axi4lite_bridge.sv
vlog -sv +incdir+tb/tb_avalon_axi4lite_bridge tb/tb_avalon_axi4lite_bridge/tb_top.sv

vsim work.tb_avalon_axi4lite_bridge
view wave
add wave -divider "tb_top"
add wave -radix hexadecimal sim:/tb_avalon_axi4lite_bridge/*
add wave -divider "interface"
add wave -radix hexadecimal sim:/tb_avalon_axi4lite_bridge/tb_if/*
add wave -divider "dut"
add wave -radix hexadecimal sim:/tb_avalon_axi4lite_bridge/dut/*
run -all
