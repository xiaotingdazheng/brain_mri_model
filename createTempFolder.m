function [refBrainNum, pathTempImFolder, pathResultsPrefix] = createTempFolder(prefix)

% build the name of current test brain, and create 2 folders: results and
% temp directories.

% build refBrainNum
[~,refBrainNum,~] = fileparts(prefix);

% define temp directories
pathTempImFolder = [prefix '_temp'];
pathResultsFolder = [prefix '_results'];

aux=getenv('USE_SCRATCH');
if ~isempty(aux) && str2double(aux)>0 && exist('/scratch/','dir')>0
    pathTempImFolder(pathTempImFolder=='/')='_';
    pathTempImFolder(pathTempImFolder==' ')='_';
    pathTempImFolder(pathTempImFolder=='.')='_';
    pathTempImFolder=['/scratch/' pathTempImFolder];
    pathResultsFolder(pathResultsFolder=='/')='_';
    pathResultsFolder(pathResultsFolder==' ')='_';
    pathResultsFolder(pathResultsFolder=='.')='_';
    pathResultsFolder=['/scratch/' pathResultsFolder];
end

% define result prefix
pathResultsPrefix = fullfile(pathResultsFolder, refBrainNum);

% create temp dir
if exist(pathTempImFolder,'dir'), warning([pathTempImFolder ' already exists']);
else, mkdir(pathTempImFolder); end

% create result dir
if exist(pathResultsFolder,'dir'), warning([pathResultsFolder ' already exists']);
else, mkdir(pathResultsFolder); end

end