function MRIlabels = OASISpreProcessing(pathLabels, pathImage, numberOfSmoothing, pathPreprocessedLabelsFolder)

% reading image and labels
MRIimage = MRIread(pathImage);
MRIlabels = MRIread(pathLabels);
image = MRIimage.vol;
labels = MRIlabels.vol;

% correcting labels mistakes
disp('correcting labels mistakes')
labels(labels>1000 & labels<2000) = 3; % set left cortex to unique label 3
labels(labels > 2000) = 42;
labels(labels==6) = 8; % set left cerebellum cortex to correct label
labels(labels==45) = 47; % set right cerebellum cortex to correct label
idx = find(labels == 49);
[~,~,K] = ind2sub(size(labels),idx);
maxLeftIdx = max(K);
idx = find(labels==0 & image>0);
[~,~,K] = ind2sub(size(labels),idx);
idxLeftWM = idx(K>=maxLeftIdx);
labels(idxLeftWM) = 2; % set left WM to 2
idxRightWM = idx(K<maxLeftIdx);
labels(idxRightWM) = 41; % set left WM to 41

% smooth labels
disp('smoothing labels')
[~,cropping] = cropLabelVol(MRIimage, 4); % find max cropping around image
labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels
for i=1:numberOfSmoothing
    labelsCrop = smoothLabels(labelsCrop); %perform smoothing
end
labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelsCrop; % paste smoothed labels back in the image

% writing preprocessed labels
brainNum = pathImage(regexp(pathImage,'brain'):regexp(pathImage,'.nii.gz')-1);
pathLabels = fullfile(pathPreprocessedLabelsFolder, ['test_' brainNum '_labels.nii.gz']);
if ~exist(pathPreprocessedLabelsFolder, 'dir'), mkdir(pathPreprocessedLabelsFolder); end
disp(['writing preprocessed labels in ',pathLabels])
MRIlabels.vol = labels;
MRIlabels.fspec = pathLabels;
MRIwrite(MRIlabels, pathLabels);

end