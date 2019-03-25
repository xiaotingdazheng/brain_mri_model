function pathMaskedImage = mask(pathImage, pathMask, result, channel, padChar, padFS, brainNum, pathTempImFolder, freeSurferHome, recompute, verbose)

% Mask image with provided mask. Result is saved in specified folder with
% '_masked' added to the original filename.

% create name of masked file
if ~contains(result,'.nii.gz')
    temp_path = strrep(pathImage,'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_path);
    pathMaskedImage = fullfile(result, [name '_masked.nii.gz']);
    if ~exist(result, 'dir'), mkdir(result); end
else
    pathMaskedImage = pathImage;
end

if ~exist(pathMaskedImage, 'file') || recompute
    
    if channel && verbose, disp(['masking channel ' num2str(channel)]); elseif verbose, disp(['masking ' brainNum]); end
    
    % mask image
    if padFS
        setFreeSurfer(freeSurferHome);
        cmd = ['mri_mask ' pathImage ' ' pathMask ' ' pathMaskedImage];
        [~,~] = system(cmd);
    else
        maskWithChar(pathImage, pathMask, pathMaskedImage, padChar, pathTempImFolder);
    end
    
else
    
    if channel && verbose, disp(['channel ' num2str(channel) ' already masked']); elseif verbose, disp([brainNum ' already masked']); end
    
end

end

function maskWithChar(pathImage, pathMask, pathMaskedImage, padChar, pathTempImFolder)

% read image
imageMRI = myMRIread(pathImage, 0, pathTempImFolder);
image= imageMRI.vol;
image(image<0.01) = 0;

if isequal(pathMask, pathImage)
    strel=zeros(3,3,3); strel(2,2,:)=ones(1,1,3); strel(2,:,2)=ones(1,3,1); strel(:,2,2)=ones(3,1,1);
    mask = imdilate(image > 0, strel);
else
    % read mask
    maskMRI = myMRIread(pathMask, 0, pathTempImFolder);
    mask = maskMRI.vol;
    mask = mask > 0;
end

% mask image with NaNs
image(~mask) = padChar;

% write new Image
imageMRI.vol = image;
myMRIwrite(imageMRI, pathMaskedImage, 'float', pathTempImFolder);

end