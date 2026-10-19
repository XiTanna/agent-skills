"""Molecule counts + box for a bulk electrolyte from a salt:solvent molar ratio.

usage:  python plan_counts.py <basicfile dir> --cation Na --anion BPh4 --solvent DME --ratio 32.1 [--rho 0.87] [--amin 5000 --amax 7000]
        (--ratio X means salt : solvent = 1 : X ;  several solvents: --solvent G2 DME --ratio 20 10)
Tries N salt pairs = 1,2,3,... and keeps every N for which all solvent counts are integers (within 0.05) and the atom count is
inside [amin, amax]; prints the spec string for bulk_electrolyte.sh.  Box edge = (total mass / rho)^(1/3) rounded up to 0.1 nm
(rho in g/mL, default 1.0: pass the solvent density; the NPT run relaxes the box).
"""
import argparse, math, re, os

ap = argparse.ArgumentParser()
ap.add_argument('basicfile'); ap.add_argument('--cation', required=True); ap.add_argument('--anion', required=True)
ap.add_argument('--solvent', nargs='+', required=True); ap.add_argument('--ratio', nargs='+', type=float, required=True)
ap.add_argument('--rho', type=float, default=1.0); ap.add_argument('--amin', type=int, default=5000); ap.add_argument('--amax', type=int, default=7000)
ap.add_argument('--name', default='case-xxx')
a = ap.parse_args()


def info(mol):                                   # atoms from the pdb, mass from the first [ atoms ] block of the itp (col 8; else element table)
    n = sum(1 for l in open('%s/pdb/%s.pdb' % (a.basicfile, mol)) if l.startswith(('ATOM', 'HETATM')))
    m = 0.0; inatoms = False; seen = False
    for l in open('%s/FF/%s.itp' % (a.basicfile, mol)):
        s = l.strip()
        if s.startswith('['):
            if inatoms: break
            inatoms = re.match(r'\[\s*atoms', s) is not None; continue
        if inatoms and s and not s.startswith(';'):
            f = s.split(';')[0].split()
            if len(f) >= 8: m += float(f[7])
    return n, m


mols = [a.cation, a.anion] + a.solvent
I = {x: info(x) for x in mols}
assert len(a.solvent) == len(a.ratio)
out = []
for N in range(1, 200):
    ns = [r * N for r in a.ratio]
    if any(abs(x - round(x)) > 0.05 for x in ns): continue
    ns = [int(round(x)) for x in ns]
    atoms = N * I[a.cation][0] + N * I[a.anion][0] + sum(n * I[s][0] for n, s in zip(ns, a.solvent))
    if atoms < a.amin: continue
    if atoms > a.amax: break
    mass = N * I[a.cation][1] + N * I[a.anion][1] + sum(n * I[s][1] for n, s in zip(ns, a.solvent))
    box = math.ceil((mass / 0.6022 / a.rho) ** (1 / 3)) / 10      # volume in A^3 = mass / (0.6022 rho); edge in A -> nm, rounded up to 0.1 nm
    spec = '%s=%s:%d,%s:%d,%s' % (a.name, a.cation, N, a.anion, N, ','.join('%s:%d' % (s, n) for s, n in zip(a.solvent, ns)))
    out.append((N, atoms, box, spec))
if not out: print('no integer solution in the atom window; relax --amin/--amax or round the ratio')
for N, atoms, box, spec in out:
    print('pairs %-3d atoms %-5d box %.1f nm   %s' % (N, atoms, box, spec))
