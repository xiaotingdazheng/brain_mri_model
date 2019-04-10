function catImages(cellPathImages, pathCatImage, pathTempImFolder, recompute)

if ~exist(fileparts(pathCatImage),'dir'), mkdir(fileparts(pathCatImage)); end

if ~exist(pathCatImage, 'file') || recompute
    
    disp('concatenating all channels');
    
    nChannel = length(cellPathImages);

    % read first image
    refImageMRI = myMRIread(cellPathImages{1}, 0, pathTempImFolder);
    new_refImage = single(refImageMRI.vol);
    new_refImage(new_refImage<0.01) = 0;
    % concatenate other channels
    for channel=2:nChannel
        temp_refImageMRI = myMRIread(cellPathImages{channel}, 0, pathTempImFolder);
        temp_refImage = single(temp_refImageMRI.vol);
        temp_refImage(temp_refImage<0.2) = 0;
        new_refImage = cat(4, new_refImage, temp_refImage);
    end
    % write concatenated image
    refImageMRI.vol = new_refImage;
    myMRIwrite(refImageMRI, pathCatImage, 'float', pathTempImFolder);
    
else
    disp('channels already concatenated');
end

end