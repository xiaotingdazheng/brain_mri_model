function [pathRegisteredFloatingImage, pathRegisteredFloatingLabels, pathRegisteredFloatingHippoLabels, pathTransformation] = register(pathRefMaskedImage, ...
    pathFloatingImage, pathFloatingLabels, pathFloatingHippoLabels, labelPriorType, resultsFolder, refIndex, recompute, floBrainNum)

% names of files that will be used/saved during registration
temp_pathSyntheticImage = strrep(pathFloatingImage,'.nii.gz','.mgz');
[~,filename,~] = fileparts(temp_pathSyntheticImage);
if ~contains(filename, 'brain') && contains(pathFloatingImage, 'brain')
    brain_num = floBrainNum;
    filename = [brain_num '_' filename];
end
pathRegisteredFloatingImage = fullfile(resultsFolder,[filename '.registered_to_image_' num2str(refIndex) '.nii.gz']); %path of registered real image
aff = fullfile(resultsFolder, [filename,'.aff']); %deformation of first registration
pathAffineTransformation = fullfile(resultsFolder, [filename '.registered_to_image_' num2str(refIndex) '.affine.nii.gz']); %path of registered real image
pathTransformation = fullfile(resultsFolder, [filename '.registered_to_image_' num2str(refIndex) '.cpp.nii.gz']); %modify name of the saved aff file

% compute first rigid registration
if ~exist(aff, 'file') || recompute
    disp(['registering with reg_aladin ',pathFloatingImage,' to ',pathRefMaskedImage]);
    cmd = ['reg_aladin -ref ' pathRefMaskedImage ' -flo ' pathFloatingImage ' -aff ' aff ' -res ' pathAffineTransformation ' -pad 0 -voff'];
    system(cmd);
end
% compute registration synthetic image to real images
if ~exist(pathRegisteredFloatingImage, 'file') || recompute
    disp(['registering with reg_f3d ',pathFloatingImage,' to ',pathRefMaskedImage]);
    cmd = ['reg_f3d -ref ' pathRefMaskedImage ' -flo ' pathFloatingImage ' -res ' pathRegisteredFloatingImage ' -aff ' aff ' -cpp ' pathTransformation ' -pad 0 -ln 4 -sx 5 --lncc 5.0 -vel -voff'];
    system(cmd);    
end

if isequal(labelPriorType, 'delta function')
    
    % define pathnames of used/saved files for label registration
    temp_floSegm = strrep(pathFloatingLabels,'.nii.gz','.mgz');
    [~,filename,~] = fileparts(temp_floSegm);
    pathRegisteredFloatingLabels = fullfile(resultsFolder, [filename,'.registered_to_image_',num2str(refIndex),'.nii.gz']); % path of registered segmentation map
    % apply registration to segmentation map
    if ~exist(pathRegisteredFloatingLabels, 'file') || recompute
        disp(['applying ',pathTransformation,' to ',pathFloatingLabels]);
        cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',pathFloatingLabels,' -trans ',pathTransformation,' -res ',pathRegisteredFloatingLabels,' -pad 0 -inter 0 -voff'];
        system(cmd);
    end
    
    % same mechanism for hippocampus segmentation map
    temp_floSegm = strrep(pathFloatingHippoLabels,'.nii.gz','.mgz');
    [~,filename,~] = fileparts(temp_floSegm);
    pathRegisteredFloatingHippoLabels = fullfile(resultsFolder, [filename,'.registered_to_image_',num2str(refIndex),'.nii.gz']); % path of registered segmentation map
    % apply registration to segmentation map
    if ~exist(pathRegisteredFloatingHippoLabels, 'file') || recompute
        disp(['applying ',pathTransformation,' to ',pathFloatingLabels]);
        cmd = ['reg_resample -ref ',pathRefMaskedImage,' -flo ',pathFloatingHippoLabels,' -trans ',pathTransformation,' -res ',pathRegisteredFloatingHippoLabels,' -pad 0 -inter 0 -voff'];
        system(cmd);
    end
    
else
    pathRegisteredFloatingLabels = '';
    pathRegisteredFloatingHippoLabels = '';
end

end