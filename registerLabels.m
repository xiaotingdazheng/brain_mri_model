function regPriorSubfolder = registerLabels(pathFloLabels, priorSubfolder, pathRefImage, registrationSubfolder, labelPriorType, labelsList,...
    niftyRegHome, recompute, debug)

% It applies to the logOdds files the warping computed during the registration
% of the floating image to the reference one. The registered logOdds are
% saved in the result folder (no output).

% naming variables
floBrainNum = findBrainNum(pathFloLabels);
refBrainNum = findBrainNum(pathRefImage);
pathTransformation = fullfile(registrationSubfolder, [floBrainNum '_to_' refBrainNum '.cpp.nii.gz']);
pathRegResample = fullfile(niftyRegHome, 'reg_resample');

switch labelPriorType
    
    case 'delta function'
        
        % define registered logOdds Subfolder
        regPriorSubfolder = fullfile(registrationSubfolder,'registered_labels');
        if ~exist(regPriorSubfolder, 'dir'), mkdir(regPriorSubfolder); end
        pathRegFloLabels = fullfile(regPriorSubfolder, 'labels.nii.gz');
                pathFloHippoLabels = fullfile(priorSubfolder, 'hippo_labels.nii.gz');
        pathRegFloHippoLabels = fullfile(regPriorSubfolder, 'hippo_labels.nii.gz');
        
        % apply registration to segmentation map
        if ~exist(pathRegFloLabels, 'file') || recompute
            disp(['applying ' floBrainNum ' to ' refBrainNum ' registration to labels']);
            cmd = [pathRegResample ' -ref ' pathRefImage ' -flo ' pathFloLabels ' -trans ' pathTransformation ' -res ' pathRegFloLabels ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        
        % apply registration to segmentation hippo map
        if ~exist(pathRegFloHippoLabels, 'file') || recompute
            cmd = [pathRegResample ' -ref ' pathRefImage ' -flo ' pathFloHippoLabels ' -trans ' pathTransformation ' -res ' pathRegFloHippoLabels ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        
    case 'logOdds'
        
        % define registered logOdds Subfolder
        regPriorSubfolder = fullfile(registrationSubfolder,'registered_logOdds');
        if ~exist(regPriorSubfolder, 'dir')
            mkdir(regPriorSubfolder);
            disp(['applying ' floBrainNum ' to ' refBrainNum ' registration to logOdds']);
        end
        
        % apply transformation to all logOdds
        for k=1:length(labelsList)
            pathRegisteredLogOdds = fullfile(regPriorSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
            if ~exist(pathRegisteredLogOdds, 'file') || recompute
                temp_pathLogOdds = fullfile(priorSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']); % path of file to register
                cmd = [pathRegResample ' -ref ' pathRefImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
                if debug, system(cmd); else, [~,~] = system(cmd); end
            end
        end
        
        % apply same mechanism to hippo and non-hippo logOdds
        pathRegisteredLogOdds = fullfile(regPriorSubfolder, 'logOdds_hippo.nii.gz');
        if ~exist(pathRegisteredLogOdds, 'file') || recompute
            temp_pathLogOdds = fullfile(priorSubfolder, 'logOdds_hippo.nii.gz');
            cmd = [pathRegResample ' -ref ' pathRefImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        pathRegisteredLogOdds = fullfile(regPriorSubfolder, 'logOdds_non_hippo.nii.gz');
        if ~exist(pathRegisteredLogOdds, 'file') || recompute
            temp_pathLogOdds = fullfile(priorSubfolder, 'logOdds_non_hippo.nii.gz');
            cmd = [pathRegResample ' -ref ',pathRefImage ' -flo ' temp_pathLogOdds ' -trans ' pathTransformation ' -res ' pathRegisteredLogOdds ' -pad 0 -inter 0 -voff'];
            if debug, system(cmd); else, [~,~] = system(cmd); end
        end
        
end

end