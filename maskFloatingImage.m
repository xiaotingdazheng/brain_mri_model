function pathFloatingImage = maskFloatingImage(pathFloatingImage, pathFloatingLabels, resultsFolder)

temp_flo = strrep(pathFloatingImage,'.nii.gz','.mgz');
[~,name,~] = fileparts(temp_flo);

pathMaskedFloatingImage = fullfile(resultsFolder, [name '.masked.nii.gz']); %path of mask

if ~exist(pathMaskedFloatingImage, 'file')
    setFreeSurfer();
    disp(['masking real image ' pathFloatingImage])
    cmd = ['mri_mask ' pathFloatingImage ' ' pathFloatingLabels ' ' pathMaskedFloatingImage];
    system(cmd);
end

pathFloatingImage = pathMaskedFloatingImage;

end