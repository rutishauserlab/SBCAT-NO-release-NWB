function [nwbAll_filtered,all_units_filtered] = NWB_SB_filter_session(nwbAll,all_units,unit_example)
%filter session

%% Apply unit filter

% Getting unit ids
unit_sub_ids ={all_units.subject_id}'; unit_sub_ids = cellfun(@(x) str2double(x), unit_sub_ids,'UniformOutput',false); unit_sub_ids = cell2mat(unit_sub_ids);
unit_sub_ses_ids ={all_units.session_id}'; unit_sub_ses_ids = cellfun(@(x) str2double(x), unit_sub_ses_ids,'UniformOutput',false); unit_sub_ses_ids = cell2mat(unit_sub_ses_ids);
unit_sub_ses_cell_ids = double([all_units.unit_id]');

% Creating filter for unit examples
in_sub = ismember(unit_sub_ids,unit_example(1));
in_ses = ismember(unit_sub_ses_ids,unit_example(2));
in_unit = ismember(unit_sub_ses_cell_ids,unit_example(3));
is_example = in_sub.*in_ses.*in_unit;

if sum(is_example) < size(unit_example,1)
    warning('All examples not loaded. See import range. [6]')
elseif sum(is_example) > size(unit_example,1)
    error('Too many neurons filtered. Manually diagnose.')
end

% Applying filter
all_units_filtered = all_units(logical(is_example));

% Updating session count in units object
temp_units = all_units_filtered;
unique_subjects = unique([temp_units.session_count]);
for i = 1:length(unique_subjects)
    find_uniques = find([temp_units.session_count] == unique_subjects(i));
    for j = find_uniques
        all_units_filtered(j).session_count = i ;
    end
end
clear temp_units 

% Filtering files
nwbAll_filtered = nwbAll{unique_subjects};
end