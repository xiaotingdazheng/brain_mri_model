function pathMaskedImage = mask(pathImage, pathMask, result, rescale, channel, padChar, brainNum, pathTempImFolder, recompute, verbose)

% Mask image with provided mask. Result is saved in specified folder with
% '_masked' added to the original filename.

% create name of masked file
if ~contains(result,'.nii.gz')
    temp_path = strrep(pathImage,'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_path);
    if rescale, pathMaskedImage = fullfile(result, [name '_rescaled_masked.nii.gz']);
    else, pathMaskedImage = fullfile(result, [name '_masked.nii.gz']); end
    if ~exist(result, 'dir'), mkdir(result); end
else
    pathMaskedImage = pathImage;
end
if isequal(pathMask, pathImage), pathMask=''; end

% rescale and mask image
if ~exist(pathMaskedImage, 'file') || recompute
    if channel && verbose, disp(['masking channel ' num2str(channel)]); elseif verbose, disp(['masking ' brainNum]); end
    imageMRI = myMRIread(pathImage, 0, pathTempImFolder); %read image
    image= imageMRI.vol;
    if rescale, image = robustRescale(image); end % rescale image
    image = maskWithChar(image, pathMask, padChar, pathTempImFolder); % mask image
    imageMRI.vol = image;
    myMRIwrite(imageMRI, pathMaskedImage, 'float', pathTempImFolder); % write new image
else
    if channel && verbose, disp(['channel ' num2str(channel) ' already masked']); elseif verbose, disp([brainNum ' already masked']); end
end

end

function image = robustRescale(image)

% sort non-zero intensities
intensities = image(:);
intensities = intensities(intensities>0);
intensities = sort(intensities);

% define robust min and max
robustMin = intensities(round(0.025*length(intensities)));
robustMax = intensities(round(0.975*length(intensities)));

% trim values outside new range
image(image < robustMin) = 0;
image(image > robustMax) = robustMax;

% rescale image
image = (image-robustMin)/(robustMax-robustMin)*255;
image(image<0) = 0;

end

function image = maskWithChar(image, pathMask, padChar, pathTempImFolder)

dilate = 7;

% remove negative values
image(image<0) = 0;

if isempty(pathMask)
    mask = image >0.01;
else
    % read mask
    maskMRI = myMRIread(pathMask, 0, pathTempImFolder);
    mask = maskMRI.vol;
    mask = mask > 0;
end

% dilate mask
% strel=zeros(3,3,3); strel(2,2,:)=ones(1,1,3); strel(2,:,2)=ones(1,3,1); strel(:,2,2)=ones(3,1,1);
strel=ones(dilate,dilate,dilate);
mask = imdilate(mask, strel);

% mask image with NaNs
image(~mask) = padChar;

end