function [croppedRefLabels, croppedRefMaskedImage, cropping] = prepareRefImageAndLabels(pathRefImage, pathRefLabels, ...
    computeMaskRefImages, cropAll, margin, maskedImageFolder, croppedFolder)

% mask real image
if computeMaskRefImages == 1
    pathRefMaskedImage = maskImage(pathRefImage, pathRefLabels, maskedImageFolder);
end

% crop ref image/labels around hippocampus if specified, otherwise read images
if cropAll
    [croppedRefLabels, croppedRefMaskedImage, cropping] = cropHippo(pathRefMaskedImage, pathRefLabels, margin, croppedFolder);
else
    refLabels = MRIread(pathRefLabels);
    refMaskedImage = MRIread(pathRefMaskedImage);
    croppedRefLabels = refLabels.vol;
    croppedRefMaskedImage = refMaskedImage.vol;
    cropping = 0;
end

end