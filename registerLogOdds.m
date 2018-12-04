function pathRegisteredLogOddsSubfolder = registerLogOdds(pathTransformation, pathRefMaskedImage, labelsList, pathlogOddsSubfolder, ...
    resultsFolder, recompute, refBrainNum, floBrainNum)

% This function is called only if labelPriorType was set to 'logOdds'. It
% applies to the logOdds files the warping computed during the registration
% of the floating image to the reference one. The registered logOdds are
% saved in the result folder (no output).

for k=1:length(labelsList)
    
    registrationName = [floBrainNum '_registered_to_' refBrainNum];
    pathRegisteredLogOddsSubfolder = fullfile(resultsFolder, ['logOdds.' registrationName]);
    if ~exist(pathRegisteredLogOddsSubfolder, 'dir'), mkdir(pathRegisteredLogOddsSubfolder), end
    pathRegisteredLogOdds = fullfile(pathRegisteredLogOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.' registrationName '.nii.gz']);
    
    % apply deformation only if file doesn't already exist or if we recompute everything
    if ~exist(pathRegisteredLogOdds, 'file') || recompute
        
        % define pathname of file to register
        temp_pathLogOdds = fullfile(pathlogOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
        
        % register current logOdds file to masked reference image
        cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',temp_pathLogOdds,' -trans ',pathTransformation,' -res ',pathRegisteredLogOdds,' -pad 0 -inter 0 -voff'];
        system(cmd);
        
    end
    
end

end