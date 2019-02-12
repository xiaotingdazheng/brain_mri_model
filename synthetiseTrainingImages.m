function [pathDirSyntheticImages, pathDirSyntheticLabels] = synthetiseTrainingImages(pathRefImage, pathFirstLabels, pathDirTrainingLabels,...
    pathClassesTable, targetResolution, recompute, freeSurferHome, niftyRegHome, debug)

% files handling
structPathsTrainingLabels = dir(pathDirTrainingLabels);
idx = regexp(pathRefImage,'brain');
refBrainNum = pathRefImage(idx(end):regexp(pathRefImage,'.nii.gz')-1);
pathTempImageSubfolder = fullfile(fileparts(structPathsTrainingLabels(1).folder), ['temp_' refBrainNum]);
if ~exist(pathTempImageSubfolder, 'dir'), mkdir(pathTempImageSubfolder); end
pathStatsMatrix = fullfile(pathTempImageSubfolder, 'ClassesStats.mat');

% compute stats from reference image
classesStats = computeIntensityStats(pathRefImage, pathFirstLabels, pathClassesTable, pathStatsMatrix, recompute);

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats, targetResolution, ...
        pathTempImageSubfolder, pathRefImage, pathFirstLabels, recompute, freeSurferHome, niftyRegHome, debug);

end

end