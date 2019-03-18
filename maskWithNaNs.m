function maskWithNaNs(pathImage, pathMask, pathMaskedImage)

% read image
imageMRI = MRIread(pathImage);
image= imageMRI.vol;
image(image<0.01) = 0;

if isequal(pathMask, pathImage)
    strel=zeros(3,3,3); strel(2,2,:)=ones(1,1,3); strel(2,:,2)=ones(1,3,1); strel(:,2,2)=ones(3,1,1);
    mask = imdilate(image > 0, strel);
else
    % read mask
    maskMRI = MRIread(pathMask);
    mask = maskMRI.vol;
    mask = mask > 0;
end

% mask image with NaNs
image(~mask) = NaN;

% write new Image
imageMRI.vol = image;
MRIwrite(imageMRI, pathMaskedImage);

end