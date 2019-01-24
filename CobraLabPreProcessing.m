function mriLabels = CobraLabPreProcessing(pathLabels, pathHippoLabels, numberOfSmoothing, pathPreprocessedLabelsFolder, targetResolution)

% This function combines the labels from general image and more precise
% hippocampal segmentations.
% The difference between the two segm maps being located at around the
% hippocampus, we first crop the image. We then replace the hippocampus
% label in the general segmentation by the nearest labels. This results in
% a "hippocampus-less" image that is saved in order to resample it like the
% hippocampus segm map. When the two images are aligned we can then paste
% the labels of hippocampus subregions.
% For the last step we might need to perform several operations to obtain
% more realistic segmentations. First we observe that the molecular layer
% is a bit too thick, so we need to shrink it. An then we need to fill the
% cyst with CSF instead of white matter.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% initialisation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hippoLabels = [17, 53]; %hippocampal labels
listHippoSubfieldsLabelsToExpend = [2,4,5]; %labels of regions to expend
labelMolecularLayer = 6;
CSFlabel = 24;


%%%%%%%%%%%%%%%%%%%%%%%% preprocessing hippocampus %%%%%%%%%%%%%%%%%%%%%%%%

mriHippoLabels = MRIread(pathHippoLabels);
brainNum = pathHippoLabels(regexp(pathHippoLabels,'brain'):regexp(pathHippoLabels,'_hippo_labels.nii.gz')-1);

% smooth subfields labels
disp('smoothing hippocampus subfields')
if numberOfSmoothing
    mriHippoLabels = smoothHippoSubfields(mriHippoLabels, pathHippoLabels, numberOfSmoothing, brainNum);
end
HippoLabels = mriHippoLabels.vol;

%cropping hippocampus
[GTcropMRI,GTcropping] = cropLabelVol(mriHippoLabels,1); %define ROI
GTcrop = GTcropMRI.vol; %extract image

% shrink molecular layer in hippocampus
disp('shrinking molecular layer');
GTcrop = shrinkMolecularLayer(GTcrop, listHippoSubfieldsLabelsToExpend, labelMolecularLayer);

% find CSF holes in GT labels
disp('filling CSF Holes')
GTcrop = fillCsfHoles(GTcrop, CSFlabel);

% paste modified Hippocampus back onto its image
HippoLabels(GTcropping(1):GTcropping(2),GTcropping(3):GTcropping(4),GTcropping(5):GTcropping(6)) = GTcrop;


%%%%%%%%%%%%%%%%%%%%%%%%% preprocess labels image %%%%%%%%%%%%%%%%%%%%%%%%%

mriLabels = MRIread(pathLabels);
firstLabelsResolution = [mriLabels.xsize mriLabels.ysize mriLabels.zsize];

% set WM hypointensities to WM
mriLabels = correctWMHypointensities(mriLabels);

% build hippocampus-less image
disp('building hippocampus-less temporary image')
mriLabels = buildHippocampusLessImage(mriLabels, hippoLabels);

% convert image into hippo labels format
disp('upsampling hippocampus-less image to hippocampus subfields resolution')
setFreeSurfer();
path_temp_file = '/tmp/test.nii.gz'; %path of temp hippocampus-less segmemtation
MRIwrite(mriLabels, path_temp_file); %write a new mgz file.
path_new_temp_file = '/tmp/test.0.3.nii.gz'; %path of upsampled file to be produced
cmd = ['mri_convert ' path_temp_file ' ' path_new_temp_file ' -rl ' pathHippoLabels ' -rt nearest'];
[~,~] = system(cmd); %execute command

% read upsampled file
mriLabels = MRIread(path_new_temp_file);

% paste gt labels on top
disp('merging hippocampal subfields and segmentation')
mriLabels = pasteHippoLabels(mriLabels, HippoLabels, CSFlabel);


%%%%%%%%%%%%%%%%%%%%%%%% writting preprocessed file %%%%%%%%%%%%%%%%%%%%%%%

if ~exist(pathPreprocessedLabelsFolder, 'dir'), mkdir(pathPreprocessedLabelsFolder); end
pathPreprocessedLabels = fullfile(pathPreprocessedLabelsFolder, ['training_' brainNum '_labels.nii.gz']);
mriLabels.fspec = pathPreprocessedLabelsFolder;

disp(['writing merged labels in ' pathPreprocessedLabels])
MRIwrite(mriLabels, pathPreprocessedLabels); %write a new nii.gz file.


%%%%%%%%%%%%%%%%%%%%%%%% modifying file resolution %%%%%%%%%%%%%%%%%%%%%%%%

sampleResolution = [mriLabels.xsize mriLabels.ysize mriLabels.zsize];
if nargin == 5
    modifyResolution(sampleResolution, targetResolution, firstLabelsResolution, pathPreprocessedLabels, pathLabels);
end

end

function mriHippoLabels = smoothHippoSubfields(mriHippoLabels, pathHippoLabels, numberOfSmoothing, brainNum)

labels = mriHippoLabels.vol;

%find left hippocampus
maskmri = mriHippoLabels; %copies mri
maskmri.vol(:) = labels>0 & labels<100;
[~,cropping] = cropLabelVol(maskmri, 4); % crop hippocampus
labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels

% smoothing left side
for i=1:numberOfSmoothing
    labelsCrop = smoothLabels(labelsCrop);
end

% paste result back onto the image
labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelsCrop; % paste modified labels on original image

%find right hippocampus
maskmri = mriHippoLabels; %copies mri
maskmri.vol(:) = labels>100;
[~,cropping] = cropLabelVol(maskmri, 4); % crop hippocampus
labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop the labels

% smoothing right side
for i=1:numberOfSmoothing
    labelsCrop = smoothLabels(labelsCrop);
end

labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = labelsCrop; % paste modified labels on original image

%%% save corrected labels
mriHippoLabels.vol = labels;
pathSmoothedLabels = strrep(pathHippoLabels,'nii.gz','mgz');
[dir,~,~] = fileparts(pathSmoothedLabels);

pathSmoothedLabels = fullfile(dir, [brainNum, '_hippo_labels.nii.gz']);

% disp(['writing smoothed subfields ' pathSmoothedLabels]);
% MRIwrite(mriHippoLabels, pathSmoothedLabels); %write a new nii.gz file.

end

function GTcrop = shrinkMolecularLayer(GTcrop, listLabelsToExpend, labelMolecularLayer)

Dist = zeros([size(GTcrop) length(listLabelsToExpend)]); %stack of 3d distance matrices to corresponding labels

for i=1:length(listLabelsToExpend)
    temp_mask = zeros(size(GTcrop));
    temp_mask(GTcrop == mod(listLabelsToExpend(i), 10)) = 1; %mod spots labels in both hemishperes
    Dist(:,:,:,i) = bwdist(temp_mask); %build distance 3D matrix
end

distThreshold = 1.01; %bound replacing area
[minDist, idxmin] = min(Dist,[],4); %find closest label
idxreplace = find(minDist<distThreshold & mod(GTcrop,10) == labelMolecularLayer); %find molecular voxels in define areas
idxmin = arrayfun(@(x) listLabelsToExpend(x), idxmin); %switch index from min to values in listLabelsToExpend
GTcrop(idxreplace) = idxmin(idxreplace); %replace values

end

function GTcrop = fillCsfHoles(GTcrop, CSFlabel)

temp_GTcrop = GTcrop;
GTcrop = zeros(size(GTcrop));

%dilate hippocampus
maskGTcrop = temp_GTcrop>0;
GTHoles = imfill(maskGTcrop,'holes')  & ~maskGTcrop; %find holes(=1)
dilated = imdilate(maskGTcrop, ones(3));

%find holes in dilated hippocampus and dilate them
dilatedHoles = imfill(dilated,'holes') & ~dilated;
dilatedHoles = imdilate(dilatedHoles, ones(7)); %dilate these holes

%keep only hole voxels corresponding to original holes
GTHoles = GTHoles | dilatedHoles;
GTcrop(GTHoles) = CSFlabel;
previous_nonzero_labels = find(temp_GTcrop>0);
GTcrop(previous_nonzero_labels) = temp_GTcrop(previous_nonzero_labels);

end

function mriLabels = correctWMHypointensities(mriLabels)

labels = mriLabels.vol;

% find index of righest voxel of left hemishpere
idx = find(labels == 49);
[~,J,~] = ind2sub(size(labels),idx);
maxLeftIdx = max(J);

%find WM hypointensities
idx = find(labels == 77);
[~,J,~] = ind2sub(size(labels),idx);

% set left WM hypointensities to left WM
idxLeftWM = idx(J>=maxLeftIdx);
labels(idxLeftWM) = 2;
% set right WM hypointensities to right WM
idxRightWM = idx(J<maxLeftIdx);
labels(idxRightWM) = 41;

% write labels back to mriLabels
mriLabels.vol = labels;

end

function mriLabels = buildHippocampusLessImage(mriLabels, hippoLabels)

labels = mriLabels.vol;

% build mask of hippocampus
maskmri = mriLabels; %copies mri
maskmri.vol(:) = 0; %sets image to zeros
for h=1:length(hippoLabels)
    maskmri.vol = maskmri.vol | labels==hippoLabels(h); %logical mask of hippocampus by performing or operation
end

% crop labelled image around hippocampus
[~,cropping] = cropLabelVol(maskmri,20); %maximal cropping around ROI and padds, give back where to crop (don't care about cropped mask)
labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); %crop the labelled image

% remove hippocampus labels from list of labels used to calculate distance maps
labelList = unique(labelsCrop);
for h=1:length(hippoLabels)
    labelList = labelList(labelList~=hippoLabels(h));
end

% build distance maps
DIST = zeros([size(labelsCrop) length(labelList)]); %build a 4d matrix that will contain the distance transform for every labels
for l=1:length(labelList)
    DIST(:,:,:,l) = bwdist(labelsCrop==labelList(l)); %compute distance transform for given label
end

% replaces hippocampus labels by nearest neighbour
[~,idx] = min(DIST,[],4); %get the index of the closest label for each voxel
INPAINT = labelList(idx); %build the new labelled matrix without hippocampus

% put back hippocmapus less image in nifty file
labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = INPAINT; %puts back the modified part
mriLabels.vol = labels; %write it in the header of mgz file

end

function mriLabels = pasteHippoLabels(mriLabels, HippoLabels, CSFlabel)

labels = mriLabels.vol;

realHippoIndices = find(HippoLabels > 0); %find real hippocampal voxels
labels(realHippoIndices) = HippoLabels(realHippoIndices) + 20000; %paste subfield labels in result image, add 20k to differentiate them from existing labels
labels(labels==CSFlabel + 20000) = CSFlabel; %puts back CSF in hippocampus to 24

mriLabels.vol = labels; %write new matrix in header

end

function modifyResolution(sampleResolution, targetResolution, firstLabelsResolution, pathPreprocessedLabels, pathLabels)

% change resolution if sampling and target resolutions are not the same
targetResName = [num2str(targetResolution(1),'%.2f') ' ' num2str(targetResolution(2),'%.2f') ' ' num2str(targetResolution(3),'%.2f')];
sampleResName = [num2str(sampleResolution(1),'%.2f') ' ' num2str(sampleResolution(2),'%.2f') ' ' num2str(sampleResolution(3),'%.2f')];
if ~isequal(sampleResName, targetResName)
    
    % build name of saved downsampled file
    if targetResolution(1) == targetResolution(2) && targetResolution(1) == targetResolution(3)
        resolution = num2str(targetResolution(1),'%.1f');
    else
        resolution = [num2str(targetResolution(1),'%.1f'), 'x',num2str(targetResolution(2),'%.1f'), 'x',num2str(targetResolution(3),'%.1f')];
    end
    voxsize = [num2str(targetResolution(1),'%.1f') ' ' num2str(targetResolution(2),'%.1f') ' ' num2str(targetResolution(3),'%.1f')];
    pathPreprocessedLabelsDownsampled = strrep(pathPreprocessedLabels,'_labels.nii.gz', ['_labels.' resolution '.nii.gz']);
    
    disp(['changing labels resolution to ' voxsize])
    
    % build command to be executed. Reslice like original labels if they have same resolution as target
    firstLabelsResName = [num2str(firstLabelsResolution(1),'%.2f') ' ' num2str(firstLabelsResolution(2),'%.2f') ' ' num2str(firstLabelsResolution(3),'%.2f')];
    if isequal(firstLabelsResName, targetResName)
        cmd = ['mri_convert ' pathPreprocessedLabels ' ' pathPreprocessedLabelsDownsampled ' -rl ' pathLabels ' -rt nearest -odt float'];
    else
        cmd = ['mri_convert ' pathPreprocessedLabels ' ' pathPreprocessedLabelsDownsampled ' -voxsize ' voxsize ' -rt nearest -odt float'];
    end
    [~,~] = system(cmd);
end
    
end