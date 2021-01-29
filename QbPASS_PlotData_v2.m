function [fig]=QbPASS_PlotData_v2(app)

fig = figure('Units','Normalized','Position',[0 0 1 1],'visible','off');
toPlot = contains(app.Summary.ParName,'-A');
app.Summary.PlotNo = ceil(sum(toPlot)/6);
count = 0;
maxSD2 = max(app.Summary.F0SDInt(:).^2);

xPlots = 5;
yPlots = 6;
t= tiledlayout(yPlots,xPlots);
t.TileSpacing = 'compact';
t.Padding = 'compact';

for i = 1:numel(toPlot)
    if toPlot(i) == 1
        
        count = count +1;
        if count == (xPlots*yPlots)+1;
            count = 0; % reset count for new plot
            
            ind = numel(fig) + 1;
            sgtitle([app.LoadedDataset.ID, ' | ' , datestr(app.LoadedDataset.AcqDate(1))],'FontSize',16,'FontWeight','bold')
            
            fig(ind) = figure('Units','Normalized','Position',[0 0 1 1],'visible','off');
            t= tiledlayout(yPlots,xPlots);
            t.TileSpacing = 'compact';
            t.Padding = 'compact';
            
        end
        
        nexttile
        FailText{1} = [];
        FailText{2} = [];
        
        xData1 = app.Summary.VtInt;
        xData2 = app.Summary.VtRaw;
        
        yData1 = app.Summary.SP2Int(:,i);
        yData2 = app.Summary.SP2Raw(:,i);
        
        switch getpref('QbPASS','VoltPlotStat')
            case 'SD^2'
                yData3 = app.Summary.F0SDInt(:,i).^2;
                yData4 = app.Summary.F0SD(:,i).^2;
            case 'Spe'
                yData3 = app.Summary.SpeInt(:,i);
                yData4 = app.Summary.SpeRaw(:,i);
            case 'Phi'
                yData3 = app.Summary.PhiInt(:,i);
                yData4 = app.Summary.PhiRaw(:,i);
            case 'Gain'
                yData3 = app.Summary.GainInt(:,i);
                yData4 = app.Summary.Gain(:,i);
        end
        
        OptVolt = app.Summary.VtOpt(i);
        PhiOptVolt = app.Summary.PhiVtOpt(i);
        ParName = app.Summary.ParName{i};
        
        
        % SP2 Data plotting
        yyaxis left
        plot(xData1, yData1, '-', 'Color','r', 'LineWidth', 2)
        hold on
        scatter(xData2, yData2, 10, 'o','MarkerFaceColor','k')
        ylim([0 max(ylim())])
        
        if min(yData1) == max(yData1)
            vtstr = ['Min = Indeterminable'];
        else
            line([OptVolt OptVolt],ylim(),'Color','r','LineWidth', 2,'LineStyle', ':')
            vtstr = ['Min = ', num2str(OptVolt)];
        end
        
        
        if max(yData1) < 75
            FailText{1} = 'max SP^2 <75';
        end
        
        set(gca,'yscale','linear','YColor','r','Box','on','LineWidth',2);
        ylabel([ParName,' SP^2'],'FontWeight','bold')
        xlabel(['Voltage | SP^2 ', vtstr],'FontWeight','bold')
        
        top = app.Summary.XLimMax;
        if top > 1500
            xticks([0:200:top])
        else
            xticks([0:100:top])
        end
        xtickangle(90)
        xlim([0 top])
        axis on
        
        % Spe/SD^2/Phi plotting
        yyaxis right
        plot(xData1, yData3, '-', 'Color','b', 'LineWidth',2)
        hold on
        scatter(xData2, yData4, 10, 'o','MarkerFaceColor','k')
        
        switch getpref('QbPASS','VoltPlotStat')
            case 'Phi'
                ylim([0 1.2])
                if min(yData3) == max(yData3)
                    vtstr2 = 'Min = Indeterminable';
                else
                    line([PhiOptVolt PhiOptVolt],ylim(),'Color','b','LineWidth', 2,'LineStyle', ':')
                    vtstr2 = ['Min = ', num2str(PhiOptVolt)];
                end
            case 'Gain'
                yData2 = yData4(xData2>200);
                xData3 = xData2(xData2>200);
                [~,VtInd] = min(yData2);
                minVtThr = xData3(VtInd);
                
                minGainThrC = app.MinGainThresholdEditField.Value;
                maxGainThrC = app.MaxGainThresholdEditField.Value;
                
                [~, minGainThr] = min(sqrt((yData3(xData1>minVtThr,1)-minGainThrC).^2));
                [~, maxGainThr] = min(sqrt((yData3(xData1>minVtThr,1)-maxGainThrC).^2));
                
                xData3i = xData1(xData1>minVtThr);
                GainThr = [xData3i(minGainThr) xData3i(maxGainThr)];
                 maxy = ceil((max(yData3)*1.1)/100)*100;

                fill([ GainThr fliplr(GainThr)], [  0.1 0.1 maxy maxy],'b','facealpha',0.1)
                %                 if max(yData3) < getpref('QbPASS','Threshold_VtPhi')
                %                     FailText{2} = ['max Phi = ' num2str(round(max(yData3),3))];
                %                 end
        end
        
        % add text if Phi or SP^2 failed
        FailText(cellfun(@isempty, FailText)) = [];
        if isempty(FailText)
        else
            TextLocation(FailText,'Location', 'best')
        end
        
        switch getpref('QbPASS','VoltPlotStat')
            case 'SD^2'
                ylabel([ParName,' SD^2'],'FontWeight','bold')
                set(gca,'YColor','b','yscale','log')
                ylim([1 maxSD2])
            case 'Spe'
                ylabel([ParName,' Spe'],'FontWeight','bold')
                set(gca,'YColor','b','yscale','linear')
            case 'Phi'
                xlabel(['Voltage | SP^2 ', vtstr, ', Phi ', vtstr2],'FontWeight','bold')
                ylabel([ParName,' Phi'],'FontWeight','bold')
                set(gca,'YColor','b','yscale','linear')
            case 'Gain'
                %                 xlabel(['Voltage | SP^2 ', vtstr, ', Gain ', vtstr2],'FontWeight','bold')
                ylabel([ParName,' Gain'],'FontWeight','bold')
                set(gca,'YColor','b','yscale','log')
                ylim([0.1 max(yData4)])
        end
    end
end

sgtitle([app.LoadedDataset.ID, ' | ' , datestr(app.LoadedDataset.AcqDate(1))],'FontSize',16,'FontWeight','bold')
for i = 1:numel(fig)
    fig(i).Visible = 'off';
end

end

function hOut = TextLocation(textString,varargin)

l = legend(textString,varargin{:});
t = annotation('textbox');
t.String = textString;
t.Position = l.Position;
delete(l);
t.LineStyle = 'None';
t.FontWeight = 'bold';
t.Color = 'r';

if nargout
    hOut = t;
end
end


