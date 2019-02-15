clear
now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

freeSurferHome = '/usr/local/freesurfer/';

pathDirRotatedImages = '~/data/CobraLab/images/brains_t2/rotated_images/*nii.gz';
pathDirOriginalLabels = '~/data/CobraLab/labels/original_labels_low_res/*nii.gz';

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
    pathAnisotropicImage = strrep(pathRotatedImage, 'rotated_images', 'anisotropic_images');
    pathOriginalLabels = fullfile(structPathsOriginalLabels(i).folder, structPathsOriginalLabels(i).name);
    pathAnisotropicLabels = strrep(pathOriginalLabels, 'original_labels_low_res', 'rotated_anisotropic_labels_low_res');
    pathRotation = strrep(pathRotatedImage, '.nii.gz', '.nii.gz.lta');
    
    % create dir if they don't exist
    if ~exist(fileparts(pathAnisotropicImage), 'dir'), mkdir(fileparts(pathAnisotropicImage)); end
    if ~exist(fileparts(pathAnisotropicLabels), 'dir'), mkdir(fileparts(pathAnisotropicLabels)); end
    
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
        % cmd = ['mri_convert ' pathOriginalLabels ' ' pathAnisotropicLabels ' -rl ' pathAnisotropicImage ' -rt nearest -odt float'];
        if debug, system(cmd); else, [~,~] = system(cmd); end
        disp(' ');
        
    end
    
end

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));