function setFreeSurfer(freesurferHome)

setenv('FREESURFER_HOME',fullfile(freesurferHome,'')); %setup of freesurfer environment
PATH = getenv('PATH');
if ~contains(PATH,fullfile(freesurferHome,'bin/'))
    setenv('PATH',[PATH ':' fullfile(freesurferHome,'bin')]);
end

end