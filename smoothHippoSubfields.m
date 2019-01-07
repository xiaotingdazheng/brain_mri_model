function mriLabels = smoothHippoSubfields(mriLabels, pathLabels, subfieldsSmoothing)

% This function takes as inputs the subfields label map of an hippocampus
% and smooth it. The smoothing is performed by replacing each voxel by its
% most numerous neighours.
% The output is the nifty file containing the smoothed label map. This
% nifty file is also saved separately.

labels = mriLabels.vol;

%%% left hippocampus %%%
disp('smoothing left hippocampus')

%find left hippocampus
maskmri = mriLabels; %copies mri
maskmri.vol(:) = labels>0 & labels<100; 
[~,cropping] = cropLabelVol(maskmri, 4); % crop hippocampus
labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels

for i=1:subfieldsSmoothing
    labelsCrop = smoothLabels(labelsCrop); % smoothing
end

labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelsCrop; % paste modified labels on original image

%%% right hippocampus %%%
disp('smoothing right hippocampus')

%find left hippocampus
maskmri = mriLabels; %copies mri
maskmri.vol(:) = labels>100;
[~,cropping] = cropLabelVol(maskmri, 4); % crop hippocampus
labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels

for i=1:subfieldsSmoothing
    labelsCrop = smoothLabels(labelsCrop); % smoothing
end

labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelsCrop; % paste modified labels on original image

%%% save corrected labels
mriLabels.vol = labels;
pathCorrectedLabels = strrep(pathLabels,'nii.gz','mgz');
[dir,name,~] = fileparts(pathCorrectedLabels);
pathCorrectedLabels = fullfile(dir, [name, '.smoothed.nii.gz']);
disp(['writing smoothed subfields ' pathCorrectedLabels]);
MRIwrite(mriLabels, pathCorrectedLabels); %write a new nii.gz file.

end