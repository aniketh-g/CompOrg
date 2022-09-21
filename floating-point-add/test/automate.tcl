set fp [open "test_in.txt" r]
set file_data [read $fp]
close $fp
set data [split $file_data "\n"]
 
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
current_hw_device [get_hw_devices xc7z020_1]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z020_1] 0]
set_property PROBES.FILE {./design_1_wrapper.ltx} [get_hw_devices xc7z020_1]
set_property FULL_PROBES.FILE {./design_1_wrapper.ltx} [get_hw_devices xc7z020_1]
set_property PROGRAM.FILE {./design_1_wrapper.bit} [get_hw_devices xc7z020_1]
program_hw_devices [get_hw_devices xc7z020_1]
refresh_hw_device [lindex [get_hw_devices xc7z020_1] 0]

set f [open output.txt w]
foreach line $data {
    set fields [split $line " "]
    set data_a [lindex $fields 0]
    set data_b [lindex $fields 1]
    set_property OUTPUT_VALUE $data_a [get_hw_probes design_1_i/vio_0_probe_out2 -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    commit_hw_vio [get_hw_probes {design_1_i/vio_0_probe_out2} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    set_property OUTPUT_VALUE $data_b [get_hw_probes design_1_i/vio_0_probe_out1 -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    commit_hw_vio [get_hw_probes {design_1_i/vio_0_probe_out1} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    refresh_hw_vio [get_hw_vios {hw_vio_1}]
    set_property OUTPUT_VALUE 1 [get_hw_probes design_1_i/vio_0_probe_out0 -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    commit_hw_vio [get_hw_probes {design_1_i/vio_0_probe_out0} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    set_property OUTPUT_VALUE 0 [get_hw_probes design_1_i/vio_0_probe_out0 -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    commit_hw_vio [get_hw_probes {design_1_i/vio_0_probe_out0} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"design_1_i/vio_0"}]]
    refresh_hw_vio [get_hw_vios {hw_vio_1}]
    puts $f [get_property INPUT_VALUE [get_hw_probes design_1_i/fpadd_0_sum]]
}

close $f