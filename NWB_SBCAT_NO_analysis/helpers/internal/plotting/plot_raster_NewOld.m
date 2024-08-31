function plot_raster_NewOld(nwb,neuron)
%% plot_raster_NewOld(nwb,neuron)
%
% plots raster and PSTH for given session and neuron during LTM retrieval
% JD 2024

binsize = 200;
stepsize = 25;
toi = [-.5 1.5]; % pic

h = figure('position',[600 300 350 500]);
markercolor = {[89 21 173]/255,[26 168 196]/255}; 

fs = 3200; % "sampling rate", arbitrary, needed for raster

tvec = toi(1):1/fs:toi(2);
binwin = binsize/1000*fs;
stepsize_samples = stepsize/1000 * fs;

acc = logical(nwb.intervals.get('LTM_trials').vectordata.get('response_accuracy').data.load());
old = double(nwb.intervals.get('LTM_trials').vectordata.get('new_old').data.load());
ts = nwb.intervals.get('LTM_trials').vectordata.get('timestamps_PicOnset').data.load();

% only correct trials
ts = ts(acc);
old = old(acc);

%get spike times
spike_times = neuron.spike_times;

% init
n_trials = length(ts);

raster = zeros(n_trials,length(tvec));
PSTH = zeros(n_trials,length(tvec));

% build raster
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

% sort trials
[sorted,idx] = sort(old==1);

[yPoints,xPoints] = find(raster(idx(sorted==1),:));
[yPoints_np,xPoints_np] = find(raster(idx(sorted==0),:));
xPoints = tvec(xPoints);
xPoints_np = tvec(xPoints_np);

subplot(2,1,2)
hold on
plot(xPoints_np,yPoints_np,'Marker','.','LineStyle','none','MarkerFaceColor',markercolor{2},'MarkerEdgeColor',markercolor{2},'MarkerSize',8);
plot(xPoints,yPoints+sum(sorted==0),'Marker','.','LineStyle','none','MarkerFaceColor',markercolor{1},'MarkerEdgeColor',markercolor{1},'MarkerSize',8);
set(gca,'ylim',[0 n_trials + 1])
xlabel('Time (s)')
ylabel('Trials (re-ordered)')

% PSTH
mean_pref = mean(PSTH(idx(sorted==1),:));
mean_nonpref = mean(PSTH(idx(sorted==0),:));
std_pref = std(PSTH(idx(sorted==1),:));
std_nonpref = std(PSTH(idx(sorted==0),:));

mean_pref_PlusSEM = mean_pref + std_pref/sqrt(sum(sorted));
mean_pref_MinusSEM = mean_pref - std_pref/sqrt(sum(sorted));
mean_nonpref_PlusSEM = mean_nonpref + std_nonpref/sqrt(sum(sorted==0));
mean_nonpref_MinusSEM = mean_nonpref - std_nonpref/sqrt(sum(sorted==0));

subplot(2,1,1);
hold on
fill( [tvec_PSTH fliplr(tvec_PSTH)],  [mean_pref_PlusSEM fliplr(mean_pref_MinusSEM)], markercolor{1},'linewidth',0.25);
fill( [tvec_PSTH fliplr(tvec_PSTH)],  [mean_nonpref_PlusSEM fliplr(mean_nonpref_MinusSEM)], markercolor{2},'linewidth',0.25);
plot(tvec_PSTH, mean_pref, 'k', 'LineWidth', .5)
plot(tvec_PSTH, mean_nonpref, 'k', 'LineWidth', .5)

alpha(.8);

legend('Familiar (old)', 'Novel (new)')
ylabel('Firing rate (Hz)')
set(h.Children, 'fontsize',18,'fontname','Arial')
title('Retrieval')
