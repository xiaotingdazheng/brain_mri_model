function accuracy = computeSegmentationAccuracy(labelMap, labelMapHippo, croppedGTSegmentation)

% This function computes the dice coefficient between the segmented image
% and the provided GT.

labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

accuracy = NaN(1,length(labelsList)+1);

for i=1:length(labelsList)
    
    temp_labelMask = (labelMap == labelsList(i));
    temp_GT_Mask = (croppedGTSegmentation == labelsList(i));
    
    if ~isequal(unique(temp_labelMask), 0) && ~isequal(unique(temp_GT_Mask), 0)
        accuracy(i) = dice(temp_labelMask, temp_GT_Mask);
    end
    
end

% compute dice coef for all hippocampus
temp_GT_Mask = croppedGTSegmentation > 20000 | croppedGTSegmentation == 17 | croppedGTSegmentation == 53;
if ~isequal(unique(labelMapHippo), 0) && ~isequal(unique(temp_GT_Mask), 0)
    accuracy(end) = dice(labelMapHippo, temp_GT_Mask);
end

end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
accuracy = 2*sum(sum(sum(a.*b)))/sum(sum(sum(a+b)));

end