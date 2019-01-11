function registeredLogOddsSubFolder = registerLogOdds(pathTransformation, pathRefMaskedImage, labelsList, pathlogOddsSubfolder,...
    registrationSubFolder, recompute, refBrainNum, floBrainNum)

% This function is called only if labelPriorType was set to 'logOdds'. It
% applies to the logOdds files the warping computed during the registration
% of the floating image to the reference one. The registered logOdds are
% saved in the result folder (no output).

registrationName = [floBrainNum '_registered_to_' refBrainNum];
registeredLogOddsSubFolder = fullfile(registrationSubFolder,'logOdds');
if ~exist(registeredLogOddsSubFolder, 'dir'), mkdir(registeredLogOddsSubFolder), end

for k=1:length(labelsList)
    
    % name of resulting registered file
    pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, ['logOdds_' num2str(labelsList(k)) '.' registrationName '.nii.gz']);
    
    % apply deformation only if file doesn't already exist or if we recompute everything
    if ~exist(pathRegisteredLogOdds, 'file') || recompute
        
        % define pathname of file to register
        temp_pathLogOdds = fullfile(pathlogOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
        
        % register current logOdds file to masked reference image
        cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',temp_pathLogOdds,' -trans ',pathTransformation,' -res ',pathRegisteredLogOdds,' -pad 0 -inter 0 -voff'];
        system(cmd);
        
    end
    
end

% apply same mechanism to hippo and non-hippo logOdds
pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, ['logOdds_hippo.' registrationName '.nii.gz']);
if ~exist(pathRegisteredLogOdds, 'file') || recompute
    temp_pathLogOdds = fullfile(pathlogOddsSubfolder, 'logOdds_hippo.nii.gz');
    cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',temp_pathLogOdds,' -trans ',pathTransformation,' -res ',pathRegisteredLogOdds,' -pad 0 -inter 0 -voff'];
    system(cmd);
end
pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, ['logOdds_non_hippo.' registrationName '.nii.gz']);
if ~exist(pathRegisteredLogOdds, 'file') || recompute
    temp_pathLogOdds = fullfile(pathlogOddsSubfolder, 'logOdds_non_hippo.nii.gz');
    cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',temp_pathLogOdds,' -trans ',pathTransformation,' -res ',pathRegisteredLogOdds,' -pad 0 -inter 0 -voff'];
    system(cmd);
end

end