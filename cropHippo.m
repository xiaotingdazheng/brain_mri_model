function [pathCroppedFloImage, pathCroppedRefImage, pathCroppedLodOddsFolder, brainVoxels] = ...
    cropHippo(cropping, aff, pathRigidRegFloImage, pathRefImage, filename, refBrainNum, registrationSubFolder, priorSubfolder, niftyRegHome, recompute)

% paths
pathRegResample = fullfile(niftyRegHome, 'reg_resample');
pathTempImFolder = fileparts(fileparts(registrationSubFolder));
pathCroppedFloImage = fullfile(registrationSubFolder, [filename '.rigid.cropped.nii.gz']);
pathCroppedRefImage = fullfile(registrationSubFolder, [refBrainNum '.cropped.nii.gz']);
pathCroppedLodOddsFolder = fullfile(registrationSubFolder, 'loggOdds_cropped');
if ~exist(pathCroppedLodOddsFolder, 'dir'), mkdir(pathCroppedLodOddsFolder); end

% apply cropping to ref image
if ~exist(pathCroppedRefImage, 'file') || recompute
    mri = myMRIread(pathRefImage);
    mri = applyCropping(mri,cropping);
    myMRIwrite(mri, pathCroppedRefImage);
end
brainVoxels = selectBrainVoxels(pathCroppedRefImage, 5, pathTempImFolder);

% apply cropping to flo image
if ~exist(pathCroppedFloImage, 'file') || recompute
    mri = myMRIread(pathRigidRegFloImage);
    mri = applyCropping(mri,cropping);
    myMRIwrite(mri, pathCroppedFloImage);
end

% apply cropping to logOdds
struct = dir(fullfile(priorSubfolder,'*nii.gz'));
for i=1:length(struct)
    temp_pathLogOdds = fullfile(struct(i).folder, struct(i).name);
    temp_pathLogOddsCropped = fullfile(pathCroppedLodOddsFolder, struct(i).name);
    if ~exist(temp_pathLogOddsCropped, 'file') || recompute
        cmd = [pathRegResample ' -ref ' pathRigidRegFloImage ' -flo ' temp_pathLogOdds ' -trans ' aff ' -res ' temp_pathLogOddsCropped ' -pad 0 -inter 0'];
        [~,~] = system(cmd);
        mri = myMRIread(temp_pathLogOddsCropped);
        mri = applyCropping(mri,cropping);
        myMRIwrite(mri, temp_pathLogOddsCropped);
    end
end

end