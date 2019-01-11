function pathMaskedImage = maskImage(pathImage, pathLabels, maskedImageFolder)

% create name of masked file
temp_path = strrep(pathImage,'.nii.gz','.mgz');
[~,name,~] = fileparts(temp_path);
pathMaskedImage = fullfile(maskedImageFolder, [name '.masked.nii.gz']); %path of mask

% mask image
if ~exist(pathMaskedImage, 'file')
    setFreeSurfer();
    disp(['masking real image ' pathImage])
    cmd = ['mri_mask ' pathImage ' ' pathLabels ' ' pathMaskedImage];
    system(cmd);
end

end