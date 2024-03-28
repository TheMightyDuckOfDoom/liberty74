# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Check if CORNER_GROUP exists
set corner_dirs [glob pdk/lib/*]
set corner_names [list]
foreach corner $corner_dirs {
    lappend corner_names [file rootname [file tail $corner]]
}
if { [lsearch -exact $corner_names $CORNER_GROUP] == -1 } {
    puts "Corner Group ${CORNER_GROUP} not found"
    exit
}

# Check if PROCESS exists
set process_dirs [glob pdk/lib/$CORNER_GROUP/*]
set process_names [list]
foreach process $process_dirs {
    lappend process_names [file rootname [file tail $process]]
}
if { [lsearch -exact $process_names $PROCESS] == -1 } {
    puts "Process ${PROCESS} not found in corner group ${CORNER_GROUP}"
    exit
}

# Set LIBS for given CORNER_GROUP and PROCESS
set LIBS [list]
foreach lib [glob pdk/lib/$CORNER_GROUP/$PROCESS/*.lib] {
    lappend LIBS $lib
}
