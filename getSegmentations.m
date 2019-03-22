function [pathSegmentation, pathHippoSegmentation] = getSegmentations(labelMap, labelMapHippo, pathResultPrefix, pathRefImage, brainVoxels, ...
    labelsList, labelsNames, sizeSegmMap)

% This function performs the argmax operation on the labels posterior
% probability, to obtain the most probable segmentation. It takes as inputs
% the label maps of the whole brain and of the hippocampus. It gives the
% most likely segmentations as outputs. It also saves them in separete
% files.

% path files to be saved
pathSegmentation = [pathResultPrefix '.all_segmentation.nii.gz'];
pathHippoSegmentation = [pathResultPrefix '.hippo_vs_rest_segmentation.nii.gz'];
pathVolumesTxt = [pathResultPrefix '.volumes.txt'];
resultsFolder = fileparts(pathSegmentation);
if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end

% initialisation
mri = MRIread(pathRefImage);
refImageRes = [mri.xsize mri.ysize mri.zsize];
hippoLabelList= [0 53 17];

disp('% finding most likely segmentation');

% calculate volumes
labelMap = bsxfun(@rdivide,labelMap,sum(labelMap,'omitnan'));
volAllBrain = sum(labelMap,2,'omitnan');
labelMapHippo = bsxfun(@rdivide,labelMapHippo,sum(labelMapHippo,'omitnan'));
volHippoOnly = sum(labelMapHippo,2,'omitnan');
volumes = [volAllBrain' volHippoOnly(2:3)'];
volumes = volumes * prod(refImageRes);

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
% save text file with volume of each structure
fid=fopen(pathVolumesTxt, 'w');
for i=2:length(volumes), fprintf(fid, '%s: %.3f \n', strip(labelsNames{i}), volumes(i)); end
fclose(fid);

end