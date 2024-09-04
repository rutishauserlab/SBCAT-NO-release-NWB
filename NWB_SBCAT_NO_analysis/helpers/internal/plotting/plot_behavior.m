function plot_behavior(nwbAll)
%% This script analyses behavior of all sessions in SternbergCAT_NO
% JD 2024

nsubjects = length(nwbAll);

LTM_values = 1;
WM_values = 2;

%% Test acc and RT between WM load
clear RT_load1 RT_load3 acc_load1 acc_load3 acc_all

for isubj = 1:nsubjects
    clear RT acc
    
    RT = double(nwbAll{isubj}.intervals.values{WM_values}.vectordata.get('response_time').data.load());
    acc = double(nwbAll{isubj}.intervals.values{WM_values}.vectordata.get('response_accuracy').data.load());
    WM_load = double(nwbAll{isubj}.intervals.values{WM_values}.vectordata.get('loads').data.load());
    
    RT(RT>5) = nan;
        
    RT_load1(isubj) = nanmean(RT(WM_load == 1));
    acc_load1(isubj) = nanmean(acc(WM_load == 1));
    
    RT_load3(isubj) = nanmean(RT(WM_load == 3));
    acc_load3(isubj) = nanmean(acc(WM_load == 3));
    
    acc_all(isubj) = nanmean(acc);
end

%% Plot
h = figure('position',[300 300 250 400]);
color = {[0.8 0.2 0.7],[0.1 0.25 0.6]};
D = {acc_load1 acc_load3};
makeScatterPlot(D,0,color);
ylabel('WM Accuracy');
xlabel('WM load');
ylim([0.5 1])
set(gca,'xticklabel',{'load 1','load 3'},'fontsize',22,'fontname','Arial')

h = figure('position',[300 300 250 400]);
color = {[0.8 0.2 0.7],[0.1 0.25 0.6]};
D = {RT_load1 RT_load3};
makeScatterPlot(D,0,color);
ylabel('WM Reaction times (s)');
xlabel('WM load');
ylim([0 3])
set(gca,'xticklabel',{'load 1','load 3'},'fontsize',22,'fontname','Arial')


%%  acc in LTM part
clear RT_load1 RT_load3 acc_load1 acc_load3 d_prime
for isubj = 1:nsubjects
    clear RT acc
    
    RT = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('response_time').data.load());
    acc = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('response_accuracy').data.load());
    confidence = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('confidence').data.load());
    
    RT(RT>5) = nan;
    
    acc_highconf(isubj) = nanmean(acc(confidence==1 | confidence==6));
    acc_lowconf(isubj) = nanmean(acc(confidence~=1 & confidence~=6));


end
acc_highconf(isnan(acc_lowconf)) = nan;
acc_lowconf(isnan(acc_highconf)) = nan;
acc_highconf(isnan(acc_highconf)) = [];
acc_lowconf(isnan(acc_lowconf)) = [];

h = figure('position',[300 300 250 400]);
color = {[126 199 246]/255,[200 108 245]/255};
D = {acc_highconf acc_lowconf};
makeScatterPlot(D,0,color);
ylabel('LTM Accuracy');
xlabel('LTM confidence');
ylim([0 1])
set(gca,'xticklabel',{'High','Low'},'fontsize',22,'fontname','Arial')

%% True positive rate for load 1 vs load 3 pics
clear tpr_load1 tpr_load3
for isubj = 1:nsubjects
    clear RT acc
    
    RT = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('response_time').data.load());
    acc = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('response_accuracy').data.load());
    loads = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('load').data.load());
    
    RT(RT>5) = nan;

    tp1 = sum(acc == 1 & loads == 1);
    fn1 = sum(acc == 0 & loads == 1);
    
    tp3 = sum(acc == 1 & loads == 3);
    fn3 = sum(acc == 0 & loads == 3);
    
    tpr_load1(isubj) = tp1/(tp1+fn1);
    tpr_load3(isubj) = tp3/(tp3+fn3);
    
end

h = figure('position',[300 300 250 400]);
color = {[0.8 0.2 0.7],[0.1 0.25 0.6]};
D = {tpr_load1 tpr_load3};
makeScatterPlot(D,0,color);
ylabel('LTM True positive rate');
xlabel('WM load');
ylim([0 1])
set(gca,'xticklabel',{'load 1','load 3'},'fontsize',22,'fontname','Arial')

%% True positive rate for shown as probe vs not shown as probe

clear tpr_probe tpr_noProbe

for isubj = 1:nsubjects
    clear RT acc
    
    RT = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('response_time').data.load());
    acc = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('response_accuracy').data.load());
    num_shown = double(nwbAll{isubj}.intervals.values{LTM_values}.vectordata.get('num_times_shown').data.load());
    
    RT(RT>5) = nan;
    
    tp_p = sum(acc == 1 & num_shown == 2);
    fn_p = sum(acc == 0 & num_shown == 2);
    
    tp_np = sum(acc == 1 & num_shown == 1);
    fn_np = sum(acc == 0 & num_shown == 1);
    
    tpr_probe(isubj) = tp_p/(tp_p+fn_p);
    tpr_noProbe(isubj) = tp_np/(tp_np+fn_np);
    
end
 
h = figure('position',[300 300 250 400]);
color = {[59 137 168]./255,[245 181 110]./255}; 
D = {tpr_probe tpr_noProbe};
makeScatterPlot(D,0,color);
ylabel('LTM True positive rate');
xlabel('Probe');
ylim([0 1])
set(gca,'xticklabel',{'shown','not shown'},'fontsize',22,'fontname','Arial')
