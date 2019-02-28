function [pathDirSyntheticImages, pathDirSyntheticLabels, pathRefImage] = synthetiseTrainingImages(pathRefImage, pathRefFirstLabels, pathDirTrainingLabels,...
    pathClassesTable, targetRes, recompute, freeSurferHome, niftyRegHome, debug, rescale)

% files handling
structPathsTrainingLabels = dir(pathDirTrainingLabels);
pathTempImageSubfolder = fullfile(fileparts(fileparts(pathRefImage)), ['temp_' refBrainNum]);
pathStatsMatrix = fullfile(pathTempImageSubfolder, 'ClassesStats.mat');
pathFolderRescaledRefImage = fullfile(pathTempImageSubfolder, 'rescaled_test_images');
if ~exist(pathTempImageSubfolder, 'dir'), mkdir(pathTempImageSubfolder); end

if rescale
    pathRefImage = rescaleIntensities(pathRefImage, pathFolderRescaledRefImage, recompute);
end

% compute stats from reference image
classesStats = computeIntensityStats(pathRefImage, pathRefFirstLabels, pathClassesTable, pathStatsMatrix, recompute);

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats, targetRes, ...
        pathTempImageSubfolder, pathRefImage, pathRefFirstLabels, recompute, freeSurferHome, niftyRegHome, debug);

end

end