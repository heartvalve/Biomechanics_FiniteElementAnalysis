function dsStdDev = getDatasetStdDev(dSet)
    % GETDATASETSTDDEV
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-10
    
    
    %% Main
    % Main function definition
    
    dsnames = dSet.Properties.VarNames;
    newdata = zeros(size(dSet));
    for i = 1:length(dsnames)
        if size(dSet.(dsnames{i}),2) > 2
            newdata(:,i) = nanstd(dSet.(dsnames{i}),0,2);
        else
            newdata(:,i) = zeros(size(newdata,1),1);
        end
    end
    dsStdDev = dataset({newdata,dsnames{:}});

end
