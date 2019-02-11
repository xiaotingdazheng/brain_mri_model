function [pathRefMaskedImage, croppedRefLabels, croppedRefMaskedImage, cropping] = prepareRefImageAndLabels(pathRefImage, pathRefLabels, ...
    cropAll, margin, preprocessedRefBrainFolder, freeSurferHome)

% mask real image if told so or if it doesn't exist
pathRefMaskedImage = maskImage(pathRefImage, pathRefLabels, preprocessedRefBrainFolder, freeSurferHome);

% crop ref image/labels around hippocampus if specified, otherwise read images
if cropAll
    [croppedRefLabels, croppedRefMaskedImage, cropping] = cropHippo(pathRefMaskedImage, pathRefLabels, margin, preprocessedRefBrainFolder);
else
    refLabels = MRIread(pathRefLabels);
    refMaskedImage = MRIread(pathRefMaskedImage);
    croppedRefLabels = single(refLabels.vol);
    croppedRefMaskedImage = single(refMaskedImage.vol);
    cropping = 0;
end

end