function [labelsList, labelsNames] = updateLabelsList(labelsList, labelsNames)

% find indices of left and right hippocampi
idx = find(~contains(labelsNames, 'hippocampus'));

%remove them from list as they won't be in the new image
labelsNames = labelsNames(idx);
labelsList = labelsList(idx);

% add background
labelsNames = ['background' labelsNames'];
labelsList = [0 labelsList'];

% add whole hippocampus label
labelsNames = [labelsNames 'hippocampus'];

end