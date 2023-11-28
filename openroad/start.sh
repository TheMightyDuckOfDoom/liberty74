#!/bin/bash
cd openroad
source /home/stabo/OpenROAD/build.env
/home/stabo/OpenROAD/install/bin/openroad -gui chip.tcl -log openroad.log