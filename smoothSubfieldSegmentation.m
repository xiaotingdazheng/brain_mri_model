function mriLabels = smoothSubfieldSegmentation(mriLabels, pathLabels)

% This function takes as inputs the subfields label map of an hippocmapus
% adn smooth it. The smoothing is performed by replacing each voxel by its
% most numerous neighours.
% The ooutput is the nifty file containing the smoothed label map. This
% nifty file is also saved separately.

addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

labels = mriLabels.vol;

%%% left hippocampus %%%

disp('smoothing left hippocampus')
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

disp('smoothing right hippocmapus')
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
disp(['writing smoothed subfields ' pathCorrectedLabels]);
MRIwrite(mriLabels, pathCorrectedLabels); %write a new nii.gz file.

end