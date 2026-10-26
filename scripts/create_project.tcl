# ------------------------------------------------------------------------------
# Recreates the Vivado project for the PYNQ-Z2 from the sources in this repository.
# Written for Vivado 2020.1 (the version the design was built with).
#
# Run from the repository root:
#   vivado -mode batch -source scripts/create_project.tcl                 # project only
#   vivado -mode batch -source scripts/create_project.tcl -tclargs build  # + bitstream
#
# The project is created in build/vivado/ (ignored by git).
# ------------------------------------------------------------------------------

set repo_dir  [file normalize [file join [file dirname [info script]] ..]]
set proj_name fpga_multiprecision_adder
set proj_dir  [file join $repo_dir build vivado]

create_project $proj_name $proj_dir -part xc7z020clg400-1 -force
if {[catch {set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]}]} {
  puts "WARNING: PYNQ-Z2 board files not found - continuing with the bare xc7z020clg400-1 part."
}
set_property target_language Verilog [current_project]

# RTL, constraints and testbenches
add_files -norecurse [glob [file join $repo_dir rtl * *.v]]
add_files -fileset constrs_1 -norecurse [file join $repo_dir constraints pynq_z2.xdc]
add_files -fileset sim_1 -norecurse [glob [file join $repo_dir sim *.v]]
set_property top tb_mp_adder [get_filesets sim_1]
update_compile_order -fileset sources_1

# Block design: clocking wizard + debounced reset + uart_top (module references)
source [file join $repo_dir vivado block_design_1.tcl]
set bd_file [get_files block_design_1.bd]
generate_target all $bd_file
make_wrapper -files $bd_file -top
set wrapper [glob -nocomplain \
  [file join $proj_dir $proj_name.gen  sources_1 bd block_design_1 hdl block_design_1_wrapper.v] \
  [file join $proj_dir $proj_name.srcs sources_1 bd block_design_1 hdl block_design_1_wrapper.v]]
add_files -norecurse $wrapper
set_property top block_design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Optional: run synthesis, implementation and bitstream generation
if {[lsearch -exact $argv build] >= 0} {
  launch_runs impl_1 -to_step write_bitstream -jobs 4
  wait_on_run impl_1
  puts "Bitstream: [glob -nocomplain [file join $proj_dir $proj_name.runs impl_1 *.bit]]"
}
