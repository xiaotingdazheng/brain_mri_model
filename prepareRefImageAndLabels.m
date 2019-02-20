function [pathRefMaskedImage, croppedRefMaskedImage, voxelSelection] = prepareRefImageAndLabels(pathRefImage, pathRefLabels, ...
    cropAll, margin, preprocessedRefBrainFolder, freeSurferHome)

% mask real image if told so or if it doesn't exist
pathRefMaskedImage = maskImage(pathRefImage, pathRefLabels, preprocessedRefBrainFolder, freeSurferHome);

% crop ref image/labels around hippocampus if specified, otherwise read images
if cropAll
    
    [croppedRefMaskedImage, voxelSelection] = cropHippo(pathRefMaskedImage, pathRefLabels, margin, preprocessedRefBrainFolder);
    
else

    % get indices of voxels belonging to brain
    refLabelsMRI = MRIread(pathRefLabels);
    brainMask = refLabelsMRI.vol >0;
    brainMask1 = imdilate(brainMask, ones(margin, margin, margin));
    voxelSelection = find(brainMask1 >0)';
    
    % open ref masked image and set cropping to 0
    refMaskedImage = MRIread(pathRefMaskedImage);
    croppedRefMaskedImage = single(refMaskedImage.vol);
end

end