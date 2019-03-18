function varargout = readPaths(varargin)

nChannel = length(varargin{1});
useSynthethicImages = varargin{end};
if isequal(varargin{5}, '') && ~useSynthethicImages, error(['please provide ' inputname(5)]); end

for input=1:nargin-1
    
    % check if input is a cell or a string. Transfrom string into cell
    if ~isequal(class(varargin{input}),'cell')
        if ~isequal(class(varargin{input}),'char')
            error([inputname(input) ' must be a string (one path) or a cell of strings (several paths)']);
        else
            varargin{input} = {varargin{input}};
        end
    end
    % check that only one set of test labels is given
    if input == 3 && length(varargin{input}) > 1
        error([inputname(1) ' should only contain one path. Please provide test labels corresponding to the first channel.']);
    end
    % check that length of input doesn't exceed channel number
    if length(varargin{input}) > nChannel
        error([inputname(input) ' contains too many paths']);
    end
    for i=1:length(varargin{input})
        % add *nii.gz to folder names and check no mgz files
        if ~contains(varargin{input}{i}, 'nii.gz')
            if contains(varargin{input}{i}, '.mgz')
                error('all files should be nii.gz');
            else
                varargin{input}{i}=fullfile(varargin{input}{i}, '*nii.gz');
            end
        end
        % check if all files are writen under the same main folder
        current_mainFolder = fileparts(fileparts(varargin{input}{i}));
        if i>1 && ~isequal(current_mainFolder, previous_mainFolder)
            error(['paths in ' inputname(input) ' should have the same main folder']);
        elseif input > 1 && ~isequal(current_mainFolder, previous_mainFolder) && (input < 5 || (~useSynthethicImages && input == 5))
            error(['paths in ' inputname(input) ' and ' inputname(input-1) ' should have the same main folder']);
        else
            previous_mainFolder = current_mainFolder;
        end
    end
    varargout{input} = varargin{input};
    
end

% check that test images and first labels have the same length
if length(varargin{1}) ~= length(varargin{2})
    error([inputname(1) ' and ' inputname(2) ' should have the same number of paths']);
end
% check that test images and training images have the same length
if ~useSynthethicImages && length(varargin{5}) ~= length(varargin{1})
    error([inputname(1) ' and ' inputname(5) ' should have the same number of paths']);
end

end