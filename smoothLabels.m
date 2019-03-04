function labelsMap = smoothLabels(LabelsMap)

labelsList = unique(LabelsMap); % find all present labels
labelsNum = length(labelsList); % number of present labels

labelsMasks = zeros([size(LabelsMap), labelsNum]); % masks for each labels
labelsCount = zeros([size(LabelsMap), labelsNum]); % number of neighbour voxels of this type
convMask = ones(3,3,3); % convolution neighbour counting mask

for i=1:labelsNum
    labelsMasks(:,:,:,i) = LabelsMap==labelsList(i); % mask
    labelsCount(:,:,:,i) = convn(labelsMasks(:,:,:,i), convMask, 'same'); % count
end

[~, index] = max(labelsCount ,[], 4); % find most numerous neighour
labelsMap = arrayfun(@(x) labelsList(x), index); % assign voxel to most numerous neigbour

end