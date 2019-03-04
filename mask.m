function pathMaskedImage = mask(pathImage, pathMask, resultFolder, freeSurferHome)

% Mask image with provided mask. Result is saved in specified folder with 
% '_masked' added to the original filename.

% create name of masked file
temp_path = strrep(pathImage,'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_path);
pathMaskedImage = fullfile(resultFolder, [name '_masked.nii.gz']);
if ~exist(resultFolder, 'dir'), mkdir(resultFolder); end

% mask image
setFreeSurfer(freeSurferHome);
cmd = ['mri_mask ' pathImage ' ' pathMask ' ' pathMaskedImage];
[~,~] = system(cmd);

end