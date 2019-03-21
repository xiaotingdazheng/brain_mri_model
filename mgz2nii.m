function pathImageNii = mgz2nii(pathImage, resultFolder, eraseOld, Imagetype, channel, freeSurferHome, recompute)

[folder,name,ext] = fileparts(pathImage);
brainNum = findBrainNum(pathImage);

if strcmp(ext, '.mgz')
    
    if strcmp(resultFolder,'same'), resultFolder = folder; end
    pathImageNii = fullfile(resultFolder, [name '.nii.gz']);
    if ~exist(resultFolder, 'dir'), mkdir(resultFolder); end
    
    if ~exist(pathImageNii, 'file') || recompute
        
        
        
        setFreeSurfer(freeSurferHome);
        
        % convert mgz to nii.gz
        if strcmp(Imagetype, 'images')
            if channel, disp(['converting channel ' num2str(channel) ' image to .mgz']); else, disp(['converting ' brainNum ' image to mgz']); end
            cmd = ['mri_convert ' pathImage ' ' pathImageNii ' -odt float '];
        elseif strcmp(Imagetype, 'labels')
            if channel, disp(['converting channel ' num2str(channel) ' labels to .mgz']); else, disp(['converting ' brainNum ' labels to mgz']); end
            cmd = ['mri_convert ' pathImage ' ' pathImageNii ' -odt float -rt nearest'];
        else
            error('type should be images or labels');
        end
        [~,~] = system(cmd);
        
        % erase previous image if needed
        if eraseOld
           cmd = ['rm ' pathImage]; [~,~]=system(cmd);
        end
  
    end
    
else
    pathImageNii = pathImage;
end

end