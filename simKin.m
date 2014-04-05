classdef simKin < handle
    % SIMKIN
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-04
    
    
    %% Properties
    % Properties for the simKin class
    
    properties (SetAccess = private)
        SimTime
        Data
    end
    
    
    %% Methods
    % Methods for the simKin class
    
    methods
        function obj = simKin(subID,simName)
            % SIMKIN - Construct instance of class
            %
            
            % SIMKIN path
            kinPath = [Abaqus.getSubjectDir(subID),subID,'_',simName,'_KIN.data'];
            % Import the file
            kinimport = importdata(kinPath,' ',1);
            % Column headers
            kinnames = kinimport.colheaders(2:end);
            % Time
            timedata = kinimport.data(26:end,1)-kinimport.data(26,1);
            obj.SimTime = timedata;
            % Data
            kindataset = dataset({kinimport.data(26:end,2:end),kinnames{:}});
            obj.Data = kindataset;
        end
    end
    
end

