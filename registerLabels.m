function [registeredLogOddsSubFolder, pathRegisteredFloatingLabels, pathRegisteredFloatingHippoLabels] = registerLabels(pathFloatingLabels, pathFloatingHippoLabels,...
    pathRefMaskedImage, labelsList, logOddsSubfolder, registrationSubfolder, recompute, refBrainNum, floBrainNum, labelPriorType, niftyRegHome, debug)

% This function is called only if labelPriorType was set to 'logOdds'. It
% applies to the logOdds files the warping computed during the registration
% of the floating image to the reference one. The registered logOdds are
% saved in the result folder (no output).

pathTransformation = fullfile(registrationSubfolder, [floBrainNum '_to_' refBrainNum '.cpp.nii.gz']);
pathRegResample = fullfile(niftyRegHome, 'reg_resample');

switch labelPriorType
    
    case 'delta function'
        
        % define pathnames of used/saved files for label registration
        filename = [floBrainNum '_to_' refBrainNum];
        pathRegisteredFloatingLabels = fullfile(registrationSubfolder, [filename '.labels.nii.gz']); % path of registered segmentation map
        % apply registration to segmentation map
        if ~exist(pathRegisteredFloatingLabels, 'file') || recompute
            disp(['applying ' floBrainNum ' to ' refBrainNum ' registration to labels']);
            cmd = [pathRegResample ' -ref ' pathRefMaskedImage ' -flo ' pathFloatingLabels ' -trans ' pathTransformation ' -res ' pathRegisteredFloatingLabels ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        
        % same mechanism for hippocampus segmentation map
        pathRegisteredFloatingHippoLabels = fullfile(registrationSubfolder, [filename '.hippo_labels.nii.gz']); % path of registered segmentation map
        if ~exist(pathRegisteredFloatingHippoLabels, 'file') || recompute
            cmd = [pathRegResample ' -ref ' pathRefMaskedImage ' -flo ' pathFloatingHippoLabels ' -trans ' pathTransformation ' -res ' pathRegisteredFloatingHippoLabels ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        
        registeredLogOddsSubFolder = '';
        
    case 'logOdds'
        
        % define registered logOdds Subfolder
        registeredLogOddsSubFolder = fullfile(registrationSubfolder,'registered_logOdds');
        if ~exist(registeredLogOddsSubFolder, 'dir')
            mkdir(registeredLogOddsSubFolder);
            disp(['applying ' floBrainNum ' to ' refBrainNum ' registration to logOdds']);
        end
        
        % apply transformation to all logOdds
        for k=1:length(labelsList)
            pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
            if ~exist(pathRegisteredLogOdds, 'file') || recompute
                temp_pathLogOdds = fullfile(logOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']); % path of file to register
                cmd = [pathRegResample ' -ref ' pathRefMaskedImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
                if debug, system(cmd); else, [~,~] = system(cmd); end
            end
        end
        
        % apply same mechanism to hippo and non-hippo logOdds
        pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, 'logOdds_hippo.nii.gz');
        if ~exist(pathRegisteredLogOdds, 'file') || recompute
            temp_pathLogOdds = fullfile(logOddsSubfolder, 'logOdds_hippo.nii.gz');
            cmd = [pathRegResample ' -ref ' pathRefMaskedImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        pathRegisteredLogOdds = fullfile(registeredLogOddsSubFolder, 'logOdds_non_hippo.nii.gz');
        if ~exist(pathRegisteredLogOdds, 'file') || recompute
            temp_pathLogOdds = fullfile(logOddsSubfolder, 'logOdds_non_hippo.nii.gz');
            cmd = [pathRegResample ' -ref ',pathRefMaskedImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        
        pathRegisteredFloatingLabels = '';
        pathRegisteredFloatingHippoLabels = '';
        
end

end