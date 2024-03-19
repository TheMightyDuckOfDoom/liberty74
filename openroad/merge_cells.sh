#!/bin/bash

# Copyright 2024 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

rm -rf out/.merged_cells

# Get filenams in config/merge_cells
for file in ../config/merge_cells/*.v; do
  # Get the cell name from the file name
  cell_name=$(basename $file .v)
  echo "Merging cell ${cell_name} for corner ${1}"
  # Merge the cells
  echo "set design_name ${cell_name};set CORNER_GROUP ${1};source merge_cell.tcl" > tmp.tcl
  openroad tmp.tcl
  echo $cell_name >> out/.merged_cells
done

echo "Genreated merged cells:"
cat out/.merged_cells

rm tmp.tcl
