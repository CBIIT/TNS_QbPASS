function FileDirectoryCheck(GUI)

if ispref('QbPASS','FileDirectory') == 0
    
    [answer] = DirectoryDlg(GUI);
    
    % Handle response
    switch answer
        case 'Select Directory'
            selpath = uigetdir;
            setpref('QbPASS','FileDirectory',selpath)
            
    end
    FileDirectoryCheck()
    
elseif length(getpref('QbPASS','FileDirectory')) <= 1
    [answer] = DirectoryDlg(GUI);
    
    % Handle response
    switch answer
        case 'Select Directory'
            selpath = uigetdir;
            setpref('QbPASS','FileDirectory',selpath)
    end
    FileDirectoryCheck()
    
elseif exist(getpref('QbPASS','FileDirectory')) == 0
    [answer] = DirectoryDlg(GUI);
    
    
    % Handle response
    switch answer
        case 'Select Directory'
            selpath = uigetdir;
            setpref('QbPASS','FileDirectory',selpath)
    end
    FileDirectoryCheck()
end

end

function [answer] = DirectoryDlg(GUI)
answer = uiconfirm(GUI,{'A folder containing your database files has not been found.', newline,'Select a folder where your database files are located or where you would like them saved'}, ...
    'Specify Directory','Options',{'Select Directory'},'Icon','warning');
end