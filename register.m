function [pathRegisteredFloatingImage, pathRegisteredFloatingLabels, pathRegisteredFloatingHippoLabels, pathTransformation] = register(pathRefMaskedImage, ...
    pathFloatingImage, pathFloatingLabels, pathFloatingHippoLabels, labelPriorType, registrationSubFolder, recompute, refBrainNum, floBrainNum)

% names of files that will be used/saved during registration
if ~exist(registrationSubFolder, 'dir'), mkdir(registrationSubFolder), end % logOdds folder
temp_pathSyntheticImage = strrep(pathFloatingImage,'.nii.gz','.mgz');
[~,filename,~] = fileparts(temp_pathSyntheticImage);
pathRegisteredFloatingImage = fullfile(registrationSubFolder,[filename '.registered_to_' refBrainNum '.nii.gz']); %path of registered floating image
aff = fullfile(registrationSubFolder, [filename,'.aff']); %deformation of first registration
pathTransformation = fullfile(registrationSubFolder, [filename '.registered_to_' refBrainNum '.cpp.nii.gz']); %modify name of the saved aff file

% compute first rigid registration
if ~exist(aff, 'file') || recompute
    disp(['registering with reg_aladin ',floBrainNum,' to ',refBrainNum]);
    cmd = ['reg_aladin -ref ' pathRefMaskedImage ' -flo ' pathFloatingImage ' -aff ' aff ' -pad 0 -voff'];
    system(cmd);
end
% compute registration synthetic image to real images
if ~exist(pathRegisteredFloatingImage, 'file') || recompute
    disp(['registering with reg_f3d ',floBrainNum,' to ',refBrainNum]);
    cmd = ['reg_f3d -ref ' pathRefMaskedImage ' -flo ' pathFloatingImage ' -res ' pathRegisteredFloatingImage ' -aff ' aff ' -cpp ' pathTransformation ' -pad 0 -ln 4 -lp 3 -sx 2.5 --lncc 5.0 -be 0.0005 -le 0.005 -vel -voff'];
    system(cmd);    
end

if isequal(labelPriorType, 'delta function')
    
    % define pathnames of used/saved files for label registration
    temp_floSegm = strrep(pathFloatingLabels,'.nii.gz','.mgz');
    [~,filename,~] = fileparts(temp_floSegm);
    pathRegisteredFloatingLabels = fullfile(registrationSubFolder, [filename,'.registered_to_',refBrainNum,'.nii.gz']); % path of registered segmentation map
    % apply registration to segmentation map
    if ~exist(pathRegisteredFloatingLabels, 'file') || recompute
        disp(['applying ',pathTransformation,' to ',pathFloatingLabels]);
        cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',pathFloatingLabels,' -trans ',pathTransformation,' -res ',pathRegisteredFloatingLabels,' -pad 0 -inter 0 -voff'];
        system(cmd);
    end
    
    % same mechanism for hippocampus segmentation map
    temp_floSegm = strrep(pathFloatingHippoLabels,'.nii.gz','.mgz');
    [~,filename,~] = fileparts(temp_floSegm);
    pathRegisteredFloatingHippoLabels = fullfile(registrationSubFolder, [filename,'.registered_to_',refBrainNum,'.nii.gz']); % path of registered segmentation map
    % apply registration to segmentation map
    if ~exist(pathRegisteredFloatingHippoLabels, 'file') || recompute
        disp(['applying ',pathTransformation,' to ',pathFloatingHippoLabels]);
        cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',pathFloatingHippoLabels,' -trans ',pathTransformation,' -res ',pathRegisteredFloatingHippoLabels,' -pad 0 -inter 0 -voff'];
        system(cmd);
    end
    
else
    pathRegisteredFloatingLabels = '';
    pathRegisteredFloatingHippoLabels = '';
end

end