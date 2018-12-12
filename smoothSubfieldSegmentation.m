clear
close all

addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

cellPathsHippoLabels = {'/home/benjamin/data/hippocampus_labels/brain1_labels.nii.gz';
    '/home/benjamin/data/hippocampus_labels/brain2_labels.nii.gz';
    '/home/benjamin/data/hippocampus_labels/brain3_labels.nii.gz';
    '/home/benjamin/data/hippocampus_labels/brain4_labels.nii.gz';
    '/home/benjamin/data/hippocampus_labels/brain5_labels.nii.gz'};

for brain=1:length(cellPathsHippoLabels)
    
    pathLabels = cellPathsHippoLabels{brain};
    disp(['%%%%% loading ', pathLabels]);
    mriLabels = MRIread(pathLabels);
    labels = mriLabels.vol;
    
    %%% left hippocampus %%%
    
    disp('precessing left hippocampus')
    maskmri = mriLabels; %copies mri
    maskmri.vol(:) = labels>0 & labels<100; %find left hippocampus
    
    [~,cropping] = cropLabelVol(maskmri, 4); % crop hippocampus
    labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels
    labelsList = unique(labelsCrop); % find all present labels
    labelsNum = length(labelsList); % number of present labels
    
    labelsMasks = zeros([size(labelsCrop),labelsNum]); % masks for each labels
    labelsCount = zeros([size(labelsCrop),labelsNum]); % number of neighbour voxels of this type
    convMask = ones(3,3,3); convMask(2,2) = 1; % convolution neighbour counting mask
    
    for i=1:labelsNum
        labelsMasks(:,:,:,i) = labelsCrop==labelsList(i); % mask
        labelsCount(:,:,:,i) = convn(labelsMasks(:,:,:,i), convMask, 'same'); % count
    end
    
    [~, index] = max(labelsCount ,[], 4); % find most numerous neighour
    labelMap = arrayfun(@(x) labelsList(x), index); % assign voxel to most numerous neigbour
    
    labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelMap; % paste modified labels on original image
    
    %%% right hippocampus %%%
    
    disp('precessing right hippocmapus')
    maskmri = mriLabels; %copies mri
    maskmri.vol(:) = labels>100; %find left hippocampus
    
    [~,cropping] = cropLabelVol(maskmri, 4); % crop hippocampus
    labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels
    labelsList = unique(labelsCrop); % find all present labels
    labelsNum = length(labelsList); % number of present labels
    
    labelsMasks = zeros([size(labelsCrop),labelsNum]); % masks for each labels
    labelsCount = zeros([size(labelsCrop),labelsNum]); % number of neighbour voxels of this type
    convMask = ones(3,3,3); convMask(2,2) = 1; % convolution neighbour counting mask
    
    for i=1:labelsNum
        labelsMasks(:,:,:,i) = labelsCrop==labelsList(i); % mask
        labelsCount(:,:,:,i) = convn(labelsMasks(:,:,:,i), convMask, 'same'); % count
    end
    
    [~, index] = max(labelsCount ,[], 4); % find most numerous neighour
    labelMap = arrayfun(@(x) labelsList(x), index); % assign voxel to most numerous neigbour
    
    labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelMap; % paste modified labels on original image
    
    %%% save corrected labels
    
    mriLabels.vol = labels;
    pathCorrectedLabels = strrep(pathLabels,'nii.gz','mgz');
    [dir,name,~] = fileparts(pathCorrectedLabels);
    pathCorrectedLabels = fullfile(dir, [name, '.corrected.nii.gz']);
    disp(['writing corrected file ' pathCorrectedLabels]); disp(' ');
    MRIwrite(mriLabels, pathCorrectedLabels); %write a new nii.gz file.
    
end