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
    name = strrep(name, '.nii', '');
    now = single(clock); now(6) = now(6)*1000; now = uint16(now);
    timeStamp = [num2str(now(3),'%02d') '_' num2str(now(2),'%02d') '_' num2str(now(1),'%04d') '_' ...
        num2str(now(4),'%02d') '_' num2str(now(5),'%02d') '_' num2str(now(6),'%05d')];
    brainNum = [name '_' timeStamp];
end

end