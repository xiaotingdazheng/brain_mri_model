clear
now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% experiment title
title = 'label fusion on CobraLab anisotropic T2';

% add paths for additionnal functions
freeSurferHome = '/usr/local/freesurfer/';
niftyRegHome = '/usr/local/nifty_reg/';

% define paths
pathDirTestImages = '~/data/CobraLab/label_fusions/brains_t2/label_fusion_synthetic_anisotropic/test_images/*nii.gz';         % test images
pathTestFirstLabels = '~/data/CobraLab/label_fusions/brains_t2/label_fusion_synthetic_anisotropic/test_first_labels/*nii.gz'; % FS labels
pathDirTestLabels = '~/data/CobraLab/label_fusions/brains_t2/label_fusion_synthetic_anisotropic/test_gt_labels/*nii.gz';      % test labels for evaluation
pathDirTrainingLabels = '~/data/CobraLab/label_fusions/brains_t2/label_fusion_synthetic_anisotropic/training_labels/*nii.gz'; % training labels
pathClassesTable = '~/data/CobraLab/label_fusions/brains_t2/label_fusion_synthetic_anisotropic/classesTable.txt';             % table between labels and intensity classes

% parameters
targetResolution = [0.6 0.6 2.0]; % resolution of synthetic images
cropImage = 1;                    % perform cropping around hippocampus (0-1)
margin = 30;                      % cropping margin
rho = 0.5;                        % exponential decay for logOdds maps
threshold = 0.1;                  % lower bound for logOdds maps
sigma = 300;                      % var for Gaussian likelihhod
labelPriorType = 'logOdds';       % type of prior ('logOdds' or 'delta function')
deleteSubfolder = 0;              % delete subfolder after having segmented an image
recompute = 1;                    % recompute files, even if they exist (0-1)
debug = 1;                        % display debug information from registrations
registrationOptions = '-pad 0 -ln 4 -lp 3 -sx 2.5 --lncc 5.0 -omp 3 -be 0.0005 -le 0.005 -vel -voff'; % registration parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add paths of freesurfer functions and toolobox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));

% initialisation
structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathTestFirstLabels);
structPathsRefLabels = dir(pathDirTestLabels);
structPathsTrainingLabels = dir(pathDirTrainingLabels);
accuracies = cell(length(structPathsTestImages),1);
labelFusionParameters = {cropImage margin rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};

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
    [pathDirSyntheticImages, pathDirSyntheticLabels] = synthetiseTrainingImages...
        (pathRefImage, pathTestFirstLabels, pathDirTrainingLabels, pathClassesTable, targetResolution, recompute, freeSurferHome, niftyRegHome, debug);
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' structPathsTestImages(i).name])
    pathDirFloatingImages = fullfile(pathDirSyntheticImages, '*nii.gz');
    pathDirFloatingLabels = fullfile(pathDirSyntheticLabels, '*nii.gz');
    [pathSegmentation, pathHippoSegmentation, cropping] = performLabelFusion...
        (pathRefImage, pathTestFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters, freeSurferHome, niftyRegHome, debug);
    
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
comparisonGraph({accuracy,'regions'}, title)
tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));