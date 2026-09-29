# Templates

Style-compliant building blocks. Each assumes the common header from SKILL.md §1
(`sizeoffont`, `widthofline`, `markersize`, `configPlot(...)`, `axPos = [3.5 3.4 8 6]`)
and ends with `configPlot` appended as a local function. Adapt data and names; keep the styling lines.

Contents
1. Reading data robustly
2. Two-series comparison
3. Parity plot with tolerance band
4. Offset (waterfall) stacking with real-value ticks
5. Category-to-category gradient series
6. Two reference scales on left/right y axes
7. Two-group legend
8. Zoom-in / inset figure

---

## 1. Reading data robustly

```matlab
% text data with comment/header lines (e.g. '#', '@')
data = readmatrix(f,'FileType','text','CommentStyle',{'#','@'});
% readmatrix may add a leading NaN column for whitespace-led rows -> check columns once;
% textread(f,'','headerlines',N) is a safe fallback.

% spreadsheet: locate columns by header text
raw = readcell(fname);
isBlank = @(v) isa(v,'missing') || (isnumeric(v)&&isnan(v)) || (ischar(v)&&isempty(strtrim(v)));
hdr = raw(1,:); hdr(cellfun(isBlank,hdr)) = {''};
hdr = cellfun(@(h) regexprep(char(string(h)),'\s',''), hdr, 'UniformOutput', false);
cX = find(contains(hdr,'unique-substring'),1);     % verify it matches only one column

function v = to_num(c)                              % '-', empty, missing -> NaN
    if isnumeric(c) && isscalar(c), v = double(c); else, v = NaN; end
end
```
Forward-fill merged cells (group name only on a group's first row) while looping over rows.

## 2. Two-series comparison

```matlab
names  = {'Reference','Model'};
styles = {'-','--'};                        % model always dashed
colors = [79 0 11; 255 127 81]/255;         % dark wine, coral
figure; hold on
for m = 1:2
    plot(x{m}, y{m}, styles{m}, 'Color',colors(m,:), 'LineWidth',widthofline, ...
        'DisplayName',names{m});
end
xlabel('{\itx} (unit)','FontSize',sizeoffont)
ylabel('{\ity} (unit)','FontSize',sizeoffont)
legend('show','Location','northeast','FontSize',sizeoffont-8)
set(gca,'unit','centimeter','position',axPos,'fontsize',sizeoffont);
box on; xlim(x_lim); ylim(y_lim)
```
Several quantities of one system in the same axes: keep color = method; the curves' positions
separate the quantities, which the caption (or slide text) names.

## 3. Parity plot with tolerance band

```matlab
lim = [lo hi]; tk = lo:step:hi; band = 0.2;
figure; hold on
fill([lim(1) lim(2) lim(2) lim(1)], [lim(1)-band lim(2)-band lim(2)+band lim(1)+band], ...
    [0.55 0.55 0.55],'EdgeColor','none','FaceAlpha',0.15,'HandleVisibility','off');
plot(lim, lim,      '-',  'Color',[0.2 0.2 0.2],'LineWidth',1.5,'HandleVisibility','off');
plot(lim, lim+band, '--', 'Color',[0.2 0.2 0.2],'LineWidth',1.2,'HandleVisibility','off');
plot(lim, lim-band, '--', 'Color',[0.2 0.2 0.2],'LineWidth',1.2,'HandleVisibility','off');
for i = 1:numel(groups)
    plot(xr(idx{i}), yp(idx{i}), 'o', 'LineStyle','none', 'LineWidth',1.5, ...
        'MarkerFaceColor',col(i,:), 'MarkerEdgeColor',[32 56 100]/255, ...
        'MarkerSize',markersize, 'DisplayName',groups{i});
end
fprintf('MAE = %.4f\n', mean(abs(yp-xr)));      % print, don't annotate
xlabel('{\itQ}_{ref} (unit)','FontSize',sizeoffont)
ylabel('{\itQ}_{model} (unit)','FontSize',sizeoffont)
set(gca,'unit','centimeter','position',axPos,'fontsize',sizeoffont);
box on; xlim(lim); ylim(lim); xticks(tk); yticks(tk); xtickangle(0)
```
Dense version: `scatter(x,y,6,col,'filled','MarkerEdgeColor','none','MarkerFaceAlpha',0.45,
'HandleVisibility','off')` on a subsample (`rng(2026); randperm(n,min(n,1e4))`), legend keys from
`plot(nan,nan,'o','MarkerFaceColor',col,'MarkerEdgeColor','none','MarkerSize',11)`.

## 4. Offset (waterfall) stacking with real-value ticks

For several curves of one quantity that overlap too much to read.

```matlab
offset = 2000;  tick_v = [0 1];          % real values marked on each curve (here in 10^3 units)
figure; hold on; y_tick = []; y_top = 0;
for c = 1:n
    y0 = (c-1)*offset;
    y_tick = [y_tick, y0 + 1000*tick_v];
    plot(x{c}, y{c}+y0, '-', 'Color',cmap(c,:), 'LineWidth',widthofline, 'HandleVisibility','off');
    y_top = max(y_top, max(y{c})+y0);
    text(x_lim(2)+0.1, y_end(c), label{c}, 'Color','k','FontSize',sizeoffont-6,'Clipping','off');
end
set(gca,'unit','centimeter','position',axPos,'fontsize',sizeoffont);
box on; xlim(x_lim); ylim([0 1.1*y_top])
yticks(y_tick); yticklabels(string(repmat(tick_v,1,n)));
ax = gca; ax.YAxis.FontSize = sizeoffont-8;   % small tick labels, full-size axis label
ylabel('{\it\rho} (10^{3} kg m^{-3})','FontSize',sizeoffont);
```
Tick and curve labels stay black. Choose `offset` larger than the tallest peak.

## 5. Category-to-category gradient series

```matlab
c1 = colA; c2 = colB; n = numel(x);
cmap = [linspace(c1(1),c2(1),n)', linspace(c1(2),c2(2),n)', linspace(c1(3),c2(3),n)'];
for j = 1:n-1
    plot(x(j:j+1), y(j:j+1), '-', 'Color',(cmap(j,:)+cmap(j+1,:))/2, ...
        'LineWidth',widthofline, 'HandleVisibility','off');
end
for j = 1:n
    plot(x(j), y(j), 'o', 'MarkerFaceColor',cmap(j,:), 'MarkerEdgeColor',[0 0 0], ...
        'MarkerSize',markersize, 'HandleVisibility','off');
end
plot(nan,nan,'-o','Color',cmap(ceil(n/2),:),'LineWidth',widthofline, ...          % legend key
    'MarkerFaceColor',cmap(ceil(n/2),:),'MarkerEdgeColor',[0 0 0],'MarkerSize',markersize, ...
    'DisplayName','A-B');
xticks(0:2:8); xticklabels({'8:0','6:2','4:4','2:6','0:8'}); xtickangle(0);
xlabel('A : B (n:n)','FontSize',sizeoffont)
```
Pure-component series elsewhere keep their fixed category colors (no gradient); a second A–B type
series in the same axes gets a different marker shape.

## 6. Two reference scales on left/right y axes

For data sets measured against different references that should be compared on one plot. Derive the
offset between scales from items measured on both, then lock the right axis to the left one.

```matlab
shift = mean(U_scale1_overlap - U_scale2_overlap);   % print it for the caption
y_lim1 = [a b];
figure; hold on; ax = gca;
yyaxis left
plot(x1, y1, '--s', 'Color',c, 'LineWidth',widthofline, 'MarkerFaceColor',c, ...
    'MarkerEdgeColor',[0 0 0], 'MarkerSize',markersize, 'HandleVisibility','off');
ylabel('{\itU} (V scale 1)'); ylim(y_lim1)
yyaxis right; hold on
plot(x2, y2, '-o', 'Color',c, 'LineWidth',widthofline, 'MarkerFaceColor',c, ...
    'MarkerEdgeColor',[0 0 0], 'MarkerSize',markersize, 'HandleVisibility','off');
ylabel('{\itU} (V scale 2)'); ylim(y_lim1 - shift)       % same physical scale
ax.YAxis(1).Color = [0 0 0]; ax.YAxis(2).Color = [0 0 0];
```
Encode the scale by line style + marker shape and explain it with gray-filled marker keys (second
legend, §7). Only `y_lim1` is tuned; the right axis follows.

## 7. Two-group legend

```matlab
function split_legend(h, font)
% h(1:2) top-left on the main axes, h(3:4) bottom-right via a tiny off-plot axes
ax = gca;
legend(ax, h(1:2), 'Location','northwest', 'FontSize',font);
axPos = get(ax,'Position');                               % cm
ax2 = axes('Units','centimeters','Position',[0 0 0.01 0.01], ...
    'Visible','off','Color','none','HitTest','off');
hold(ax2,'on');
lgd2 = legend(ax2, copyobj(h(3:4),ax2), 'FontSize',font);
lgd2.Units = 'centimeters';
lgd2.Position(1:2) = [axPos(1)+axPos(3)-lgd2.Position(3)-0.1, axPos(2)+0.1];
set(gcf,'CurrentAxes',ax);        % not axes(ax): that would cover the second legend
end
```
Call it after `set(gca,'unit','centimeter','position',axPos,...)`.

## 8. Zoom-in / inset figure

```matlab
font_zoom = sizeoffont + 8;
figure; hold on
for m = 1:2
    plot(x{m}, y{m}, styles{m}, 'Color',colors(m,:), 'LineWidth',widthofline);
end
set(gca,'unit','centimeter','position',axPos,'fontsize',font_zoom);
box on; xlim(x_lim_zoom)          % no xlabel / ylabel / legend
```
