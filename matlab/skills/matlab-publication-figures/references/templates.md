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
9. Page-wide panel grid
10. Spectra-style column profiles (sparse parameter, shared full scale)
11. Categorical grid with side strip, summary rows and threshold markers

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

## 9. Page-wide panel grid

```matlab
figW = 2*6.5*2.54;                    % 2 x text width (6.5 in); pasted at 50 %
x0 = 2.2; y0 = 2.3; gx = 0.6; gy = 0.5; labR = 3.9;   % margins trimmed to the content
nCol = 3; nRow = 3; ph = 4.2;
pw = (figW - x0 - (nCol-1)*gx - 0.4 - labR)/nCol;     % panel width follows the page width
figH = y0 + nRow*ph + (nRow-1)*gy + 1.1;              % keep below ~25 cm
figure('Name','Fig. N: panel grid','Position',[2 2 figW figH]);
for r = 1:nRow
    for k = 1:nCol
        ax = axes('Units','centimeters','Position',[x0+(k-1)*(pw+gx), y0+(nRow-r)*(ph+gy), pw, ph]);
        hold on; box on; set(ax,'FontSize',sizeoffont,'LineWidth',1.2,'Layer','top');
        % ... plot ...
        if r == 1, title(colName{k},'FontSize',sizeoffont,'FontWeight','normal'); end
        if r < nRow, xticklabels([]); else, xlabel('{\itC} (M)'); end
        if k == 1, ylabel('{\itz} (Å)'); else, yticklabels([]); end
    end
end
```
Render once, measure the blank border of the PNG and adjust `x0`, `y0`, `labR` and the top margin
until about 0.1 cm is left on every side.

## 10. Spectra-style column profiles (sparse parameter, shared full scale)

One column per sampled parameter value; the profile of that sample is drawn to the right of its
baseline. In a row, every column and panel uses the same full scale `rmax`.

```matlab
xl   = @(n) [0.85, n + 0.9];                         % first baseline close to the left frame
wmin = pw/diff(xl(nMax));                            % cm, narrowest column of the figure
rmax = max(cellfun(@(R) max(R,[],'all'), rowData));  % full scale of the row
f = 0.84*wmin/(pw/diff(xl(n)));                      % same cm per unit in every panel of the row
for j = 1:n
    x = j + f*R(:,j)/rmax;
    fill([j; x; j], [z(1); z; z(end)], col, 'FaceAlpha',0.35, 'EdgeColor','none');
    plot(x, z, '-', 'Color',col, 'LineWidth',1.5);
    plot([j j], z_lim, '-', 'Color',0.7*[1 1 1], 'LineWidth',0.8);    % baseline on the tick
end
xlim(xl(n)); xticks(1:n); xticklabels(compose('%.1f',v)); xtickangle(0)
% feature position (e.g. first peak) on selected columns: dotted to the next column, value below
xe = min(j + 1, max(xl(n)));
plot([j xe], zp*[1 1], ':', 'Color',0.3*[1 1 1], 'LineWidth',2.2);
text(xe - 0.04, zp, sprintf('%.1f Å', zp), 'Color',0.3*[1 1 1], 'FontSize',sizeoffont-8, ...
    'HorizontalAlignment','right', 'VerticalAlignment','top');
% full scale, once per row, outside and aligned with the other rows
annotation('textbox','Units','centimeters','Position',[x0+nCol*pw+(nCol-1)*gx+0.4, axB, labR, ph], ...
    'String',{'{\it\rho} (unit)', sprintf('{\it\rho}_{max} = %.1f', rmax)}, 'Color',col*0.85, ...
    'EdgeColor','none','VerticalAlignment','middle','FontSize',sizeoffont-4,'Margin',0);
```
First-feature finder: first local maximum above ~10 % of the profile maximum (weak but real first
layers count); print the positions with `fprintf`.

## 11. Categorical grid with side strip, summary rows and threshold markers

```matlab
% cells: rectangle per (row r, column i); value text in the upper half, markers in the lower half
rectangle('Position',[i-0.5, r-0.5, 1, 1], 'FaceColor',cellColor, 'EdgeColor','none');
text(i, r-0.24, sprintf('%.2f', V(r,i)), 'HorizontalAlignment','center', 'FontSize',sizeoffont-10);
gx_of = @(i,u) i - 0.5 + 0.14 + (u - u_lo)/(u_hi - u_lo)*0.72;    % shared value axis inside the cells
plot(gx_of(i,T(i)), r+0.18, 'o', 'MarkerFaceColor',cThr, 'MarkerEdgeColor',cEdge, 'LineWidth',1.3, 'MarkerSize',6.5);
plot(gx_of(i,V(r,i)), r+0.18, mk(r), 'MarkerFaceColor',cCat(r,:), 'MarkerEdgeColor',cEdge, 'LineWidth',1.3, 'MarkerSize',6.5);
% side strip: group color, darker with a larger count inside the group
t  = (cnt(r) - min(cnt))/max(max(cnt) - min(cnt), 1);
cg = interp1([0 0.5 1], [0.45*cBase + 0.55; cBase; 0.70*cBase], t);
annotation('rectangle','Units','centimeters','Position',[axX-0.33, axB+(nr-r)*cellH+0.04, 0.25, cellH-0.08], ...
    'FaceColor',cg,'EdgeColor','none');
% white cell borders, thicker above the summary rows; no column borders through a row written once
plot([0.5 nc+0.5], [nk nk]+0.5, 'w-', 'LineWidth',4);
text((nc+1)/2, nk+2, sprintf('%.2f', constValue), 'HorizontalAlignment','center', 'FontWeight','bold');
% two numbers in one cell, colored by category: 'a/b'
two = @(a,b) sprintf('\color[rgb]{%.3f %.3f %.3f}%.0f\color[rgb]{0.4 0.4 0.4}/\color[rgb]{%.3f %.3f %.3f}%.0f', cA, a, cB, b);
```
Color bar below the first column; legend of the markers in one row under it, centred on the color bar
by measuring its text extent.
