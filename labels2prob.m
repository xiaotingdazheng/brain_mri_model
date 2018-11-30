function cellLogOdds = labels2prob(pathLabels, pathCellToLogOdds, rho, threshold, labelsList)

addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

Labels = MRIread(pathLabels);
Labels = Labels.vol;

cellLogOdds = cell(7,length(labelsList)); % initialise result matrix

% loop over all the labels
for l=1:length(labelsList)
    
    mask = (Labels == labelsList(l)); % find mask of current label
    erudedMask = imerode(mask,ones(2,2,2)); % erode mask
    prob = exp(-rho*bwdist(erudedMask)); % calculate prob of voxel belonging to label l
    thresholdMap = prob > threshold; 
    prob = prob.*thresholdMap; % threshold prob map
    
    % crop the prob map
    idx = find(prob>0);
    [I,J,K]=ind2sub(size(prob),idx);
    minI=min(I); maxI=max(I);
    minJ=min(J); maxJ=max(J);
    minK=min(K); maxK=max(K);
    prob = prob(minI:maxI,minJ:maxJ,minK:maxK);
    
    % store cropping indices and cropped label prob
    cellLogOdds(:,l) = {minI,minJ,minK,maxI,maxJ,maxK,prob};
    
end

save(pathCellToLogOdds,'cellLogOdds');

end