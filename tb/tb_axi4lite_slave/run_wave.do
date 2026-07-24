transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog -sv rtl/axi4lite_slave.sv
vlog -sv +incdir+tb/tb_axi4lite_slave tb/tb_axi4lite_slave/tb_top.sv

vsim work.tb_axi4lite_slave
view wave
add wave -divider "tb_top"
add wave -radix hexadecimal sim:/tb_axi4lite_slave/*
add wave -divider "interface"
add wave -radix hexadecimal sim:/tb_axi4lite_slave/tb_if/*
add wave -divider "dut"
add wave -radix hexadecimal sim:/tb_axi4lite_slave/dut/*
run -all
