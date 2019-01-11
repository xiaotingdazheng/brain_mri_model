function pathMaskedFloatingImage = maskImage(pathImage, pathLabels, maskedImageFolder)

% create name of masked file
temp_flo = strrep(pathImage,'.nii.gz','.mgz');
[~,name,~] = fileparts(temp_flo);
pathMaskedFloatingImage = fullfile(maskedImageFolder, [name '.masked.nii.gz']); %path of mask

% mask image
if ~exist(pathMaskedFloatingImage, 'file')
    setFreeSurfer();
    disp(['masking real image ' pathImage])
    cmd = ['mri_mask ' pathImage ' ' pathLabels ' ' pathMaskedFloatingImage];
    system(cmd);
end

end