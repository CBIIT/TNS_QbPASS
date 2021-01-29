function QbPASS_SaveDataset(app)

path = char(getpref('QbPASS','FileDirectory'));
folder = app.CytometersListBox.Items{app.CytometersListBox.Value};
date = ['D_',num2str(datenum(app.LoadedDataset.AcqDate(1)))];
filename = char(fullfile(path,folder,[date,'.mat']));

Database = app.LoadedDataset;
Database.Summary = app.Summary;
Database.OptiStats = app.OptiStats;
Database.VoltTNames = app.TData;
Database.VoltTData = app.UITable2.Data;                      
Database.PhiThreshold = app.PhiThresholdEditField.Value;
save(filename,'Database')
                            
end

