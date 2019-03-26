function [refBrainNum, pathTempImFolder] = createTempFolder(prefix)

% build refBrainNum
[~,refBrainNum,~] = fileparts(prefix);

% define temp dir
pathTempImFolder = [prefix '_temp'];

aux=getenv('USE_SCRATCH');
if ~isempty(aux) && str2double(aux)>0 && exist('/scratch/','dir')>0
    pathTempImFolder(pathTempImFolder=='/')='_';
    pathTempImFolder(pathTempImFolder==' ')='_';
    pathTempImFolder(pathTempImFolder=='.')='_';
    pathTempImFolder=['/scratch/' pathTempImFolder];
end

% create temp dir
if exist(pathTempImFolder,'dir')
    warning([pathTempImFolder ' already exists']);
else
    mkdir(pathTempImFolder);
end

end