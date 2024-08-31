function m = NWB_computeGLM(nwbAll, all_units, cat_cells_all, params)
%NWB_computeGLM Takes the output of NWB_SB_extractUnits and runs
% a mixed-effects GLM across all category neurons

if isfield(params,'rateFilter') && ~isempty(params.rateFilter) && params.rateFilter > 0
    rateFilter = params.rateFilter;
else
    rateFilter = [];
end

whichWindow = [0 2.5]; % maintenance
whichWindow_bsl = [-.9 -.3]; % baseline

% Filtering for Global Rate (rateFilter should be a nonzero float)
if ~isempty(rateFilter)
    aboveRate = rateFilter_units(nwbAll,all_units,rateFilter);
end
all_units = all_units(logical(aboveRate));

if length(cat_cells_all.cat_cells) ~= length(all_units)
    error('Number of cateogry neurons and all considered neurons not the same! Make sure to use the same FR filter!')
end

% Looping over all cells
T = table;
counter = 0;
neuron_counter = 0;
warning off
disp('Creating table...')
for i = 1:length(all_units)

    % only consider cat neurons
    if cat_cells_all.cat_cells(i)
        neuron_counter = neuron_counter + 1;
        prefCat = cat_cells_all.pref_cat(i);
        SU = all_units(i);
        subject_id = SU.subject_id;
        session_id = SU.session_id;
        identifier = SU.identifier;
        cellID = SU.unit_id;
        unit_area = SU.unit_area;
        spikes_times = SU.spike_times;

        tsEnc1 = nwbAll{SU.session_count}.intervals.get('WM_trials').vectordata.get('timestamps_Encoding1').data.load();
        tsMaint = nwbAll{SU.session_count}.intervals.get('WM_trials').vectordata.get('timestamps_Maintenance').data.load();
        WM_acc = logical(nwbAll{SU.session_count}.intervals.get('WM_trials').vectordata.get('response_accuracy').data.load());
        ID_Enc1 = double(nwbAll{SU.session_count}.intervals.get('WM_trials').vectordata.get('PicIDs_Encoding1').data.load());
        ID_Enc2 = double(nwbAll{SU.session_count}.intervals.get('WM_trials').vectordata.get('PicIDs_Encoding2').data.load());
        ID_Enc3 = double(nwbAll{SU.session_count}.intervals.get('WM_trials').vectordata.get('PicIDs_Encoding3').data.load());
        picIDs = [ID_Enc1,ID_Enc2,ID_Enc3];

        n_trials = length(ID_Enc1);

        LTM_pics = double(nwbAll{SU.session_count}.intervals.get('LTM_trials').vectordata.get('PicIDs').data.load());
        LTM_acc = logical(nwbAll{SU.session_count}.intervals.get('LTM_trials').vectordata.get('response_accuracy').data.load());
        confidence = double(nwbAll{SU.session_count}.intervals.get('LTM_trials').vectordata.get('confidence').data.load());


        for itrial = 1:n_trials

            for ipic = picIDs(itrial,:)
                if ~sum(LTM_pics==ipic)
                    itrial_LTM = [];
                    continue;
                else
                    itrial_LTM = LTM_pics==ipic;
                end

                counter  = counter + 1;
                T.FR(counter,1) = sum(spikes_times>tsMaint(itrial)+whichWindow(1) & spikes_times<tsMaint(itrial)+whichWindow(2));
                T.FR_bsl(counter,1) = sum(spikes_times>tsEnc1(itrial)+whichWindow_bsl(1) & spikes_times<tsEnc1(itrial)+whichWindow_bsl(2));
                T.acc_WM(counter,1) = WM_acc(itrial);
                T.pref(counter,1) = floor(ipic/100)==prefCat;
                T.prefCat(counter,1) = prefCat;

                %LTM
                T.LTMacc(counter,1) = logical(LTM_acc(itrial_LTM));
                T.conf(counter,1) = confidence(itrial_LTM);


                T.neuronID(counter,1) = neuron_counter;
                T.sessionID(counter,1) = categorical(cellstr(SU.session_id));
                T.patientID(counter,1) = categorical(cellstr(SU.subject_id));
                if strcmp(unit_area,'amygdala_left') || strcmp(unit_area,'amygdala_right')
                    T.area(counter,1) = categorical(cellstr('A'));
                else
                    T.area(counter,1) = categorical(cellstr('H'));
                end
            end
        end
    end
end
warning on

%% Compute GLM
disp('Computing GLM...')

% baseline correct
T.FR = T.FR / (whichWindow(2)-whichWindow(1));
T.FR_bsl = T.FR_bsl / (whichWindow_bsl(2)-whichWindow_bsl(1));
for ineuron = 1:neuron_counter
    T.FR(T.neuronID==ineuron) = (T.FR(T.neuronID==ineuron)/mean(T.FR_bsl(T.neuronID==ineuron))-1).*100;
    T.FR_bsl(T.neuronID==ineuron) = (T.FR_bsl(T.neuronID==ineuron)/mean(T.FR_bsl(T.neuronID==ineuron))-1).*100;
end
T(isinf(T.FR),:) = [];

FR = [];
for ineuron = 1:neuron_counter
    FR = [FR;mean(T.FR(T.neuronID==ineuron))];
end
sd = nanstd(FR);
thresh = 3*sd;
for ineuron = 1:neuron_counter
    if FR(ineuron)>thresh
        T(T.neuronID==ineuron,:) = [];
    end
end

T = T(T.acc_WM == 1,:);
T = T(T.pref == 1,:);
T(isnan(T.conf),:) = [];

T.conf_3level_flipped = T.conf;
T.conf_3level_flipped(T.conf == 6) = 3; %
T.conf_3level_flipped(T.conf == 5) = 2;
T.conf_3level_flipped(T.conf == 4) = 1;

T.conf = T.conf_3level_flipped;

m = fitglme(T,'FR ~ LTMacc*conf*area +  (1 | patientID) + (1 | patientID:neuronID)', 'Distribution','normal','FitMethod','Laplace');


