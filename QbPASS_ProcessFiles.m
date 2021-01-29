function [app, Dataset, d, var] = QbPASS_ProcessFiles(app, Filenames)
% progress bar

d = uiprogressdlg(app.Qb,'Title','Please Wait',...
    'Message','Importing fcs file data');

for i = 1:numel(Filenames)
    
    % read fcs
    [app.fcsdata{i}, app.fcshdr] = QbPASS_fcs_read(Filenames{i});
    
    if numel(strfind(Filenames{i},'$')) == 4
        InputLocator = strfind(Filenames{i},'$');
        
        app.Test_Condition{i} = Filenames{i}(InputLocator(1)+1:InputLocator(2)-1); % get test condition of .fcs data
        app.Laser_State{i} = Filenames{i}(InputLocator(2)+1:InputLocator(3)-1); % get laser status of .fcs data
        app.Pulser_Intensity{i} = Filenames{i}(InputLocator(3)+1:InputLocator(4)-1); % get pulser intensity of .fcs data
        app.Voltage(i) = str2double(Filenames{i}(InputLocator(4)+1:end-4)); % get voltage of .fcs data
        
    else
        
        % check keywords exist in the fcs file
        Keywords = {'Voltage','Laser_Status','Test_Condition','Pulser_Intensity'};
        for ie = 1:numel(Keywords)
            error(ie) = isfield(app.fcshdr, Keywords{ie});
        end
        
        % give error message if keyword doesnt exist
        if min(error) == 0
            errorstr = [app.fcshdr.Filename, ' does not contain the following keywords:  ', (Keywords(not(error)))];
            uialert(app.Qb, errorstr, 'Error reading keywords');
            return
        else
            
            app.Voltage(i) = app.fcshdr.(Keywords{1}); % get voltage of .fcs data
            app.Laser_State{i} = app.fcshdr.(Keywords{2}); % get laser status of .fcs data
            app.Test_Condition{i} = app.fcshdr.(Keywords{3}); % get test condition of .fcs data
            app.Pulser_Intensity{i} = num2str(app.fcshdr.(Keywords{4})); % get pulser intensity of .fcs data
        end
    end
    
    P_name = repmat({'P'}, app.fcshdr.PAR, 1); % parameter
    N_name = repmat({'N'}, app.fcshdr.PAR, 1); % parameter name
    V_name = repmat({'V'}, app.fcshdr.PAR, 1); % parameter voltage
    R_name = repmat({'R'}, app.fcshdr.PAR, 1); % parameter range
    
    Par_no = strsplit(num2str(1:app.fcshdr.PAR));
    
    Par_vt = strcat(P_name(:), Par_no(:), V_name(:));
    
    Par_N = strcat(P_name(:), Par_no(:), N_name(:));
    Par_R = strcat(P_name(:), Par_no(:), R_name(:));
    
    for ii = 1:app.fcshdr.PAR
        if isfield(app.fcshdr,(Par_N{ii}))
            
            app.ParNames{i,ii} = app.fcshdr.(Par_N{ii});    % get parameter names
            app.ParInd(i,ii)  = ii;                         % get index for parameter
            app.ParVt(i,ii) = app.Voltage(i);               % get voltages
            Range{i,ii} = app.fcshdr.(Par_R{ii});           % get dynamic ranges
            
            Per84 = prctile(app.fcsdata{i}(:,ii), 84.13);   % 84 percentile
            Per15 = prctile(app.fcsdata{i}(:,ii), 15.87);   % 15th percentile
            
            app.Stat_Median(i,ii) = median(app.fcsdata{i}(:,ii)); % get statistics for each of the parameters
            app.Stat_SD(i,ii) = ((Per84-app.Stat_Median(i,ii))+(app.Stat_Median(i,ii)-Per15))/2; % standard deviation
            app.Stat_CV(i,ii) = std(app.fcsdata{i}(:,ii))./mean(app.fcsdata{i}(:,ii)); % CV
        end
        
        % get voltage of fcs file
        if isfield(app.fcshdr,(Par_vt{ii}))
            app.ParVt(i,ii) = app.fcshdr.(Par_vt{ii});
        end
        
        
        
    end
    
    if isfield(app.fcshdr,'DATE') == 1
        Date(i) = datetime(app.fcshdr.DATE);
    end
    if isfield(app.fcshdr,'CYT') == 1
        Cyt{i} = app.fcshdr.CYT;
    end
    % progress bar update
    d.Value = i/numel(Filenames);
    
end


if isempty(Date)
    unqDate = datetime('now', 'Format','dd-MMM-yyyy');
else
    unqDate = unique(Date);
end
var = ['D_', num2str(datenum(unqDate(1)))];

Dataset.(var).ID = app.CytometersListBox.Items{app.CytometersListBox.Value};
Dataset.(var).Cyt = unique(Cyt);
Dataset.(var).AcqDate = unique(Date);
Dataset.(var).Range = Range;
Dataset.(var).ParNames = app.ParNames;
Dataset.(var).SD = app.Stat_SD;
Dataset.(var).CV = app.Stat_CV;
Dataset.(var).Med = app.Stat_Median;
Dataset.(var).Vt = app.ParVt;
Dataset.(var).LaserState = app.Laser_State;
Dataset.(var).TestCond = app.Test_Condition;
Dataset.(var).PulserInt = app.Pulser_Intensity;
Dataset.(var).Voltage = app.Voltage;
Dataset.(var).fcsdir = app.ImportSelpath;
Dataset.(var).phiThresh = app.PhiThresholdEditField.Value;

UnqParNames = unique(Dataset.(var).ParNames, 'stable')';
ParInd = not(contains(UnqParNames(1,:), (getpref('QbPASS','ExclusionParameters'))));
RangeArray = cell2mat(Dataset.(var).Range(:,ParInd)); % remove FS,SS,Time from dynamic ranges

UniqRanges = unique(RangeArray(:)); % find unique ranges
if numel(UniqRanges) == 1
    Dataset.(var).DyRange = UniqRanges;
else
    uialert(app.Qb,'Inconsisent instrument .fcs files detected','Error finding dynamic range')
end


d = uiprogressdlg(app.Qb,'Title','Please Wait',...
    'Message','Processing file data','Indeterminate','on');


end