define_corners tt ss ff

read_liberty -corner tt lib/liberty74_typ_5p00V_25C.lib
read_liberty -corner ss lib/liberty74_slow_4p50V_85C.lib
read_liberty -corner ff lib/liberty74_fast_5p50V_m40C.lib

read_lef lef/liberty74_tech.lef
read_lef lef/liberty74.lef