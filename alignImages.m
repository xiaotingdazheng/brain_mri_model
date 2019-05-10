function res = alignImages(pathRefImage, pathFloImage, alignImages, channel, freeSurferHome, niftyRegHome, recompute, debug)

% define paths
temp_flo = strrep(pathFloImage, 'nii.gz', 'mgz'); [folder,name,~] = fileparts(temp_flo);
res = fullfile(folder, [name '_aligned.nii.gz']);

if ~exist(res, 'file') || recompute
    
    disp(['aligning channel ' num2str(channel)]);
    
    if alignImages == 1
        % register channel to first one
        aff = '/tmp/aff.aff';
        cmd = [fullfile(niftyRegHome,'reg_aladin') ' -ref ' pathRefImage ' -flo ' pathFloImage ' -res ' res ' -aff ' aff ' -rigOnly -ln 4 -lp 3 -nac'];
        if debug, system(cmd); else, [~,~] = system(cmd); end
        [~,~]=system(['rm ' aff]);
    elseif alignImages == 2
        % reslice channel like first one
        setFreeSurfer(freeSurferHome);
        cmd = ['mri_convert ' pathFloImage ' ' res ' -rl ' pathRefImage ' -odt float'];
        if debug, system(cmd); else, [~,~] = system(cmd); end
    end
    
else
    disp(['channel ' num2str(channel) ' already aligned']);
end

end