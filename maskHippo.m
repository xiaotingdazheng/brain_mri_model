function pathFloatingHippoLabels = maskHippo(pathFloatingLabels, resultsFolder, floBrainNum, recompute)

% builds name of hippo label file that will be saved
temp_lab = strrep(pathFloatingLabels,'.nii.gz','');
[~,name,~] = fileparts(temp_lab);
if ~contains(name, 'brain')
    brain_num = [floBrainNum '_'];
else
    brain_num = '';
end
pathFloatingHippoLabels = fullfile(resultsFolder, [brain_num name '.hippo_segmentation_map.nii.gz']);

% if file doesn't exist or must be recomputed
if ~exist(pathFloatingHippoLabels, 'file') || recompute
    
    setFreeSurfer();
    
    FloatingLabels = MRIread(pathFloatingLabels); % read labels
    
    hippoMap = FloatingLabels.vol > 20000 | FloatingLabels.vol == 17 | FloatingLabels.vol == 53; % hippo mask
    
    FloatingLabels.vol = hippoMap; 
    
    MRIwrite(FloatingLabels, pathFloatingHippoLabels); % write new file
    
end

end