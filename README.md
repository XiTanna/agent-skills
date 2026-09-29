# agent-skills

Claude Code skills, grouped by topic.

| Plugin | Skill | Description |
|---|---|---|
| `matlab` | `matlab-publication-figures` | Consistent, publication-quality MATLAB figures: canvas and axes sizing, color system, label typography, legends, insets, and a cross-figure consistency checklist. Generated scripts are self-contained. |

## Install

```
/plugin marketplace add XiTanna/agent-skills
/plugin install matlab@xitan-agent-skills
```

Update:

```
/plugin marketplace update xitan-agent-skills
```

Manual install: copy `matlab/skills/matlab-publication-figures/` into `~/.claude/skills/`.

## Use

Ask Claude Code to write or restyle a MATLAB plotting script; the skill loads automatically.
To call it explicitly: `/matlab-publication-figures`.

## Layout

```
.claude-plugin/marketplace.json
matlab/
  .claude-plugin/plugin.json
  skills/matlab-publication-figures/
    SKILL.md                  # style rules and workflow
    assets/configPlot.m       # plot defaults, appended to generated scripts
    references/templates.md   # templates for common figure types
```
