transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog -sv rtl/axi_register_bank.sv
vlog -sv +incdir+tb/tb_axi_register_bank tb/tb_axi_register_bank/tb_top.sv

vsim work.tb_axi_register_bank
view wave
add wave -divider "tb_top"
add wave -radix hexadecimal sim:/tb_axi_register_bank/*
add wave -divider "interface"
add wave -radix hexadecimal sim:/tb_axi_register_bank/tb_if/*
add wave -divider "dut"
add wave -radix hexadecimal sim:/tb_axi_register_bank/dut/*
run -all
