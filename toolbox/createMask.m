function createMask(pathImage, pathCreatedMask, pathTempImFolder)

% This function writes the mask of the provided image at the given path.
% the mask is computed by keeping numbers (not nans) above 0.2.

% read image
mri = myMRIread(pathImage, 0, pathTempImFolder);
vol = mri.vol;

% create mask of the image
mask = zeros(size(vol),'int8');
mask(~isnan(vol) & vol>0.2) = 1;

% write mask
mriMask = mri;
mriMask.vol = mask;
myMRIwrite(mriMask,pathCreatedMask);

end