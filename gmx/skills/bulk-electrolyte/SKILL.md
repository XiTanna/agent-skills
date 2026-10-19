---
name: gmx-bulk-electrolyte
description: Build and launch GROMACS bulk electrolyte (salt + solvent) MD cases from a user-maintained basicfile (pdb + FF itp) - molar ratio to molecule counts (5000-7000 atoms), packmol box, steep minimisation, <T>K run folder, NPT submission to Slurm. Use when the user gives case names, salt:solvent molar ratios or concentrations, and a temperature and wants bulk electrolyte simulation cases built or submitted ("build case1/2/3 ...", "0.3 M NaX in Y", "set up bulk electrolyte cases").
---

# GROMACS bulk electrolyte cases

The user maintains `basicfile/` (their `pdb/` and `FF/`) and only tells you **case names, molar ratios, temperature** (and which species). Everything else is this workflow. Do the whole chain; do not ask about things fixed below.

## Inputs you need from the user
- case name(s), species per case (cation, anion, solvent(s)), molar ratio `salt : solvent = 1 : X` (or a concentration), temperature (K).
- Target size **5000-7000 atoms** unless told otherwise. Cubic box.
- A workdir (`cmd_workflow`) containing `basicfile/pdb/<mol>.pdb`, `basicfile/FF/ffatomtype.itp`, `basicfile/FF/<mol>.itp`. Molecule names in the itp `[ moleculetype ]` must equal the pdb/itp file names.

## Steps
1. **Read** `basicfile/` first: list pdb/itp, atoms per molecule, charge sums (`[ atoms ]` column 7: each ion and solvent must be integer, cation + anion = 0 per pair), and `ffatomtype.itp` for `[ bondtypes ]/[ angletypes ]`. Any bond/angle line without parameters and no matching `*types` entry gives grompp `No default Bond types`: **ask the user for the parameters, never invent them**; if they paste them, write explicit values into that itp's lines (comment the source).
2. **Counts and box**:
   `python scripts/plan_counts.py <workdir>/basicfile --cation Na --anion BPh4 --solvent DME --ratio 32.1 --rho 0.87 --name case1-NaBPh4-DME`
   It lists the numbers of salt pairs for which the solvent count is an integer (±0.05) and atoms are in the window, with a box edge (nm). Use the smallest N inside 5000-7000 unless the user prefers otherwise, and the solvent liquid density for `--rho`. Show the user the table (atoms, counts) before building.
3. **Build** (login node, interactive shell so packmol and libs are found):
   `bash -ic 'bash scripts/bulk_electrolyte.sh build <workdir> <T> <box_nm> "<name>=Na:10,BPh4:10,DME:321" "<name2>=..."'`
   Per case it creates `<workdir>/<name>/{mixgro,mixgrosteep,<T>K}`: packmol (tolerance 2.1, packmol box = final box), editconf to the cubic box, topology from the species itps, steepest descent (3 threads), and copies `min.gro index.ndx topol.top FF/` into `<T>K/`. It refuses to overwrite an existing case; with several cases the login node (3 CPUs) runs them one after another. Only build the named cases if you re-run (existing ones are skipped).
4. **Check** each case: atom count, `Steepest Descents converged`, no net-charge note, `FF/` present. Report a table.
5. **Submit** only after the user'says so (NPT length, mdp and time limit are the user's, see below):
   `bash -ic 'bash scripts/bulk_electrolyte.sh submit <workdir> <T> <name> ...'`
   Needs `ACCOUNT`, `PARTITION` and `GMX_SETUP` (shell line that loads GROMACS in the job, e.g. `module load gromacs`) in the environment; ask the user for them once and reuse. It copies `gmx.job` and `grompp_npt.mdp` (from the workdir if present, else `assets/`), sets job-name `<name>-<T>K`, account, partition, the environment line and `ref_t/gen_temp = T`, and `sbatch`es from the interactive shell. Submit one case first, look at `slurm-*.out` after ~1 min (mdrun stepping, no error), then the rest.

## Fixed choices (the user's workflow, keep them)
- Cut-offs (0.7 nm), `nstlist = 1`, 15 ns NPT (`nsteps = 7500000`), Nose-Hoover + Parrinello-Rahman, **`gen_vel = no`**, 6 cores + 1 GPU and 4 h are the user's `grompp_npt.mdp` / `gmx.job` in `assets/`. Do not change them silently. The user declined `gen_vel = yes`. If a long run might hit the 4 h limit, say so; `gmx.job` has `-cpi`, so resubmitting the same file continues.
- Minimisation mdp `grompp_min_ele_3dc.mdp`, `mixgro.sh`, `mixgrosteep.sh` are the user's templates in `assets/` (the workdir copies win if they exist).

## Gotchas (all hit in practice)
- Use a **plain GROMACS build** (`GMX_BIN` or `GMX_SETUP`). A constant-potential (CPM) patched `gmx` makes `mdrun` die with `"CPM_ControlFile.dat" cannot be loaded`.
- Slurm jobs submitted from a non-interactive ssh lose the `module` function and the intel/CUDA libraries (jobs fail in seconds). Always submit from an interactive shell (`ssh <cluster> "bash -ic '...sbatch...'"`), and check `slurm-*.out` a minute later.
- `mixgrosteep.sh` runs `rm -rf min.*`: never name a log `min.*` (use `steep.log`).
- A species itp with a stray extra `[ moleculetype ]` block (e.g. an unused `Na1` with an undefined atomtype) breaks grompp. The script keeps only the first block in the **case copy** and leaves `basicfile/` untouched; tell the user.
- Every pdb must contain only the atoms of one molecule (the script counts `ATOM/HETATM` lines).
- Keep folders clean: no stray logs or scratch files; do not delete the user's data without asking.

## Report to the user
A table per case (species counts, atoms, box, minimisation steps), what was changed in copies, and the job IDs with node and speed once running.
