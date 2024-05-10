# Copyright 2024 Tobias Senti
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

echo $@
cat $3
sed 's/read_lib/read_lib -S 20 -G 2/' $3 > $3.tmp
mv $3.tmp $3
echo "After sed"
cat $3
yosys-abc $@