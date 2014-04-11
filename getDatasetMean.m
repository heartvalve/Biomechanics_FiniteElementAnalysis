function dsMean = getDatasetMean(dSet)
    % GETDATASETMEAN
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-10
    
    
    %% Main
    % Main function definition
    
    dsnames = dSet.Properties.VarNames;        
    newdata = zeros(size(dSet));
    for i = 1:length(dsnames)
        newdata(:,i) = mean(dSet.(dsnames{i}),2);
    end
    dsMean = dataset({newdata,dsnames{:}});
    
end
