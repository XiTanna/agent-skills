# gmx

GROMACS skills for Claude Code.

## Skills

### gmx-bulk-electrolyte

Build and launch bulk electrolyte MD cases. You keep `basicfile/` (`pdb/` and `FF/`); tell Claude the case names, salt:solvent molar ratios and the temperature. It computes molecule counts (5000-7000 atoms), runs packmol, steepest-descent minimisation, prepares the `<T>K` folder and submits the NPT run to Slurm.

### gmx-ecacf-current

Charge-current data for conductivity of a finished bulk electrolyte case: five annealed NPT runs, ten frames each, fifty short NVT runs that write the current on the fly (`onfly_ecacf.dat`), then collection of the files and box lengths. Post-processing is not included.

## Install

```
/plugin marketplace add XiTanna/agent-skills
/plugin install gmx@xitan-agent-skills
```

Update:

```
/plugin marketplace update xitan-agent-skills
```

Manual install: copy `skills/bulk-electrolyte/` and `skills/ecacf-current/` into `~/.claude/skills/`.

## Use

Example: "build case1-NaBPh4-DME (1:32.1), case2-NaBPh4-G2 (1:23.3) at 298 K in cmd_workflow". To call it explicitly: `/gmx-bulk-electrolyte`. For the current data: "run the ecacf workflow for case1 at 298 K" (`/gmx-ecacf-current`).

## Contents

```
.claude-plugin/plugin.json
skills/bulk-electrolyte/
  SKILL.md                      # workflow, fixed choices, gotchas
  scripts/plan_counts.py        # ratio -> molecule counts and box
  scripts/bulk_electrolyte.sh   # build / submit
  assets/                       # mixgro.sh, mixgrosteep.sh, min mdp, NPT mdp, gmx.job
skills/ecacf-current/
  SKILL.md                      # stages, fixed choices, gotchas
  scripts/ecacf_workflow.sh     # manycase / submit-manycase / frames / runcase / collect
  assets/                       # annealed NPT mdp, current NVT mdp, job templates
```
