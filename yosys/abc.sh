echo $@
cat $3
sed 's/read_lib/read_lib -S 20 -G 2/' $3 > $3.tmp
mv $3.tmp $3
echo "After sed"
cat $3
yosys-abc $@