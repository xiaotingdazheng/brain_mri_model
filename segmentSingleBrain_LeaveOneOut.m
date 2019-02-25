function accuracies = segmentSingleBrain_LeaveOneOut(pathTestImage, pathTestFirstLabels, pathTestLabels)

now = clock;
fprintf('Started on %d/%d at %dh%d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% add paths for additionnal functions
% freeSurferHome = '/share/apps/freesurfer';
% niftyRegHome = '/home/bbillot/.local/NiftyReg/bin/';
freeSurferHome = '/usr/local/freesurfer/';
niftyRegHome = '/usr/local/nifty_reg/';

% define paths
pathDirTrainingLabels = '~/data/CobraLab/label_fusions/brains_t2/synthetic_rescaled_anisotropic/training_labels/*nii.gz'; % training labels
pathClassesTable = '~/data/CobraLab/label_fusions/brains_t2/synthetic_rescaled_anisotropic/classesTable.txt';

% parameters
targetResolution = [0.6 2.0 0.6]; % resolution of synthetic images
rescale = 0;                      % rescale intensities between 0 and 255 (0-1)
cropImage = 0;                    % perform cropping around hippocampus (0-1)
margin = 15;                      % cropping margin (if cropImage=1) or brain's dilation (if cropImage=0)
rho = 0.5;                        % exponential decay for logOdds maps
threshold = 0.1;                  % lower bound for logOdds maps
sigma = 15;                       % var for Gaussian likelihhod
labelPriorType = 'logOdds';       % type of prior ('logOdds' or 'delta function')
deleteSubfolder = 0;              % delete subfolder after having segmented an image
recompute = 1;                    % recompute files, even if they exist (0-1)
debug = 1;                        % display debug information from registrations
registrationOptions = '-pad 0 -ln 3 -sx 5 --lncc 5.0 -omp 3 -voff'; % registration parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idx = regexp(pathTestImage,'brain');
refBrainNum = pathTestImage(idx(end):regexp(pathTestImage,'.nii.gz')-1);
disp(['%%% Processing test ' refBrainNum]); disp(' ');

% add paths of freesurfer functions and toolobox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));

% initialisation
pathRefImage = pathTestImage;
pathRefLabels = pathTestLabels;
pathAccuraciesSubfolder = fullfile(fileparts(fileparts(pathTestImage)), 'accuracies');
if ~exist(pathAccuraciesSubfolder, 'dir'), mkdir(pathAccuraciesSubfolder); end
pathAccuracies = fullfile(pathAccuraciesSubfolder, ['accuracy_' refBrainNum '.mat']);
labelFusionParameters = {cropImage margin rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};

% copies training labels and erase the one corresponding to test image
pathTempImageSubfolder = fullfile(fileparts(fileparts(pathDirTrainingLabels)), ['temp_' refBrainNum]);
if ~exist(pathTempImageSubfolder,'dir'), mkdir(pathTempImageSubfolder); end
cmd = ['rm -r ' fullfile(pathTempImageSubfolder, 'training_labels')];
[~,~] = system(cmd);
cmd = ['cp -r ' fileparts(pathDirTrainingLabels) ' ' fullfile(pathTempImageSubfolder, 'training_labels')];
[~,~] = system(cmd);
pathDirTrainingLabels = fullfile(pathTempImageSubfolder, 'training_labels', '*nii.gz');
structPathsTrainingLabels = dir(pathDirTrainingLabels);
for i=1:length(structPathsTrainingLabels)
    if contains(structPathsTrainingLabels(i).name, refBrainNum)
        pathRefTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
        cmd = ['rm ' pathRefTrainingLabels];
        [~,~] = system(cmd);
        break
    end
end

% floating images generation
disp(['%% synthetising images for ' refBrainNum])
[pathDirSyntheticImages, pathDirSyntheticLabels, pathRefImage] = synthetiseTrainingImages...
    (pathRefImage, pathTestFirstLabels, pathDirTrainingLabels, pathClassesTable, targetResolution, recompute, freeSurferHome, niftyRegHome, debug, rescale);

% labelFusion
disp(' '); disp(['%% segmenting ' refBrainNum])
pathDirFloatingImages = fullfile(pathDirSyntheticImages, '*nii.gz');
pathDirFloatingLabels = fullfile(pathDirSyntheticLabels, '*nii.gz');
[pathSegmentation, pathHippoSegmentation, voxelSelection] = performLabelFusion...
    (pathRefImage, pathTestFirstLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters, freeSurferHome, niftyRegHome, debug);

% evaluation
disp(' '); disp(['%% evaluating ' refBrainNum]); disp(' '); disp(' ');
accuracies = computeSegmentationAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, voxelSelection);
save(pathAccuracies, 'accuracies');

tEnd = toc;
fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));

end