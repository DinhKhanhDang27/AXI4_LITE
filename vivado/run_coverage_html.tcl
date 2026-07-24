# Run XSIM code coverage for the current RTL/testbench set and export HTML.
#
# Usage from repository root:
#   vivado -mode batch -source vivado/run_coverage_html.tcl
#
# Output:
#   vivado/coverage_html/index.html

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file dirname $script_dir]
set work_dir   [file normalize [file join $script_dir coverage_work]]
set report_dir [file normalize [file join $script_dir coverage_html]]
set cov_dir    [file normalize [file join $work_dir xsim.covdb]]

file mkdir $work_dir
file mkdir $report_dir

cd $work_dir

set rtl_files [list \
    [file join $repo_root rtl alu_core.sv] \
    [file join $repo_root rtl axi_register_bank.sv] \
    [file join $repo_root rtl axi4lite_slave.sv] \
    [file join $repo_root rtl avalon_axi4lite_bridge.sv] \
    [file join $repo_root rtl avalon_axi4lite_alu.sv] \
]

set testbenches [list \
    tb_axi_register_bank \
    tb_axi4lite_slave \
    tb_avalon_axi4lite_bridge \
]

set run_tcl [file join $work_dir run_all.tcl]
set fp [open $run_tcl w]
puts $fp "run all"
puts $fp "quit"
close $fp

proc run_cmd {args} {
    puts "\n==> $args"
    if {[catch {exec {*}$args} result opts]} {
        puts $result
        error "Command failed: $args"
    }
    puts $result
}

foreach tb $testbenches {
    puts "\n============================================================"
    puts "Running coverage for $tb"
    puts "============================================================"

    set tb_file [file join $repo_root tb ${tb}.sv]
    set snapshot ${tb}_cov
    set cov_name ${tb}

    run_cmd xvlog --sv --incr --relax {*}$rtl_files $tb_file

    run_cmd xelab --incr --relax --debug typical -coverage all \
        --snapshot $snapshot \
        -cov_db_dir $cov_dir \
        -cov_db_name $cov_name \
        xil_defaultlib.$tb

    run_cmd xsim $snapshot \
        -tclbatch $run_tcl \
        -cov_db_dir $cov_dir \
        -cov_db_name $cov_name
}

puts "\n============================================================"
puts "Generating HTML coverage report"
puts "============================================================"

run_cmd xcrg \
    -dir $cov_dir \
    -report_format html \
    -report_dir $report_dir \
    -report_name coverage_report

puts "\nCoverage HTML report:"
puts "  [file join $report_dir coverage_report index.html]"

exec xcrg -cc_dir . -cc_db tb_axi_register_bank_behav -cc_report D:/INTERN/NghienCuu_AXI_LITE/vivado/coverage_html


cd D:/INTERN/NghienCuu_AXI_LITE/vivado/AXI_Lite/AXI_Lite.sim/sim_1/behav/xsim
exec xcrg -cc_dir . -cc_db tb -cc_report D:/INTERN/NghienCuu_AXI_LITE/vivado/coverage_html


tb_axi4lite_slave
exec xcrg -cc_dir . -cc_db tb_axi4lite_slave -cc_report D:/INTERN/NghienCuu_AXI_LITE/vivado/coverage_html/tb_axi4lite_slave



tb_avalon_axi4lite_bridge
exec xcrg -cc_dir . -cc_db tb_avalon_axi4lite_bridge -cc_report D:/INTERN/NghienCuu_AXI_LITE/vivado/coverage_html/tb_avalon_axi4lite_bridge

tb_axi_register_bank
exec xcrg -cc_dir . -cc_db tb_axi_register_bank -cc_report D:/INTERN/NghienCuu_AXI_LITE/vivado/coverage_html/tb_axi_register_bank

