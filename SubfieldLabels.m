% This script is a tool to generate synthetic images simulating brain MRIs.

% First, it takes segmentation maps and is able to fuse them with more
% precise segmentation of the hippocampus (generally at higher resolution).

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

% list of segmentation masks which will be merged with hippocampal 
% subfields' labels (only if fuseHippoLabels = 1). If mergeHippoLabels 
% is set to 0, then the images will direclty be generated from these. If
% computeStatsMatrix = 1, the first path of this list should be the aseg
% corresponding to the image used to compute the stats matrix.
% cellPathsLabels = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/aseg.mgz'; 
%     '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/aseg.mgz';
%     '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/aseg.mgz';
%     '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/aseg.mgz';
%     '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/aseg.mgz'};
cellPathsLabels = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/aseg+corrected_subfields.nii.gz'; 
    '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/aseg+corrected_subfields.nii.gz';
    '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/aseg+corrected_subfields.nii.gz';
    '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/aseg+corrected_subfields.nii.gz';
    '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/aseg+corrected_subfields.nii.gz'};

% merge labels between aseg and hippocampal subfields (0 or 1)
mergeHippoLabels = 0;
% if mergeHippoLabels = 1, specify here the paths of hippocampal subfields' 
% labels. They should be in the same order as the corresponding
% segmentation maps specified in cellPathsLabels.
cellPathsHippoLabels = {'/home/benjamin/data/hippocampus_labels/brain1_labels.corrected.nii.gz';
    '/home/benjamin/data/hippocampus_labels/brain2_labels.corrected.nii.gz'; 
    '/home/benjamin/data/hippocampus_labels/brain3_labels.corrected.nii.gz'; 
    '/home/benjamin/data/hippocampus_labels/brain4_labels.corrected.nii.gz'; 
    '/home/benjamin/data/hippocampus_labels/brain5_labels.corrected.nii.gz'};

% compute stats matrix from a specified image. If computeStatsMatrix = 0 
% the script will load a previously computed matrix (pathStatsMatrix).
computeStatsMatrix = 1;
% if computeStatsMatrix=0 path where resulting stats matrix will be stored,
% if computeStatsMatrix=1 path of stats matrix to load
pathStatsMatrix = '~/matlab/brain_mri_model/ClassesStats_t1_corrected.mat';
% if computeStatsMatrix=1, image to analyse to compute stats from. This 
% should be the image corresponding to the first segmentation map specified
%in cellPathsLabels. This should also be at hippocampal labels' resolution.
% pathImage = '~/subjects/brain1_t1_to_t2.0.6/mri/norm.0.3.mgz';
pathImage = '/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/norm.0.3.mgz';

% folder that will contain created images
pathNewImagesFolder = '/home/benjamin/data/synthetic_brains_t1/';

% define regions that w4559.71e want to study and group them by class
ClassNames = ["Cerebral GM","Cerebral WM","Cerebellum GM","Cerebellum WM","Brainstem","Ventral PC","Thalamus","Caudate","Accumbens","Putamen","Pallidum","Ventricules","Choroid Plexus","Hippocampus","Amygdala","CSF","Optic Chiasm","Vessel"];
ClassIndices = '  1            2                 3            4              5            6           7          8           9         10         11         12              13              14          15      16         17          18';
labelsList = [  2,3, 4, 5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
labelClasses = [2,1,12,12,4,3, 7, 8,10,11,12,12, 5,14,15,16, 9, 6,18,13, 2, 1,12,12, 4, 3, 7, 8,10,11,15, 9, 6,18,13,17,  2,  2,  2,  2,  2,   14,   14,   14,   14,    2,   14,   14,   14,   14,    2];
listClassesToGenerate = 1:length(ClassNames); % all classes

% select type of gaussian 'mean' or 'median'
gaussianType = 'median';

% target resolution of generated images
targetRes=[0.6 0.6 0.6];
% set to 1 if you wish to compute the downsampling to target resolution
% with the current version, and to 0 to use mri_convert
downsampleWithMatlab = 0;
% if downsample = 0 provide here image to us as template for downsampling
pathImageResliceLike = '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/norm.mgz';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(pathNewImagesFolder, 'dir'), mkdir(pathNewImagesFolder), end
for i=1:length(cellPathsLabels)
    
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    disp(['PROCESSING IMAGE ', num2str(i)])

    if mergeHippoLabels == 1
        % merge general and hippocampal labels for generative image
        disp(['%%%%%%%%%%%%%%',' merge general and hippocampal labels ', '%%%%%%%%%%%%%%%']);
        mergedLabelsMRI = mergeSubfieldLabels(cellPathsLabels{i}, cellPathsHippoLabels{i}, maxCropping);
        mergedLabels = mergedLabelsMRI.vol;
    else
        disp(['%%%%%%%%%%%%%%%%%%%%%',' loading merged labels ', '%%%%%%%%%%%%%%%%%%%%%%%']);
        mergedLabelsMRI = MRIread(cellPathsLabels{i});
        mergedLabels = mergedLabelsMRI.vol;
    end

    if i == 1
        if computeStatsMatrix == 1 
            % calculate intensity stats for all the specified regions
            disp(['%%%%%',' calculate intensity stats for all the specified regions ', '%%%%%']);
            classesStats = computeIntensityStats(pathImage, mergedLabels, labelsList, labelClasses, ClassNames, pathStatsMatrix );
        else
            disp(['%%%%%%%%%%%%%%%%%%%%%%%%%%',' loading stats ', '%%%%%%%%%%%%%%%%%%%%%%%%%%']);
            load(pathStatsMatrix,'classesStats')
        end
    end

    % create new images
    disp(['%%%%%%%%%%%%%%%%%%%%%%%%%',' create new image ', '%%%%%%%%%%%%%%%%%%%%%%%%']);
    new_image = createNewImage(mergedLabelsMRI, classesStats, listClassesToGenerate, labelsList, labelClasses, gaussianType, targetRes,...
        pathNewImagesFolder, pathStatsMatrix, cellPathsLabels{i}, pathImageResliceLike, downsampleWithMatlab);

end

toc