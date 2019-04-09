function [pathRegFloImage, pathCroppedLogOddsFolder, pathRefImage, brainVoxels] = registerImage(pathRefImage, pathFloImage, registrationSubFolder, registrationOptions,...
    multiChannel, brainVoxels, recompute, refBrainNum, cropping, priorSubfolder, niftyRegHome, debug)

% naming variables
floBrainNum = findBrainNum(pathFloImage);
filename = [floBrainNum '_to_' refBrainNum];
% names of files that will be used/saved during registration
if cropping, pathRegFloImage = fullfile(registrationSubFolder,[filename '_cropped.nii.gz']); %path of registered floating image
else, pathRegFloImage = fullfile(registrationSubFolder,[filename '.nii.gz']); end
aff = fullfile(registrationSubFolder, [filename '.aff']); %deformation of first registration
pathRigidRegFloImage = fullfile(registrationSubFolder, [filename '.rigid.nii.gz']);
pathTransformation = fullfile(registrationSubFolder, [filename '.cpp.nii.gz']); %modify name of the saved aff file
if ~exist(registrationSubFolder, 'dir'), mkdir(registrationSubFolder), end % logOdds folder

% compute first rigid registration
if ~exist(aff, 'file') || recompute
    disp(['registering ' floBrainNum ' to ' refBrainNum ' with reg_aladin']);
    pathRegAladin = fullfile(niftyRegHome, 'reg_aladin');
    cmd = [pathRegAladin ' -ref ' pathRefImage ' -flo ' pathFloImage ' -aff ' aff ' -res ' pathRigidRegFloImage ' -pad 0'];
    if debug, system(cmd); else, [~,~] = system(cmd); end
end

if cropping
    [pathFloImage, pathRefImage, pathCroppedLogOddsFolder, brainVoxels] = ...
        cropHippo(cropping, aff, pathRigidRegFloImage, pathRefImage, filename, refBrainNum, registrationSubFolder, priorSubfolder, niftyRegHome, recompute);
else
    pathCroppedLogOddsFolder = priorSubfolder;
end

% compute registration synthetic image to real images
if ~exist(pathRegFloImage, 'file') || recompute
    disp(['registering ' floBrainNum ' to ' refBrainNum ' with reg_f3d']);
    pathRegF3d = fullfile(niftyRegHome, 'reg_f3d');
    if cropping
        cmd = [pathRegF3d ' -ref ' pathRefImage ' -flo ' pathFloImage ' -res ' pathRegFloImage ' -cpp ' pathTransformation ' ' registrationOptions];
    else
        cmd = [pathRegF3d ' -ref ' pathRefImage ' -flo ' pathFloImage ' -res ' pathRegFloImage ' -aff ' aff ' -cpp ' pathTransformation ' ' registrationOptions];
    end
    if multiChannel
        weights = zeros(1,length(brainVoxels));
        for i=1:length(brainVoxels), weights(i)=length(brainVoxels{i}); end
        weights = weights/sum(weights);
        for i=1:length(brainVoxels), cmd = [cmd ' -lnccw ' num2str(i-1) ' ' num2str(weights(i))]; end
    end
    if debug, system(cmd); else, [~,~] = system(cmd); end
end

end