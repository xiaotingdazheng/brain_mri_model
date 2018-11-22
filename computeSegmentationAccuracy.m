function accuracy = computeSegmentationAccuracy(labelMap, registeredGTSegmentation, listLabels)

% This function computes the dice coefficient between the segmented image
% and the provided GT.

accuracy = NaN(1,length(listLabels));

for i=1:length(listLabels)

    temp_labelMask = (labelMap == listLabels(i));
    temp_GT_Mask = (registeredGTSegmentation == listLabels(i));
    
    if ~isequal(unique(temp_labelMask), 0) && ~isequal(unique(temp_GT_Mask), 0)
        accuracy(i) = dice(temp_labelMask, temp_GT_Mask);
    end
    
end

end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
    
    accuracy = 2*sum(sum(sum(a.*b)))/sum(sum(sum(a+b)));
    
end