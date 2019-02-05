clear
now = clock;
fprintf('Started on %d/%d at %dh%d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% add paths for additionnal functions
addpath /usr/local/freesurfer/matlab % path of freesurfer's matlab functions
addpath(genpath(pwd))                % includes toolbox folder

% define paths
pathDirTestImages = '~/data/OASIS/label_fusion_real/test_images/*nii.gz';         % test images
pathFirstTestLabels = '~/data/OASIS/label_fusion_real/test_first_labels/*nii.gz'; % FS labels
pathDirTestLabels = '~/data/OASIS/label_fusion_real/test_first_labels/*nii.gz';   % test labels for evaluation
pathDirTrainingImages = '~/data/OASIS/label_fusion_real/training_images/*nii.gz'; % training images
pathDirTrainingLabels = '~/data/OASIS/label_fusion_real/training_labels/*nii.gz'; % training labels

% parameters
targetResolution = [1 1 1]; % resolution of synthetic images
cropImage = 1;              % perform cropping around hippocampus (0-1)
margin = 30;                % cropping margin
rho = 0.5;                  % exponential decay for logOdds maps
threshold = 0.1;            % lower bound for logOdds maps
sigma = 150;                % var for Gaussian likelihhod
labelPriorType = 'logOdds'; % type of prior ('logOdds' or 'delta function')
deleteSubfolder = 0;        % delete subfolder after having segmented an image
recompute = 1;              % recompute files, even if they exist (0-1)
registrationOptions = '-pad 0 -ln 3 -sx 5 --lncc 5.0 -voff'; % registration parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathFirstTestLabels);
structPathsRefLabels = dir(pathDirTestLabels);
accuracies = cell(length(structPathsTestImages),1);
labelFusionParameters = {cropImage margin rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};

for i=1:length(structPathsTestImages)
    
    disp(['%%% Processing test brain ' structPathsTestImages(i).name]); disp(' ');
    
    % paths of reference image and corresponding FS labels
    pathRefImage = fullfile(structPathsTestImages(i).folder, structPathsTestImages(i).name);
    pathFirstTestLabels = fullfile(structPathsFirstRefLabels(i).folder, structPathsFirstRefLabels(i).name);
    pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
    
    % floating images generation
    disp(['%% preprocessing images for ' structPathsTestImages(i).name])
    [pathDirFloatingImages, pathDirFloatingLabels] = ...
        preprocessTrainingImages(pathRefImage, pathFirstTestLabels, pathDirTrainingImages, pathDirTrainingLabels, targetResolution, recompute);
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' structPathsTestImages(i).name])
    pathDirFloatingImages = fullfile(pathDirFloatingImages, '*nii.gz');
    pathDirFloatingLabels = fullfile(pathDirFloatingLabels, '*nii.gz');
    [pathSegmentation, pathHippoSegmentation, cropping] = ...
        performLabelFusion(pathRefImage, pathFirstTestLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters);
    
    % evaluation
    disp(' '); disp(['%% evaluating ' structPathsTestImages(i).name]); disp(' '); disp(' ');
    accuracies{i} = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, cropping);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);
comparisonGraph({accuracy,'Oasis'},'label fusion on Oasis dataset')
tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));