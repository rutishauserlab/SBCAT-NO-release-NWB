%% NWB_SBCAT_import_main
% Sample code to load/analyze the provided dataset for Daume et. al. 2024
% Calculates the following:
%   - Behavioral metrics
%   - Determine category-selective/memory-selective cells
%   - Proportion of CAT/MS cells per area
%   - Compute and plot results of main GLM analysis (Fig. 3a)
%   - Plotting of sample cells (Fig. 2a,4a)
%

clear; clc; close all
fs = filesep;
%% Parameters
% The first section of the script sets important parameters.
% The importRange is the range of files for the dataset. 
% For the current release, subject IDs have a range of 1:44. 
% The full range can also be specified by setting importRange=[]


% subject IDs for dataset.
importRange = []; % Full Range
% importRange = [1:3]; % Arbitrary example
% importRange = [6]; % SB-CAT Example Cat Cell (See Daume et. al. Fig 2a)
% importRange = [25]; % MS Example Cell (See Daume et. al. Fig 4a)


%% Initializing and pathing
% The script then defines the directory paths for the code, 
% the currently installed MatNWB package, and the dataset, 
% and then adds them to the MATLAB path. If figures are generated, 
% there is an additional option to add a custom save destination. 
% Please ensure that the defined paths in the script are correct for your 
% setup. This section also uses MatNWB's generateCore() function to 
% initialize the NWB API if it has not been initialized already.

paths.baseData = '/path-to-folder/Dandisets/001187'; % Dataset directory
paths.nwb_sb = paths.baseData; % Dandiset Directory
% This script should be in master directory
scriptPath = matlab.desktop.editor.getActiveFilename; scriptPathParse = split(scriptPath,fs); scriptPathParse = scriptPathParse(1:end-1);
paths.code = strjoin(scriptPathParse,filesep); 
paths.matnwb = '/path-to-matlab-folder/MATLAB/matnwb-2.6.0.2';
paths.figOut = [strjoin(scriptPathParse(1:end-1),filesep) fs 'sbcat_no_figures'];
% Helpers
if(~isdeployed) 
  cd(fileparts(matlab.desktop.editor.getActiveFilename));
  addpath(genpath([pwd fs 'helpers'])) % Should be in same folder as active script. 
else
    error('Unexpected error.')
end

pathCell = struct2cell(paths);
for i = 1:length(pathCell)
    addpath(genpath(pathCell{i}))
end

% Initialize NWB Package
% generateCore() for first instantiation of matnwb API
fprintf('Checking generateCore() ... ')
if isfile([paths.matnwb fs '+types' fs '+core' fs 'NWBFile.m'])
     fprintf('generateCore() already initialized.\n') %only need to do once
else 
    cd(paths.matnwb)
    generateCore();
    fprintf('generateCore() initialized.\n')
end 

%% Importing Datasets From Folder
% The script will then import datasets from the given folder using the 
% NWB_importFromFolder function. Only files specified using importRange 
% will be loaded into the workspace.

tic % It is highly recommended to load nwb files from local drives for speed.
[nwbAll_sb, importLog_sb] = NWB_importFromFolder_SBCAT_NO(paths.nwb_sb, importRange);
toc

%% Extracting Single Units
% Single unit information is extracted from the loaded NWB files for ease of 
% indexing, using the NWB_SB_extractUnits function. If spike waveforms are 
% not needed for analysis, the load_all_waveforms flag can be set to 0 to 
% only extract the mean waveform. All future plots will use this mean 
% waveform instead of a spike waveform pdf.

load_all_waveforms = 1; % Extracts all by default. Set to '0' to only extract the mean waveform. 
fprintf('Loading SternbergCAT_NO\n')
all_units_sbcat = NWB_SB_extractUnits(nwbAll_sb,load_all_waveforms);  

%% Plot behavior
% plots behavior as in Fig. 1c-g (Daume et al. 2024b)
% set inputRange to full range, it will crash when only a single session is
% loaded in

paramsSB.plotBehavior = 1;
if paramsSB.plotBehavior
    plot_behavior(nwbAll_sb);
end


%% STERNBERG Params
paramsSB.doPlot = 0;  % if =1, plot significant cells. 
paramsSB.plotAlways = 0; % Plot regardless of selectivity (NOTE: generates a lot of figure windows unless exportFig=1)
paramsSB.exportFig = 0; % this worked fine on Windows but created problems on a Mac (M3, Matlab 2024a)
paramsSB.exportType = 'png'; % File type for export. 'png' is the default. 
paramsSB.rateFilter =  0.1; % Rate filter in Hz. Removes cells from analysis that are below threshold. Setting to empty disables the filter. 
paramsSB.figOut = [paths.figOut fs 'stats_sternberg'];

%% Determine Category Cells
% This section selects for category neurons in all areas. It is preceded by
% a parameters section, which allows for the 
% control of various stages of the analysis and plotting process. 
% For example, one can choose to plot figures for significant cells by 
% setting paramsSC.doPlot = 1 or filter units being used for analysis by 
% specifying a minimum firing rate threshold paramsSC.rateFilter. To disable 
% analysis of all cells entirely, set paramsSC.calcSelective = 0.

% category neuron count might slightly vary from Daume et al. 2024 due to
% using permutation tests
paramsSB.calcSelective = 1;
if paramsSB.calcSelective
    [sig_CatCells_sb, areas_sb_cat] = NWB_calcCatSelective_SB(nwbAll_sb,all_units_sbcat,paramsSB);
end
%% Category Cells Per-Area
% This section calculates the proportion of 
% category-selective cells across each area measured (compute the previous section first) 
% It is intended to use `importRange = []`.

specify_selectivity = 1; % Set importRange to full range
if paramsSB.calcSelective && specify_selectivity
    % Getting selectivity
    sig_cells_total = logical(sig_CatCells_sb.cat_cells);
    unit_areas = cellfun(@(x) condenseAreas(x),areas_sb_cat,'UniformOutput',false);
    % Areas of selective cells
    selective_areas = unit_areas(sig_cells_total);
    
    [unique_labels, ~, label_assignments] = unique(unit_areas);
    label_hist = histcounts(label_assignments);

    [unique_labels_selective, ~, label_assignments_selective] = unique(selective_areas);
    label_hist_selective = histcounts(label_assignments_selective);
    
    is_identical = strcmp(unique_labels,unique_labels_selective);
    if all(is_identical)
        selective_proportions = label_hist_selective./label_hist*100;
        for i = 1:length(unique_labels)
            fprintf('%s %.2f%% (%d/%d)\n',unique_labels{i}, selective_proportions(i),label_hist_selective(i),label_hist(i) )
        end
    else
        error('Labels not identical.')
    end
end

%% Cat-selective neuron Example.
% This section plots the example category-selective cell that can be 
% found in Fig 2a of Daume et al (2024b). 

% Specify by sub-id, ses-id, unit_id, preferred CAT
unit_example = [5, 1, 16, 2]; % sub-5-ses-1 cell 29 % Category 2: Animals

paramsSB_ex.processExamples = 1;
if paramsSB_ex.processExamples
    [nwb_filtered,unit_filtered] = NWB_SB_filter_session(nwbAll_sb,all_units_sbcat,unit_example);
    plot_raster_pic1_delayWM(nwb_filtered,unit_filtered,unit_example(4))
end


%% Compute GLM
% This computes the mixed-model GLM used for Fig. 3a in Daume et al. 2024b
% and prints/plots its results
% This needs the output from the "Determine Category Cells" section as it
% computes the GLM across all category neurons

paramsSB.doPlot = 1;
paramsSB.computeGLM = 1;

if paramsSB.computeGLM
    m = NWB_computeGLM(nwbAll_sb, all_units_sbcat, sig_CatCells_sb, paramsSB);

    % print GLM
    disp(m)

    %Plot
    if paramsSB.doPlot
        figure; hold on
        predictors = m.Coefficients.Name(2:end);
        b = bar(m.Coefficients.Estimate(2:end),'facecolor',[.5 .5 .5]);
        b.FaceAlpha = .6;
        e = errorbar(m.Coefficients.Estimate(2:end),m.Coefficients.SE(2:end),'k.');
        e.CapSize = 20;
        xlabel('Predictors')
        ylabel('beta')
        set(gca,'xtick',1:length(predictors),'xticklabel',predictors,'fontsize',18,'xlim',[0.5 length(predictors)+0.5],'xticklabelrotation',45)
        ylim([-50 100])
    end
end

%% Determine Memory-selective Cells
% This section selects for MS neurons in both areas. Use the
% parameters section above to allow for the 
% control of various stages of the analysis and plotting process. 

paramsSB.doPlot = 0; %plotting not implemented for MS cells
paramsSB.calcSelective = 1;
if paramsSB.calcSelective
    [sig_MSCells_sb, areas_sb_mem] = NWB_calcMemSelective_SB(nwbAll_sb,all_units_sbcat,paramsSB);
end

%% MS Cells Per-Area
% This section calculates the proportion of 
% memory-selective cells across each area measured (compute the previous section first) 
% It is intended to use `importRange = []`.

specify_selectivity = 1; % Set importRange to full range
if paramsSB.calcSelective && specify_selectivity
    % Getting selectivity
    sig_cells_total = logical(sig_MSCells_sb.ms_cells);
    unit_areas = cellfun(@(x) condenseAreas(x),areas_sb_mem,'UniformOutput',false);
    % Areas of selective cells
    selective_areas = unit_areas(sig_cells_total);
    
    [unique_labels, ~, label_assignments] = unique(unit_areas);
    label_hist = histcounts(label_assignments);

    [unique_labels_selective, ~, label_assignments_selective] = unique(selective_areas);
    label_hist_selective = histcounts(label_assignments_selective);
    
    is_identical = strcmp(unique_labels,unique_labels_selective);
    if all(is_identical)
        selective_proportions = label_hist_selective./label_hist*100;
        for i = 1:length(unique_labels)
            fprintf('%s %.2f%% (%d/%d)\n',unique_labels{i}, selective_proportions(i),label_hist_selective(i),label_hist(i) )
        end
    else
        error('Labels not identical.')
    end
end

%% MS neuron example. 
% This section plots the example memory-selective cell that can be 
% found in Fig 4a of Daume et al (2024b). 
% Set importRange to 25 to reduce load times
 
% Specify by sub-id, ses-id, unit_id
unit_example = [20, 1, 26]; % sub-20-ses-1 cell 26 

paramsSB_ex.processExamples = 1;
if paramsSB_ex.processExamples
    [nwb_filtered,unit_filtered] = NWB_SB_filter_session(nwbAll_sb,all_units_sbcat,unit_example);
    plot_raster_NewOld(nwb_filtered,unit_filtered)
end
