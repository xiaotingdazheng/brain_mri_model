clear
now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% experiment title
title = 'label fusion on CobraLab isotropic T2';

% add paths for additionnal functions
freeSurferHome = '/usr/local/freesurfer/';
niftyRegHome = '/usr/local/nifty_reg/';

% define paths
pathDirTestImages = '~/data/OASIS/label_fusions/label_fusion_reduced_label_map/test_images/*nii.gz';         % test images
pathTestFirstLabels = '~/data/OASIS/label_fusions/label_fusion_reduced_label_map/test_first_labels/*nii.gz'; % FS labels
pathDirTestLabels = '~/data/OASIS/label_fusions/label_fusion_reduced_label_map/test_first_labels/*nii.gz';   % test labels for evaluation
pathDirTrainingLabels = '~/data/OASIS/label_fusions/label_fusion_reduced_label_map/training_labels/*nii.gz'; % training labels
pathClassesTable = '~/data/OASIS/label_fusions/label_fusion_reduced_label_map/classesTable.txt';             % table between labels and intensity classes

% parameters
targetResolution = [1 1 1]; % resolution of synthetic images
isotropicLabelFusion = 1;
rescale = 0;                % rescale intensities between 0 and 255 (0-1)
cropImage = 0;              % perform cropping around hippocampus (0-1)
margin = 10;                % cropping margin (if cropImage=1) or brain's dilation (if cropImage=0)
rho = 0.5;                  % exponential decay for logOdds maps
threshold = 0.1;            % lower bound for logOdds maps
sigma = 15;                 % var for Gaussian likelihhod
labelPriorType = 'logOdds'; % type of prior ('logOdds' or 'delta function')
deleteSubfolder = 0;        % delete subfolder after having segmented an image
recompute = 0;              % recompute files, even if they exist (0-1)
debug = 1;                  % display debug information from registrations
registrationOptions = '-pad 0 -ln 3 -sx 5 --lncc 5.0 -omp 3 -voff'; % registration parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add paths of freesurfer functions and toolobox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));

% initialisation
structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathTestFirstLabels);
structPathsRefLabels = dir(pathDirTestLabels);
accuracies = cell(length(structPathsTestImages),1);
labelFusionParameters = {cropImage margin rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};

for i=1:length(structPathsTestImages)
    
    disp(['%%% Processing ' structPathsTestImages(i).name]); disp(' ');
    
    % paths of reference image and corresponding FS labels
    pathRefImage = fullfile(structPathsTestImages(i).folder, structPathsTestImages(i).name);
    pathTestFirstLabels = fullfile(structPathsFirstRefLabels(i).folder, structPathsFirstRefLabels(i).name);
    pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
    
    % floating images generation
    disp(['%% synthetising images for ' structPathsTestImages(i).name])
    [pathDirSyntheticImages, pathDirSyntheticLabels, pathRefImage] = synthetiseTrainingImages...
        (pathRefImage, pathTestFirstLabels, pathDirTrainingLabels, pathClassesTable, targetResolution, recompute, freeSurferHome, niftyRegHome, debug, rescale);
    
    % upsampling to isotropic resolution
    disp('%% upsampling to isotropic resolution');
    if isotropicLabelFusion && ~isequal(targetResolution(1), targetResolution(2), targetResolution(3))
        [pathRefImage, pathRefFirstLabels, pathRefLabels] = upsampleToIsotropic...
            (pathDirSyntheticImages, pathDirSyntheticLabels, pathRefImage, pathRefFirstLabels, pathRefLabels, targetResolution);
    end
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' structPathsTestImages(i).name])
    pathDirFloatingImages = fullfile(pathDirSyntheticImages, '*nii.gz');
    pathDirFloatingLabels = fullfile(pathDirSyntheticLabels, '*nii.gz');
    [pathSegmentation, pathHippoSegmentation, voxelSelection] = performLabelFusion...
        (pathRefImage, pathTestFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters, freeSurferHome, niftyRegHome, debug);
    
    % evaluation
    disp(' '); disp(['%% evaluating segmentation for ' structPathsTestImages(i).name]); disp(' '); disp(' ');
    accuracies{i} = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, voxelSelection);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);
comparisonGraph({accuracy,'regions'}, title)
tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));
