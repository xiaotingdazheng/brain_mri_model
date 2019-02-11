function pathMaskedImage = maskImage(pathImage, pathLabels, maskedImageFolder, freeSurferHome)

% create name of masked file
temp_path = strrep(pathImage,'.nii.gz','.mgz');
[~,name,~] = fileparts(temp_path);
pathMaskedImage = fullfile(maskedImageFolder, [name '.masked.nii.gz']); %path of mask
if ~exist(maskedImageFolder, 'dir'), mkdir(maskedImageFolder); end

% mask image
setFreeSurfer(freeSurferHome);
cmd = ['mri_mask ' pathImage ' ' pathLabels ' ' pathMaskedImage];
[~,~] = system(cmd);

end