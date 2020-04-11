function [Pref] = QbPASS_Preference_Check(Version, GUI)

if ispref('QbPASS') == 1 % if QbPASS preferences exist
    
    FileDirectoryCheck(GUI) % Check file directory from preferences
    if ispref('QbPASS','version') == 1
    else
        setpref('QbPASS','version', Version)
    end
    PrefVersionUpdate(Version)
    
else
    
    PrefVersionUpdate(Version)
    
    [answer] = DirectoryDlg(GUI);
    
    
    % Handle response
    switch answer
        case 'Select Directory'
            selpath = uigetdir;
            if selpath == 0
            else
                setpref('QbPASS','FileDirectory',selpath)
            end
            
    end
end

Pref = getpref('QbPASS');  % retrieve preferences

end


function PrefVersionUpdate(Version)

Prefs = {'GUI_ExtPlot','on';...
    'ExclusionParameters',{'FSC','SSC','Time'};...
    'Threshold_Phi',0.8;...
    'Threshold_Grad',50;...
    'Threshold_Channel',50;...
    'FigLabel_FontSize', 'default';...
    'FigLabel_FontWeight', 'bold';...
    'Fig_Tick_FontSize', 'default';...
    'Fig_Tick_FontWeight', 'normal';...
    'FigTitle_FontSize', 'default';...
    'FigTitle_FontWeight', 'bold';...
    'FigAxes_FontSize', 'default';...
    'FigAxes_FontWeight', 'normal';...
    'FigLabel_FontSize', 'default';...
    'FigLabel_FontWeight', 'bold';...
    'VoltPlotStat', 'SD^2'};

if ispref('QbPASS','version') == 1
    if getpref('QbPASS','version') == Version
    else
        setpref('QbPASS','version', Version)
        
        for i = 1:size(Prefs,1)
            
            if ispref('QbPASS',Prefs{i,1}) == 1
            else
                setpref('QbPASS', Prefs{i,1}, Prefs{i,2})
            end
            
        end
    end
else
    setpref('QbPASS','version', Version)
    
    for i = 1:size(Prefs,1)
        
        if ispref('QbPASS',Prefs{i,1}) == 1
        else
            setpref('QbPASS', Prefs{i,1}, Prefs{i,2})
        end
        
    end
end

end

function [answer] = DirectoryDlg(GUI)
answer = uiconfirm(GUI,{'A folder containing your database files has not been found.', newline,'Select a folder where your database files are located or where you would like them saved'}, ...
    'Specify Directory','Options',{'Select Directory'},'Icon','warning');
end