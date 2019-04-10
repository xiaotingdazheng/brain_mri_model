function SingleBrainSegmentationCluster(pathRefImage, pathRefFirstLabels, pathRefLabels)

now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5));
tic

% add paths for additionnal functions
% freeSurferHome = '/usr/local/freesurfer/';
% niftyRegHome = '/home/benjamin/Software/nifty-reg-mod/niftyreg/build/reg-apps/';
freeSurferHome = '/share/apps/freesurfer/';
niftyRegHome = '/home/bbillot/software/exe_brain_mri_model/compiled-nifty-reg/bin';

% cell paths training labels
pathDirTrainingLabels = '/home/bbillot/data/CobraLab/label_fusions/brains_t1/real_new/training_labels';
% path labels table
pathClassesTable= '/home/bbillot/data/CobraLab/label_fusions/brains_t1/real_new/classesTable.txt';
% optional paths
pathDirTrainingImages = '/home/bbillot/data/CobraLab/label_fusions/brains_t1/real_new/training_images';

% general parameters
evaluate = 1;                % evaluate test scans segmentations aginst provided ref labels (0-1)
cropHippo = 0;               % crop results around hippocampus (0-1)
leaveOneOut = 1;             % segment one image with the rest of the datatset (0-1)
useSynthethicImages = 0;     % use real or synthetic images (0-1)
recompute = 0;               % recompute files, even if they exist (0-1)
debug = 0;                   % display debug information from registrations (0-1)
deleteSubfolder = 0;         % delete subfolder where all intermediate information is stored (0-1)
% preprocessing parameters
targetResolution = 0.4;      % resolution of synthetic images (0 = test image resolution, only if one channel)
alignTestImages = 1;         % align multi-channel test images, (0=no, 1=rigid reg, 2=rl)
rescale = 1;                 % rescale intensities between 0 and 255 (0-1)
% label fusion parameters
margin = 5;                  % margin for brain voxels selection
rho = 0.5;                   % exponential decay for logOdds maps
threshold = 0.1;             % lower bound for logOdds maps
sigma = 15;             % var for Gaussian likelihood
labelPriorType = 'logOdds';  % type of prior ('logOdds' or 'delta function')
% registration parameters
registrationOptions = '-ln 4 -lp 3 -sx 2.5 --lncc 5.0 -omp 3 -be 0.0005 -le 0.005';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add paths of freesurfer functions and toolbox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));

% read paths
if ~exist('pathDirTrainingImages','var'), pathDirTrainingImages=''; end
[pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages] = readPaths...
    (pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages, useSynthethicImages, 1, evaluate);

% regroup parameters
params = {evaluate cropHippo leaveOneOut useSynthethicImages recompute debug deleteSubfolder targetResolution rescale alignTestImages ...
    margin rho threshold sigma labelPriorType registrationOptions freeSurferHome niftyRegHome pathClassesTable};

%------------------------- equivalent of segment -------------------------%

% read and check parameters
nChannel = length(pathRefImage);
[evaluate, cropHippo, leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, alignTestImages, margin, rho, threshold,...
    sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome, labelsList, labelClasses, labelsNames] = readParams(params, nChannel, 1);

% build path resulting accuracies
pathMainFolder = fileparts(fileparts(pathRefImage{1}));
pathAccuracies = fullfile(pathMainFolder, 'accuracy.mat');
% parameters initialisation
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder  multiChannel recompute registrationOptions};
% paths of reference image and corresponding FS labels
refBrainNum = findBrainNum(pathRefImage{1});
pathResultPrefix = fullfile(pathMainFolder, 'results', refBrainNum, refBrainNum);
pathTempImFolder = fullfile(pathMainFolder, ['temp_' refBrainNum]);

% display processed test brain
disp(' '); disp(['%%% Processing test ' refBrainNum]);

% copies training labels to temp folder and erase labels corresponding to test image
disp(' '); disp('%% copying training data');
if ~exist(pathTempImFolder,'dir'), mkdir(pathTempImFolder); end
if ~useSynthethicImages
    temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, pathTempImFolder, refBrainNum, 1, 'labels', freeSurferHome, recompute, leaveOneOut);
    temp_pathDirTrainingImages = copyTrainingData(pathDirTrainingImages, pathTempImFolder, refBrainNum, nChannel, 'images', freeSurferHome, recompute, leaveOneOut);
else
    temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, pathTempImFolder, refBrainNum, 1, 'labels', freeSurferHome, recompute, leaveOneOut);
    temp_pathDirTrainingImages = pathDirTrainingImages;
end

% preprocessing test image
disp(' '); if multiChannel, disp(['%% preprocessing test ' refBrainNum ' images ']); else, disp(['%% preprocessing test ' refBrainNum]); end
[pathRefImage, pathRefFirstLabels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, pathTempImFolder, rescale, ...
    alignTestImages, refBrainNum, freeSurferHome, niftyRegHome, recompute, debug);

% floating images generation or preprocessing of real training images
if useSynthethicImages
    disp(' '); disp(['%% synthetising images for ' refBrainNum]);
    [pathDirFloatingImages, pathDirFloatingLabels] = generateTrainingImages(temp_pathDirTrainingLabels, labelsList, labelClasses,...
        pathRefImage, pathRefFirstLabels, pathTempImFolder, targetResolution, refBrainNum, recompute, freeSurferHome, niftyRegHome, debug);
else
    disp(' '); disp(['%% preprocessing real training images for ' refBrainNum]);
    [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(temp_pathDirTrainingImages,...
        temp_pathDirTrainingLabels, pathRefImage, pathTempImFolder, targetResolution, nChannel, rescale, freeSurferHome, niftyRegHome, recompute, debug);
end

% upsample ref data to targetRes
[pathRefImage, pathRefLabels, brainVoxels, cropping] = upsampleToTargetRes(pathRefImage, pathRefLabels, pathRefFirstLabels, pathTempImFolder, ...
    targetResolution, multiChannel, margin, recompute, evaluate, cropHippo);

% remove old hippocampus labels and add background
[updatedLabelsList, updatedLabelsNames] = updateLabelsList(labelsList, labelsNames);

% labelFusion
disp(' '); disp(['%% segmenting ' refBrainNum]);
[pathSegmentation, pathHippoSegmentation] = labelFusion...
    (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, updatedLabelsList, updatedLabelsNames, ...
    pathTempImFolder, pathResultPrefix, refBrainNum, cropping, freeSurferHome, niftyRegHome, debug);

% evaluation
disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' ');
accuracies = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, updatedLabelsList, pathTempImFolder, cropping);
if ~exist(fileparts(pathAccuracies), 'dir'), mkdir(fileparts(pathAccuracies)); end
save(pathAccuracies, 'accuracies');


%-------------------------------------------------------------------------%

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));

end