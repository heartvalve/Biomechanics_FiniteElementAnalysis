classdef expKin < handle
    % EXPKIN
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-04
    
    %% Properties
    % Properties for the expKin class
    
    properties (SetAccess = private)
        PerCycle
        Data
    end
    
    
    %% Methods
    % Methods for the expKin class
    
    methods
        function obj = expKin(subID,simName)
            % EXPKIN - Construct instance of class
            %
            
            % EXPKIN path
            kinPath = [Abaqus.getSubjectDir(subID),subID,'_',simName,'_EXP.data'];
            % Import the file
            kinimport = importdata(kinPath,'\t',1);
            % Column headers
            kinnames = kinimport.colheaders(2:end);
            % Percent cycle
            cycledata = kinimport.data(:,1);
            obj.PerCycle = cycledata;
            % Data
            kindataset = dataset({kinimport.data(:,2:end),kinnames{:}});
            obj.Data = kindataset;
        end
    end
    
end

