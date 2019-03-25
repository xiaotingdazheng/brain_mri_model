function accuracy = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, labelsList, pathTempImFolder)

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
refLabels = refLabelsMRI.vol;

% initialise result matrix
accuracy = NaN(1,length(labelsList)+1);

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

% compute dice coef for whole hippocampus
temp_RefMask = refLabels > 20000 | refLabels == 17 | refLabels == 53;
if ~isequal(unique(hippoSegmentation), 0) && ~isequal(unique(temp_RefMask), 0)
    accuracy(end) = dice(hippoSegmentation, temp_RefMask);
end


end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
accuracy = 2*sum(sum(sum(a.*b)))/sum(sum(sum(a+b)));

end