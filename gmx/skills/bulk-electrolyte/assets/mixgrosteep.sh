rm -rf *#*

echo -e "\n q" | gmx make_ndx  -f mixture.gro

name=min
groname=mixture.gro
mdpname1=grompp_min_ele_3dc.mdp

rm -rf min.*
gmx grompp -f $mdpname1 -p topol.top -c $groname -o $name  -n index.ndx -maxwarn 2
gmx mdrun  -s $name -deffnm $name -v -ntmpi 1 -ntomp 3
