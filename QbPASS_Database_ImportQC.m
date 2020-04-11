function [LData]=QbPASS_Database_ImportQC(LData)

%% check there are an equal number of voltages across datasets
ParIn = ~contains(LData.ParNames(1,:), {'FSC','SSC','Time'});
Pars = LData.ParNames(1,ParIn);
UniqueVt = unique(LData.Vt(:,ParIn));
Vts = LData.Vt(:,ParIn);

for i = 1:numel(UniqueVt)
    NumVt(1,i) = UniqueVt(i);
    NumVt(2,i) = sum(Vts(:) == UniqueVt(i));
end

%% if unequal remove
if numel(unique(NumVt(2,:))) == 1
else
    ind =  NumVt(1,(NumVt(2,:)<max(NumVt(2,:))));
    [rind, ~]=find(LData.Vt == ind);
    
    LData.Range(rind, :) = [];
    LData.ParNames(rind, :) = [];
    LData.SD(rind, :) = [];
    LData.CV(rind, :) = [];
    LData.Med(rind, :) = [];
    LData.Vt(rind, :) = [];
    LData.LaserState(rind) = [];
    LData.TestCond(rind) = [];
    LData.PulserInt(rind) = [];
    LData.Voltage(rind) = [];
end

end