clear
tic
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

% define paths
pathDirTestImages = '/home/benjamin/data/CobraLab/label_fusion/test_images/*nii.gz';         % original images
pathTestFirstLabels = '/home/benjamin/data/CobraLab/label_fusion/test_first_labels/*nii.gz'; % FS labels at test image resolution, for intensity sampling
pathDirTrainingLabels = '/home/benjamin/data/CobraLab/label_fusion/training_labels/*nii.gz'; % labels at 0.3 resolution, for image generation
pathDirTestLabels = '/home/benjamin/data/CobraLab/label_fusion/test_first_labels/*nii.gz';   % same labels as training at test image resolution, for evaluation
pathClassesTable = '/home/benjamin/data/CobraLab/label_fusion/classesTable.txt';             % correspondance between labels and classes

% parameters
targetResolution = [1 1 1];
cropImage = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathTestFirstLabels);
structPathsRefLabels = dir(pathDirTestLabels);
structPathsTrainingLabels = dir(pathDirTrainingLabels);
accuracies = cell(length(structPathsTestImages),1);

% leave one out indices
n_training_data = length(structPathsLabels);
leaveOneOutIndices = flipud(nchoosek(1:n_training_data,n_training_data-1));

for i=1:length(structPathsTestImages)
    
    disp(['%%% Processing test brain ' structPathsTestImages(i).name]); disp(' ');
    
    % paths of reference image and corresponding FS labels
    pathRefImage = fullfile(structPathsTestImages(i).folder, structPathsTestImages(i).name);
    pathTestFirstLabels = fullfile(structPathsFirstRefLabels(i).folder, structPathsFirstRefLabels(i).name);
    pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
    
    % convert labels corresponding to test image into mgz
    pathRefTrainingLabelsNifty = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    pathRefTrainingLabelsMgz = strrep(pathRefTrainingLabelsNifty, '.nii.gz', '.mgz');
    cmd1 = ['mri_convert ' pathRefTrainingLabelsNifty ' ' pathRefTrainingLabelsMgz];
    cmd2 = ['rm ' pathRefTrainingLabelsNifty];
    [~,~] = system(cmd1); [~,~] = system(cmd2);
    
    % floating images generation
    disp(['%% synthetising images for ' structPathsTestImages(i).name])
    [pathDirSyntheticImages, pathDirSyntheticLabels] = synthetiseTrainingImages(pathRefImage, pathTestFirstLabels, pathDirTrainingLabels, pathClassesTable, targetResolution);
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' structPathsTestImages(i).name])
    pathDirFloatingImages = fullfile(pathDirSyntheticImages, '*nii.gz');
    pathDirFloatingLabels = fullfile(pathDirSyntheticLabels, '*nii.gz');
    [pathSegmentation, pathHippoSegmentation, cropping] = performLabelFusion(pathRefImage, pathTestFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, cropImage);
    
    % evaluation
    disp(' '); disp(['%% evaluating ' structPathsTestImages(i).name]); disp(' '); disp(' ');
    accuracies{i} = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, cropping);
    
    % convert labels corresponding to test image back into nii.gz
    cmd3 = ['mri_convert ' pathRefTrainingLabelsMgz ' ' pathRefTrainingLabelsNifty];
    cmd4 = ['rm ' pathRefTrainingLabelsMgz];
    [~,~] = system(cmd3); [~,~] = system(cmd4);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);
comparisonGraph({accuracy,'Oasis'},'label fusion on Oasis dataset')
toc