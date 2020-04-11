function [fig]=QbPASS_PlotData_v2(app)

fig = figure('Units','Normalized','Position',[0 0 1 1],'visible','off');
toPlot = contains(app.Summary.ParName,'-A');
app.Summary.PlotNo = ceil(sum(toPlot)/6);
count = 0;
maxSD2 = max(app.Summary.F0SDInt(:).^2);

t=  tiledlayout(app.Summary.PlotNo,6);
t.TileSpacing = 'compact';
t.Padding = 'compact';

for i = 1:numel(toPlot)
    if toPlot(i) == 1
        
        count = count +1;
        nexttile
        
        xData1 = app.Summary.VtInt;
        xData2 = app.Summary.VtRaw;
        
        yData1 = app.Summary.SP2Int(:,i);
        yData2 = app.Summary.SP2Raw(:,i);
        switch getpref('QbPASS','VoltPlotStat')
            case 'SD^2'
                yData3 = app.Summary.F0SDInt(:,i).^2;
                yData4 = app.Summary.F0SD(:,i).^2;
            case 'Spe'
                yData3 = app.Summary.SpeInt(:,i).^2;
                yData4 = app.Summary.SpeRaw(:,i).^2;
        end
        
        OptVolt = app.Summary.VtOpt(i);
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
            line([OptVolt OptVolt],ylim(),'Color','k','LineWidth', 2,'LineStyle', ':')
            vtstr = ['Min = ', num2str(OptVolt)];
        end
        
        if max(yData1) < 75
            TextLocation('max SP^2 < 75','Location', 'best')
        end
        
        set(gca,'yscale','linear','YColor','r','Box','on','LineWidth',2);
        ylabel([ParName,' SP^2'],'FontWeight','bold')
        xlabel([ParName,' Voltage | ', vtstr],'FontWeight','bold')
        
        top = app.Summary.XLimMax;
        if top > 1500
            xticks([0:200:top])
        else
            xticks([0:100:top])
        end
        xtickangle(90)
        xlim([0 top])
        axis on
        
        % Spe/SD^2 plotting
        yyaxis right
        plot(xData1, yData3, '-', 'Color','b', 'LineWidth',2)
        hold on
        scatter(xData2, yData4, 10, 'o','MarkerFaceColor','k')
        
        switch getpref('QbPASS','VoltPlotStat')
            case 'SD^2'
                ylabel([ParName,' SD^2'],'FontWeight','bold')
                set(gca,'YColor','b','yscale','log')
                ylim([1 maxSD2])
            case 'Spe'
                ylabel([ParName,' Spe'],'FontWeight','bold')
                set(gca,'YColor','b','yscale','linear')
        end
    end
end

sgtitle([app.LoadedDataset.ID, ' | ' , datestr(app.LoadedDataset.AcqDate(1))],'FontSize',16,'FontWeight','bold')
fig.Visible = 'off';

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


