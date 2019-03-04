clear
now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

% add paths for additionnal functions
freeSurferHome = '/usr/local/freesurfer/';
niftyRegHome = '/usr/local/nifty_reg/';

% real
pathDirTestImages = '~/data/test/synth/test_images/*nii.gz';         % test images
pathRefFirstLabels = '~/data/test/synth/test_first_labels/*nii.gz';  % FS labels
pathDirTestLabels = '~/data/test/synth/test_labels/*nii.gz';         % test labels for evaluation
pathDirTrainingLabels = '~/data/test/synth/training_labels/*nii.gz'; % training labels
pathDirTrainingImages = '~/data/test/synth/training_images/*nii.gz'; % training images (if useSynthethicImages=0)
pathClassesTable= '~/data/test/synth/classesTable.txt';

% experiment title
title = 'label fusion on CobraLab upsampled anisotropic T2';
% general parameters
leaveOneOut = 0;                  % evaluate one image with the rest of the datatset
useSynthethicImages = 1;          % use real or synthetic images
recompute = 1;                    % recompute files, even if they exist (0-1)
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

% add paths of freesurfer functions and toolbox
addpath(fullfile(freeSurferHome, 'matlab/'));
addpath(genpath(pwd));
% regroup parameters
params = {leaveOneOut useSynthethicImages recompute debug deleteSubfolder targetResolution rescale...
    margin rho threshold sigma labelPriorType registrationOptions freeSurferHome niftyRegHome};
% deal with potential inexistant variables
if ~exist('pathDirTrainingImages','var'), pathDirTrainingImages=''; end
if ~exist('pathClassesTable','var'), pathClassesTable=''; end

% segment brains
accuracy = segment(pathDirTestImages, pathRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, pathClassesTable, params);

% plot results
comparisonGraph({accuracy,'regions'}, title)

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));