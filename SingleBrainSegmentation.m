function SingleBrainSegmentation(pathRefImage, pathRefFirstLabels, pathRefLabels)

now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% add paths for additionnal functions
freeSurferHome = '/share/apps/freesurfer';
niftyRegHome = '/home/bbillot/.local/NiftyReg/bin/';

% real
pathDirTrainingLabels = '~/data/test/synth/training_labels/*nii.gz'; % training labels
pathDirTrainingImages = '~/data/test/synth/training_images/*nii.gz'; % training images (if useSynthethicImages=0)
pathClassesTable= '~/data/test/synth/classesTable.txt';

% general parameters
leaveOneOut = 0;                  % evaluate one image with the rest of the datatset
useSynthethicImages = 1;          % use real or synthetic images
recompute = 0;                    % recompute files, even if they exist (0-1)
debug = 0;                        % display debug information from registrations
deleteSubfolder = 0;              % delete subfolder after having segmented an image
% preprocessing parameters
targetResolution = [0.6 2.0 0.6]; % resolution of synthetic images
rescale = 0;                      % rescale intensities between 0 and 255 (0-1)
% label fusion parameters
margin = 10;                      % margin for brain voxels selection
rho = 0.5;                        % exponential decay for logOdds maps
threshold = 0.1;                  % lower bound for logOdds maps
sigma = 15;                       % var for Gaussian likelihood
labelPriorType = 'logOdds';       % type of prior ('logOdds' or 'delta function')
registrationOptions = '-pad 0 -ln 4 -lp 3 -sx 2.5 --lncc 5.0 -omp 3 -be 0.0005 -le 0.005 -vel -voff'; % registration parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isdeployed
    % add paths of freesurfer functions and toolbox
    addpath(fullfile(freeSurferHome, 'matlab/'));
    addpath(genpath(pwd));
end

% display processed test brain
refBrainNum = findBrainNum(pathRefImage);
disp(['%%% Processing test ' refBrainNum]);

% deal with potential inexistant variables
if ~exist('pathDirTrainingImages','var'), pathDirTrainingImages=''; end
if ~exist('pathClassesTable','var'), pathClassesTable=''; end
% initialisation
pathAccuraciesSubfolder = fullfile(fileparts(fileparts(pathRefImage)), 'accuracies');
if ~exist(pathAccuraciesSubfolder, 'dir'), mkdir(pathAccuraciesSubfolder); end
pathAccuracies = fullfile(pathAccuraciesSubfolder, ['accuracy_' refBrainNum '.mat']);
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};

% copies training labels to temp folder and erase labels corresponding to test image
if leaveOneOut && ~useSynthethicImages
    temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum);
    temp_pathDirTrainingImages = copyTrainingData(pathDirTrainingImages, refBrainNum);
elseif leaveOneOut && useSynthethicImages
    temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum);
    temp_pathDirTrainingImages = pathDirTrainingImages;
else
    temp_pathDirTrainingLabels = pathDirTrainingLabels;
    temp_pathDirTrainingImages = pathDirTrainingImages;
end

% preprocessing test image
disp(' '); disp(['%% preprocessing test ' refBrainNum]);
[pathRefImage, brainVoxels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, rescale, recompute, margin, freeSurferHome);

% floating images generation or preprocessing of real training images
if useSynthethicImages
    disp(['%% synthetising images for ' refBrainNum]);
    [pathDirFloatingImages, pathDirFloatingLabels] = generateTrainingImages(temp_pathDirTrainingLabels, pathClassesTable, pathRefImage, ...
        pathRefFirstLabels, targetResolution, recompute, freeSurferHome, niftyRegHome, debug);
else
    disp('%% preprocessing real training images');
    [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(temp_pathDirTrainingImages, temp_pathDirTrainingLabels, ...
        pathRefImage, targetResolution, rescale, recompute, freeSurferHome);
end

% labelFusion
disp(' '); disp(['%% segmenting ' refBrainNum])
[pathSegmentation, pathHippoSegmentation] = labelFusion...
    (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, freeSurferHome, niftyRegHome, debug);

% evaluation
disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' '); disp(' ');
accuracies = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels);
save(pathAccuracies, 'accuracies');

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));

if isdeployed, exit; end

end