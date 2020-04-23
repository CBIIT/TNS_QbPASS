function [string, Summary, OtptStats] = QbPASS_OptimalDataset_v5(LData, Limits, Export2CSV, TableData, XLimMax)

MaxChannel = LData.DyRange * (getpref('QbPASS','Threshold_Channel')/100);
GuiVoltage = [];

[Var1A,~,Var1C] = unique(LData.TestCond, 'stable');
[Var2A,~,Var2C] = unique(LData.LaserState, 'stable');
[Var3A,~,Var3C] = unique(LData.PulserInt, 'stable');

Variations = [Var1C, Var2C, Var3C];  % matrix of condition variations
UniqVariations = unique(Variations, 'rows'); % obtain unique condition variations

string = ({'Test Condition','Laser State','Pulser Intensity','Parameter','Voltage 1', 'Statistic 1 ', 'Voltage 2', 'Statistic 2'});

UniqVarNames = cell(size(UniqVariations, 1), 3);
SortedData = cell(size(UniqVariations, 1), 3);

for i = 1:size(UniqVariations, 1) % obtain names of unique condition variations
    
    UniqVarNames{i,1} = Var1A{UniqVariations(i,1)}; % test condition names
    UniqVarNames{i,2} = Var2A{UniqVariations(i,2)}; % laser state names
    UniqVarNames{i,3} = Var3A{UniqVariations(i,3)}; % pulser intensity names
    
    % find index for data matching unique combination
    ind = find(sum(Variations == [UniqVariations(i, 1) UniqVariations(i, 2) UniqVariations(i, 3)], 2) == 3);
    
    % find index for fluorescent channels excluding FSC, SSC, & Time
    ParInd = not(contains(LData.ParNames(1,:), ["FSC","SSC","Time"]));
    ParIndNames = LData.ParNames(1, ParInd);
    
    % Get statistics for each fluorescent channel
    MedData = [LData.Vt(ind,1), LData.Med(ind,ParInd)];
    SDData =  [LData.Vt(ind,1), LData.SD(ind,ParInd)];
    
    % get index to sort data by voltage increase
    [~,iSortVolts]  = sort(unique(LData.Vt(ind,1), 'stable'));
    
    % sort data by ascending voltage
    SortedData{i,1} = MedData(iSortVolts,:);
    SortedData{i,2} = SDData(iSortVolts,:);
    SortedData{i,3} = max(SortedData{i,1}) < MaxChannel ;
    
    if contains(UniqVarNames{i,1}, 'Signal')
        for ii = 1:size(SortedData{i,1},1)-1
            for iii = 2:size(SortedData{i,1},2)
                if SortedData{i,1}(ii,1) <= Limits
                else
                    if SortedData{i,1}(ii,iii) > SortedData{i,1}(ii+1,iii)
                        
                        newstring = ([UniqVarNames(i,:),...
                            ParIndNames{iii-1},...
                            num2str(SortedData{i,1}(ii,1)),...
                            num2str(SortedData{i,1}(ii,iii)),...
                            num2str(SortedData{i,1}(ii+1,1)),...
                            num2str(SortedData{i,1}(ii+1,iii))]);
                        
                        string = vertcat(string, newstring);
                        
                    end
                end
            end
        end
    end
end

switch Export2CSV
    case 'yes'
        TimeStamp = replace(datestr(datetime('now')), ':','-');
        DateStr = [TimeStamp,'.xls'];
        [file,path] = uiputfile('*.xls', 'Save Output File', DateStr);
        OutputStr = fullfile(path, file);
    case 'no'
        
end

WriteDataFinal = [];

for i = 1:numel(Var1A)
    
    % find all test condition associated matrices
    indType = find(contains(UniqVarNames, Var1A{i}));
    
    for ii = 1:numel(indType)
        
        Int = SortedData{indType(ii),1}; % channel intensity data
        IntNames = horzcat({'Voltage'}, strcat('Median (', ParIndNames, ')')); % channel intensity names
        
        SD = SortedData{indType(ii),2}; % channel SD data
        SDNames = horzcat({'Voltage'}, strcat('rSD (', ParIndNames, ')')); % channel SD names
        
        % interleave intensity and SD data to single matrix
        WriteData = [zeros(size(Int)), zeros(size(SD))];
        WriteData(:, 1:2:end) = round(Int,2);
        WriteData(:, 2:2:end) = round(SD,2);
        WriteData = num2cell(WriteData(:,2:end));
        
        % interleave intensity and SD names to single row
        WriteDataNames = cell(1,(numel(IntNames)*2)-1);
        WriteDataNames(1,1) = IntNames(:,1);
        WriteDataNames(1,2:2:end) = IntNames(:,2:end);
        WriteDataNames(1,3:2:end) = SDNames(:,2:end);
        
        % title for matrix
        WriteDataTitle = cell(1,numel(WriteDataNames));
        WriteDataTitle(1,1:3) = UniqVarNames(indType(ii),1:3);
        
        % concat arrays into single array
        WriteDataCat = vertcat(WriteDataTitle, WriteDataNames, WriteData);
        
        if ii > 1
            Spacer = cell(1,numel(WriteDataTitle));
            WriteDataFinal = vertcat(WriteDataFinal, Spacer, WriteDataCat);
        else
            WriteDataFinal = vertcat(WriteDataFinal, WriteDataCat);
        end
        
    end
    
    switch Export2CSV
        case 'yes'
            % write cell matrix to .xls sheet
            writecell(WriteDataFinal,OutputStr,'Sheet',Var1A{i})
        case 'no'
    end
    WriteDataFinal = [];
    
end

FullOptiData = [];

AllCondStr = strcat(UniqVarNames(:,1),{' '} ,UniqVarNames(:,2));
[CondStr] = unique(AllCondStr);

for i = 1:numel(ParIndNames)
    
    for ii = 1:numel(CondStr)
        
        ChanInd = [];
        
        % find all test condition associated matrices
        indType = find(contains(AllCondStr, CondStr{ii}));
        
        for iii = 1:numel(indType)
            ChanInd(iii, 1) = str2double(UniqVarNames{indType(iii),3});  % pulser intensity
            ChanInd(iii, 2) = SortedData{indType(iii),3}(i+1);           % max channel threshold exceeded (1 = no, 0 = yes)
        end
        
        if sum(ChanInd(:, 2)) == 0
            % if all do not exceed max channel number use highest setting
            [~,IndOptParSet2] = min(ChanInd(:,1));
            IndOptParSet2 = indType(IndOptParSet2);
            
        elseif sum(ChanInd(:, 2)) == size(ChanInd,1)
            % if all exceed max channel number use lowest setting
            [~,IndOptParSet2] = max(ChanInd(:,1));
            IndOptParSet2 = indType(IndOptParSet2);
            
        else
            % find the index for the optimal LED pulser setting
            IndOptParSet2 = indType(ChanInd(:, 1) == max(ChanInd((ChanInd(:, 2)==1),1)));
            
        end
        
        % collate optimal statistics
        OptiSet{ii}(i)  = strcat({'Median ('}, ParIndNames{i}, {')'}, {' LED Set ('}, num2str(IndOptParSet2), {')'});
        OptiSet2{ii}(i) = strcat({'rSD ('},    ParIndNames{i}, {')'}, {' LED Set ('}, num2str(IndOptParSet2), {')'});
        
        OptiChan{ii}(:, i) = SortedData{IndOptParSet2,1}(:,i+1);
        OptiSD{ii}(:, i) =   SortedData{IndOptParSet2,2}(:,i+1);
        
    end
end


for i = 1:numel(CondStr)
    
    Data1 = cell(1, 2*numel(OptiSet{i}));
    Data1(1:2:end) = OptiSet{i};
    Data1(2:2:end) = OptiSet2{i};
    Data1 = horzcat({'Voltage'}, Data1);
    
    Data2 = zeros(size(OptiSet{i},1), 2*size(OptiSet{i},2));
    Data2(1:size(OptiChan{i},1),1:2:end) =  OptiChan{i};
    Data2(1:size(OptiSD{i},1),2:2:end) =  OptiSD{i};
    Data2 = num2cell([SortedData{1,1}(:,1), round(Data2,2)]);
    
    % screen intensity values to remove outliers
    VoltageSet = SortedData{1,1}(:,1);
    for ii = 1:size(Data2,2)-1
        % obtain dataset for a parameter
        ScreenData = cell2mat(Data2(:,ii+1));
        for iii = 1:size(ScreenData,1)-1
            % if voltage is below 100 do not check
            if VoltageSet(iii) <= 100
            else
                % if intensity at x voltage is above the value at
                % next voltage step remove data point.
                if ScreenData(iii) > ScreenData(iii)+1
                    Data2{iii,ii+1} = '';
                else
                end
            end
        end
    end
    
    % create title row for the dataset
    Title = cell(1, numel(Data1));
    Title{1} = CondStr{i};
    
    % concat the datasets
    OptiData = vertcat(Title, Data1, Data2);
    
    if i > 1
        spacer = cell(2, size(OptiData,2));
        FullOptiData = vertcat(FullOptiData, spacer, OptiData);
    else
        FullOptiData = vertcat(FullOptiData, OptiData);
    end
    
end

switch Export2CSV
    case 'yes'
        % write optimal datasets to file
        writecell(FullOptiData,OutputStr,'Sheet','Optimal')
    case 'no'
end

if max(contains(CondStr,'LED')) == 1
    TrigInd = find(contains(CondStr,'LED'));
    BackOnInd = find(contains(CondStr,'Trigger B Off'));
    BackOffInd = find(contains(CondStr,'Trigger B On'));
else
    TrigInd = find(contains(CondStr,'L 1'));
    BackOnInd = find(contains(CondStr,'B 0'));
    BackOffInd = find(contains(CondStr,'B 1'));
end


%% collate raw data
Summary.XLimMax = XLimMax;      % plot x limits
Summary.F0med = OptiChan{TrigInd};
Summary.F0SD = OptiSD{TrigInd};
Summary.B0med = OptiChan{BackOnInd};
Summary.B0SD = OptiSD{BackOnInd};
Summary.MuFoRaw = OptiChan{TrigInd}-OptiChan{BackOnInd};
Summary.SpeRaw = ( (OptiChan{TrigInd}  - OptiChan{BackOnInd}).^2) ./ (OptiSD{TrigInd}.^2 - OptiSD{BackOnInd}.^2);
Summary.SP2Raw = (((OptiChan{TrigInd}  - OptiChan{BackOnInd}).^2) ./ (OptiSD{TrigInd}.^2 + OptiSD{BackOnInd}.^2));
Summary.PhiRaw = (  OptiSD{TrigInd}.^2 - OptiSD{BackOnInd}   .^2) ./ (OptiSD{TrigInd}.^2 + OptiSD{BackOnInd}.^2);
Summary.SspeRaw =  Summary.SpeRaw ./  Summary.MuFoRaw;
Summary.MuFoSpe =  Summary.MuFoRaw ./  Summary.SpeRaw;
Summary.MuBoRaw = ( Summary.MuFoRaw/2) .* ((( Summary.SspeRaw.* Summary.MuFoRaw)./ Summary.SP2Raw)-1);
Summary.VtRaw = cell2mat(Data2(:,1));
Summary.VtInt = min( Summary.VtRaw):max( Summary.VtRaw);
Summary.ParName = ParIndNames;
Summary.phiThreshold = getpref('QbPASS','Threshold_Phi');
Summary.gradThreshold = getpref('QbPASS','Threshold_Grad');

%% generate interpolate data and find optimal values
for i = 1:size( Summary.SP2Raw,2)
    try
        Summary.SP2Int(:,i)   = interp1( Summary.VtRaw,  Summary.SP2Raw(:,i),   Summary.VtInt,'makima'); % get interpolated SP^2 data
    catch
        Summary.VtOpt(i) = NaN;
    end
    try
        Summary.SpeInt(:,i)   = interp1( Summary.VtRaw,  Summary.SpeRaw(:,i),   Summary.VtInt,'makima'); % get interpolated Spe data
    catch
        Summary.VtOpt(i) = NaN;
    end
    try
        Summary.MuFoInt(:,i)  = interp1( Summary.VtRaw,  Summary.MuFoRaw(:,i),  Summary.VtInt,'makima'); % get interpolated µf0 data
        
    catch
        Summary.VtOpt(i) = NaN;
    end
    try
        Summary.PhiInt(:,i)   = interp1( Summary.VtRaw,  Summary.PhiRaw(:,i),   Summary.VtInt,'makima'); % get interpolated phi data
    catch
        Summary.VtOpt(i) = NaN;
    end
    try
        Summary.F0SDInt(:,i)  = interp1( Summary.VtRaw,  Summary.F0SD(:,i),   Summary.VtInt,'makima'); % get interpolated SD^2 data
    catch
        Summary.VtOpt(i) = NaN;
    end
    try
        [ Summary.VtOpt(i), MaxSP2Ind(:,i)]   = IntersectDetermination(Summary, i); % optimal voltage
        vtInd =  Summary.VtInt ==  Summary.VtOpt(i);
        Summary.SSpeOpt(i) =  Summary.SpeInt(vtInd,i)/ Summary.MuFoInt(vtInd,i); % SSpe at optimal voltage
        Summary.SP2Opt(i)  =  Summary.SP2Int(vtInd,i); % SP2 at optimal voltage
        Summary.MuFoOpt(i) =  Summary.MuFoInt(vtInd,i); % mean Fo at optimal voltage
        Summary.MuBoOpt(i) = ( Summary.MuFoOpt(i)/2) * ((( Summary.SSpeOpt(i) *  Summary.MuFoOpt(i)) /  Summary.SP2Opt(i)) - 1); % mean Bo at optimal voltage
    catch
        Summary.VtOpt(i) = NaN;
    end
end

%% create  Summary statistics
for i = 1:size( Summary.SpeRaw,2)
    
    indERFVt = ( Summary.VtRaw == TableData{i,5}); % voltage for which ERF calibrated
    
    OtptStats.ParName{i} =  Summary.ParName{i};
    OtptStats.VtOpt(i) =  Summary.VtOpt(i);
    OtptStats.ERFvt(i) = TableData{i,5};
    
    % statistcs relying upon ERF calibration voltage
    OtptStats.MuFMed(i)    = mean( Summary.F0med(MaxSP2Ind(:,i),i));
    OtptStats.MuFSD(i)     = mean( Summary.F0SD(MaxSP2Ind(:,i),i));
    OtptStats.MuBMed(i)    = mean( Summary.B0med(MaxSP2Ind(:,i),i));
    OtptStats.MuBSD(i)     = mean( Summary.B0SD(MaxSP2Ind(:,i),i));
    OtptStats.ERF(i)       = TableData{i,3};
    OtptStats.Channel(i)   = TableData{i,4};
    OtptStats.SP2(i)       = mean( Summary.SP2Raw(MaxSP2Ind(:,i),i));
    OtptStats.Spe(i)       = mean( Summary.SpeRaw(MaxSP2Ind(:,i),i));
    OtptStats.Phi(i)       = mean( Summary.PhiRaw(MaxSP2Ind(:,i),i));
    OtptStats.F0B0(i)      =  OtptStats.MuFMed(i) /  OtptStats.MuFSD(i)^2;
    OtptStats.MuFo(i)      =  OtptStats.MuFMed(i) -  OtptStats.MuBMed(i);
    OtptStats.Sspe(i)      =  OtptStats.Spe(i) /  OtptStats.MuFo(i);
    OtptStats.S_ERF(i)     = TableData{i,3}/TableData{i,4};
    OtptStats.MuFoSpe(i)   =  OtptStats.MuFo(i) *  OtptStats.Sspe(i);
    OtptStats.MuBo(i)      = mean( Summary.MuBoRaw(MaxSP2Ind(:,i),i));
    OtptStats.MuBoSpe(i)   =  OtptStats.MuBo(i) *  OtptStats.Sspe(i);
    OtptStats.QSpe(i)      =  OtptStats.F0B0(i) /  OtptStats.S_ERF(i);
    OtptStats.Btot(i)      = ( OtptStats.MuFo(i) -  OtptStats.Phi(i) *  OtptStats.MuFMed(i))/2;
    OtptStats.Bspe(i)      =  OtptStats.MuBoSpe(i) *  OtptStats.Sspe(i);
    OtptStats.BeadSpe(i)   =  OtptStats.Channel(i) *  OtptStats.F0B0(i);
    OtptStats.MChSpe(i)       = max(cell2mat(LData.Range(:)))*OtptStats.F0B0(i);
    OtptStats.DyRSpe(i)       = OtptStats.MChSpe(i)-OtptStats.MuBMed(i);
    OtptStats.DyRDb(i)        = 10.*log10(OtptStats.DyRSpe(i));
    %     end
end

app.LoadedDataset.Summary = Summary;


%% export data
switch Export2CSV
    case 'yes'
        
        %% generate names for writing to file
        SP2Header = strcat({'SP^2 ('}, ParIndNames, {')'});
        SP2Header = horzcat({'Voltage'}, SP2Header);
        SP2DataWrite = horzcat(Data2(:,1), num2cell(round( Summary.SP2Raw,2)));
        SP2DataWrite = vertcat(SP2Header, SP2DataWrite);
        SP2DataWrite = vertcat(SP2DataWrite, repmat({''},1, size(SP2DataWrite,2)));
        SP2DataWrite = vertcat(SP2DataWrite, horzcat({'Min. Gain'}, strsplit(num2str( Summary.VtOpt))));
        
        % write SP^2 datasets to file
        writecell(SP2DataWrite,OutputStr,'Sheet','SP^2');
        
        DataHeaders = {'Parameter',...
            'Min Vt',...
            'ERF Vt',...
            'µ F',...
            'Sigma F',...
            'µ B',...
            'Sigma B',...
            'ERF units',...
            'ERF channel',...
            'Bead Spe',...
            'SP^2',...
            'Spe',...
            'Phi',...
            'Mu F0 + Mu B0 (Spe/Channel)',...
            'Mu F0 (S_Spe)',...
            'Mu F0 + Mu B0 (S_ERF)',...
            'Mu F0 Spe',...
            'Mu F0',...
            'Mu B0 Channel',...
            'Mu B0 Spe',...
            'Q Spe',...
            'Mean B Channel',...
            'Mean B Spe',...
            'Spe @ max channel',...
            'Dy Range (Spe)',...
            'Dy Range (dB)'};
        
        Data = vertcat(DataHeaders, [ Summary.ParName(:),...
            num2cell(real([ OtptStats.VtOpt(:),...
            round( OtptStats.ERFvt(:), 2),...
            round( OtptStats.MuFMed(:), 2),...
            round( OtptStats.MuFSD(:), 2),...
            round( OtptStats.MuBMed(:), 2),...
            round( OtptStats.MuBSD(:), 2),...
            round( OtptStats.ERF(:), 0),...
            round( OtptStats.Channel(:), 2),...
            round( OtptStats.BeadSpe(:), 2),...
            round( OtptStats.SP2(:), 2),...
            round( OtptStats.Spe(:), 2),...
            round( OtptStats.Phi(:), 2),...
            round( OtptStats.F0B0(:), 2),...
            round( OtptStats.Sspe(:), 2),...
            round( OtptStats.S_ERF(:), 2),...
            round( OtptStats.MuFoSpe(:), 2),...
            round( OtptStats.MuFo(:), 2),...
            round( OtptStats.MuBo(:), 2),...
            round( OtptStats.MuBoSpe(:), 2),...
            round( OtptStats.QSpe(:), 2),...
            round( OtptStats.Btot(:), 2),...
            round( OtptStats.Bspe(:), 2),...
            round( OtptStats.MChSpe(:), 2),...
            round( OtptStats.DyRSpe(:), 2),...
            round( OtptStats.DyRDb(:), 2),...
            ]))]);
        
        writecell(Data,OutputStr,'Sheet',' Summary');
    case 'no'
end


end

function [IntersectX, MaxSP2Ind] = IntersectDetermination(Summary, SumInd)

xData =  Summary.VtRaw;
yData =  Summary.SP2Raw(:,SumInd);
xDatai =  Summary.VtInt;
yDatai =  Summary.SP2Int(:,SumInd);
thresh =  Summary.gradThreshold;

slopeX = (xDatai(1:end-1)+0.5);
slopeY = diff(yDatai(:))./diff(xDatai(:));

GradMax = max(slopeY);
GradMaxInd = find(slopeY == GradMax);

IndNo = 2; % number of max SP2 values to use
[SP2maxY] = sort(yData); % sort SP2 value
SP2maxY2 = SP2maxY(end-(IndNo-1):end);
MaxSP2Ind = zeros(numel(yData),1);

for i = 1:IndNo
    MaxSP2Ind = or(MaxSP2Ind, yData == SP2maxY2(i)) ;
end

SP2maxYMean = mean(SP2maxY2); % select the top 'IndNo' of max SP2 values

x1 = xDatai(xDatai==round(slopeX(GradMaxInd),0));
y1 = yDatai(xDatai==round(slopeX(GradMaxInd),0));

GradFactor = 100/thresh;
HalfGMaxDiff = sqrt((slopeY - (GradMax/GradFactor)).^2);
HalfGMaxindi(1) = find(min(HalfGMaxDiff(GradMaxInd:end)) == HalfGMaxDiff);
HalfGMaxindi(2) = find(min(HalfGMaxDiff(1:GradMaxInd)) == HalfGMaxDiff);
MaxDist = sqrt((HalfGMaxindi - GradMaxInd).^2);

if MaxDist(1) > MaxDist(2)
    HalfGMaxind = HalfGMaxindi(1);
else
    HalfGMaxind = HalfGMaxindi(2);
end

y2 = yDatai(xDatai==round(slopeX(HalfGMaxind),0));
x2 = round(slopeX(HalfGMaxind),0);
m1 = (x2-x1)\(y2-y1);
b1 = y2-(m1*x2);

m2 = 0;
b2 = SP2maxYMean;

%find the intersection point (min voltage)
IntersectX = round((b2-b1)/(m1-m2),0);

return

%% QC plotting data - can be removed when working
figure
nexttile
yyaxis left
plot(slopeX,slopeY,'-b')
hold on

set(gca,'YColor','b')
ylabel('Gradient')

yyaxis right

% plot SP2
plot(xDatai, yDatai,'-r')

% overlay raw data
scatter(xData, yData,30,'.k')
[SP2maxY2] = sort(yData);
SP2maxY3 = SP2maxY2(end-(IndNo-1):end);

SP2maxX3 = zeros(numel(yData),1);
for i = 1:IndNo
    SP2maxX3 = or(MaxSP2Ind, yData == SP2maxY3(i)) ;
end

scatter(xData(SP2maxX3), yData(SP2maxX3), 30, 'ob')

% max gradient line
yHigh = SP2maxYMean*1.5;
xLow = (0-b1)/m1;
xHigh = (yHigh-b1)/m1;
line([xLow xHigh], [0 yHigh],'LineWidth',1.5,'LineStyle',':','Color','k')

% max SP2 line
line([0 max(xDatai)], [SP2maxYMean SP2maxYMean],'LineWidth',1.5,'LineStyle',':','Color','k')

% intersect
y0 = m1*IntersectX+b1;
line([IntersectX IntersectX], [0 yHigh],'LineWidth',1.5,'LineStyle','-','Color','b')
scatter(IntersectX, y0,50,'xk')

% max gradient
scatter(x1, y1, 50, 'xk')
scatter(x2, y2, 50, 'xk')

% max SP2
SP2maxX = mean(xData(end-(IndNo+1):end));

scatter(SP2maxX, SP2maxYMean,50,'xk')

ylabel('SP^2')
xlabel('Voltage')
title([' Min Vt = ',num2str(ceil(IntersectX))])
legend off
ylim([0 yHigh])
xlim([0 max(xDatai)+10])
set(gca,'YColor','r')

end


