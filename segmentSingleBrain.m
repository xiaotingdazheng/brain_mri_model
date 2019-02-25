function accuracies = segmentSingleBrain(pathTestImage, pathTestFirstLabels, pathTestLabels)

now = clock;
fprintf('Started on %d/%d at %dh%d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% add paths for additionnal functions
freeSurferHome = '/share/apps/freesurfer';
niftyRegHome = '/home/bbillot/.local/NiftyReg/bin/';

% define paths
pathDirTrainingLabels = '~/data/OASIS/label_fusions/label_fusion_FS_single_brain/training_labels/*nii.gz'; % training labels
pathClassesTable = '~/data/OASIS/label_fusions/label_fusion_FS_single_brain/classesTable.txt';

% parameters
targetResolution = [1 1 1]; % resolution of synthetic images
rescale = 0;                      % rescale intensities between 0 and 255 (0-1)
cropImage = 0;                    % perform cropping around hippocampus (0-1)
margin = 10;                      % cropping margin (if cropImage=1) or brain's dilation (if cropImage=0)
rho = 0.5;                        % exponential decay for logOdds maps
threshold = 0.1;                  % lower bound for logOdds maps
sigma = 15;                       % var for Gaussian likelihhod
labelPriorType = 'logOdds';       % type of prior ('logOdds' or 'delta function')
deleteSubfolder = 0;              % delete subfolder after having segmented an image
recompute = 1;                    % recompute files, even if they exist (0-1)
debug = 1;                        % display debug information from registrations
registrationOptions = '-pad 0 -ln 3 -sx 5 --lncc 5.0 -omp 3 -voff'; % registration parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[folder,name,~] = fileparts(pathTestImage);
disp(['%%% Processing test brain ' name]); disp(' ');

% add paths of freesurfer functions and toolobox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));

% initialisation
pathRefImage = pathTestImage;
pathRefLabels = pathTestLabels;
pathAccuraciesSubfolder = fullfile(fileparts(folder), 'accuracies');
if ~exist(pathAccuraciesSubfolder, 'dir'), mkdir(pathAccuraciesSubfolder); end
pathAccuracies = fullfile(pathAccuraciesSubfolder, ['accuracy_' name '.mat']);
labelFusionParameters = {cropImage margin rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};

% floating images generation
disp(['%% synthetising images for ' name])
[pathDirSyntheticImages, pathDirSyntheticLabels, pathRefImage] = synthetiseTrainingImages...
    (pathRefImage, pathTestFirstLabels, pathDirTrainingLabels, pathClassesTable, targetResolution, recompute, freeSurferHome, niftyRegHome, debug, rescale);

% labelFusion
disp(' '); disp(['%% segmenting ' name])
pathDirFloatingImages = fullfile(pathDirSyntheticImages, '*nii.gz');
pathDirFloatingLabels = fullfile(pathDirSyntheticLabels, '*nii.gz');
[pathSegmentation, pathHippoSegmentation, voxelSelection] = performLabelFusion...
    (pathRefImage, pathTestFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters, freeSurferHome, niftyRegHome, debug);

% evaluation
disp(' '); disp(['%% evaluating ' name]); disp(' '); disp(' ');
accuracies = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, voxelSelection);
save(pathAccuracies, 'accuracies');

tEnd = toc;
fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));

end