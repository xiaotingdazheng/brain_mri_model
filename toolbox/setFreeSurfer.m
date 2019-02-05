function setFreeSurfer

setenv('FREESURFER_HOME','/usr/local/freesurfer/'); %setup of freesurfer environment
PATH = getenv('PATH');
if ~contains(PATH,'/usr/local/freesurfer/bin')
    setenv('PATH',[PATH ':/usr/local/freesurfer/bin']);
end

end