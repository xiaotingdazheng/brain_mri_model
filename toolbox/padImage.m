function padImage(pathImage, pathPaddedImage, padding, pathTempImFolder)

% read image
mri = myMRIread(pathImage, 0, pathTempImFolder);
vol = mri.vol;

% pad image
matlabPadding = padding; 
matlabPadding([1 2]) = matlabPadding([2 1]);
paddedVol = padarray(vol, matlabPadding, 0, 'both');

% update header
v2r=mri.vox2ras0;
v2r(1:3,4)=v2r(1:3,4)-v2r(1:3,1:3)*[padding(1); padding(2); padding(3)];

% write image
mri.vol = paddedVol;
mri.vox2ras0=v2r;
mri.vox2ras1=v2r;
mri.vox2ras=v2r;
myMRIwrite(mri, pathPaddedImage, 'float', pathTempImFolder);

end