function brainVoxels = selectBrainVoxels(pathRefFirstLabels, margin)

% get indices of voxels belonging to brain
refFirstLabelsMRI = MRIread(pathRefFirstLabels);
brainMask = refFirstLabelsMRI.vol >0;
brainMask = imdilate(brainMask, ones(margin, margin, margin));
brainVoxels = find(brainMask >0)';

end