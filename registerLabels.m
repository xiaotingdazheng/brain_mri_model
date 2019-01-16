function [registeredLogOddsSubFolder, pathRegisteredFloatingLabels, pathRegisteredFloatingHippoLabels] = registerLabels(pathFloatingLabels, pathFloatingHippoLabels,...
    pathRefMaskedImage, labelsList, pathlogOddsSubfolder, registrationSubfolder, recompute, refBrainNum, floBrainNum)

% This function is called only if labelPriorType was set to 'logOdds'. It
% applies to the logOdds files the warping computed during the registration
% of the floating image to the reference one. The registered logOdds are
% saved in the result folder (no output).

pathTransformation = fullfile(registrationSubfolder, [floBrainNum '_to_' refBrainNum '.cpp.nii.gz']);

switch labelPriorType
    
    case 'delta function'
        
        % define pathnames of used/saved files for label registration
        filename = [floBrainNum '_to_' refBrainNum];
        pathRegisteredFloatingLabels = fullfile(registrationSubfolder, [filename '.labels.nii.gz']); % path of registered segmentation map
        % apply registration to segmentation map
        if ~exist(pathRegisteredFloatingLabels, 'file') || recompute
            disp(['applying ',pathTransformation,' to ',pathFloatingLabels]);
            cmd = ['reg_resample -ref ' pathRefMaskedImage ' -flo ' pathFloatingLabels ' -trans ' pathTransformation ' -res ' pathRegisteredFloatingLabels ' -pad 0 -inter 0 -voff'];
            [~,~] = system(cmd);
        end
        
        % same mechanism for hippocampus segmentation map
        pathRegisteredFloatingHippoLabels = fullfile(registrationSubfolder, [filename '.hippo_labels.nii.gz']); % path of registered segmentation map
        % apply registration to segmentation map
        if ~exist(pathRegisteredFloatingHippoLabels, 'file') || recompute
            disp(['applying ' pathTransformation ' to ' pathFloatingHippoLabels]);
            cmd = ['reg_resample -ref ' pathRefMaskedImage ' -flo ' pathFloatingHippoLabels ' -trans ' pathTransformation ' -res ' pathRegisteredFloatingHippoLabels ' -pad 0 -inter 0 -voff'];
            [~,~] = system(cmd);
        end
        
        registeredLogOddsSubFolder = '';
        
    case 'logOdds'
        
        % define registered logOdds Subfolder
        registeredLogOddsSubFolder = fullfile(registrationSubfolder,'registered_logOdds');
        if ~exist(registeredLogOddsSubFolder, 'dir'), mkdir(registeredLogOddsSubFolder), end
        
        % apply transformation to all logOdds
        for k=1:length(labelsList)
            pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
            if ~exist(pathRegisteredLogOdds, 'file') || recompute
                temp_pathLogOdds = fullfile(pathlogOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']); % path of file to register
                cmd = ['reg_resample -ref ' pathRefMaskedImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
                [~,~] = system(cmd);
            end
        end
        
        % apply same mechanism to hippo and non-hippo logOdds
        pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, 'logOdds_hippo.nii.gz');
        if ~exist(pathRegisteredLogOdds, 'file') || recompute
            temp_pathLogOdds = fullfile(pathlogOddsSubfolder, 'logOdds_hippo.nii.gz');
            cmd = ['reg_resample -ref ' pathRefMaskedImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
            [~,~] = system(cmd);
        end
        pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, 'logOdds_non_hippo.nii.gz');
        if ~exist(pathRegisteredLogOdds, 'file') || recompute
            temp_pathLogOdds = fullfile(pathlogOddsSubfolder, 'logOdds_non_hippo.nii.gz');
            cmd = ['reg_resample -ref ',pathRefMaskedImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
            [~,~] = system(cmd);
        end
        
        pathRegisteredFloatingLabels = '';
        pathRegisteredFloatingHippoLabels = '';
        
end

end