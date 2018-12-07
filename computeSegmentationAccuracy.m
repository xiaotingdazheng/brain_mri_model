function accuracy = computeSegmentationAccuracy(labelMap, labelMapHippo, croppedGTSegmentation, labelsList)

% This function computes the dice coefficient between the segmented image
% and the provided GT.

accuracy = NaN(1,length(labelsList)+1);

for i=1:length(labelsList)
    
    temp_labelMask = (labelMap == labelsList(i));
    temp_GT_Mask = (croppedGTSegmentation == labelsList(i));
    
    if ~isequal(unique(temp_labelMask), 0) && ~isequal(unique(temp_GT_Mask), 0)
        accuracy(i) = dice(temp_labelMask, temp_GT_Mask);
    end
    
end

% compute dice coef for all hippocampus
temp_GT_Mask = croppedGTSegmentation > 20000 | croppedGTSegmentation == 17 | croppedGTSegmentation == 43;
if ~isequal(unique(labelMapHippo), 0) && ~isequal(unique(temp_GT_Mask), 0)
    accuracy(end) = dice(labelMapHippo, temp_GT_Mask);
end

end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
accuracy = 2*sum(sum(sum(a.*b)))/sum(sum(sum(a+b)));

end