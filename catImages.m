function catImages(cellPathImages, pathCatImage, pathTempImFolder, recompute)

if ~exist(fileparts(pathCatImage),'dir'), mkdir(fileparts(pathCatImage)); end

if ~exist(pathCatImage, 'file') || recompute
    
    disp('concatenating all channels');
    
    nChannel = length(cellPathImages);

    % read first image
    refImageMRI = myMRIread(cellPathImages{1}, 0, pathTempImFolder);
    new_refImage = refImageMRI.vol;
    % concatenate other channels
    for channel=2:nChannel
        temp_refImageMRI = myMRIread(cellPathImages{channel}, 0, pathTempImFolder);
        new_refImage = cat(4, new_refImage, temp_refImageMRI.vol);
    end
    % write concatenated image
    refImageMRI.vol = new_refImage;
    myMRIwrite(refImageMRI, pathCatImage, 'float', pathTempImFolder);
    
else
    disp('channels already concatenated');
end

end