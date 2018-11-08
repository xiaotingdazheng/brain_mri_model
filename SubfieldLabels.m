% This script takes segmentation labels (0.6mm resolution) of the whole
% brain and combines them with labels of the hippocampal subsctructures.
tic

clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% list of segmentation masks from which new images will be generated (the one which will be used to compute stats should be first)
cellPathsLabels = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/aseg.mgz'; 
    '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/aseg.mgz';
    '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/aseg.mgz';
    '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/aseg.mgz';
    '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/aseg.mgz'};
% '~/subjects/brain2_t1_to_t2.0.6/mri/aseg+subfields_rotated.mgz'};

% recompute the label fusion between aseg and hippocampal subfield (0 or 1)
refuseHippoLabels = 1;
% hippocampal subfields' lab
% recompute stats matrix (set to zero only when it has been already computed)
recomputeStatsMatrix = 1;
% image to analyse to compute stats from (at hippocampal labels' resolution)
pathImage = '/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/norm.0.3.mgz';
% stats to use to generate the image
pathStatsMatrix = '~/matlab/brain_mri_model/ClassesStats_t1.mat';

% folder that will contain created images
pathNewImagesFolder = '/home/benjamin/data/synthetic_brains_t1/';

% define regions that we want to study and group them by class
ClassNames = ["Cerebral GM","Cerebral WM","Cerebellum GM","Cerebellum WM","Brainstem","Ventral PC","Thalamus","Caudate","Accumbens","Putamen","Pallidum","Ventricules","Choroid Plexus","Hippocampus","Amygdala","CSF","Optic Chiasm","Vessel"];
ClassIndices = '  1            2                 3            4              5            6           7          8           9         10         11         12              13              14          15      16         17          18';
labelsList = [  2,3, 4, 5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
labelClasses = [2,1,12,12,4,3, 7, 8,10,11,12,12, 5,14,15,16, 9, 6,18,13, 2, 1,12,12, 4, 3, 7, 8,10,11,15, 9, 6,18,13,17,  2,  2,  2,  2,  2,   14,   14,   14,   14,    2,   14,   14,   14,   14,    2];
listClassesToGenerate = 1:length(ClassNames); % all classes

% select type of gaussian 'mean' or 'median'
gaussianType = 'median';

% resolutions
targetRes=[0.6 0.6 0.6]; %final resolution of the created image
%targetRes=[2.0 0.4 0.4];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:length(cellPathsLabels)
    
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    disp(['PROCESSING IMAGE ', num2str(i)])
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

    if refuseHippoLabels == 1
        % fuse general and hippocampal labels for generative image
        disp(['%%%%%%%%%%%%%',' fuse general and hippocampal labels ', '%%%%%%%%%%%%%']);
        fusedLabelsMRI = mergeSubfieldLabels(cellPathsLabels{i}, cellPathsHippoLabels{i});
        fusedLabels = fusedLabelsMRI.vol;
    else
        disp(['%%%%%%%%%%%%%',' loading fused labels ', '%%%%%%%%%%%%%']);
        fusedLabelsMRI = MRIread(cellPathsLabels{i});
        fusedLabels = fusedLabelsMRI.vol;
    end

    if i == 1
        if recomputeStatsMatrix == 1 
            % calculate intensity stats for all the specified regions
            disp(['%%%%%%%%%%%%%',' calculate intensity stats for all the specified regions ', '%%%%%%%%%%%%%']);
            classesStats = computeIntensityStats(pathImage, fusedLabels, labelsList, labelClasses, ClassNames, pathStatsMatrix);
        else
            disp(['%%%%%%%%%%%%%',' loading stats ', '%%%%%%%%%%%%%']);
            load(pathStatsMatrix,'classesStats')
        end
    end

    % create new images
    disp(['%%%%%%%%%%%%%',' create new image ', '%%%%%%%%%%%%%']);
    new_image = createNewImage(fusedLabelsMRI, classesStats, listClassesToGenerate, labelsList, labelClasses, gaussianType, targetRes, pathNewImagesFolder, cellPathsLabels{i});

end

toc