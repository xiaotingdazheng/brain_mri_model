function [pathDirSyntheticImages, pathDirSyntheticLabels, pathRefImage] = synthetiseTrainingImages(pathRefImage, pathRefFirstLabels, pathDirTrainingLabels,...
    pathClassesTable, targetRes, recompute, freeSurferHome, niftyRegHome, debug, rescale)

% files handling
structPathsTrainingLabels = dir(pathDirTrainingLabels);
idx = regexp(pathRefImage,'brain');
refBrainNum = pathRefImage(idx(end):regexp(pathRefImage,'.nii.gz')-1);
pathTempImageSubfolder = fullfile(fileparts(fileparts(pathRefImage)), ['temp_' refBrainNum]);
if ~exist(pathTempImageSubfolder, 'dir'), mkdir(pathTempImageSubfolder); end
pathStatsMatrix = fullfile(pathTempImageSubfolder, 'ClassesStats.mat');

if rescale
    pathRefImage = rescaleIntensities(pathRefImage, refBrainNum, recompute);
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