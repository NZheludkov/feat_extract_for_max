##WRITE WORST ACTUAL DELAY FOR 3 BASIC GROUP
puts $new_file "path_group;startpoint;endpoint;n_elements;req_time;actual_delay;slack;slack_met"

set groups "in2reg reg2reg reg2out in2out"
set new_groups ""

foreach group $groups {

with_output_to_variable report_checks "report_checks -path_group $group -format end -digits 3"
exec echo $report_checks > ./report_delay.txt

set read_file [open ./report_delay.txt r]
set contents [read -nonewline $read_file]
close $read_file

set split_contents [split $contents "\n"] 
set no_path [lindex $split_contents 0]

	if {$no_path ne "No paths found."} {
	lappend new_groups $group
	} else {
	puts $new_file "$group;'N/A';'N/A';'N/A';'N/A';'N/A';'N/A';'N/A'"
	}

}

foreach group $new_groups {

    with_output_to_variable report_checks "report_checks -path_group $group -format end -digits 3"
    exec echo $report_checks > ./report_delay.txt

    set read_file [open ./report_delay.txt r]
    set contents [read -nonewline $read_file]
    close $read_file

    set split_contents [split $contents "\n"] 
    set endpoint [lindex [lindex $split_contents 5] 0]

    with_output_to_variable report_checks "report_checks -path_group $group -to $endpoint -digits 3"
    exec echo $report_checks > ./find_startpoint.txt

    set startpoint_file [open ./find_startpoint.txt r]
    set startpoint_contents [read -nonewline $startpoint_file]
    close $startpoint_file
    set startpoint_split_contents [split $startpoint_contents "\n"]
    set startpoint [lindex [lindex $startpoint_split_contents 0] 1]

    foreach line $startpoint_split_contents {

	if {([lindex $line 2] eq "clock") && ([lindex $line 3] eq "network")} {

	    set clk_path [lindex $line 1]
	    break
	}	
    }
    
    
    if {$group eq "in2out"} {
    
    set k 0
	while {$k < [llength $startpoint_split_contents]} {

	    set mark0 [lindex [lindex $startpoint_split_contents $k] 0]
	    set mark1 [lindex [lindex $startpoint_split_contents $k] 1]
	    set mark2 [lindex [lindex $startpoint_split_contents $k] 2]

	    if {($mark0 > 0) && ($mark1 eq "data") && ($mark2 eq "arrival")} {

		set k_find $k
		set N_max_path [expr $k - 12]
	    }

	    incr k
	}
	
	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "required")} {

		set req_time [lindex $line 0]
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 3] eq "input") && ([lindex $line 4] eq "external")} {

		set io_delay [lindex $line 0]
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "arrival")} {

		set arrival_time [lindex $line 0]
		break
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "slack") } {

		set slack [lindex $line 0]
		set slack_met [lindex $line 2]
		break
	    }
	}	

	set actual_delay [expr $arrival_time - $io_delay]
    
    
    }
    

    if {$group eq "in2reg"} {

	set k 0
	while {$k < [llength $startpoint_split_contents]} {

	    set mark0 [lindex [lindex $startpoint_split_contents $k] 0]
	    set mark1 [lindex [lindex $startpoint_split_contents $k] 1]
	    set mark2 [lindex [lindex $startpoint_split_contents $k] 2]

	    if {($mark0 > 0) && ($mark1 eq "data") && ($mark2 eq "arrival")} {

		set k_find $k
		set N_max_path [expr $k - 12]
	    }

	    incr k
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "required")} {

		set req_time [lindex $line 0]
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 3] eq "input") && ([lindex $line 4] eq "external")} {

		set io_delay [lindex $line 0]
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "arrival")} {

		set arrival_time [lindex $line 0]
		break
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "slack") } {

		set slack [lindex $line 0]
		set slack_met [lindex $line 2]
		break
	    }
	}	

	set actual_delay [expr $arrival_time - $io_delay]	
    } 


    if {$group eq "reg2out"} {



	set k 0
	while {$k < [llength $startpoint_split_contents]} {

	    set mark0 [lindex [lindex $startpoint_split_contents $k] 0]
	    set mark1 [lindex [lindex $startpoint_split_contents $k] 1]
	    set mark2 [lindex [lindex $startpoint_split_contents $k] 2]

	    if {($mark0 > 0) && ($mark1 eq "data") && ($mark2 eq "arrival")} {

		set k_find $k
		set N_max_path [expr $k - 11]
	    }

            incr k
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "required")} {

		set req_time [lindex $line 0]
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 3] eq "output") && ([lindex $line 4] eq "external")} {

		set io_delay [lindex $line 0]
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "arrival")} {

		set arrival_time [lindex $line 0]
		break
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "slack") } {

		set slack [lindex $line 0]
		set slack_met [lindex $line 2]
		break
	    }
	}

	set actual_delay [expr $arrival_time - $clk_path]	
    }

    if {$group eq "reg2reg"} {

	set k 0
	while {$k < [llength $startpoint_split_contents]} {

	    set mark0 [lindex [lindex $startpoint_split_contents $k] 0]
	    set mark1 [lindex [lindex $startpoint_split_contents $k] 1]
	    set mark2 [lindex [lindex $startpoint_split_contents $k] 2]

	    if {($mark0 > 0) && ($mark1 eq "data") && ($mark2 eq "arrival")} {

		set k_find $k
		set N_max_path [expr $k - 11]
	    }

            incr k
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "required")} {

		set req_time [lindex $line 0]
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "data") && ([lindex $line 2] eq "arrival")} {

		set arrival_time [lindex $line 0]
		break
	    }
	}

	foreach line $startpoint_split_contents {

	    if {([lindex $line 1] eq "slack") } {

		set slack [lindex $line 0]
		set slack_met [lindex $line 2]
		break
	    }
	}

	set actual_delay [expr $arrival_time - $clk_path]	
    }

    puts $new_file "$group;$startpoint;$endpoint;$N_max_path;$req_time;$actual_delay;$slack;$slack_met"
}
