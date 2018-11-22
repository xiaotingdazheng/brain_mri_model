function [pathResultSynthetic, pathResultLabels] = register(pathRealRefImage, fmask, pathSyntheticImage, pathLabels, refIndex)

% names of files that will be used/saved during registration
temp_pathSyntheticImage = strrep(pathSyntheticImage,'.nii.gz','.mgz');
[dir,filename,~] = fileparts(temp_pathSyntheticImage);
pathResultSynthetic = fullfile(dir,[filename,'.registered_to_image_',num2str(refIndex),'.nii.gz']); %path of registered real image
pathTransformation = fullfile(dir,[filename,'.registered_to_image_',num2str(refIndex),'.cpp.nii.gz']); %modify name of the saved aff file
aff = fullfile(dir,[filename,'.aff']); %result of first registration
% compute binary mask of ROI synthetic image
stripped = fullfile(dir,[filename,'.stripped','.nii.gz']); %path of stripped synthetic image
rmask = fullfile(dir,[filename,'.mask','.nii.gz']); %path of binary mask
cmd = ['~/Software/ROBEX/runROBEX.sh ' pathSyntheticImage ' ' stripped ' ' rmask];
system(cmd);
% compute first rigid registration           
cmd = ['reg_aladin -ref ',pathRealRefImage,' -flo ',pathSyntheticImage,' -fmask ',fmask,' -rmask ',rmask,' -aff ',aff,' -pad 0 -voff'];
system(cmd);
% compute registration synthetic image to real image
cmd = ['reg_f3d -ref ',pathRealRefImage,' -flo ',pathSyntheticImage,' -fmask ',fmask,' -rmask ',rmask,' -res ',pathResultSynthetic,' -aff ',aff,' -cpp ',pathTransformation,' -pad 0 -voff'];
system(cmd);            


% define pathnames of used/saved files for label registration
temp_floSegm = strrep(pathLabels,'.nii.gz','.mgz');
[dir,filename,~] = fileparts(temp_floSegm);
pathResultLabels = fullfile(dir, [filename,'.registered_to_image_',num2str(refIndex),'.nii.gz']); % path of registered segmentation map
% apply registration to segmentation map
cmd = ['reg_resample -ref ',pathRealRefImage,' -flo ',pathLabels,' -trans ',pathTransformation,' -res ',pathResultLabels,' -pad 0 -inter 0'];
system(cmd);

end