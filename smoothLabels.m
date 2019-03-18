function newLabelsMap = smoothLabels(LabelsMap, voff)

labelsList = unique(LabelsMap); % find all present labels
labelsNum = length(labelsList); % number of present labels

newLabelsMap = zeros(size(LabelsMap),'single');
labelsCount = zeros(size(LabelsMap),'single');

convMask = zeros(3,3,3); % convolution neighbour counting mask
convMask(2,2,:) = ones(1,1,3); convMask(:,2,2) = ones(3,1,1); convMask(2,:,2) = ones(1,3,1);
 
for i=1:labelsNum
    
    if nargin == 1 || (nargin == 2 && ~voff)
        disp(['processing label ' num2str(i) '/' num2str(labelsNum)]);
    end
    
    temp_labelsMasks = LabelsMap==labelsList(i); % mask
    temp_labelsCount = convn(temp_labelsMasks, convMask, 'same'); % count
    
    % updates labels and counts
    idx = find(temp_labelsCount>labelsCount);
    newLabelsMap(idx) = labelsList(i);
    labelsCount(idx) = temp_labelsCount(idx);
end

end