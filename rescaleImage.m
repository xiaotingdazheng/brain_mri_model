function pathNewImage = rescaleImage(pathImage, resultFolder, channel, brainNum, recompute)

% Rescale image. Result is saved in specified folder with '_rescaled' added
% to the original filename.

% naming variables
temp_path = strrep(pathImage,'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_path);
% defining new paths
pathNewImage = fullfile(resultFolder, [name '_rescaled.nii.gz']);
if ~exist(resultFolder, 'dir'), mkdir(resultFolder); end

% rescale image intensities
if ~exist(pathNewImage, 'file') || recompute
    
    if channel, disp(['rescaling channel ' num2str(channel)]); else, disp(['rescaling ' brainNum]); end
    
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
    
    if channel, disp(['channel ' num2str(channel) ' already rescaled']); else, disp([brainNum ' already rescaled']); end
    
end

end