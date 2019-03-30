function brainVoxels = selectBrainVoxels(pathImage, margin, pathTempImFolder)

% pathImage can be the path of an image or of corresponding labels

% get indices of voxels belonging to brain
refFirstLabelsMRI = myMRIread(pathImage, 0, pathTempImFolder);
brainMask = refFirstLabelsMRI.vol >0.001;
brainMask = imdilate(brainMask, ones(margin, margin, margin));

if size(brainMask,4) == 1
    
    brainVoxels = find(brainMask >0)';

elseif size(brainMask,4) > 1
    
    brainVoxels = cell(1,length(size(brainMask,4)));
    for i=1:size(brainMask,4)
        brainVoxels{i} = find(brainMask(:,:,:,i) >0)';
    end
    
end
    
end