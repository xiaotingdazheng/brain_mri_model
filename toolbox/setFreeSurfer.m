function setFreeSurfer(freeSurferHome)

setenv('FREESURFER_HOME',fullfile(freeSurferHome,'')); %setup of freesurfer environment
PATH = getenv('PATH');
if ~contains(PATH,fullfile(freeSurferHome,'bin/'))
    setenv('PATH',[PATH ':' fullfile(freeSurferHome,'bin')]);
end

end