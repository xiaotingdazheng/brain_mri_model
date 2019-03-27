function [likelihood, sizeSegmMap] = calculateLikelihood(pathRefImage, pathRegFloImage, pathTempImFolder, sigma)


% read registered floating image
regFloImage = myMRIread(pathRegFloImage, 0, pathTempImFolder);
regFloImage = single(regFloImage.vol);
regFloImage(regFloImage<0) = 0;
regFloImage(isnan(regFloImage)) = 0;

% read ref masked image
refImage = myMRIread(pathRefImage, 0, pathTempImFolder);
refImage = single(refImage.vol);
refImage(refImage<0) = 0;
refImage(isnan(refImage)) = 0;
sizeSegmMap = size(refImage(:,:,:,1));

% calculate similarity between test (real) image and training (synthetic) image
nChannel = size(refImage,4);
likelihood = ones([size(refImage,1), size(refImage,2), size(refImage,3)], 'single');
for channel=1:nChannel
    temp_image = 1/sqrt(2*pi*sigma(channel))*exp(-((refImage(:,:,:,channel)-regFloImage(:,:,:,channel)).^2)/(2*sigma(channel)^2));
    temp_image(isnan(temp_image)) = 1;
    likelihood = likelihood.*temp_image;
end

end