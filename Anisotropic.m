clear
now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

freeSurferHome = '/usr/local/freesurfer/';

% paths folders containing to process
pathDirRotatedImages = '~/data/CobraLab/images/brains_t2/rotated_images/*nii.gz';
pathDirOriginalLabels = '~/data/CobraLab/labels/merged_high_res/*nii.gz';

% paths result folders
pathDirResultImages = '~/data/CobraLab/images/brains_t2/anisotropic_images';
pathDirResultLabels = '~/data/CobraLab/labels/rotated_anisotropic_merged_low_res';

% parameters
targetRes = [0.6 0.6 2];
coronalDim = 3;
recompute = 1;
debug = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsRotatedImages = dir(pathDirRotatedImages);
structPathsOriginalLabels = dir(pathDirOriginalLabels);

for i=1:length(structPathsRotatedImages)
    
    disp(['%% processing ' structPathsRotatedImages(i).name]);
    
    % define paths
    pathRotatedImage = fullfile(structPathsRotatedImages(i).folder, structPathsRotatedImages(i).name);
    pathRotation = strrep(pathRotatedImage, '.nii.gz', '.nii.gz.lta');
    pathOriginalLabels = fullfile(structPathsOriginalLabels(i).folder, structPathsOriginalLabels(i).name);
    pathAnisotropicImage = fullfile(pathDirResultImages, structPathsRotatedImages(i).name);
    pathAnisotropicLabels = fullfile(pathDirResultLabels, structPathsOriginalLabels(i).name);
    
    % create result folders if they don't exist
    if ~exist(pathDirResultImages, 'dir'), mkdir(fileparts(pathAnisotropicImage)); end
    if ~exist(pathDirResultLabels, 'dir'), mkdir(fileparts(pathAnisotropicLabels)); end
    
    if ~exist(pathAnisotropicImage, 'file') || recompute
        
        % read image
        disp('loading image');
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
        MRIwrite(mri, pathAnisotropicImage);
        
        % downsample to target resolution
        disp('downsampling image to target resolution');
        setFreeSurfer(freeSurferHome);
        voxsize = [num2str(targetRes(1),'%.1f') ' ' num2str(targetRes(2),'%.1f') ' ' num2str(targetRes(3),'%.1f')];
        cmd = ['mri_convert ' pathAnisotropicImage ' ' pathAnisotropicImage ' --voxsize ' voxsize ' -odt float'];
        if debug, system(cmd); else, [~,~] = system(cmd); end
        
    end
    
    if ~exist(pathAnisotropicLabels, 'file') || recompute
        
        % apply transformation to labels
        disp('applying transformation to labels')
        cmd = ['mri_convert ' pathOriginalLabels ' ' pathAnisotropicLabels ' -at ' pathRotation ' -rl ' pathAnisotropicImage ' -rt nearest -odt float'];
        if debug, system(cmd); else, [~,~] = system(cmd); end
        disp(' ');
        
    end
    
end

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));