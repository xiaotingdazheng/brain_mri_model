function [pathDirSyntheticImages, pathDirSyntheticLabels] = generateTrainingImages(pathDirTrainingLabels, pathClassesTable, pathRefImage, pathRefFirstLabels,...
    recompute, freeSurferHome, niftyRegHome, debug)

% files handling
structPathsTrainingLabels = dir(pathDirTrainingLabels);
pathTempImageSubfolder = fileparts(fileparts(pathRefImage));
pathStatsMatrix = fullfile(pathTempImageSubfolder, 'ClassesStats.mat');

% compute stats from reference image
classesStats = computeIntensityStats(pathRefImage, pathRefFirstLabels, pathClassesTable, pathStatsMatrix, recompute);

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats, pathTempImageSubfolder, ...
        pathRefImage, pathRefFirstLabels, recompute, freeSurferHome, niftyRegHome, debug);

end

end