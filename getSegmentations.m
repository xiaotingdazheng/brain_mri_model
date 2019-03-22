function [pathSegmentation, pathHippoSegmentation] = getSegmentations(labelMap, labelMapHippo, pathResultPrefix, pathRefImage, brainVoxels, ...
    labelsList, sizeSegmMap)

% This function performs the argmax operation on the labels posterior
% probability, to obtain the most probable segmentation. It takes as inputs
% the label maps of the whole brain and of the hippocampus. It gives the
% most likely segmentations as outputs. It also saves them in separete
% files.

% path files to be saved
pathSegmentation = [pathResultPrefix '.all_segmentation.nii.gz'];
pathHippoSegmentation = [pathResultPrefix '.hippo_vs_rest_segmentation.nii.gz'];
resultsFolder = fileparts(pathSegmentation);
if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end

% initialisation
mri = MRIread(pathRefImage);
hippoLabelList= [0, 1];

disp('% finding most likely segmentation');

% argmax on labelMap to get final segmentation
[~,index] = max(labelMap, [], 1);
voxelLabels = arrayfun(@(x) labelsList(x), index);
labelMap = zeros(sizeSegmMap, 'single');
labelMap(brainVoxels{1}) = voxelLabels;

% argmax on labelMapHippo to get final hippocampus segmentation
[~,index] = max(labelMapHippo, [], 1);
voxelLabels = arrayfun(@(x) hippoLabelList(x), index);
labelMapHippo = zeros(sizeSegmMap, 'single');
labelMapHippo(brainVoxels{1}) = voxelLabels;

% save result whole brain segmentation
mri.vol = labelMap;
MRIwrite(mri, pathSegmentation);
% save result hippocampus segmentation
mri.vol = labelMapHippo;
MRIwrite(mri, pathHippoSegmentation);

end