clear
now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5));
tic

% add paths for additionnal functions
freeSurferHome = '/usr/local/freesurfer/';
niftyRegHome = '/home/benjamin/Software/nifty-reg-mod/niftyreg/build/reg-apps/';
% freeSurferHome = '/share/apps/freesurfer/';
% niftyRegHome = '/home/bbillot/software/exe_brain_mri_model/compiled-nifty-reg/bin';

% cell paths test images
pathDirTestImages= {'~/data/CobraLab/label_fusions/multi_channel/synth_new_fixed_t2/test_images_t1';...
                    '~/data/CobraLab/label_fusions/multi_channel/synth_new_fixed_t2/test_images_t2'};
% cell paths test first labels (FS labels)
pathDirRefFirstLabels= {'~/data/CobraLab/label_fusions/multi_channel/synth_new_fixed_t2/test_first_labels_t1';...
                        '~/data/CobraLab/label_fusions/multi_channel/synth_new_fixed_t2/test_first_labels_t2'};
% cell paths test labels
pathDirTestLabels = '~/data/CobraLab/label_fusions/multi_channel/synth_new_fixed_t2/test_labels';
% cell paths training labels
pathDirTrainingLabels = '~/data/CobraLab/label_fusions/multi_channel/synth_new_fixed_t2/training_labels';
% path labels table
pathClassesTable= '~/data/CobraLab/label_fusions/multi_channel/synth_new_fixed_t2/classesTable.txt';
% optional paths
% pathDirTrainingImages = '~/data/CobraLab/label_fusions/brains_t1/synth_new/training_images';

% experiment title
title = 'label fusion on multispectral synthetic images from CobraLab data';
% general parameters
evaluate = 1;                % evaluate test scans segmentations aginst provided ref labels (0-1)
cropHippo = 0;               % crop results around hippocampus (0-1)
leaveOneOut = 1;             % segment one image with the rest of the datatset (0-1)
useSynthethicImages = 1;     % use real or synthetic images (0-1)
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
sigma = 25;                  % var for Gaussian likelihood
labelPriorType = 'logOdds';  % type of prior ('logOdds' or 'delta function')
% registration parameters
registrationOptions = '-ln 4 -lp 3 -sx 2.5 -omp 3 -be 0.0005 -le 0.005 --lncc 1.0';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add paths of freesurfer functions and toolbox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));

% read paths
if ~exist('pathDirTrainingImages','var'), pathDirTrainingImages=''; end
[pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages] = readPaths...
    (pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, useSynthethicImages, 0, evaluate);

% regroup parameters
params = {evaluate cropHippo leaveOneOut useSynthethicImages recompute debug deleteSubfolder targetResolution rescale alignTestImages ...
    margin rho threshold sigma labelPriorType registrationOptions freeSurferHome niftyRegHome pathClassesTable};

% segment brains  
accuracy = segment(pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, params);

% plot results
comparisonGraph({accuracy,'regions'}, title, 'all')

disp(' '); tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));