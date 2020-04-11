function QbPASS_ERFTemplateCompare(app)

TVars = app.UITable2.Data(:,1);
switch class(TVars)
    case 'table'
        TVars =  table2cell(TVars);
    otherwise
end


for i = 1:size(app.ERFTemplate,1)
    
    ERFVars = app.ERFTemplate{i,1};
    ind = contains(TVars, ERFVars);
    if max(ind) == 1
        % add ERF
        switch class(app.ERFTemplate{i,2})
            case 'double'
                app.UITable2.Data(ind,3) = {app.ERFTemplate{i,2}};
            otherwise
                app.UITable2.Data(ind,3) = {str2double(app.ERFTemplate{i,2})};
        end
        % add ERF Channel no.
        switch class(app.ERFTemplate{i,3})
            case 'double'
                app.UITable2.Data(ind,4) = {app.ERFTemplate{i,3}};
            otherwise
                app.UITable2.Data(ind,4) = {str2double(app.ERFTemplate{i,3})};
                
        end
        % add cali voltage
        switch class(app.ERFTemplate{i,4})
            case 'double'
                app.UITable2.Data(ind,5) = {app.ERFTemplate{i,4}};
            otherwise
                app.UITable2.Data(ind,5) = {str2double(app.ERFTemplate{i,4})};
                
        end
    else
    end
end

end