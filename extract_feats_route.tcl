# =====================================
# Basic run vars
# =====================================

set design              $env(design)
set rtl_dataset_path    $env(rtl_dataset_path)
set pdk_path            $env(pdk_path)
set output_dir          $env(output_dir)

# =====================================
# Timing / floorplan vars
# =====================================

set CLK_PERIOD          $env(CLK_PERIOD)
set IO_DELAY            $env(IO_DELAY)

set CU                  $env(CU)
set AR                  $env(AR)

# =====================================
# PDN vars
# =====================================

set PDN_HWIDTH          $env(PDN_HWIDTH)
set PDN_HSPACING        $env(PDN_HSPACING)
set PDN_HPITCH          $env(PDN_HPITCH)

set PDN_VWIDTH          $env(PDN_VWIDTH)
set PDN_VSPACING        $env(PDN_VSPACING)
set PDN_VPITCH          $env(PDN_VPITCH)

# =====================================
# PDK vars
# =====================================

set tech_lef            $env(tech_lef)
set cells_lef           $env(cells_lef)
set lef_list            $env(lef_list)

set liberty             $env(liberty)

set core_site           $env(core_site)

set tap_cell            $env(tap_cell)
set endcap_cell         $env(endcap_cell)
set tap_cell_distance   $env(tap_cell_distance)

set techmap_verilog_files $env(techmap_verilog_files)

set bottom_routing_metal $env(bottom_routing_metal)
set top_routing_metal    $env(top_routing_metal)

set pins_hor_layers      $env(pins_hor_layers)
set pins_ver_layers      $env(pins_ver_layers)

set wire_rc_metal        $env(wire_rc_metal)

set tiehi_cell           $env(tiehi_cell)
set tielo_cell           $env(tielo_cell)

set tiehi_cell_pin       $env(tiehi_cell_pin)
set tielo_cell_pin       $env(tielo_cell_pin)

set filler_cells         $env(filler_cells)
set dont_use_cells       $env(dont_use_cells)

set max_slew_cts         $env(max_slew_cts)
set max_cap_cts          $env(max_cap_cts)

set cts_root_buf         $env(cts_root_buf)
set cts_buf_list         $env(cts_buf_list)

set process_node         $env(process_node)

set rc_extract_file      $env(rc_extract_file)

set pdk_name             $env(pdk_name)

set run_dir             $env(run_dir)

##source config
source $rtl_dataset_path/designs/${design}/config.tcl

##DESIGN UNITS
set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um

##DEFINE STA CORNER
define_corners view

##READ LEF LIST
foreach lef $lef_list {
    read_lef $lef
}

##READ LIBERTY FILE
read_liberty -corner view $liberty

##READ NETLIST
#read_verilog ${run_dir}/route/netlist/netlist.v
#link_design $design

##READ DEF
read_def ${run_dir}/route/def/def.def

##READ SDC
read_sdc ${run_dir}/route/sdc/sdc.sdc

##CREATE PATH GROUP
group_path -name reg2reg -from [all_registers] -to [all_registers]
group_path -name in2reg -from [all_inputs] -to [all_registers]
group_path -name reg2out -from [all_registers] -to [all_outputs]
group_path -name in2out -from [all_inputs] -to [all_outputs]

##READ SPEF
read_spef ${run_dir}/route/spef/spef.spef -corner view -max

##db_units_per_micron
set db [::ord::get_db]
set block [[$db getChips] getBlock]
set db_units_per_micron [$block getDbUnitsPerMicron]

##CELL AREA

set cell_area  0

foreach inst [get_cells *] {

    set dx [expr [[[sta::sta_to_db_inst $inst] getBBox] getDX] / 1000.0]
    set dy [expr [[[sta::sta_to_db_inst $inst] getBBox] getDY] / 1000.0]
    set inst_area [expr $dx * $dy]
    set cell_area [expr $cell_area + $inst_area]
}

set cell_area [format %.3f $cell_area]

##WNS
with_output_to_variable wns "report_wns"
set wns [lindex [lindex $wns 1] 0]

##TNS
with_output_to_variable tns "report_tns"
set tns [lindex [lindex $tns 1] 0]

if {[info exists regs] eq 0} {

    set regs [all_registers] 
} 
    
##N triggers
set n_triggers [llength $regs]

proc start_stage {stage} {
set start_time [exec date +%Y\_%m\_%d_%H\.%M_%S]
exec echo "$stage starts at $start_time" >> ./local_log.txt
}

proc end_stage {stage} {
set end_time [exec date +%Y\_%m\_%d_%H\.%M_%S]
exec echo "$stage ends at $end_time \n" >> ./local_log.txt
}


##WRITE WORST ACTUAL DELAY FOR 3 BASIC GROUP
set folder_name [file tail $::env(run_dir)]
set folder_name  $output_dir/${pdk_name}/${design}/$folder_name
exec mkdir -p $folder_name

start_stage "actual_delay_route"
exec mkdir -p $folder_name/actual_delay
set new_file [open $folder_name/actual_delay/actual_delay_route.csv w+]
source ./report_delay.tcl
close $new_file
end_stage "actual_delay_route.csv"
