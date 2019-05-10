function padImage(pathImage, pathPaddedImage, padsize, pathTempImFolder, padchar)

% pad image with padchar (0 by default)
% padsize: vector (symetric) or 1x6 vector (asymetric) containing padding size in each dimension.
%          symetric padding -> 1x3 vector, one element for each dimension
%          asymetric padding -> 1x6 vetcor [xpre xpost ypre ypost zpre zpost]
% pathImage: path nifty image to pad
% pathPaddedImage: path padded image

% set padding character to 0 if unset
if nargin < 5
    padchar = 0;
end

if length(padsize) == 1, padsize = repmat(padsize, 1, 3); end

% read image
mri = myMRIread(pathImage, 0, pathTempImFolder);
vol = mri.vol;

% pad image
if length(padsize) == 3
    paddedVol = padarray(vol, padsize([2 1 3]), padchar, 'both');
elseif length(padsize) == 6
    paddedVol = padarray(vol, padsize([3 1 5]), padchar, 'pre');
    paddedVol = padarray(paddedVol, padsize([4 2 6]), padchar, 'post');
else
    error('padsize must be of length 1 (isotropic padding), 3 (symetric padding on each side of image) or 6 (asymetric padsize)');
end

% update vox2ras matrix
v2r=mri.vox2ras0;
if length(padsize) == 3
    v2r(1:3,4)=v2r(1:3,4)-v2r(1:3,1:3)*[padsize(1); padsize(2); padsize(3)];
elseif length(padsize) == 6
    v2r(1:3,4)=v2r(1:3,4)-v2r(1:3,1:3)*[padsize(1); padsize(3); padsize(5)];
end

% write new image
mri.vol = paddedVol;
mri.vox2ras0=v2r;
mri.vox2ras1=v2r;
mri.vox2ras=v2r;
myMRIwrite(mri, pathPaddedImage, 'float', pathTempImFolder);

end