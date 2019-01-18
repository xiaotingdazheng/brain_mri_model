function accuracy = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, cropping)

% This function computes the dice coefficient between the segmented image
% and the provided GT.

labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

% open files
segmentationMRI = MRIread(pathSegmentation);
segmentation = segmentationMRI.vol;
hippoSegmentationMRI = MRIread(pathHippoSegmentation);
hippoSegmentation = hippoSegmentationMRI.vol;
refLabelsMRI = MRIread(pathRefLabels);
refLabels = refLabelsMRI.vol;
if cropping, refLabels = refLabels(cropping(1):cropping(2), cropping(3):cropping(4), cropping(5):cropping(6)); end

accuracy = NaN(1,length(labelsList)+1);

for i=1:length(labelsList)
    
    temp_labelMask = (segmentation == labelsList(i));
    temp_GT_Mask = (refLabels == labelsList(i));
    
    if ~isequal(unique(temp_labelMask), 0) && ~isequal(unique(temp_GT_Mask), 0)
        accuracy(i) = dice(temp_labelMask, temp_GT_Mask);
    end
    
end

% compute dice coef for all hippocampus
temp_GT_Mask = refLabels > 20000 | refLabels == 17 | refLabels == 53;
if ~isequal(unique(hippoSegmentation), 0) && ~isequal(unique(temp_GT_Mask), 0)
    accuracy(end) = dice(hippoSegmentation, temp_GT_Mask);
end

end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
accuracy = 2*sum(sum(sum(a.*b)))/sum(sum(sum(a+b)));

end