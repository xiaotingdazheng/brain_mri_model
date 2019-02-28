function pathNewImage = rescaleIntensities(pathImage, pathFolderRescaledImage, recompute)

% naming variables
idx = regexp(pathImage,'brain');
refBrainNum = pathImage(idx(end):regexp(pathImage,'.nii.gz')-1);
[~, name, ext] = fileparts(pathImage);
% handling paths
pathNewImage = fullfile(pathFolderRescaledImage, [name ext]);
if ~exist(pathFolderRescaledImage, 'dir'), mkdir(pathFolderRescaledImage); end

% rescale image intensities
if ~exist(pathNewImage, 'file') || recompute
    
    disp(['% rescaling ' refBrainNum])
    
    % read image
    imageMRI = MRIread(pathImage);
    image = imageMRI.vol;
    
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
    
    % save image
    imageMRI.vol = image;
    MRIwrite(imageMRI, pathNewImage);
    
else
    
    disp('% loading already rescaled image')
    
end

end