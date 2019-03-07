function [pathDirSyntheticImages, pathDirSyntheticLabels] = generateTrainingImages(pathDirTrainingLabels, pathClassesTable, pathRefImage,...
    pathRefFirstLabels, channel, recompute, freeSurferHome, niftyRegHome, debug)

% files handling
structPathsTrainingLabels = dir(pathDirTrainingLabels);
if channel == 0
    pathTempImageSubfolder = fileparts(fileparts(pathRefImage));
    pathStatsMatrixFolder = fullfile(pathTempImageSubfolder, 'ClassesStats');
    pathStatsMatrix = fullfile(pathStatsMatrixFolder, 'ClassesStats.mat');
else
    pathTempImageSubfolder = fileparts(fileparts(fileparts(pathRefImage)));
    pathStatsMatrixFolder = fullfile(pathTempImageSubfolder, 'ClassesStats');
    pathStatsMatrix = fullfile(pathStatsMatrixFolder, ['ClassesStats_channel' num2str(channel) '.mat']);
end
if ~exist(pathStatsMatrixFolder, 'dir'), mkdir(pathStatsMatrixFolder); end


% compute stats from reference image
classesStats = computeIntensityStats(pathRefImage, pathRefFirstLabels, pathClassesTable, pathStatsMatrix, recompute);

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats, pathTempImageSubfolder, ...
        pathRefImage, pathRefFirstLabels, channel, recompute, freeSurferHome, niftyRegHome, debug);

end

end