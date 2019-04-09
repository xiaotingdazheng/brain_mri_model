function [evaluate, cropHippo, leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, alignTestImages, margin, rho,...
    threshold, sigma, labelPriorType, regOptions, freeSurferHome, niftyRegHome, labelsList, labelClasses, labelsNames] = readParams(params, nChannel, singleBrain)

%read params
evaluate = params{1};
cropHippo = params{2};
leaveOneOut = params{3};
useSynthethicImages = params{4};
recompute = params{5};
debug = params{6};
deleteSubfolder = params{7};
targetResolution = params{8};
rescale = params{9};
alignTestImages = params{10};
margin = params{11};
rho = params{12};
threshold = params{13};
sigma = params{14};
labelPriorType = params{15};
regOptions = params{16};
freeSurferHome = params{17};
niftyRegHome = params{18};
pathClassesTable = params{19};

%check them
if ~(evaluate==0 || evaluate==1), error('evaluate should be 0 or 1'); end
if ~(cropHippo==0 || cropHippo==1), error('cropHippo should be 0 or 1'); end
if ~(leaveOneOut==0 || leaveOneOut==1), error('leaveOneOut should be 0 or 1'); end
if ~(useSynthethicImages==0 || useSynthethicImages==1), error('useSynthethicImages should be 0 or 1'); end
if ~(recompute==0 || recompute==1), error('recompute should be 0 or 1'); end
if ~(debug==0 || debug==1), error('debug should be 0 or 1'); end
if ~(deleteSubfolder==0 || deleteSubfolder==1), error('deleteSubfolder should be 0 or 1'); end
if length(targetResolution)==1
    if targetResolution == 0 && nChannel > 1
        error('please provide a non zero target resolution in the multi channel case');
    else
        targetResolution = repmat(targetResolution, 1, 3); 
    end
elseif length(targetResolution)==3 && ~all(targetResolution)
    error('targetResolution should not contain zeros when it has 3 elements')
elseif ~(length(targetResolution)==3)
    error('targetResolution should be of length 1 (isotropic) or 3 (anisotropic)'); 
end
if ~(rescale==0 || rescale==1), error('rescale should be 0 or 1'); end
if ~(alignTestImages == 0 || alignTestImages == 1 || alignTestImages == 2), error('alignImages should be 0, 1 or 2'); end
if rho<=0, error('rho should be a strictly positive number'); end
if threshold<0, error('threshold should be a positive or null number'); end

if length(sigma) == 1
    sigma = repmat(sigma, 1, nChannel);
elseif length(sigma) ~= nChannel
    error(['sigma should be of length 1 (same value for all channels), or length ' num2str(nChannel) ' (number of channels)']);
end

for i=1:nChannel, if sigma(i)<=0, error('sigma should only contain strictly positive numbers'); end; end

if ~isequal(labelPriorType,'logOdds') && ~isequal(labelPriorType,'delta function'), error('labelPriorType should be "delta_function" or "logOdds"'); end
if ~isequal(class(regOptions), 'char'), error('registrationOptions should be a string'); end
regOptions=strrep(regOptions,'_',' ');
setFreeSurfer(freeSurferHome); [a,~]=system('mri_convert --help'); if a, error('freeSurferHome not recognised'); end
[a,~]=system([niftyRegHome '/reg_f3d --help']); if a, error('niftyRegHome not recognised'); end
if isequal(class(pathClassesTable),'cell'), pathClassesTable=pathClassesTable{1}; end
if ~isequal(class(pathClassesTable), 'char'), error('registrationOptions should be a string or a cell containing the path'); end

%read classes
fid = fopen(pathClassesTable, 'r');
if fid == -1, error([pathClassesTable ' does not exist']); end
txt = textscan(fid,'%f %f %q');
fclose(fid);
labelsList = txt{1};
labelClasses = txt{2};
labelsNames = txt{3};

% write parameters in a file
if ~singleBrain
    pathParamsTxt=fullfile(fileparts(pathClassesTable), 'parameters.txt');
    fid=fopen(pathParamsTxt, 'w');
    fprintf(fid, 'evaluate: %d \n', evaluate);
    fprintf(fid, 'cropHippo: %d \n', cropHippo);
    fprintf(fid, 'leaveOneOut: %d \n', leaveOneOut);
    fprintf(fid, 'useSynthethicImages: %d \n', useSynthethicImages);
    fprintf(fid, 'recompute: %d \n', recompute);
    fprintf(fid, 'debug: %d \n', debug);
    fprintf(fid, 'deleteSubfolder: %d \n', deleteSubfolder);
    fprintf(fid, 'targetResolution: %s \n', mat2str(targetResolution));
    fprintf(fid, 'rescale: %d \n', rescale);
    fprintf(fid, 'alignTestImages: %d \n', alignTestImages);
    fprintf(fid, 'margin: %.3f \n', margin);
    fprintf(fid, 'rho: %.3f \n', rho);
    fprintf(fid, 'threshold: %.3f \n', threshold);
    fprintf(fid, 'sigma: %.3f \n', mat2str(sigma));
    fprintf(fid, 'labelPriorType: %s \n', labelPriorType);
    fprintf(fid, 'regOptions: %s \n', regOptions);
    fprintf(fid, 'freeSurferHome: %s \n', freeSurferHome);
    fprintf(fid, 'niftyRegHome: %s \n', niftyRegHome);
    fclose(fid);
end

end