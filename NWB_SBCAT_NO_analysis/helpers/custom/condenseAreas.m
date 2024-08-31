function str_out = condenseAreas(str_in)
% Remaps strings of brain areas stored in the SB NWB format to a
% de-lateralized naming convension (e.g. 'amygdala_left' -> 'amygdala')
% Input: A string of the lateralized brain area.
% Output: A string of the de-lateralized brain area. 
str_mid = str_in;
switch (str_mid)
    case {'amygdala_left','amygdala_right'}
        str_mid = 'Amy';
    case {'hippocampus_left','hippocampus_right'}
        str_mid = 'Hippo';
    otherwise
        error('Area cannot be remapped. Are you using the right input?')
end
str_out = str_mid;
end