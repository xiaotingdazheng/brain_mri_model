function [pathSegmentation, pathHippoSegmentation] = getSegmentation(labelMap, labelMapHippo, labelsList, resultsFolder, refBrainNum)

% This function performs the argmax operation on the labels posterior
% probability, to obtain the most probable segmentation. It takes as inputs
% the label maps of the whole brain and of the hippocampus. It gives the
% most likely segmentations as outputs. It also saves them in separete
% files.

disp('finding most likely segmentation and calculating corresponding accuracy');

hippoLabelList= [0, 1];

z = zeros(4); z(1:3,1:3) = eye(3); z(4,4) = 1;
SegmentationMaskMRI.vox2ras0 = z; % initialse nifty files to be saved

% argmax on labelMap to get final segmentation
[~,index] = max(labelMap, [], 4);
labelMap = arrayfun(@(x) labelsList(x), index);

% save result whole brain segmentation
SegmentationMaskMRI.vol = labelMap;
pathSegmentation = fullfile(resultsFolder, ['test_' refBrainNum '.segmentation.nii.gz']);
if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
MRIwrite(SegmentationMaskMRI, pathSegmentation);

% argmax on labelMapHippo to get final hippocampus segmentation
[~,index] = max(labelMapHippo, [], 4);
labelMapHippo = arrayfun(@(x) hippoLabelList(x), index);

% save result hippocampus segmentation 
SegmentationMaskMRI.vol = labelMapHippo;
pathHippoSegmentation = fullfile(resultsFolder, ['test_' refBrainNum '.hippo_segmentation.nii.gz']);
MRIwrite(SegmentationMaskMRI, pathHippoSegmentation);

end