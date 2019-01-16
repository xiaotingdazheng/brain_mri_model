function synthetiseTrainingImages(pathRefImage, pathFirstLabels, pathDirLabels, pathClassesTable, targetResolution)

% files handling
structPathsTrainingLabels = dir(pathDirLabels);
refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);
pathTempImageSubfolder = fullfile(fileparts(structPathsFloatingImages(1).folder), ['temp_' refBrainNum]);
pathStatsMatrix = fullfile(pathTempImageSubfolder, 'ClassesStats.mat');

% compute stats from reference image
classesStats = computeIntensityStats(pathRefImage, pathFirstLabels, pathClassesTable, pathStatsMatrix);

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    
    createNewImage(pathTrainingLabels, classesStats, targetResolution, pathTempImageSubfolder)

end

end