function accuracy = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, labelsList, pathTempImFolder, cropping)

% This function computes the dice coefficient between the segmented image
% and the provided GT.

% open whole brain segmentation
segmentationMRI = myMRIread(pathSegmentation, 0, pathTempImFolder);
segmentation = segmentationMRI.vol;
% open hippo segmentation
hippoSegmentationMRI = myMRIread(pathHippoSegmentation, 0, pathTempImFolder);
hippoSegmentation = hippoSegmentationMRI.vol;
% open test labels and crop them if necessary
refLabelsMRI = myMRIread(pathRefLabels, 0, pathTempImFolder);
if cropping, refLabelsMRI = applyCropping(refLabelsMRI,cropping); end
refLabels = refLabelsMRI.vol;
    
% initialise result matrix
accuracy = NaN(1,length(labelsList)+2);

% compute dice coef for each brain region
for i=1:length(labelsList)
    
    % build temporary masks for each structure
    temp_segmentationMask = (segmentation == labelsList(i));
    temp_RefMask = (refLabels == labelsList(i));
    
    % calculate dice coef if structure present both in test and obtained labels
    if ~isequal(unique(temp_segmentationMask), 0) && ~isequal(unique(temp_RefMask), 0)
        accuracy(i) = dice(temp_segmentationMask, temp_RefMask);
    end
    
end

% compute dice coef for right hippocampus
temp_RefMask = (refLabels > 20000 & refLabels < 20100) | refLabels == 53;
temp_segmentationMask = (hippoSegmentation > 20000 & hippoSegmentation < 20100) | hippoSegmentation == 53;
if ~isequal(unique(temp_segmentationMask), 0) && ~isequal(unique(temp_RefMask), 0)
    accuracy(end-1) = dice(temp_segmentationMask, temp_RefMask);
end

% compute dice coef for left hippocampus
temp_RefMask = refLabels > 20100 | refLabels == 17;
temp_segmentationMask = hippoSegmentation == 17 | hippoSegmentation > 20100;
if ~isequal(unique(temp_segmentationMask), 0) && ~isequal(unique(temp_RefMask), 0)
    accuracy(end) = dice(temp_segmentationMask, temp_RefMask);
end

end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
accuracy = 2*sum(sum(sum(a.*b)))/sum(sum(sum(a+b)));

end