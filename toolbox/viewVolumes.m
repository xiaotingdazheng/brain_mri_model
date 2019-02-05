function viewVolumes(varargin)

if nargin<2
    error('not enough arguments')
end

downsample=varargin{1};
cmd='/usr/local/freesurfer/bin/freeview';
setenv('FREESURFER_HOME','/usr/local/freesurfer/');
PATH=getenv('PATH');
if isempty(strfind(PATH,'/usr/local/freesurfer/bin'))
    setenv('PATH',[PATH ':/usr/local/freesurfer/bin']);
end
for n=2:nargin
    V=varargin{n}(1:downsample:end,1:downsample:end,1:downsample:end,:);
    mri=[];
    mri.vol=V;
    mri.vox2ras0=eye(4);
    fname=['/tmp/' inputname(n) '.nii.gz'];
    MRIwrite(mri,fname);
    cmd=[cmd ' ' fname];
end
system([cmd ' &']);
% system(cmd);


