function [pathSegmentation, pathHippoSegmentation] = getSegmentations(labelMap, labelMapHippo, resultsFolder, pathRefImage, brainVoxels, ...
    labelsList, sizeSegmMap)

% This function performs the argmax operation on the labels posterior
% probability, to obtain the most probable segmentation. It takes as inputs
% the label maps of the whole brain and of the hippocampus. It gives the
% most likely segmentations as outputs. It also saves them in separete
% files.

% path files to be saved
refBrainNum = findBrainNum(pathRefImage);
if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
pathSegmentation = fullfile(resultsFolder, ['test_' refBrainNum '.segmentation.nii.gz']);
pathHippoSegmentation = fullfile(resultsFolder, ['test_' refBrainNum '.hippo_segmentation.nii.gz']);

% initialisation
mri = MRIread(pathRefImage);
hippoLabelList= [0, 1];

disp('finding most likely segmentation and calculating corresponding accuracy');

% argmax on labelMap to get final segmentation
[~,index] = max(labelMap, [], 1);
voxelLabels = arrayfun(@(x) labelsList(x), index);
labelMap = zeros(sizeSegmMap, 'single');
labelMap(brainVoxels) = voxelLabels;

% argmax on labelMapHippo to get final hippocampus segmentation
[~,index] = max(labelMapHippo, [], 1);
voxelLabels = arrayfun(@(x) hippoLabelList(x), index);
labelMapHippo = zeros(sizeSegmMap, 'single');
labelMapHippo(brainVoxels) = voxelLabels;

% save result whole brain segmentation
mri.vol = labelMap;
MRIwrite(mri, pathSegmentation);
% save result hippocampus segmentation
mri.vol = labelMapHippo;
MRIwrite(mri, pathHippoSegmentation);

end