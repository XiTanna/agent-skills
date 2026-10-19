lx=4
ly=4
lz=4
packmol<mixture.inp
gmx editconf -f mixture.pdb -o mixture.gro

sed -i "$ s/.*/$lx $ly $lz/" mixture.gro
rm -rf  ''#*.*.*#''