function aboveRate = rateFilter_units(nwbAll,all_units,rateFilter)

aboveRate = ones(length(all_units),1);

for i = 1:length(all_units)
    SU = all_units(i);
    tsEvents_WM = nwbAll{SU.session_count}.acquisition.get('events_raw_WM').timestamps.load;
    tsEvents_LTM = nwbAll{SU.session_count}.acquisition.get('events_raw_LTM').timestamps.load;
    spike_times_WM = all_units(i).spike_times(all_units(i).spike_times<=tsEvents_WM(end));
    spike_times_LTM = all_units(i).spike_times(all_units(i).spike_times>=tsEvents_LTM(1));
    globalRate_WM = length(spike_times_WM)/(tsEvents_WM(end)-tsEvents_WM(1));
    globalRate_LTM = length(spike_times_LTM)/(tsEvents_LTM(end)-tsEvents_LTM(1));
    rateBool = globalRate_WM < rateFilter | globalRate_LTM < rateFilter;
    if rateBool % If the rate is below the filter threshold
        aboveRate(i) = 0;
    end
end