function [fig]=QbPASS_QC_Plot_v1(Data, Names, PType, LData)
close all
PlotWid = 6;
FSize = 12;
[toPlot] = and(contains(Names.ParNames,'-A'), ~contains(Names.ParNames,{'FSC','SSC','Time'}));

Data.Med = Data.Med(:,toPlot);
Data.SD = Data.SD(:,toPlot);
Data.Vt = Data.Vt(:,toPlot);
Names.ParNames = Names.ParNames(toPlot);
Names.LED = Names.LED;
Names.LaserStat = Names.LaserStat;
Names.TestCond = Names.TestCond;

PlotNo = ceil((numel(Names.ParNames)+1)/PlotWid);

fig = figure('Units','Normalized','Position',[0 0 1 1],'Visible','off');

switch PType
    case 'QC'
        Bind = or(categorical(Names.TestCond) == {'B'}, categorical(Names.TestCond) == {'Trigger B'});
        Lind1 = or(categorical(Names.LaserStat) == categorical(1), categorical(Names.LaserStat) == 'On');
        Lind2 = or(categorical(Names.LaserStat) == categorical(0), categorical(Names.LaserStat) == 'Off');
        
        yInd1 = and(Bind, Lind1);
        yInd2 = and(Bind, Lind2);
        
        ydatamax = [Data.SD(yInd1, :); Data.SD(yInd2, :)];
        maxY = max(ydatamax(:))^2;
        maxXlog = 1:ceil(log10(maxY));
        t=  tiledlayout(PlotNo,PlotWid);
        t.TileSpacing = 'compact';
        t.Padding = 'none';
        t.YLabel.String = 'Standard Deviation^2';
        t.YLabel.FontSize = 18;
        t.YLabel.FontWeight = 'bold';
        for i = 1:numel(Names.ParNames)+1
            nexttile
            if i == numel(Names.ParNames)+1
                
                scatter([], [], 50, 'filled')
                hold on
                scatter([], [], 50, 'filled')
                axis off;
                plot([1 1],[1 1],'Color','k','LineWidth',2)
                
                legend({'B Lasers On','B Lasers Off','Min Voltage'},'box','off','FontSize',14,'Location','north')
            else
                Pind = find(contains(unique(Names.ParNames,'stable'), Names.ParNames(i)));
                Pind2 = find(contains(unique(Data.Processed.ParName,'stable'), Names.ParNames(i)));
                
                ydata1 = Data.SD(yInd1, Pind).^2;
                ydata2 = Data.SD(yInd2, Pind).^2;
                ystr = 'SD^2';
                
                xdata1 = Data.Vt(yInd1, Pind);
                xdata2 = Data.Vt(yInd2, Pind);
                xstr = [Names.ParNames{i}, ' Voltage'];
                
                xxInt1 = 0:max(xdata1);
                yyInt1 = interp1(xdata1,ydata1, xxInt1,'makima');
                xxInt2 = 0:max(xdata2);
                yyInt2 = interp1(xdata2,ydata2, xxInt2,'makima');
                
                plot(xxInt1, yyInt1,'Color',[0 0.4470 0.7410],'linewidth',2)
                hold on
                plot(xxInt2, yyInt2,'Color',[0.8500 0.3250 0.0980],'linewidth',2)
                
                scatter(xdata1, ydata1, 50, 'filled', 'MarkerFaceColor', [0 0.4470 0.7410])
                scatter(xdata2, ydata2, 50, 'filled', 'MarkerFaceColor', [0.8500 0.3250 0.0980])
                
                line([Data.Processed.VtOpt(Pind2) Data.Processed.VtOpt(Pind2)],[1 maxY],'Color','k','LineWidth',2)
                
                xlabel([xstr],'FontSize',FSize,'FontWeight',"bold")
                %                 ylabel(ystr,'FontSize',FSize,'FontWeight',"bold")
                
                top = 200*ceil(max(xdata1)/200);
                if top > 1500
                    xticks(0:200:top)
                else
                    xticks(0:100:top)
                end
                xtickangle(90)
                yticks(10.^maxXlog)
                xlim([0 top])
                ylim([0 maxY])
                set(gca,'FontSize',FSize,'yscale','log','box','on','LineWidth',2,'ygrid','on','xgrid','on','gridlinestyle','-','minorgridlinestyle','none');
                
            end
        end
        
    case 'overlay'
        col = cbrewer('div', 'Spectral', numel(Names.ParNames));
        for i = 1:numel(Names.ParNames)
            
            Pind = find(contains(unique(Names.ParNames,'stable'), Names.ParNames(i)));
            
            ydata1 = Data.SD(yInd1, Pind).^2;
            ydata2 = Data.SD(yInd2, Pind).^2;
            ratio = ydata1./ydata2;
            ystr = 'SD^2';
            
            xdata1 = Data.Vt(yInd1, Pind);
            xstr = 'Voltage';
            
            plot(xdata1, ratio,'color',col(i,:))
            
            hold on
            
        end
        xlabel(xstr,'FontSize',14,'FontWeight',"bold")
        ylabel(ystr,'FontSize',14,'FontWeight',"bold")
        box('on')
        grid('minor')
        set(gca,'FontSize',14,'yscale','log');
        legend(Names.ParNames,'Location','northeastoutside')
        top = 200*ceil(max(xdata1)/200);
        if top > 1500
            xticks([0:200:top])
        else
            xticks([0:100:top])
        end
        xtickangle(90)
        xlim([0 top])
        
    case 'Signal'
        Combs = strcat(Names.TestCond,Names.LaserStat,Names.LED);
        CombsUnq = unique(Combs,'stable');
        t=  tiledlayout(PlotNo,PlotWid);
        t.TileSpacing = 'compact';
        t.Padding = 'none';
        t.YLabel.String = 'Normalized Intensity';
        t.YLabel.FontSize = 16;
        t.YLabel.FontWeight = 'bold';
        for i = 1:numel(Names.ParNames)
            nexttile
            Pind = find(contains(unique(Names.ParNames,'stable'), Names.ParNames(i)));
            
            for ii = 1:numel(CombsUnq)
                Ind = contains(Combs, CombsUnq{ii});
                PlotDataX(:,ii) = Data.Vt(Ind,Pind);
                PlotDataY(:,ii) = Data.Med(Ind,Pind);
            end
            
            for iii = 1:size(PlotDataX,2)
                col = lines(size(PlotDataX,2));
                scatter(PlotDataX(:,iii), PlotDataY(:,iii)./PlotDataY(:,4),500,'Marker','.','MarkerFaceColor',col(iii,:))
                hold on
            end
            
            xlabel([Names.ParNames{i},' Voltage'],'FontSize',FSize,'FontWeight',"bold")
            yticklabels('')
            box('on')
            grid('minor')
            set(gca,'FontSize',FSize,'yscale','log');
            
            top = max(PlotDataX(:));
            if top > 1500
                xticks(0:200:top)
            else
                xticks(0:100:top)
            end
            xtickangle(90)
            xlim([0 top])
        end
    case 'Area Scaling'
        ind = ~contains(LData.ParNames(1,:),'Time');
        TestCondInd = ~contains(Names.TestCond,'B');
        [ParNameInd] = unique(replace(LData.ParNames(1,ind),{'-A','-H'},''),'stable');
        ParNamePairs = [];
        for i = 1:numel(ParNameInd)
            if sum(contains(LData.ParNames(1,:),ParNameInd{i})) == 2
                ParNamePairs{numel(ParNamePairs)+1} = ParNameInd{i};
            else
            end
        end
        for i = 1:numel(ParNamePairs)
            Parind = contains(LData.ParNames(1,:),ParNamePairs{i});
            MedStats = LData.Med(TestCondInd,Parind);
            ydata(:,i) = log10(MedStats(:,2)./MedStats(:,1));
            xdata(:,i) = normrnd(i, 0.1, size(MedStats,1),1);
        end
        
        scatter(xdata(:), ydata(:),20, 'ob','filled')
        hold on
        line([0 numel(ParNamePairs)+1], [0 0],'Color', 'k','LineWidth',2,'LineStyle',':')
        xlim([0 numel(ParNamePairs)+1])
        xticklabels(ParNamePairs)
        xticks(1:numel(ParNamePairs))
        xtickangle(90)
        ylabel('Area/Height (log_{10})','FontWeight','bold','FontSize',14)
        xlabel('Parameters','FontWeight','bold','FontSize',14)
        set(gca,'box','on','LineWidth',2,'FontSize',14,'ticklength',[0 0])
        
        if max(ydata(:)) > 0
            ylim([-0.5 inf])
            if max(ydata(:)) < 0.5
                ylim([-0.5 0.5])
            end
        end
        
end
sgtitle([LData.ID, ' | ' , datestr(LData.AcqDate(1))],'FontSize',18,'FontWeight','bold')
fig.Visible = 'off';
end

