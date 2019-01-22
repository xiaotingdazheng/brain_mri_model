function [pathDirSyntheticImages, pathDirSyntheticLabels] = synthetiseTrainingImages(pathRefImage, pathFirstLabels, pathDirLabels, pathClassesTable, targetResolution)

% files handling
structPathsTrainingLabels = dir(pathDirLabels);
refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);
pathTempImageSubfolder = fullfile(fileparts(structPathsTrainingLabels(1).folder), ['temp_' refBrainNum]);
if ~exist(pathTempImageSubfolder, 'dir'), mkdir(pathTempImageSubfolder); end
pathStatsMatrix = fullfile(pathTempImageSubfolder, 'ClassesStats.mat');

% compute stats from reference image
disp(['% computing intensity stats for ' refBrainNum])
classesStats = computeIntensityStats(pathRefImage, pathFirstLabels, pathClassesTable, pathStatsMatrix);

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    disp(['% creating new image from ' structPathsTrainingLabels(i).name])
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats, targetResolution, pathTempImageSubfolder, pathRefImage);

end

end