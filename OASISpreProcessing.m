function MRIlabels = OASISpreProcessing(pathLabels, pathImage, numberOfSmoothing, smoothingName, brainNum)

MRIimage = MRIread(pathImage);
MRIlabels = MRIread(pathLabels);

image = MRIimage.vol;
labels = MRIlabels.vol;

labels(labels>1000 & labels<2000) = 3; % set left cortex to unique label 3
labels(labels > 2000) = 42; % set right cortex to unique label 42

labels(labels==0 & image>0) = 2;

[~,cropping] = cropLabelVol(MRIimage, 4); % find max cropping around image
labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels

for i=1:numberOfSmoothing
    labelsCrop = smoothLabels(labelsCrop); % smooth labels
end

labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelsCrop; % paste smoothed labels back in the image

MRIlabels.vol = labels;

[dir,~,~] = fileparts(pathLabels);
pathLabels = fullfile(dir, [brainNum, '_preprocessed_labels.', smoothingName, 'nii.gz']);
MRIwrite(MRIlabels, pathLabels);

end