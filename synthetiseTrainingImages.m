function [pathDirSyntheticImages, pathDirSyntheticLabels] = synthetiseTrainingImages(pathRefImage, pathFirstLabels, pathDirLabels, pathClassesTable, targetResolution)

% files handling
structPathsTrainingLabels = dir(pathDirLabels);
refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);
pathTempImageSubfolder = fullfile(fileparts(structPathsTrainingLabels(1).folder), ['temp_' refBrainNum]);
if ~exist(pathTempImageSubfolder, 'dir'), mkdir(pathTempImageSubfolder); end
pathStatsMatrix = fullfile(pathTempImageSubfolder, 'ClassesStats.mat');

% compute stats from reference image
classesStats = computeIntensityStats(pathRefImage, pathFirstLabels, pathClassesTable, pathStatsMatrix);

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    
    [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats, targetResolution, pathTempImageSubfolder);

end

end