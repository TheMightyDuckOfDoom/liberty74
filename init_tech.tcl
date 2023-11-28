define_corners tt ss ff

read_liberty -corner tt lib/74LVC_typ.lib
read_liberty -corner ss lib/74LVC_worst.lib
read_liberty -corner ff lib/74LVC_best.lib

read_lef lef/liberty74_tech.lef
read_lef lef/74LVC.lef