function brainNum = findBrainNum(path)

[~,name,~] = fileparts(path);
indicesBrain = regexp(name, 'brain');
indicesStop = regexp(name, '_');

if length(indicesStop) ==1
    indicesStop = regexp(name, '.nii');
    idxUnderscore = 1; 
else
    idxUnderscore = 2;
end

try
    brainNum = name(indicesBrain(end):indicesStop(idxUnderscore)-1);
catch
    warning('no clear brain num could be identified from ref image name')
    brainNum = 'brainN';
end

end