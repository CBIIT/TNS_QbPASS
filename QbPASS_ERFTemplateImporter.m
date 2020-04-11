function QbPASS_ERFTemplateImporter(app, ImportMethod)

switch ImportMethod
    case 'User'
        
        [file,path] = uigetfile('*.xls');
        if isequal(file,0)
        else
            try
                app.ERFTemplate = readcell(fullfile(path,file));
                QbPASS_ERFTemplateCompare(app)
            catch
                app.ERFTemplate = [];
                uialert(app.Qb,'Import ERF Template','Error importing ERF Template');
            end
        end
        
    case 'Automatic'
        
        % find spreadsheets in same directory
        Files = dir([app.ImportSelpath,'/*.xls']);
        
        Filenames = {Files.name};
        Filepaths = fullfile({Files.folder},{Files.name});
        
        Ind = contains(Filenames,'ERF Template');
        
        
        if sum(Ind) == 1
%             try
                app.ERFTemplate = readcell(Filepaths{Ind});
                
                QbPASS_ERFTemplateCompare(app)
                
%             catch
%                 app.ERFTemplate = [];
%                 uialert(app.Qb,'Import ERF Template','Error importing ERF Template');
%             end
            
        else
        end
        
        
end
end