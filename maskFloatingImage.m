function pathFloatingImage = maskFloatingImage(pathFloatingImage, pathFloatingLabels, resultsFolder)

temp_flo = strrep(pathFloatingImage,'.nii.gz','.mgz');
[~,name,~] = fileparts(temp_flo);

if contains(pathFloatingImage, 'brain') && ~contains(name, 'brain')
    brain_num = [pathFloatingImage(regexp(pathFloatingImage,'brain'):regexp(pathFloatingImage,'brain')+5) '_'];
else
    brain_num = '';
end

pathMaskedFloatingImage = fullfile(resultsFolder, [brain_num  name '.masked.nii.gz']); %path of mask

if ~exist(pathMaskedFloatingImage, 'file')
    setFreeSurfer();
    disp(['masking real image ' pathFloatingImage])
    cmd = ['mri_mask ' pathFloatingImage ' ' pathFloatingLabels ' ' pathMaskedFloatingImage];
    system(cmd);
end

pathFloatingImage = pathMaskedFloatingImage;

end