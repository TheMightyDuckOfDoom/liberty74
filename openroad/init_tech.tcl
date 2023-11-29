# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

define_corners tt ss ff

# Load Corners
read_liberty -corner tt ../pdk/lib/74lvc_typ_5p00V_25C.lib
read_liberty -corner ss ../pdk/lib/74lvc_slow_4p50V_85C.lib
read_liberty -corner ff ../pdk/lib/74lvc_fast_5p50V_m40C.lib

# Load Technology files
read_lef ../pdk/lef/liberty74_tech.lef
read_lef ../pdk/lef/liberty74_site.lef

# Load Cell LEFs
read_lef ../pdk/lef/74lvc.lef