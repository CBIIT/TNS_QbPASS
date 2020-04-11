function QbPASS_SaveDataset(app)
path = char(getpref('QbPASS','FileDirectory'));
name = char([app.CytometersListBox.Items{app.CytometersListBox.Value},' Database.mat']);
filename = char(fullfile(path,name));

ID = ['D_',num2str(datenum(app.LoadedDataset.AcqDate(1)))];
Database.(ID) = app.LoadedDataset;
Database.(ID).Summary = app.Summary;
Database.(ID).OptiStats = app.OptiStats;
Database.(ID).VoltTNames = app.TData;
Database.(ID).VoltTData = app.UITable2.Data;                      

save(filename,'-struct','Database','-append')

                            
end