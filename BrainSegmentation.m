clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

% define paths
pathDirTestImages = '/home/benjamin/data/OASIS/label_fusion/test_images/*nii.gz';
pathTestFirstLabels = '/home/benjamin/data/OASIS/label_fusion/test_first_labels/*nii.gz';
pathDirTrainingLabels = '/home/benjamin/data/OASIS/label_fusion/training_labels/*nii.gz';
pathClassesTable = '/home/benjamin/data/OASIS/label_fusion/classesTable.txt';
pathDirTestLabels = '/home/benjamin/data/OASIS/label_fusion/test_first_labels/*nii.gz'; % for evaluation

% parameters
targetResolution = [1 1 1];
cropImage = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathTestFirstLabels);
structPathsRefLabels = dir(pathDirTestLabels);
accuracies = cell(length(structPathsTestImages),1);

for i=1:length(structPathsTestImages)
    
    % paths of reference image and corresponding FS labels
    pathRefImage = fullfile(structPathsTestImages(i).folder, structPathsTestImages(i).name);
    pathTestFirstLabels = fullfile(structPathsFirstRefLabels(i).folder, structPathsFirstRefLabels(i).name);
    pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
    
    % floating images generation
    [pathDirSyntheticImages, pathDirSyntheticLabels] = synthetiseTrainingImages(pathRefImage, pathTestFirstLabels, pathDirTrainingLabels, pathClassesTable, targetResolution);
    
    % labelFusion
    pathDirFloatingImages = fullfile(pathDirSyntheticImages, '*nii.gz');
    pathDirFloatingLabels = fullfile(pathDirSyntheticLabels, '*nii.gz');
    [pathSegmentation, pathHippoSegmentation, cropping] = performLabelFusion(pathRefImage, pathTestFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, cropImage);
    
    % evaluation
    accuracies{i} = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, cropping);
    
end

pathAccuracies = fileparts(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);