function [croppedRefSegmentation, croppedRefMaskedImage, cropping] = prepareRefImageAndLabels(pathRefImage, pathRefLabels, computeMaskRefImages, cropAll, margin, resultsFolder)

% mask real image
refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);
temp_ref = strrep(pathRefImage,'.nii.gz','.mgz');
[~,name,~] = fileparts(temp_ref);
pathRefMaskedImage = fullfile(resultsFolder, [refBrainNum '_' name '.masked.nii.gz']); %path of binary mask
if ~exist(pathRefMaskedImage, 'file') || computeMaskRefImages == 1
    setFreeSurfer();
    disp(['masking reference image ' pathRefImage])
    cmd = ['mri_mask ' pathRefImage ' ' pathRefLabels ' ' pathRefMaskedImage];
    system(cmd); %mask real ref image
end

% open reference labels
refSegmentation = MRIread(pathRefLabels);
refMaskedImage = MRIread(pathRefMaskedImage);

% open corresponding segmentation and crop ref image/labels around hippocampus
refSegmentation = refSegmentation.vol; refMaskedImage = refMaskedImage.vol;
if cropAll
    [croppedRefSegmentation, croppedRefMaskedImage, cropping] = cropHippo(refSegmentation, refMaskedImage, margin, resultsFolder, refBrainNum);
else
    croppedRefSegmentation = refSegmentation;
    croppedRefMaskedImage = refMaskedImage;
    cropping = 0;
end

end