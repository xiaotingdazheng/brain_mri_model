function mriLabels = mergeSubfieldLabels(pathLabels, pathHippoLabels, subfieldsSmoothing)

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

%%%%%%%%%%%%%%%%%%% read labelled image and GT labels %%%%%%%%%%%%%%%%%%%%
disp('loading data');

mriLabels = MRIread(pathLabels);
labels = mriLabels.vol;

mriHippoLabels = MRIread(pathHippoLabels);
HippoLabels = mriHippoLabels.vol;

hippoLabels = [17, 53]; %hippocampal labels
CSFlabel = 24;

%%%%%%%%%%%%%%%%%%%%%%%% smooth subfields labels %%%%%%%%%%%%%%%%%%%%%%%%%%

if subfieldsSmoothing
    mriHippoLabels = smoothSubfieldSegmentation(mriHippoLabels, pathHippoLabels);
    HippoLabels = mriHippoLabels.vol;
end

%%%%%%%%%%%%%%%%%%%%%%% find ROI and crop the image %%%%%%%%%%%%%%%%%%%%%%%
disp('locating hippocampus')

maskmri = mriLabels; %copies mri
maskmri.vol(:) = 0; %sets image to zeros
for h=1:length(hippoLabels)
    maskmri.vol = maskmri.vol | labels==hippoLabels(h); %logical mask of hippocampus by performing or operation
end

[~,cropping] = cropLabelVol(maskmri,20); %maximal cropping around ROI and padds, give back where to crop (don't care about cropped mask)

labelsCrop = labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); %crop the labelled image


%%%%%%%%%%% build distance maps for all non hippocampal labels %%%%%%%%%%%%
disp('building distance maps for all the other labels')

labelList = unique(labelsCrop); %gives all values contained in cropped labelled images ie gives all present labels
for h=1:length(hippoLabels)
    labelList = labelList(labelList~=hippoLabels(h)); %remove hippocampus labels from the list
end
DIST = zeros([size(labelsCrop) length(labelList)]); %build a 4d matrix that will contain the distance transform for every labels
for l=1:length(labelList)
    DIST(:,:,:,l) = bwdist(labelsCrop==labelList(l)); %compute distance transform for given label
end

%%%%%%%%%%%% find closest non hippocampal label for all voxel %%%%%%%%%%%%%

[~,idx] = min(DIST,[],4); %get the index of the closest label for each voxel
INPAINT = labelList(idx); %build the new labelled matrix without hippocampus

%%%%%%%%%%%%%%%%%%%% write modified image in a new file %%%%%%%%%%%%%%%%%%%
disp('building hippocampus-less temporary image')

labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)) = INPAINT; %puts back the modified part
mriLabels.vol = labels; %write it in the header of mgz file

path_temp_file = '/tmp/.nii.gz'; %path of temp hippocampus-less segmemtation
path_new_temp_file = '/tmp/test.0.3.nii.gz'; %path of upsampled file to be produced

MRIwrite(mriLabels, path_temp_file); %write a new mgz file.

%%%%%%%%%%%%%%%%%% convert image into hippo labels format  %%%%%%%%%%%%%%%%

setFreeSurfer();
cmd = ['mri_convert ' path_temp_file ' ' path_new_temp_file ' -rl ' pathHippoLabels ' -rt nearest'];
[~,~] = system(cmd); %execute command

mriLabels = MRIread(path_new_temp_file); %read file converted to the GT file format
labels = mriLabels.vol;

%%%%%%%%%%%%%%%%% shrink molecular layer in hippocampus %%%%%%%%%%%%%%%%%%
disp('shrinking molecular layer');

[GTcropMRI,GTcropping] = cropLabelVol(mriHippoLabels,1); %define ROI
GTcrop = GTcropMRI.vol; %extract image

listLabelsToExpend = [2,4,5]; %labels of regions to expend
labelMolecularLayer = 6;

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
GTcrop(idxreplace) = idxmin(idxreplace); %repplace values

%%%%%%%%%%%%%%%%%%%%% find CSF holes in GT labels %%%%%%%%%%%%%%%%%%%%%%%%
disp('filling hippocampal holes with CSF')

temp_GTcrop = GTcrop;
GTcrop = zeros(size(GTcrop));
maskGTcrop = temp_GTcrop>0;
GTHoles = imfill(maskGTcrop,'holes')  & ~maskGTcrop; %find holes(=1)
dilated = imdilate(maskGTcrop, ones(3)); %dilate hippocampus
dilatedHoles = imfill(dilated,'holes') & ~dilated; %find holes in dilated hippocampus
dilatedHoles = imdilate(dilatedHoles, ones(7)); %dilate these holes
GTHoles = GTHoles | dilatedHoles; %keep only hole voxels corresponding to original holes
GTcrop(GTHoles) = CSFlabel;
previous_nonzero_labels = find(temp_GTcrop>0);
GTcrop(previous_nonzero_labels) = temp_GTcrop(previous_nonzero_labels);
HippoLabels(GTcropping(1):GTcropping(2),GTcropping(3):GTcropping(4),GTcropping(5):GTcropping(6)) = GTcrop; %puts back the modified hippocampus

%%%%%%%%%%%%%%%%%%%%%%%% paste gt labels on top  %%%%%%%%%%%%%%%%%%%%%%%%%
disp('merging hippocampal subfields and segmentation')

realHippoIndices = find(HippoLabels > 0); %find real hippocampal voxels
labels(realHippoIndices) = HippoLabels(realHippoIndices) + 20000; %paste subfield labels in result image, add 20k to differentiate them from existing labels
labels(labels==20024) = 24; %puts back CSH in hippocampus to 24

[pathFusedLabels,~,~] = fileparts(pathLabels);
if subfieldsSmoothing
    pathFusedLabels = fullfile(pathFusedLabels,'aseg+corrected_subfields.nii.gz');
else
    pathFusedLabels = fullfile(pathFusedLabels,'aseg+subfields.nii.gz');
end

mriLabels.vol = labels; %write new matrix in header
mriLabels.fspec = pathFusedLabels;
MRIwrite(mriLabels, pathFusedLabels); %write a new nii.gz file.

end