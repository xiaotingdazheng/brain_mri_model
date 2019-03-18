function catImages(cellPathImages, pathCatImage, recompute)

if ~exist(fileparts(pathCatImage),'dir'), mkdir(fileparts(pathCatImage)); end

if ~exist(pathCatImage, 'file') || recompute
    
    disp('concatenating all channels');
    
    nChannel = length(cellPathImages);

    % read first image
    refImageMRI = MRIread(cellPathImages{1});
    new_refImage = refImageMRI.vol;
    % concatenate other channels
    for channel=2:nChannel
        temp_refImageMRI = MRIread(cellPathImages{channel});
        new_refImage = cat(4, new_refImage, temp_refImageMRI.vol);
    end
    % write concatenated image
    refImageMRI.vol = new_refImage;
    MRIwrite(refImageMRI, pathCatImage);
    
else
    disp('channels already concatenated');
end

end