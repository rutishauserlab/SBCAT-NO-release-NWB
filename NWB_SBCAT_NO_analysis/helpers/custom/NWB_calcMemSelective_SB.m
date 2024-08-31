function [sig_cells,areasSternberg] = NWB_calcMemSelective_SB(nwbAll, all_units, params)
%NWB_CALCSELECTIVE Takes the output of NWB_SB_extractUnits and runs memory
%selectivity tests for the sternberg task. Optionally plots trial aligned
%spikes

if isfield(params,'rateFilter') && ~isempty(params.rateFilter) && params.rateFilter > 0
    rateFilter = params.rateFilter;
else
    rateFilter = [];
end

% Filtering for Global Rate (rateFilter should be a nonzero float)
if ~isempty(rateFilter)
    aboveRate = rateFilter_units(nwbAll,all_units,rateFilter);
end
all_units = all_units(logical(aboveRate));


areasSternberg = cell(length(all_units),1);
mem_cells_sb = zeros(length(all_units),1); 
hzPref = zeros(length(all_units),1);
hzNonPref = zeros(length(all_units),1);
% Looping over all cells
for i = 1:length(all_units) 
    SU = all_units(i);
    subject_id = SU.subject_id;
    session_id = SU.session_id;
    identifier = SU.identifier;
    cellID = SU.unit_id;
    brain_area = nwbAll{SU.session_count}.general_extracellular_ephys_electrodes.vectordata.get('location').data.load(SU.electrodes);
    clusterID = nwbAll{SU.session_count}.units.vectordata.get('clusterID_orig').data.load(SU.unit_id);
    areasSternberg{i} = brain_area{:};
    fprintf('Processing: (%d/%d) sub-%s-ses-%s, Unit %d Cluster %d ',i,length(all_units),string(subject_id),string(session_id),cellID,clusterID)
    
    % Loading stim timestamps from LTM part
    tsPic = nwbAll{SU.session_count}.intervals.get('LTM_trials').vectordata.get('timestamps_PicOnset').data.load();
    old = double(nwbAll{SU.session_count}.intervals.get('LTM_trials').vectordata.get('new_old').data.load());
    acc = logical(nwbAll{SU.session_count}.intervals.get('LTM_trials').vectordata.get('response_accuracy').data.load());

    old = old(acc); % only correct trials
    tsPic = tsPic(acc);
    
    %% Get all stimulus rates
    signalDelay = 0.2; % Delay of stimulus onset to effect. 
    stimOffset = 1.2; % Time past stimulus onset. End of picture presentation.
    trialRate = NaN(length(old),1);
    for k = 1:length(old)
        singleTrialSpikes = SU.spike_times((SU.spike_times>(tsPic(k)+signalDelay)) & (SU.spike_times<(tsPic(k)+stimOffset)));
        trialRate(k) = length(singleTrialSpikes); % spike count across testing period.
    end
    
    %% Significance Tests: Mem cells
    alphaLim = 0.05;

    a = trialRate(old==1); b = trialRate(old~=1);
    [~,~,p_perm] = statcond({a',b'},'paired','off','method', 'perm', 'naccu', 10000, 'verbose','off');

    if p_perm < alphaLim %
        fprintf('| Mem-Sel -> sub-%s-ses-%s, Unit %d p:%.2f',string(SU.subject_id),string(SU.session_id),SU.unit_id,p_perm)
        mem_cells_sb(i) = 1;
    end

    %% Rasters, PSTH
    % Flagging significant cells for plotting
    plotFlag = params.doPlot && mem_cells_sb(i);
    if plotFlag || params.plotAlways
        warning('Plotting not specified yet for mem cells...')
    end
    fprintf('\n')
end
fprintf('Total Mem-Selective Cells: %d/%d (%.2f%%)\n',sum(mem_cells_sb),length(all_units),sum(mem_cells_sb)/length(all_units)*100)
sig_cells.ms_cells = mem_cells_sb;
end

