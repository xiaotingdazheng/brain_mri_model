function accuracy = computeSegmentationAccuracy(labelMap, croppedGTSegmentation, labelsList)

% This function computes the dice coefficient between the segmented image
% and the provided GT.

accuracy = NaN(1,length(labelsList));

for i=1:length(labelsList)-1

    temp_labelMask = (labelMap == labelsList(i));
    temp_GT_Mask = (croppedGTSegmentation == labelsList(i));
    
    if ~isequal(unique(temp_labelMask), 0) && ~isequal(unique(temp_GT_Mask), 0)
        accuracy(i) = dice(temp_labelMask, temp_GT_Mask);
    end
    
end

% compute accuracy for all hippocampus (combining all subfields)
hippoSubfieldLabels = labelsList(labelsList >= 20000);
temp_labelMask = zeros(size(labelMap));
temp_GT_Mask = zeros(size(croppedGTSegmentation));

% build mask of hippocampus
for i=1:length(hippoSubfieldLabels)
    temp_labelMask = temp_labelMask | (labelMap == hippoSubfieldLabels(i));
    temp_GT_Mask = temp_GT_Mask | (croppedGTSegmentation == hippoSubfieldLabels(i));
end

% compute dice coef for all hippocampus
if ~isequal(unique(temp_labelMask), 0) && ~isequal(unique(temp_GT_Mask), 0)
    accuracy(end) = dice(temp_labelMask, temp_GT_Mask);
end

end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
    
    accuracy = 2*sum(sum(sum(a.*b)))/sum(sum(sum(a+b)));
    
end