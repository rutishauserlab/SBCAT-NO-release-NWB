function plot_raster_pic1_delayWM(nwb,neuron,pref_cat)
%% plot_raster_pic1_delayWM(nwb,neuron,pref_cat)
%
% plots raster and PSTH for given session and neuron for just pic 1 and the
% dlay period in WM task
% JD 2024

binsize = 200;
stepsize = 25;
toi1 = [-.5 2]; % baseline + pic1
toi2 = [0 2.5]; % maintenance

h = figure('position',[100 300 800 500]);
markercolor = {[59 137 168]/255,([209 145 82])/255};

fs = 3200; % "sampling rate", arbitrary, needed for raster

binwin = binsize/1000*fs;
stepsize_samples = stepsize/1000 * fs;

acc = logical(nwb.intervals.get('WM_trials').vectordata.get('response_accuracy').data.load());
pic1 = double(nwb.intervals.get('WM_trials').vectordata.get('PicIDs_Encoding1').data.load());
pic2 = double(nwb.intervals.get('WM_trials').vectordata.get('PicIDs_Encoding2').data.load());
pic3 = double(nwb.intervals.get('WM_trials').vectordata.get('PicIDs_Encoding3').data.load());

ts_enc1 = nwb.intervals.get('WM_trials').vectordata.get('timestamps_Encoding1').data.load();
ts_maint = nwb.intervals.get('WM_trials').vectordata.get('timestamps_Maintenance').data.load();

% only correct trials
ts_enc1 = ts_enc1(acc);
ts_maint = ts_maint(acc);
pic1 = pic1(acc);
pic2 = pic2(acc);
pic3 = pic3(acc);

%get spike times
spike_times = neuron.spike_times;

% init
n_trials = length(ts_enc1);

for iwindow = [1 2]

    switch iwindow
        case 1
            toi = toi1;
            ts = ts_enc1;
        case 2
            toi = toi2;
            ts = ts_maint;
    end    

    % build time vector
    eval(sprintf('tvec = toi%d(1):1/fs:toi%d(2);',iwindow,iwindow));

    raster = zeros(n_trials,length(tvec));
    PSTH = zeros(n_trials,length(tvec));
    
    for i_trial = 1:n_trials
        spks = spike_times;
        spks = spks(spks>(toi(1)+ts(i_trial)) & spks<(toi(2)+ts(i_trial)));
        spkidx = round((spks-(toi(1)+ts(i_trial)))*fs);
        spkidx(spkidx==0) = 1; % just in case there is a 0
        raster(i_trial,spkidx) = 1;
        PSTH(i_trial,:) = movmean(raster(i_trial,:),binwin)*binwin*1000/binsize; % In Hz
    end
    
    PSTH = PSTH(:,1:stepsize_samples:end);
    tvec_PSTH = tvec(1:stepsize_samples:end);
    
    % get pref trials
    switch iwindow
        case 1
            [sorted,idx] = sort(floor(pic1/100)==pref_cat);
        case 2
            [sorted,idx] = sort(any(floor([pic1, pic2, pic3]./100)==pref_cat,2));
    end
    
    [yPoints,xPoints] = find(raster(idx(sorted==1),:));
    [yPoints_np,xPoints_np] = find(raster(idx(sorted==0),:));
    xPoints = tvec(xPoints);
    xPoints_np = tvec(xPoints_np);
    
    subplot(2,2,iwindow+2)
    hold on
    plot(xPoints_np,yPoints_np,'Marker','.','LineStyle','none','MarkerFaceColor',markercolor{2},'MarkerEdgeColor',markercolor{2},'MarkerSize',8);
    plot(xPoints,yPoints+sum(sorted==0),'Marker','.','LineStyle','none','MarkerFaceColor',markercolor{1},'MarkerEdgeColor',markercolor{1},'MarkerSize',8);
    set(gca,'ylim',[0 n_trials + 1])
    xlabel('Time (s)')
    ylabel('Trials (re-ordered)')
    xlim(toi);
    
    % PSTH
    mean_pref = mean(PSTH(idx(sorted==1),:));
    mean_nonpref = mean(PSTH(idx(sorted==0),:));
    std_pref = std(PSTH(idx(sorted==1),:));
    std_nonpref = std(PSTH(idx(sorted==0),:));
    
    mean_pref_PlusSEM = mean_pref + std_pref/sqrt(sum(sorted));
    mean_pref_MinusSEM = mean_pref - std_pref/sqrt(sum(sorted));
    mean_nonpref_PlusSEM = mean_nonpref + std_nonpref/sqrt(sum(sorted==0));
    mean_nonpref_MinusSEM = mean_nonpref - std_nonpref/sqrt(sum(sorted==0));
    
    subplot(2,2,iwindow);
    hold on
    fill( [tvec_PSTH fliplr(tvec_PSTH)],  [mean_pref_PlusSEM fliplr(mean_pref_MinusSEM)], markercolor{1},'LineWidth', .25); %[0.1255 0.698 0.6667]
    fill( [tvec_PSTH fliplr(tvec_PSTH)],  [mean_nonpref_PlusSEM fliplr(mean_nonpref_MinusSEM)], markercolor{2},'LineWidth', .25);
    plot(tvec_PSTH, mean_pref, 'k', 'LineWidth', .5)
    plot(tvec_PSTH, mean_nonpref, 'k', 'LineWidth', .5)
    xlim(toi);

    alpha(.8);
    switch iwindow
        case 1
            title('Encoding')
        case 2
            title('Maintenance');
            legend('Pref', 'NonPref')
    end
    ylabel('Firing rate (Hz)')
    set(h.Children, 'fontsize',18,'fontname','Arial')
end

maxY = max([h.Children([2 4]).YLim]);
minY = min([h.Children([2 4]).YLim]);
for igraph = [2 4]
    h.Children(igraph).YLim = [minY maxY];
end