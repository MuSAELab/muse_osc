function writecsv(filename, data, varargin)
%WRITECSV Add the data in the last line of the FILENAME CSV file, if it 
%exists, if not the FILENAME CSV file is created
%
%DATA can be:
%Cell of size {1xN} //Usually for headers
%Matrix of size (1xN) //One sample of N channels
%Matrix of size (RxN) //R samples of N channels
%
%
% Raymundo Cassani 
% raymundo.cassani@gmail.com

if nargin < 3
    quotes = false; %if FALSE 123.123, if true "123.123"
    numformat = '%10.4f'; %example ±1234567890.1234
elseif nargin == 3
    quotes = varargin{1};   
elseif nargin > 3
    quotes = varargin{1};
    numformat = varargin{2};
end

if quotes
   numformat = ['"' numformat '"'];
end

numformat = [numformat ', '];

% open the file and append new data
fid = fopen(filename ,'a+');

% validate successful opening of file
if fid == (-1)
    error(message('write2csv:FileOpenFailure', filename));
end

%End of line 
%Windows requires eol1 and eol2
%unix only eol2
eol1 = sprintf('\r'); 
eol2 = sprintf('\n');

if iscell(data)
    if quotes
        data = cellfun(@(x) ['"' x '"'], data, 'UniformOutput', false);
    end
    cellaux = cellfun(@(x) [x, ','],data,'UniformOutput', false);
    strout = [cellaux{:}];
    strout = strout(1:end-1);
    strout = [strout eol1 eol2];
    fprintf(fid, '%s', strout);

elseif ismatrix(data)
    for i_row = 1: size(data,1)
    abc = num2str(data(i_row,:),numformat);
    abc(:,end-1) = eol1;
    abc(:,end) = eol2;
    fprintf(fid, '%s', abc');  
    end
end

fclose(fid);

end

