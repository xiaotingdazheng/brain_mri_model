function brainNum = findBrainNum(path)

[~,name,~] = fileparts(path);
indicesBrain = regexp(name, 'brain');
indicesStop = regexp(name, '_');

if length(indicesStop) ==1
    indicesStop = regexp(name, '.nii');
    if indicesStop
    else
        indicesStop = length(name)+1;
    end
    idxUnderscore = 1; 
else
    idxUnderscore = 2;
end

try
    brainNum = name(indicesBrain(end):indicesStop(idxUnderscore)-1);
catch
    warning('No clear brain num could be identified from ref image name, brainN will be used by default.');
    brainNum = 'brainN';
end

end