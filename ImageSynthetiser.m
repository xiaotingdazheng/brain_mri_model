
% This script is a tool to generate synthetic images simulating brain MRIs.

% First, it preprocesses the data. This step depends on the type of used
% dataset. Here we are able to use CobraLab or Oasis datasets. IN the first
% case, we have to merge tha labels with hippocampus subfields labels. In
% the second case we use the image to spot the WM.

% Then it separately computes basic statistics of each different region in
% the brain. This is done by studying the intensity distribution in an
% example image (at the resolution of the fused labels).

% Finally, synthetic images are generated by taking fused segmentation maps
% and sampling intensities from the previously derived distributions. The
% images are always generated at the resolution of the fused labels, but
% are then downsampled to a specified target resolution.

% All files are writen in nii format (no matter input formats).

tic

clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% path to main datafolder
%pathDataFolder = '/home/benjamin/data/CobraLab/';
pathDataFolder = '/home/benjamin/data/OASIS-TRT-20/';
% If preprocessing = 1, specify the folder containing preprocessing support
%pathDirPreprocessingSupport = '/home/benjamin/data/CobraLab/hippocampus_labels/*hippo_labels.nii.gz';
pathDirPreprocessingSupport = '/home/benjamin/data/OASIS-TRT-20/original_images/*.nii.gz';
% image to use as template for downsampling
%pathImageResliceLike = '~/data/CobraLab/original_images/brain1.nii.gz';
pathImageResliceLike = '/home/benjamin/data/OASIS-TRT-20/original_images/brain01.nii.gz';

preprocessing = 1;              % apply preprocessing (0 or 1)
preprocessingType = 'OASIS';    % preprocessing type ('CobraLab' or 'OASIS')
numberOfSmoothing = 1;          % smoothing to apply to preprocessing material (int)
computeStatsMatrix = 1;         % compute stats matrix (0 or 1)
gaussianType = 'median';        % select type of gaussian ('mean' or 'median')
targetRes=[1 1 1];              % target resolution of generated images
imageModality = 't1';           % naming parameter ('t1' or 't2')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% initialisation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define regions that we want to study and group them by class
ClassNames = ["Cerebral GM","Cerebral WM","Cerebellum GM","Cerebellum WM","Brainstem","Ventral PC","Thalamus","Caudate","Accumbens","Putamen","Pallidum","Ventricules","Choroid Plexus","Hippocampus","Amygdala","CSF","Optic Chiasm","Vessel"];
ClassIndices = '  1            2                 3            4              5            6           7          8           9         10         11         12              13              14          15      16         17          18';
labelsList = [  2,3, 4, 5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,53,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
labelClasses = [2,1,12,12,4,3, 7, 8,10,11,12,12, 5,14,15,16, 9, 6,18,13, 2, 1,12,12, 4, 3, 7, 8,10,11,14,15, 9, 6,18,13,17,  2,  2,  2,  2,  2,   14,   14,   14,   14,    2,   14,   14,   14,   14,    2];
listClassesToGenerate = 1:length(ClassNames); % all classes

% create name of smoothing for files
if numberOfSmoothing == 0
    smoothingName = '';
elseif numberOfSmoothing == 1
    smoothingName = 'smoothed_once.';
elseif numberOfSmoothing == 2
    smoothingName = 'smoothed_twice.';
else
    smoothingName = ['smoothed_', num2str(numberOfSmoothing), 'times.'];
end

% paths definitions
pathDirLabels = fullfile(pathDataFolder, 'original_labels/');
pathNewImagesFolder = fullfile(pathDataFolder, 'synthetic_images_and_labels/');
pathPreprocessedLabelsFolder = fullfile(pathDataFolder, 'preprocessed_labels/');
pathStatsMatrixFolder = fullfile(pwd,'ClassesStats');
pathStatsMatrix = fullfile(pathStatsMatrixFolder,['ClassesStats.',preprocessingType,'.',imageModality,'.',smoothingName,'mat']);
pathImageFolder = fullfile(pathDataFolder, 'image_for_intensity_sampling');

% subfolder creations
if ~exist(pathNewImagesFolder, 'dir'), mkdir(pathNewImagesFolder), end
if ~exist(pathPreprocessedLabelsFolder, 'dir'), mkdir(pathPreprocessedLabelsFolder), end
if ~exist(pathImageFolder, 'dir'), mkdir(pathImageFolder), end
if ~exist(pathStatsMatrixFolder, 'dir'), mkdir(pathStatsMatrixFolder), end

% list of files in specified directories
structPathsLabels = dir([pathDirLabels,'*.nii.gz']);
structPathsPreprocessingSupport = dir(pathDirPreprocessingSupport);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:length(structPathsLabels)
    
    % get filename and brain number
    pathLabels = fullfile(structPathsLabels(i).folder,structPathsLabels(i).name);
    pathPreprocessingSupport = fullfile(structPathsPreprocessingSupport(i).folder,structPathsPreprocessingSupport(i).name);
    brainNum = pathLabels(regexp(pathLabels,'brain'):regexp(pathLabels,'_labels.nii.gz')-1);
    
    disp(['%%%%%% processing ', structPathsLabels(i).name]);
    disp(' ');

    % preprocessing of images
    pathPreprocessedLabels = fullfile(pathPreprocessedLabelsFolder, [brainNum,'_preprocessed_labels.',smoothingName,'nii.gz']);
    if preprocessing == 1 || ~exist(pathPreprocessedLabels, 'file')
        disp('%%% preprocessing data')
        if isequal(preprocessingType, 'CobraLab')
            preprocessedLabelsMRI = CobraLabPreProcessing(pathLabels, pathPreprocessingSupport, numberOfSmoothing, pathPreprocessedLabelsFolder, smoothingName, brainNum);
        elseif isequal(preprocessingType, 'OASIS')
            preprocessedLabelsMRI = OASISpreProcessing(pathLabels, pathPreprocessingSupport, numberOfSmoothing, pathPreprocessedLabelsFolder, smoothingName, brainNum);
        else
            error('preprocessingType should be either CobraLab or OASIS')
        end
    else
        disp('%%% loading previously preprocessed data')
        preprocessedLabelsMRI = MRIread(pathPreprocessedLabels);
    end

    % calculate intensity stats for all the specified regions
    if i == 1
        pathImage = fullfile(pathImageFolder, [brainNum, '_sampling.nii.gz']);
        if computeStatsMatrix == 1 || ~exist(pathImage, 'file')
            disp('%%% calculating intensity stats for all the specified regions');
            classesStats = computeIntensityStats(pathImage, preprocessedLabelsMRI, labelsList, labelClasses, ClassNames, pathStatsMatrix, pathDataFolder, brainNum);
        else
            disp('%%% loading stats');
            load(pathStatsMatrix,'classesStats')
        end
    end

    % create new images
    disp('%%% creating new image'); 
    new_image = createNewImage(preprocessedLabelsMRI, classesStats, listClassesToGenerate, labelsList, labelClasses, gaussianType, targetRes,...
        pathNewImagesFolder, pathImageResliceLike, brainNum, imageModality, smoothingName);
    disp(' ');

end

toc