function [pathRefMaskedImage, croppedRefLabels, croppedRefMaskedImage, cropping] = prepareRefImageAndLabels(pathRefImage, pathRefLabels, ...
    recomputeMaskRefImages, cropAll, margin, maskedImageFolder, croppedFolder)

% mask real image if told so or if it doesn't exist
pathRefMaskedImage = maskImage(pathRefImage, pathRefLabels, maskedImageFolder, recomputeMaskRefImages);

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