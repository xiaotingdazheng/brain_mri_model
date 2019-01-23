clear
tic
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
margin = 30;
rho = 0.5;
threshold = 0.3;
sigma = 150;
labelPriorType = 'logOdds';
deleteSubfolder = 0;
recompute = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathTestFirstLabels);
structPathsRefLabels = dir(pathDirTestLabels);
accuracies = cell(length(structPathsTestImages),1);
labelFusionParameters = {cropImage margin rho threshold sigma labelPriorType deleteSubfolder recompute};

for i=1:length(structPathsTestImages)
    
    disp(['%%% Processing test brain ' structPathsTestImages(i).name]); disp(' ');
    
    % paths of reference image and corresponding FS labels
    pathRefImage = fullfile(structPathsTestImages(i).folder, structPathsTestImages(i).name);
    pathTestFirstLabels = fullfile(structPathsFirstRefLabels(i).folder, structPathsFirstRefLabels(i).name);
    pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
    
    % floating images generation
    disp(['%% synthetising images for ' structPathsTestImages(i).name])
    [pathDirSyntheticImages, pathDirSyntheticLabels] = ...
        synthetiseTrainingImages(pathRefImage, pathTestFirstLabels, pathDirTrainingLabels, pathClassesTable, targetResolution);
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' structPathsTestImages(i).name])
    pathDirFloatingImages = fullfile(pathDirSyntheticImages, '*nii.gz');
    pathDirFloatingLabels = fullfile(pathDirSyntheticLabels, '*nii.gz');
    [pathSegmentation, pathHippoSegmentation, cropping] = ...
        performLabelFusion(pathRefImage, pathTestFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters);
    
    % evaluation
    disp(' '); disp(['%% evaluating ' structPathsTestImages(i).name]); disp(' '); disp(' ');
    accuracies{i} = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, cropping);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);
comparisonGraph({accuracy,'Oasis'},'label fusion on Oasis dataset')
toc