function [labelMap, labelMapHippo] = getSegmentation(labelMap, labelMapHippo, labelsList, resultsFolder, refBrainNum)

% This function performs the argmax operation on the labels posterior
% probability, to obtain the most probable segmentation. It takes as inputs
% the label maps of the whole brain and of the hippocampus. It gives the
% most likely segmentations as outputs. It also saves them in separete
% files.

hippoLabelList= [0, 1];

SegmentationMaskMRI.vox2ras0 = zeros(4); % initialse nifty files to be saved

% argmax on labelMap to get final segmentation
[~,index] = max(labelMap, [], 4);
labelMap = arrayfun(@(x) labelsList(x), index);

% save result whole brain segmentation
SegmentationMaskMRI.vol = labelMap;
pathResultSegmentation = fullfile(resultsFolder, [refBrainNum 'labels.result.nii.gz']);
MRIwrite(SegmentationMaskMRI, pathResultSegmentation);

% argmax on labelMapHippo to get final hippocampus segmentation
[~,index] = max(labelMapHippo, [], 4);
labelMapHippo = arrayfun(@(x) hippoLabelList(x), index);

% save result hippocampus segmentation
SegmentationMaskMRI.vol = labelMapHippo;
pathResultHippoSegmentation = fullfile(resultsFolder, [refBrainNum 'hippo.labels.result.nii.gz']);
MRIwrite(SegmentationMaskMRI, pathResultHippoSegmentation);

end