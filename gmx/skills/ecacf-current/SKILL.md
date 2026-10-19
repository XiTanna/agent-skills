---
name: gmx-ecacf-current
description: Produce the charge-current time series (onfly_ecacf.dat) needed for electric-current autocorrelation / ionic conductivity of a bulk electrolyte with GROMACS - 5 annealed NPT runs, 10 frames each, 50 short NVT runs with an on-the-fly current module, then collect files and box lengths. Use when the user wants ECACF / conductivity input data for a finished bulk electrolyte case ("run the ecacf workflow", "get the current for case X", "ecacf for conductivity").
---

# ECACF current data for a bulk electrolyte case

Goal: 50 independent short NVT trajectories, each writing the instantaneous charge current of the chosen ions every 10 fs. Post-processing (autocorrelation, conductivity) is **not** part of this skill: the deliverable is `ecacf/all_ecacf/onfly_ecacf-caseK.dat` plus `ecacf/box_length.txt`.

Prerequisite: a finished bulk case (see `gmx-bulk-electrolyte`) with `<casedir>/<T>K/{npt.gro,topol.top,index.ndx,FF/}`, where `npt.gro` is the equilibrated NPT structure **with velocities**.

## What the user must provide
- the case folder and temperature `T`;
- the **index group names** of the species whose current is wanted (exactly as in `index.ndx`, case-sensitive, e.g. `Zn otf`); read the groups from `index.ndx` first and propose them;
- Slurm settings (account, partition) and where the on-the-fly GROMACS and the frame-extraction tool live (ask once, reuse).

## Workflow (all via `scripts/ecacf_workflow.sh`, run from an interactive shell: `bash -ic '...'`)
1. **Create 5 decorrelation runs**: `ecacf_workflow.sh manycase <casedir> <T>`. Each `ecacf/manycase/caseI` is the same structure and topology, a 2 ns NPT (Nose-Hoover, Parrinello-Rahman) with one heating/cooling cycle `T -> peak -> T -> T` (0, 500, 1000, 2000 ps), peaks 320, 340, 360, 380, 400 K for case1-5 (`PEAKS` to change). The different peaks make the five trajectories diverge; there is no velocity regeneration (`gen_vel = no`).
2. **Submit**: `ACCOUNT=.. PARTITION=.. GMX_SETUP="module load gromacs" ecacf_workflow.sh submit-manycase <casedir>` (GPU jobs, plain GROMACS). Check `slurm-*.out` after a minute. Wait for all five.
3. **Pick starting frames**: `GET_FRAMES=/path/tool ecacf_workflow.sh frames <casedir> <T>`: 10 frames per run at temperature `T` -> `initialframes-caseI/frame1..10.gro` (50 starts). The tool needs `npt1.tpr/.trr/.edr` (usage: `-i prefix -t T -n num -o outdir`).
4. **Create and submit the 50 current runs**: `ONFLY_SETUP='export PATH=/path/to/onfly/bin:$PATH' ECACF_PARTITION=.. ECACF_CONSTRAINT=.. ACCOUNT=.. PARTITION=.. ecacf_workflow.sh runcase <casedir> <T> "Zn otf"`.
   `ONLY="1" ... runcase` submits just run 1 first (do this, check it steps without error, then run all; `DRYRUN=1` creates folders without submitting). Each run: 200 ps NVT (Nose-Hoover, `ref_t = T`), `userint1 = 5` -> one output line per 5 steps (10 fs), 20000 lines.
5. **Collect**: `ecacf_workflow.sh collect <casedir>` copies every `onfly_ecacf.dat` to `ecacf/all_ecacf/onfly_ecacf-caseK.dat` and writes `ecacf/box_length.txt` (`K L`, cubic box edge in nm from `start.gro`), warning about missing or short files.

## The data file
`onfly_ecacf.dat`: 3 columns = x y z components of `J(t) = sum_i q_i v_i` over the selected groups (molecule charge x centre-of-mass velocity, units e nm/ps), one line per `userint1` steps, whole box as a single bin (`-nbin 1 -dim 2`). The charge of each selected molecule comes from the topology (cation and anion each with their net charge).

## Fixed choices (keep unless the user says otherwise)
- 5 annealed runs x 10 frames = 50 starts; NVT length 200 ps; output interval 5 steps; cut-offs 1.2 nm (templates in `assets/`; copies of `manycase_npt.mdp`, `ecacf_nvt.mdp`, `gmx_manycase.job`, `gmx_ecacf.job` placed in `<casedir>/ecacf/` take precedence).
- The mdp cut-offs, thermostat constants and anneal peaks are the user's; do not tune silently.

## Gotchas (all hit in practice)
- The on-the-fly GROMACS is a **CPU-only build compiled for AVX-512**. On nodes without AVX-512 (e.g. most AMD GPU nodes) `grompp`/`mdrun` die with `Illegal instruction`. Run these jobs on CPU nodes that support AVX-512 (use `ECACF_PARTITION` and `ECACF_CONSTRAINT`, e.g. an Intel feature); do not request a GPU.
- `-sel` names must match `index.ndx` exactly (the script checks this). Group names differ between systems (`OTF` vs `otf`).
- Submit from an interactive shell (`bash -ic`), otherwise `module` and libraries are missing; check `slurm-*.out` a minute after submitting.
- Plain GROMACS (not a CPM-patched build) for the NPT runs.
- Keep the case folder clean; do not delete finished data without asking.

## Report to the user
Per stage: what was created or submitted (job IDs), the anneal peaks, which groups were selected, and at the end the number of collected files, expected line count (nsteps / userint1) and any short or missing runs.
