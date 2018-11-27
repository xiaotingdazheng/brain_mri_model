function [pathRegisteredSyntheticImage, pathRegisteredSyntheticLabels] = register(pathRealRefMaskedImage, pathSyntheticImage, pathSyntheticLabels, resultsFolder, refIndex, recompute)

% names of files that will be used/saved during registration
temp_pathSyntheticImage = strrep(pathSyntheticImage,'.nii.gz','.mgz');
[~,filename,~] = fileparts(temp_pathSyntheticImage);
pathRegisteredSyntheticImage = fullfile(resultsFolder,[filename '.registered_to_image_' num2str(refIndex) '.nii.gz']); %path of registered real image
aff = fullfile(resultsFolder, [filename,'.aff']); %deformation of first registration
pathAffineTransformation = fullfile(resultsFolder, [filename '.registered_to_image_' num2str(refIndex) '.affine.nii.gz']); %path of registered real image
pathTransformation = fullfile(resultsFolder, [filename '.registered_to_image_' num2str(refIndex) '.cpp.nii.gz']); %modify name of the saved aff file

% compute first rigid registration
if ~exist(aff, 'file') || recompute == 1
    disp(['registering with reg_aladin ',pathSyntheticImage,' to ',pathRealRefMaskedImage]);
    cmd = ['reg_aladin -ref ' pathRealRefMaskedImage ' -flo ' pathSyntheticImage ' -aff ' aff ' -res ' pathAffineTransformation ' -pad 0 -voff'];
    system(cmd);
end
% compute registration synthetic image to real image
if ~exist(pathRegisteredSyntheticImage, 'file') || recompute == 1
    disp(['registering with reg_f3d ',pathSyntheticImage,' to ',pathRealRefMaskedImage]);
    cmd = ['reg_f3d -ref ' pathRealRefMaskedImage ' -flo ' pathSyntheticImage ' -res ' pathRegisteredSyntheticImage ' -aff ' aff ' -cpp ' pathTransformation ' -pad 0 -ln 4 -lp 3 -sx 2.5 --lncc 5.0 -be 0.0005 -le 0.005 -vel -voff'];
    system(cmd);    
end

% define pathnames of used/saved files for label registration
temp_floSegm = strrep(pathSyntheticLabels,'.nii.gz','.mgz');
[resultsFolder,filename,~] = fileparts(temp_floSegm);
pathRegisteredSyntheticLabels = fullfile(resultsFolder, [filename,'.registered_to_image_',num2str(refIndex),'.nii.gz']); % path of registered segmentation map
% apply registration to segmentation map
if ~exist(pathRegisteredSyntheticLabels, 'file') || recompute == 1
    disp(['applying ',pathTransformation,' to ',pathSyntheticLabels]);
    cmd = ['reg_resample -ref ',pathRealRefMaskedImage,' -flo ',pathSyntheticLabels,' -trans ',pathTransformation,' -res ',pathRegisteredSyntheticLabels,' -pad 0 -inter 0 -voff'];
    system(cmd);
end

end