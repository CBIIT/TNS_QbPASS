function [fcsdat, fcshdr, fcsdatscaled, fcsdatcomp, mnemonic_separator] = QbPASS_fcs_read(filename)
% Editted from below script found on Mathworks File Exchange
% [fcsdat, fcshdr, fcsdatscaled, fcsdat_comp] = fca_readfcs(filename);
%
% Read FCS 2.0, 3.0 and 3.1 type flow cytometry data file and put the list mode
% parameters to the fcsdat array with the size of [NumOfPar TotalEvents].
% Some important header data are stored in the fcshdr structure:
% TotalEvents, NumOfPar, starttime, stoptime and specific info for parameters
% as name, range, bitdepth, logscale(yes-no) and number of decades.

fcsdat = [];
fcshdr = [];
fcsdatscaled = [];
fcsdatcomp = [];

% if noarg was supplied
if nargin == 0 % no inputted arguments
    [FileName, FilePath] = uigetfile('*.*','Select FCS file'); % select any file type, does not have to be fcs2.0 file
    filename = [FilePath,FileName];
    if FileName == 0 % if no file selected, return null arrays
        fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
        return;
    end
else % Removes the NULL ascii character if it exists. This makes strange things!
    filename_asciicode = int16(filename);
    filename(find(filename_asciicode==0)) = [];
    filecheck = dir(filename);
    if size(filecheck,1) == 0 || size(filecheck,1) >1 % if no file exists or multiple files share name--could probably ask to choose
        msgbox([filename,': The FCS file or the source directory does not exist!'], ...
            'FCS reading info','warn');
        fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
        return;
    end
end

% if filename arg. only contain PATH, set the default dir to this
% before issuing the uigetfile command. This is an option for the "fca"
% tool
[FilePath, FileNameMain, fext] = fileparts(filename);
FilePath = [FilePath filesep];
FileName = [FileNameMain, fext];
if isempty(FileNameMain)
    currend_dir = cd;
    cd(FilePath);
    [FileName, FilePath] = uigetfile('*.*','Select FCS file');
    filename = [FilePath,FileName];
    if FileName == 0
        fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
        return;
    end
    cd(currend_dir); % changes back to original current folder
end

% Reading the File
fid = fopen(filename,'r','b');
fcsheader_1stline = fread(fid,64,'char');
fcsheader_type = char(fcsheader_1stline(1:6)'); % first six characters should always be FCS2.0, FCS3.0, ...

%% Reading the Header
if contains(fcsheader_type,'FCS1.0')
    msgbox('FCS 1.0 file type is not supported!','FCS reading info','warn');
    fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
    fclose(fid);
    return;
elseif  contains(fcsheader_type,'FCS2.0') || contains(fcsheader_type,'FCS3.0')  || contains(fcsheader_type,'FCS3.1') % FCS2.0 or FCS3.0 or FCS3.1 types
    fcshdr.fcstype = fcsheader_type;
    FcsHeaderStartPos   = str2double(char(fcsheader_1stline(11:18)'));
    FcsHeaderStopPos    = str2double(char(fcsheader_1stline(19:26)'));
    FcsDataStartPos     = str2double(char(fcsheader_1stline(27:34)'));
    fseek(fid,0,'bof');
    fcsheader_total = fread(fid,FcsHeaderStopPos+1,'char'); %read the total header
    fseek(fid,FcsHeaderStartPos,'bof');
    fcsheader_main = fread(fid,FcsHeaderStopPos-FcsHeaderStartPos+1,'char'); %read the main header
    char_fcsheader = char(fcsheader_main)'; % converts fcsheader_main into characters
    warning off MATLAB:nonIntegerTruncatedInConversionToChar; % turns off warning
    fcshdr.Filename = FileName;
    fcshdr.Filepath = FilePath;
    
    % Mnemonic Separator--The first character of the primary TEXT segment contains the delimiter (FCS standard)
    mnemonic_separator = char(fcsheader_main(1));
    double_mnem_sep = fcsheader_main(1);
    
    if strmatch('|',mnemonic_separator)
        old_mnemonic_separator = '|';
        new_mnemonic_separator = '£';
        
        char_fcsheader = replace(char_fcsheader,old_mnemonic_separator,new_mnemonic_separator);
        
        mnemonic_expression = [new_mnemonic_separator, '.*?', new_mnemonic_separator];
        [StartIndex, EndIndex] = regexp(char_fcsheader, mnemonic_expression);
        
    else
        mnemonic_expression = [mnemonic_separator, '.*?', mnemonic_separator];
        [StartIndex, EndIndex] = regexp(char_fcsheader, mnemonic_expression);
    end
    
    
    for i = 1:numel(StartIndex)
        Fieldname = char_fcsheader(StartIndex(i) + 1:EndIndex(i) - 1);
        if i == numel(StartIndex)
            if char_fcsheader(end) == mnemonic_separator
                Value = char_fcsheader(EndIndex(i) + 1:end - 1);
            else
                Value = char_fcsheader(EndIndex(i) + 1:end);
            end
        else
            Value = char_fcsheader(EndIndex(i) + 1:StartIndex(i + 1) - 1);
        end
        if isempty(Fieldname)
        elseif Fieldname(1) == '$'
            Fieldname = Fieldname(2:end);
        end
        Fieldname = strrep(Fieldname, '_', '__');
        Fieldname = strrep(Fieldname, ' ', '_');
        Valid_field_name = matlab.lang.makeValidName(Fieldname);
        fcshdr.(Valid_field_name) = str2double(Value);
        if isnan(fcshdr.(Valid_field_name))
            fcshdr.(Valid_field_name) = Value;
        end
    end
    expression = '(P\d+N|P\d+B|P\d+R|P\d+E|P\d+S|P\d+D|P\d+F|P\d+G|P\d+L|P\d+O|P\d+P|P\d+T|P\d+V)';
    
    % if the file size larger than ~100Mbyte the previously defined
    % FcsDataStartPos = 0. In that case the $BEGINDATA parameter stores the correct value
    if ~FcsDataStartPos % if first line does not store data start position
        FcsDataStartPos = str2double(get_mnemonic_value('$BEGINDATA',fcsheader_main, mnemonic_separator));
    end
    if mnemonic_separator == '@' % WinMDI
        msgbox([FileName,': The file can not be read (Unsupported FCS type: WinMDI histogram file)'],'FCS reading info','warn');
        fcsdat = []; fcshdr = [];fcsdatscaled= []; fcsdatcomp= [];
        fclose(fid);
        return;
    end
    
    if fcshdr.TOT == 0 % if no total events, then no data
        fcsdat = 0;
        fcsdatscaled = 0;
        return
    end
    
    % Determine MachineFormat
    if fcshdr.BYTEORD == 1234
        machineformat = 'ieee-le';
    elseif fcshdr.BYTEORD == 4321
        machineformat = 'ieee-be';
    end
    
else % if first line does not start with FCS2.0, FCS3.0, ...
    msgbox([FileName,': The file can not be read (Unsupported FCS type)'],'FCS reading info','warn');
    fcsdat = []; fcshdr = []; fcsdatscaled = []; fcsdatcomp = [];
    fclose(fid);
    return;
end

%% Reading the Events
fseek(fid,FcsDataStartPos,'bof'); % set offset to FcsDataStartPos for reading data
if contains(fcsheader_type,'FCS2.0')
    if double_mnem_sep == 92 || double_mnem_sep == 12 ...
            || double_mnem_sep == 47 || double_mnem_sep == 9 % These characters are '\', 'FF', '/', 'TAB'
        if fcshdr.Parameters(1).Bit == 16
            fcsdat = (fread(fid,[fcshdr.PAR fcshdr.TOT],'uint16',machineformat)');
            fcsdat_orig = uint16(fcsdat);% original 16 bit unsigned integer data
            if fcshdr.BYTEORD == 12 ...% this is the Cytomics data
                    || fcshdr.BYTEORD == 1234 %added by GAP 1/22/09
                fcsdat = bitor(bitshift(fcsdat,-8),bitshift(fcsdat,8));
            end
            new_xrange = 1024;
            for i=1:fcshdr.PAR
                if fcshdr.Parameters(i).Range > 4096
                    fcsdat(:,i) = fcsdat(:,i)*new_xrange/fcshdr.Parameters(i).Range; % rescaling data????
                    fcshdr.Parameters(i).Range = new_xrange;
                end
            end
        elseif fcshdr.Parameters(1).Bit == 32
            if fcshdr.DATATYPE ~= 'F'
                fcsdat = (fread(fid,[fcshdr.PAR fcshdr.TOT],'uint32')');
            else % 'LYSYS' case
                fcsdat = (fread(fid,[fcshdr.PAR fcshdr.TOT],'float32')');
            end
        else
            bittype = ['ubit',num2str(fcshdr.Parameters(1).Bit)];
            fcsdat = fread(fid,[fcshdr.PAR fcshdr.TOT],bittype, 'ieee-le')';
        end
    elseif double_mnem_sep == 33 % Becton EPics DLM FCS2.0 % character is '!'
        fcsdat_ = fread(fid,[fcshdr.PAR fcshdr.TOT],'uint16', 'ieee-le')';
        fcsdat = zeros(fcshdr.TOT,fcshdr.PAR);
        for i=1:fcshdr.PAR %converts decimal values to binary and only reads last 10 bits as it is little endian
            bintmp = dec2bin(fcsdat_(:,i));
            fcsdat(:,i) = bin2dec(bintmp(:,7:16)); % only the first 10bit is valid for the parameter
        end
    end
    fclose(fid);
elseif contains(fcsheader_type,'FCS3.0') || contains(fcsheader_type,'FCS3.1')
    if double_mnem_sep == 124 && contains(fcshdr.DATATYPE,'I') && (contains( fcshdr.CYT,'CyAn') || contains( fcshdr.CYT,'MoFlo Astrios' ))% CyAn Summit FCS3.0 % character is '|'
        fcsdat_ = fread(fid,[fcshdr.PAR fcshdr.TOT],['uint',num2str(fcshdr.Parameters(1).Bit)],machineformat)';
        %fcsdat_ = (fread(fid,[fcshdr.PAR fcshdr.TOT],'uint16',machineformat)');
        fcsdat = zeros(size(fcsdat_));
        new_xrange = 2^16; % range of unsigned integers for uint16
        for i=1:fcshdr.PAR
            fcsdat(:,i) = fcsdat_(:,i)*new_xrange/fcshdr.Parameters(i).Range; % maybe this allows for different parameters to be written in different bits
            fcshdr.Parameters(i).Range = new_xrange; % this changes the range as written on the file
        end
    elseif double_mnem_sep == 47 % character is '/'
        if findstr(lower(fcshdr.CYT),'accuri')  % Accuri C6, this condition added by Rob Egbert, University of Washington 9/17/2010
            fcsdat = (fread(fid,[fcshdr.PAR fcshdr.TOT],'int32',machineformat)');
        elseif findstr(lower(fcshdr.CYT),'partec')%this block added by GAP 6/1/09 for Partec, copy/paste from above
            fcsdat = uint16(fread(fid,[fcshdr.PAR fcshdr.TOT],'uint16',machineformat)');
            %fcsdat = bitor(bitshift(fcsdat,-8),bitshift(fcsdat,8));
        elseif findstr(lower(fcshdr.CYT),'lx') % Luminex data
            fcsdat = fread(fid,[fcshdr.PAR fcshdr.TOT],'int32',machineformat)';
            fcsdat = mod(fcsdat,1024); % data is the remainder after division of 2^10????
        else  %Assume FCS3.1 format that is the same as FCS3.0
            if contains(fcshdr.DATATYPE,'D')
                fcsdat = fread(fid,[fcshdr.PAR fcshdr.TOT],'double',machineformat)';
            elseif contains(fcshdr.DATATYPE,'F')
                fcsdat = fread(fid,[fcshdr.PAR fcshdr.TOT],'float32',machineformat)';
            elseif contains(fcshdr.DATATYPE,'I')
                fcsdat = fread(fid,[sum([fcshdr.Parameters.Bit]/16) fcshdr.TOT],'uint16',machineformat)'; % sum: William Peria, 16/05/2014
            end
        end
    else % ordinary FCS 3.0
        if contains(fcshdr.DATATYPE,'D')
            fcsdat = fread(fid,[fcshdr.PAR fcshdr.TOT],'double',machineformat)';
        elseif contains(fcshdr.DATATYPE,'F')
            fcsdat = fread(fid,[fcshdr.PAR fcshdr.TOT],'float32',machineformat)'; % This is what the files are read under
        elseif contains(fcshdr.DATATYPE,'I')
            if sum([fcshdr.Parameters.Bit])/fcshdr.Parameters(1).Bit ~= fcshdr.PAR % if the bitdepth different at different pars
                fcsdat = fread(fid,[sum([fcshdr.Parameters.Bit]/16) fcshdr.TOT],'uint16',machineformat)'; % sum: William Peria, 16/05/2014
            else
                fcsdat = fread(fid,[fcshdr.PAR fcshdr.TOT],['uint',num2str(fcshdr.Parameters(1).Bit)],machineformat)';
            end
        end
    end
    fclose(fid);
end

%% this is converting Partec to FacsDIVA_FCS20 format if save_FacsDIVA_FCS20 = 1;
save_FacsDIVA_FCS20 = 0;
if contains(fcshdr.CYT ,'partec PAS') && save_FacsDIVA_FCS20
    fcsheader_main2 = fcsheader_main;
    sep_place = strfind(char(fcsheader_main'),'/');
    fcsheader_main2(sep_place) = 12;
    fcsheader_1stline2 = fcsheader_1stline;
    fcsheader_1stline2(31:34) = double(num2str(FcsHeaderStopPos+1));
    fcsheader_1stline2(43:50) = double('       0');
    fcsheader_1stline2(51:58) = double('       0');
    FileSize =  length(fcsheader_main2(:))+ length(fcsheader_1stline2(1:FcsHeaderStartPos))+ 2*length(fcsdat_orig(:));
    space_char(1:8-length(num2str(FileSize)))= ' ';
    fcsheader_1stline2(35:42) = double([space_char,num2str(FileSize)]);
    
    fid2 = fopen([FilePath, FileNameMain,'_', fext],'w','b');
    fwrite(fid2,fcsheader_1stline2(1:FcsHeaderStartPos),'char');
    fwrite(fid2,fcsheader_main2,'char');
    fwrite(fid2,fcsdat_orig','uint16');
    fclose(fid2);
end

%% this is for Gy Vamosi converting MoFlo Astrios with changing some hdr parameters if save_MoFlo_Astrios = 1
save_MoFlo_Astrios = 0;
if contains(fcshdr.CYT ,'MoFlo Astrios') && save_MoFlo_Astrios
    fcsheader_total_char = char(fcsheader_total)';
    intmax_pos = strfind(fcsheader_total_char,'4294967296');
    for i=1:length(intmax_pos)
        fcsheader_total_char(intmax_pos(i):intmax_pos(i)+length('4294967296')-1) = '65536|    ';
    end
    fcsheader_total2 = int8(fcsheader_total_char');
    fid2 = fopen([FilePath, FileNameMain,'_', fext],'w','b');
    fwrite(fid2,fcsheader_total2,'char');
    fwrite(fid2,uint32(fcsdat'),'uint32','ieee-le');
    %fwrite(fid2,fcsdat','float32','ieee-le');
    fclose(fid2);
end

%%  calculate the scaled events (for log scales)
if nargout > 2
    fcsdatscaled = zeros(size(fcsdat));
    for  i = 1 : fcshdr.PAR
        Xlogdecade = fcshdr.Parameters(i).Decade;
        XChannelMax = fcshdr.Parameters(i).Range;
        Xlogvalatzero = fcshdr.Parameters(i).Logzero;
        if fcshdr.Parameters(i).Gain ~= 1 && ~isnan(fcshdr.Parameters(i).Gain) % modified for cytometers that do not write Gain
            fcsdatscaled(:,i) = double(fcsdat(:,i))./fcshdr.Parameters(i).Gain;
        elseif fcshdr.Parameters(i).Log
            fcsdatscaled(:,i) = Xlogvalatzero*10.^(double(fcsdat(:,i))/XChannelMax*Xlogdecade);
        else
            fcsdatscaled(:,i)  = fcsdat(:,i);
        end
    end
end

%% calculate the compensated events
if nargout > 3 && ~isempty(fcshdr.CompLabels)
    compcols = zeros(1, nc);
    colLabels = {fcshdr.Parameters.Name};
    for i = 1:nc
        compcols(i) = find(strcmp(fcshdr.CompLabels{i}, colLabels));
    end
    fcsdatcomp = fcsdatscaled;
    fcsdatcomp(:,compcols) = fcsdatcomp(:,compcols)/fcshdr.CompMat;
else
    fcsdatcomp=[];
end

function mneval = get_mnemonic_value(mnemonic_name, fcsheader, mnemonic_separator)
% Adds mnemonic separator to end as mnemonic name can appear more than once
% in fcsheader
mnemonic_separator = double(mnemonic_separator);
mnemonic_name = double(mnemonic_name); % convert to decimals
mnemonic_name = [mnemonic_name mnemonic_separator]; % add mnemonic separator to end which specifies which name
mnemonic_name = char(mnemonic_name); % convert back to characters to search through fcsheader
mnemonic_startpos = strfind(char(fcsheader'),mnemonic_name); % finds the mnemonic name in the fcsheader
if isempty(mnemonic_startpos) % if the mnemonic name is not found, return the null array
    mneval = [];
    return;
else
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_separators = strfind(char(fcsheader(mnemonic_stoppos:end)'), char(mnemonic_separator)); % finds all the mnemonic separators in the fcsheader after the mnemonic name
    next_separator = next_separators(1) + mnemonic_stoppos; % the next mnemonic separator
    mneval = char(fcsheader(mnemonic_stoppos : next_separator - 2)');
end