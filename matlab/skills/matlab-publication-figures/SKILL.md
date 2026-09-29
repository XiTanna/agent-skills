---
name: matlab-publication-figures
description: House style and design method for publication-quality scientific figures in MATLAB — fixed canvas/axes sizing, a muted color system with defined roles, typographically correct axis labels (italic quantities, upright units), legend and inset layout, and strict consistency across every figure of a paper. Generated scripts are self-contained. Use this skill whenever the user asks to write, modify, restyle or tidy up a MATLAB plotting script (.m) for research data — line plots, profiles, spectra, time series, parity/correlation plots, series over a parameter or composition, experiment vs simulation comparisons — or asks to make figures consistent, nicer, or match earlier figures, even if they don't mention style explicitly (in any language).
---

# MATLAB publication figures

The goal is not one nice plot but **a set of figures that look made by one hand**: same canvas, same fonts, the same color always meaning the same thing, the same label grammar. A reader flipping through a paper should never have to re-learn how to read a figure.

Read this whole file before writing code. Code building blocks for recurring figure types are in `references/templates.md` — read it when you need one of those patterns.

## 0. Working rules

- **Write the .m file; don't run MATLAB and don't export figures** (no `exportgraphics`, `saveas`, `print`, `export_fig`) unless asked. The user runs the script, looks at the result and comes back with screenshots and corrections.
- Inspect the data first (header lines, columns, value ranges) with shell/python, and choose limits and ticks from real numbers. Mention what you found in the reply (e.g. "peak is 0.81 at x = 45, so ylim [0 0.9]").
- **Locate table columns by header text, not by index** — tables grow new columns. Use a distinctive substring and make sure it matches exactly one column (a short key like `'big'` may also match `'big-corrected'`).
- One figure = one self-contained block (`figure; hold on; … set(gca,…)`) rather than a plotting function, so each figure's limits can be tuned separately. Put the knobs the user will tune (`x_lim`, `offset`, `band`, colors, number of plotted points) as named variables at the top.
- Keep scripts lean and reuse the user's existing variable names. No dead code.
- When the user changes a convention in one figure, **apply it to every sibling figure** and say so. When you notice inconsistencies between scripts (legend size, naming, direction of an axis), point them out and ask which way to unify.
- Prefer the smaller change when scope is ambiguous, and say what else could follow.

## 1. Canvas and sizing (identical in every script)

**Scripts are self-contained**: append the contents of `assets/configPlot.m` as a local function at the very end of the script (after any other local functions) under the header `%% ---- configPlot (plot defaults, bundled from the matlab-publication-figures skill) ----`. The script then runs anywhere without `addpath`. If the script already has a local `configPlot`, don't add another. (Local functions in scripts need R2016b+.)

Every script starts with:

```matlab
clc; clear; close all;
sizeoffont  = 22;
widthofline = 2.6;      % 2 for dense/noisy time series
markersize  = 11;
configPlot('FontSize',sizeoffont,'FontName','Helvetica', ...
    'Position',[2 2 4.6*2*1.8 3.6*2*1.5],'Units','centimeters', ...
    'LineWidth',widthofline,'AxesLineWidth',1.2);
axPos = [3.5 3.4 8 6];  % cm; after plotting:
% set(gca,'unit','centimeter','position',axPos,'fontsize',sizeoffont);
```

- The **axes box is always 8 × 6 cm at [3.5 3.4]**, so figures tile identically in panels and slides. Parity plots use the same box with equal x/y limits — no `axis square`, no 8 × 8 box.
- Only exception: very long y tick labels (5–6 digit numbers) → left margin 4.5 cm.
- If a legend or labels go outside the axes, enlarge the figure window (last element of `Position`); never shrink the axes. Keep `axPos(2)+axPos(4)` below the figure height.

## 2. Typography of labels

Follow SI/IUPAC conventions:

- **Quantity symbols italic**: `{\itx}`, `{\itt}`, `{\itr}`, `{\itC}`, `{\itE}`, `{\itF}`, `{\it\lambda}`, `{\it\DeltaA}`; for functions write `{\itg}({\itr})` (parentheses upright, not `{\itg(r)}`).
- **Upright**: units, chemical/material names, descriptive subscripts (`{\itE}_{ref}`, `{\itE}_{model}`), numbers.
- Always **`Quantity (unit)`**: `'{\itt} (ps)'`, `'{\itC} (mol/L)'`, `'{\itE} (eV/atom)'`, `'{\itF} (eV/Å)'`. Units in parentheses are never italic.
- **Large magnitudes**: move the power of ten into the unit — `'{\rho} (10^{3} kg m^{-3})'` with data divided by 1e3. Don't use offsets ("E + 59490") or invented Δ-quantities just to shorten ticks. If numbers are intrinsically long, keep integer ticks (`ytickformat('%.0f')`, `ax.YAxis.Exponent = 0`) and widen the left margin.
- Ratio/composition axes: short ticks (`8:0 6:2 4:4 2:6 0:8`), label like `'A : B (n:n)'` (generic `'sol_1 : sol_2 (n:n)'` when several systems share the axis), `xtickangle(0)`. Long tick strings get auto-rotated — shorten them instead.
- Charges/superscripts via TeX: `'X^+'`, `'Y^-'`.
- **No titles** — the caption does that job.
- Legend entries are short and non-redundant: drop prefixes shared by every entry.

## 3. Color system

Colors carry meaning, and one entity keeps one color throughout the paper. The palette below is deliberately **muted and earthy**; flashy "default" palettes (MATLAB defaults, tab10, journal-style NPG, popular web palettes) were tried and rejected as too saturated or too generic.

### 3.1 Categorical palette (RGB/255)

| role | name | RGB |
|---|---|---|
| primary cool anchor | deep navy blue | 47 85 151 |
| primary warm accent | burnt orange | 197 90 17 |
| secondary cool | slate gray-blue | 132 151 176 |
| secondary cool, light | periwinkle | 187 196 255 |
| secondary warm, light | peach | 248 203 175 |
| light warm | butter yellow | 250 230 153 |
| natural | olive green | 84 130 53 |
| accent | plum | 180 60 125 |

What makes it work:
- **Moderate saturation, no pure primaries**: every color is desaturated or darkened, so many series can coexist without shouting.
- **One complementary backbone**: navy blue vs burnt orange is the main high-contrast pair; use it for the two most important categories.
- **Dark + light tints of the same families**: gray-blue/periwinkle next to navy, peach next to orange — related categories get related colors.
- **Light tints are for fills and markers, not thin lines**: butter yellow, peach and periwinkle fade on white; use them as marker fills (with a dark edge) or when a series is secondary. If one must be a line, make it thick or give markers a dark edge.
- Marker edges: dark navy `[32 56 100]` or black, which keeps light fills legible.

### 3.2 Two-series comparison pair

Reference vs model / measured vs simulated / method A vs method B: **dark wine `[79 0 11]` solid** for the reference, **coral `[255 127 81]` dashed** for the approximation. Same hue family, dark vs light → reads as "the same thing, two estimates". The model/approximation is **always dashed** wherever methods are compared.

### 3.3 Gradients

- **Sequential (a parameter increases: concentration, λ, time, size)**: one hue family, light → dark. Either blend a base color with white (`c*w + (1-w)`, w from 0.2 to 1 — below 0.2 it vanishes on white), or the two-color ramp peach-white `[251 232 219]` → navy `[47 85 151]`.
- **Interpolation between two categories (mixtures, alloys, A→B compositions)**: interpolate each point's color from category A's color to B's; each line segment takes the mean of its end colors. Distinguish two such series by marker shape, not by color.
- A gradient has to be visible: if neighboring steps can't be told apart, widen the range; don't layer two gradients of similar hue in one axes (they blur) — then encode the parameter by color and the method by line style instead, or reconsider.

### 3.4 Neutrals

Totals/sums medium gray `[0.55 0.55 0.55]`; reference lines (y = x, baselines) dark gray `[0.2 0.2 0.2]` or black, thin; shaded bands gray with `FaceAlpha` 0.12–0.15; axes and tick labels always black.

### 3.5 Choosing new colors

When a figure needs categories that have no established color, stay within the families above. If the user is unhappy, show several candidate palettes side by side as rendered swatches with sample curves and let them pick; don't keep guessing blindly. Avoid: rainbow ordering, many saturated hues at once, a dark opaque series drawn last over a dense scatter (it hides everything), colored axis rulers.

## 4. Lines, markers, reference elements

- Data lines `widthofline` (2.6; 2 for noisy series); reference lines 1.2–1.5.
- Line-style grammar, fixed across the paper: solid = reference/measured/primary; dashed = model/approximation or second reference scale; dash-dot = second quantity on a right axis. State the mapping once (legend or caption).
- Parity plots: points, y = x solid dark gray 1.5, optional ±tolerance as dashed lines plus a light gray fill; identical x/y limits and ticks; print MAE/RMSE with `fprintf` instead of writing them on the plot.
- Dense scatter (≥10⁵ points): plot a random subsample (fixed `rng` seed, ~10⁴ per group), `MarkerFaceAlpha` ≈ 0.45, statistics on the full data. Too many points make *Copy Figure* fall back to a bitmap or run out of memory.
- Draw background/bulk data first, highlighted data last.

## 5. Legends

- Font `sizeoffont-8` by default (`-6` for more emphasis); no box.
- In a set of similar panels, often **only one figure carries the legend**; comment the others out rather than deleting.
- Legend keys must be legible even when data markers are tiny/transparent: build keys from `plot(nan,nan,…)` dummies (full-size, opaque) and give the real data `'HandleVisibility','off'`.
- When color encodes one thing and line/marker another, give separate keys: colored lines for the entities, gray-filled markers or black lines for the style meaning.
- Two legend groups (e.g. two data families in opposite empty corners of a parity plot, or entities vs scales): put the second legend on a **tiny, invisible, off-plot axes** and place it in cm. Return focus with `set(gcf,'CurrentAxes',ax)`, not `axes(ax)` (which raises the main axes over the second legend). Don't make the main axes transparent.
- Legend above the axes: position it manually right on top of the axes (units cm, gap ~0.1 cm), re-set the axes position afterwards, and enlarge the figure height.
- Text labels next to curves are black and unobtrusive; offer to drop them if the user annotates in slides.

## 6. Insets / zoom-in figures

Draw zoom-ins as separate figures the user will shrink into an inset: no axis labels, no legend, ticks only, larger font (`sizeoffont+8`) so ticks survive down-scaling, same axes box and styles as the parent, zoom window as a named variable.

## 7. Recurring figure types → `references/templates.md`

Two-series comparison · parity plot with tolerance band · offset (waterfall) stacking with real-value ticks · category-to-category gradient series · two reference scales on left/right axes · two-group legend · zoom-in inset.

## 8. Consistency checklist (before handing over)

1. configPlot call, `axPos`, font, line width, marker size identical to the sibling scripts; `configPlot` appended once at the end.
2. Same entity → same color and line style as in every other figure; approximations dashed.
3. Labels: italic quantities, upright units/names, `Quantity (unit)`, power of ten in the unit, no titles.
4. 3–5 major ticks, horizontal tick labels, identical x/y ticks on parity plots.
5. Legend font/placement match the siblings; legend only where agreed.
6. Shared axes (ratios, parameters) run in the same direction and use the same naming in every figure — flag mismatches.
7. Data read by header text; ranges checked; limits don't silently clip data (report what falls outside).
8. No titles, no file export, no transparent axes, no unused variables.

In the reply, summarize the change per figure, list the knobs to tune, and briefly flag anything that needs the user's decision.
