function makeScatterPlot(D,createNewFig,color)
% D must be a cell, each cell content will be a separate plot in that
% figure
if nargin < 3
    color = [];
end

if nargin < 2
    createNewFig = 1;
end

if createNewFig
    figure;
end

for ifig = 1:length(D)
    m = nanmean(D{ifig});
    semp = m + nanstd(D{ifig})./sqrt(sum(~isnan(D{ifig})));
    semm = m - nanstd(D{ifig})./sqrt(sum(~isnan(D{ifig})));
    if isempty(color)
        scatter((rand(length(D{ifig}),1)*0.1-0.05)+ifig,D{ifig},'filled')
    else
        scatter((rand(length(D{ifig}),1)*0.1-0.05)+ifig,D{ifig},[],color{ifig},'filled')
    end
    hold on
    line([[-0.2 0.2]+ifig], [m m],'color',[0 0 0],'linewidth',.5)
    line([[-0.2 0.2]+ifig], [semp semp],'color',[0 0 0],'linewidth',.25)
    line([[-0.2 0.2]+ifig], [semm semm],'color',[0 0 0],'linewidth',.25)
    maxi(ifig) = max(D{ifig});
    mini(ifig) = min(D{ifig});
end
rnge = (max(maxi) - min(mini))/10;
set(gca,'ylim', [min(mini)-rnge max(maxi)+rnge],'xlim',[0.5 ifig+0.5],'xtick',1:ifig,'fontsize',15);
if length(D) == 2
    line(repmat([1.25 1.75],[length(D{1}) 1])',[D{1}; D{2}],'color',[.5 .5 .5],'linewidth',.25)
end

% box on