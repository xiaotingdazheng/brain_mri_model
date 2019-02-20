function pathNewImage = rescaleIntensities(pathImage, refBrainNum, recompute)

[folder, name, ~] = fileparts(pathImage);
rescaledImagesFolder = fullfile(fileparts(folder), 'rescaled_test_images');
pathNewImage = fullfile(rescaledImagesFolder, name);

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