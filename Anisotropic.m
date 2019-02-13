clear
close all;

freeSurferHome = '/usr/local/freesurfer/';
pathDirRotatedImages = '~/data/CobraLab/images/brains_t2/rotated_images/*nii.gz';
targetRes = [0.6 0.6 2];
coronalDim = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsRotatedImages = dir(pathDirRotatedImages);

for i=1:length(structPathsRotatedImages)
    
    disp(['%% processing ' structPathsRotatedImages(i).name]);
    
    % read image
    disp('loading image');
    pathRotatedImage = fullfile(structPathsRotatedImages(i).folder, structPathsRotatedImages(i).name);
    mri = MRIread(pathRotatedImage);
    rotatedImage = single(mri.vol);
    
    % define sigma and kernel size
    disp('defining sigma and kernel size');
    sampleRes = [mri.xsize mri.ysize mri.zsize];
    f=targetRes./sampleRes;
    sigmaFilt=0.9*f;
    sigma = sigmaFilt(coronalDim);
    sizeCoronalMask = 2*ceil(2*sigmaFilt(coronalDim))+1;
    sizeConvMask = ones(1,3); 
    sizeConvMask(coronalDim) = sizeCoronalMask;
    
    % blur image
    disp('blurring image');
    blurredImage = imgaussfilt3(rotatedImage, sigma, 'FilterSize', sizeConvMask);
    
    % write blurred image
    disp('writting blurred image');
    mri.vol = blurredImage;
    pathBlurredImage = strrep(pathRotatedImage, 'rotated_images', 'blurred_images');
    MRIwrite(mri, pathBlurredImage);
    
    % downsample to target resolution
    disp('downsampling image to target resolution');
    setFreeSurfer(freeSurferHome);
    pathAnisotropicImage = strrep(pathBlurredImage, 'blurred_images', 'anisotropic_images');
    voxsize = [num2str(targetRes(1),'%.1f') ' ' num2str(targetRes(2),'%.1f') ' ' num2str(targetRes(3),'%.1f')];
    cmd = ['mri_convert ' pathBlurredImage ' ' pathAnisotropicImage ' --voxsize ' voxsize ' -odt float'];
    [~,~] = system(cmd);
    disp(' ');
    
end