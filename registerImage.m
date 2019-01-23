function pathRegisteredFloatingImage = registerImage(pathRefMaskedImage, pathFloatingImage, registrationSubFolder, registrationOptions,...
    recompute, refBrainNum, floBrainNum)

% names of files that will be used/saved during registration
if ~exist(registrationSubFolder, 'dir'), mkdir(registrationSubFolder), end % logOdds folder
filename = [floBrainNum '_to_' refBrainNum];
pathRegisteredFloatingImage = fullfile(registrationSubFolder,[filename '.nii.gz']); %path of registered floating image
aff = fullfile(registrationSubFolder, [filename '.aff']); %deformation of first registration
pathTransformation = fullfile(registrationSubFolder, [filename '.cpp.nii.gz']); %modify name of the saved aff file

% compute first rigid registration
if ~exist(aff, 'file') || recompute
    disp(['registering with reg_aladin ',floBrainNum,' to ',refBrainNum]);
    cmd = ['reg_aladin -ref ' pathRefMaskedImage ' -flo ' pathFloatingImage ' -aff ' aff ' -pad 0 -voff'];
    [~,~] = system(cmd);
end
% compute registration synthetic image to real images
if ~exist(pathRegisteredFloatingImage, 'file') || recompute
    disp(['registering with reg_f3d ',floBrainNum,' to ',refBrainNum]);
    cmd = ['reg_f3d -ref ' pathRefMaskedImage ' -flo ' pathFloatingImage ' -res ' pathRegisteredFloatingImage ' -aff ' aff ' -cpp ' pathTransformation ' ' registrationOptions];
    [~,~] = system(cmd);    
end

end