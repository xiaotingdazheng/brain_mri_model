function pathMaskedImage = mask(pathImage, pathMask, resultFolder, channel, padNaNs, freeSurferHome, recompute)

% Mask image with provided mask. Result is saved in specified folder with
% '_masked' added to the original filename.

% naming variables
brainNum = findBrainNum(pathImage);
% create name of masked file
temp_path = strrep(pathImage,'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_path);
pathMaskedImage = fullfile(resultFolder, [name '_masked.nii.gz']);
if ~exist(resultFolder, 'dir'), mkdir(resultFolder); end

if ~exist(pathMaskedImage, 'file') || recompute
    
    if channel, disp(['masking channel ' num2str(channel)]); else, disp(['masking ' brainNum]); end
    
    % mask image
    if padNaNs
        maskWithNaNs(pathImage, pathMask, pathMaskedImage);
    else
        setFreeSurfer(freeSurferHome);
        cmd = ['mri_mask ' pathImage ' ' pathMask ' ' pathMaskedImage];
        [~,~] = system(cmd);
    end
    
else
    
    if channel, disp(['channel ' num2str(channel) ' already masked']); else, disp([brainNum ' already masked']); end
    
end

end