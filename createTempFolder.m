function [refBrainNum, pathMainFolder, pathTempImFolder] = createTempFolder(pathRefImage, id, recompute)

% display processed test brain
if recompute
    refBrainNum = findBrainNum(pathRefImage{1}); 
else 
    refBrainNum = id; 
end
% create temp folder
pathFolderRefImage = fileparts(pathRefImage{1});
cd(pathFolderRefImage);
pathMainFolder = fileparts(pwd);
pathTempImFolder = fullfile(pathMainFolder, ['temp_' refBrainNum]);
% check if it exist
if ~exist(pathTempImFolder,'dir')
    % attribute new refBrainNum if recompute = 0
    if ~recompute
        refBrainNum = findBrainNum(pathRefImage{1});
        disp([id ' did not exist, switched to new id: ' refBrainNum]); disp(' ');
        pathTempImFolder = fullfile(pathMainFolder, ['temp_' refBrainNum]);
    end
    mkdir(pathTempImFolder);
elseif exist(pathTempImFolder,'dir') && ~recompute
    disp(['using files already computed in ' pathTempImFolder]); disp(' ');
end

end