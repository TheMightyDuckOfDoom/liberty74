#!/bin/bash

# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

rm -rf out/.merged_cells
rm -rf out/lib
rm -rf out/lef
rm -rf out/def

mkdir -p out/lib
mkdir -p out/lef
mkdir -p out/def
mkdir -p out/openroad_verilog

corner_groups=("CMOS_5V" "CMOS_3V3")
corners=("Typical" "Fast" "Slow")

for corner_group in "${corner_groups[@]}"; do
  mkdir -p out/lib/${corner_group}
  for corner in "${corners[@]}"; do
    mkdir -p out/lib/${corner_group}/${corner}
  done
done

# Get filenams in config/merge_cells
for file in ../config/merge_cells/verilog/*.v; do
  # Get the cell name from the file name
  cell_name=$(basename $file .v)
  morty ../config/merge_cells/verilog/${cell_name}.v -o out/openroad_verilog/${cell_name}.v
  for corner_group in "${corner_groups[@]}"; do
    echo "Merging cell ${cell_name} for corner ${1}"
    # Merge the cells
    echo "set design_name ${cell_name};set CORNER_GROUP ${corner_group};source merge_cell.tcl" > tmp.tcl
    openroad tmp.tcl
    exit

    # Check if we have any drc errors
    if [ ! -s merge_macros_route_drc.rpt ]; then
      echo $cell_name >> out/.merged_cells
    else
      echo "${cell_name} has DRCs"
      exit 1
    fi
  done
done

echo "Genreated merged cells:"
cat out/.merged_cells

rm tmp.tcl
