function alignFloatingImages(pathDirImages, debug, niftyRegHome)

structDirImages = cell(size(pathDirImages));

for channel=1:length(pathDirImages)
    pathDirImages{channel} = fullfile(pathDirImages{channel}, '*.nii.gz');
    structDirImages{channel} = dir(pathDirImages{channel});
end

for i=1:length(structDirImages{1}) % loop over floating images
    for channel=2:length(pathDirImages) % loop over channels
        
        % define paths
        ref = fullfile(structDirImages{1}(i).folder, structDirImages{1}(i).name);
        flo = fullfile(structDirImages{channel}(i).folder, structDirImages{channel}(i).name);
        res = flo;
        % register all channels to first one
        cmd = [fullfile(niftyRegHome,'reg_aladin') ' -ref ' ref ' -flo ' flo ' -res ' res ' -rigOnly -ln 4 -lp 3'];
        if debug, system(cmd); else, cmd = [cmd ' -voff']; [~,~] = system(cmd); end
       
    end
end


end