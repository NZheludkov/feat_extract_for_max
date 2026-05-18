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

set cell_area_${stage} [format %.3f $cell_area]

##WNS
with_output_to_variable wns "report_wns"
set wns_${stage} [lindex [lindex $wns 1] 0]

##TNS
with_output_to_variable tns "report_tns"
set tns_${stage} [lindex [lindex $tns 1] 0]

if {[info exists regs] eq 0} {

    set regs [all_registers] 
} 
    
##N triggers
set n_triggers [llength $regs]


