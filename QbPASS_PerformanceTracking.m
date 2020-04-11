function QbPASS_PerformanceTracking(Data)

ParNames = Data{1}.Summary.ParName;

for i = 1:numel(Data)-1
    ind = i + 1;
    ParNames = ParNames(ismember(ParNames,Data{ind}.Summary.ParName));
end

xData = 1:numel(ParNames);
figure('Units','Normalized','Position',[0 0.7063 1.0000 0.2367]);
for i = 1:numel(Data)
    VtInd = find(ismember(ParNames, Data{i}.Summary.ParName));
    yData = Data{i}.Summary.VtOpt(VtInd);
    AcqDate{i} = datestr(Data{i}.AcqDate(1),'dd mmm yyyy');
    
    scatter(xData, yData, 80, 'o','filled')
    hold on
end

set(gca,'box','on','linewidth',2,'FontSize',12,'TickLength',[0.005 0.005],'TickDir','out')
xlabel('Parameter','FontSize',14,'FontWeight','bold')
ylabel('Min Voltage', 'FontSize',14,'FontWeight','bold')
xticks(xData)
xticklabels(ParNames)
xtickangle(90)
xlim([0 numel(xData)+1])
legend(AcqDate,'FontSize',14,'location','eastoutside')


end