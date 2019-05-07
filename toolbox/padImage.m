function padImage(pathImage, pathPaddedImage, padsize, pathTempImFolder, padchar)

if nargin < 5
    padchar = 0;
end

% pad image with padchar (0 by default)
% padsize: 1x3 vector containing padding size in each dimension.

% read image
mri = myMRIread(pathImage, 0, pathTempImFolder);
vol = mri.vol;

% pad image
matlabPadsize = padsize; 
matlabPadsize([1 2]) = matlabPadsize([2 1]);
paddedVol = padarray(vol, matlabPadsize, padchar, 'both');

% update header
v2r=mri.vox2ras0;
v2r(1:3,4)=v2r(1:3,4)-v2r(1:3,1:3)*[padsize(1); padsize(2); padsize(3)];

% write image
mri.vol = paddedVol;
mri.vox2ras0=v2r;
mri.vox2ras1=v2r;
mri.vox2ras=v2r;
myMRIwrite(mri, pathPaddedImage, 'float', pathTempImFolder);

end