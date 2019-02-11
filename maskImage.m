function pathMaskedImage = maskImage(pathImage, pathLabels, maskedImageFolder, freesurferHome)

% create name of masked file
temp_path = strrep(pathImage,'.nii.gz','.mgz');
[~,name,~] = fileparts(temp_path);
pathMaskedImage = fullfile(maskedImageFolder, [name '.masked.nii.gz']); %path of mask
if ~exist(maskedImageFolder, 'dir'), mkdir(maskedImageFolder); end

% mask image
setFreeSurfer(freesurferHome);
cmd = ['mri_mask ' pathImage ' ' pathLabels ' ' pathMaskedImage];
[~,~] = system(cmd);

end