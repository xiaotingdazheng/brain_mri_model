clear
now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% experiment title
title = 'label fusion on CobraLab upsampled anisotropic T2';

% add paths for additionnal functions
freeSurferHome = '/usr/local/freesurfer/';
niftyRegHome = '/usr/local/nifty_reg/';

% define paths
pathDirTestImages = '~/data/CobraLab/label_fusions/brains_t2/synth_anisotropic_upsampled_local/test_images/*nii.gz';         % test images
pathRefFirstLabels = '~/data/CobraLab/label_fusions/brains_t2/synth_anisotropic_upsampled_local/test_first_labels/*nii.gz';  % FS labels
pathDirTestLabels = '~/data/CobraLab/label_fusions/brains_t2/synth_anisotropic_upsampled_local/test_labels/*nii.gz';         % test labels for evaluation
pathDirTrainingLabels = '~/data/CobraLab/label_fusions/brains_t2/synth_anisotropic_upsampled_local/training_labels/*nii.gz'; % training labels
pathClassesTable = '~/data/CobraLab/label_fusions/brains_t2/synth_anisotropic_upsampled_local/classesTable.txt';             % table labels vs intensity classes

% parameters
targetResolution = [0.6 2.0 0.6]; % resolution of synthetic images
isotropicLabelFusion = 1;
rescale = 0;                      % rescale intensities between 0 and 255 (0-1)
cropImage = 0;                    % perform cropping around hippocampus (0-1)
margin = 10;                      % cropping margin (if cropImage=1) or brain's dilation (if cropImage=0)
rho = 0.5;                        % exponential decay for logOdds maps
threshold = 0.1;                  % lower bound for logOdds maps
sigma = 15;                       % var for Gaussian likelihhod
labelPriorType = 'logOdds';       % type of prior ('logOdds' or 'delta function')
deleteSubfolder = 0;              % delete subfolder after having segmented an image
recompute = 0;                    % recompute files, even if they exist (0-1)
debug = 0;                        % display debug information from registrations
registrationOptions = '-pad 0 -ln 4 -lp 3 -sx 2.5 --lncc 5.0 -omp 3 -be 0.0005 -le 0.005 -vel -voff'; % registration parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add paths of freesurfer functions and toolobox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));

% initialisation
structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathRefFirstLabels);
structPathsRefLabels = dir(pathDirTestLabels);
accuracies = cell(length(structPathsTestImages),1);
labelFusionParameters = {cropImage margin rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};

for i=1:length(structPathsTestImages)
    
    % paths of reference image and corresponding FS labels
    pathRefImage = fullfile(structPathsTestImages(i).folder, structPathsTestImages(i).name);
    pathRefFirstLabels = fullfile(structPathsFirstRefLabels(i).folder, structPathsFirstRefLabels(i).name);
    pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
    
    idx = regexp(pathRefImage,'brain');
    refBrainNum = pathRefImage(idx(end):regexp(pathRefImage,'.nii.gz')-1);
    disp(['%%% Processing test' refBrainNum]); disp(' ');
    
    % copies training labels to temp folder and erase labels corresponding to test image
    pathTempImageSubfolder = fullfile(fileparts(fileparts(pathDirTrainingLabels)), ['temp_' refBrainNum]);
    if ~exist(pathTempImageSubfolder,'dir'), mkdir(pathTempImageSubfolder); end
    cmd = ['rm -r ' fullfile(pathTempImageSubfolder, 'training_labels')];
    [~,~] = system(cmd);
    cmd = ['cp -r ' fileparts(pathDirTrainingLabels) ' ' fullfile(pathTempImageSubfolder, 'training_labels')];
    [~,~] = system(cmd);
    temp_pathDirTrainingLabels = fullfile(pathTempImageSubfolder, 'training_labels', '*nii.gz');
    temp_structPathsTrainingLabels = dir(temp_pathDirTrainingLabels);
    for j=1:length(temp_structPathsTrainingLabels)
        if contains(temp_structPathsTrainingLabels(j).name, refBrainNum)
            pathRefTrainingLabels = fullfile(temp_structPathsTrainingLabels(j).folder, temp_structPathsTrainingLabels(j).name);
            cmd = ['rm ' pathRefTrainingLabels];
            [~,~] = system(cmd);
            break
        end
    end
    
    % floating images generation
    disp(['%% synthetising images for ' structPathsTestImages(i).name])
    [pathDirSyntheticImages, pathDirSyntheticLabels, pathRefImage] = synthetiseTrainingImages(pathRefImage, pathRefFirstLabels, temp_pathDirTrainingLabels,...
        pathClassesTable, targetResolution, recompute, freeSurferHome, niftyRegHome, debug, rescale);
    
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
        (pathRefImage, pathRefFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters, freeSurferHome, niftyRegHome, debug);
    
    % evaluation
    disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' '); disp(' ');
    accuracies{i} = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, voxelSelection);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);
comparisonGraph({accuracy,'regions'}, title)
tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));