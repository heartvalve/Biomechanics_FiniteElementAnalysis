classdef simKin < handle
    % SIMKIN
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-09
    
    
    %% Properties
    % Properties for the simKin class
    
    properties (SetAccess = private)
        PerCycle    % Percent of cycle
        Raw         % Raw data
        Data        % Smoothed
    end
    properties (SetAccess = public)
        Exp         % Compare to experiment (shifted)
    end
    
    
    %% Methods
    % Methods for the simKin class
    
    methods
        function obj = simKin(subID,simName)
            % SIMKIN - Construct instance of class
            %
            
            % Path
            kinPath = [Abaqus.getSubjectDir(subID),subID,'_',simName,'_KIN.data'];
            % Import the file
            kinimport = importdata(kinPath,' ',1);
            % Column headers
            kinnames = kinimport.colheaders(2:end);
            % Percent cycle
            obj.PerCycle = kinimport.data(:,1);
            % Raw Data
            kindataset = dataset({kinimport.data(:,2:end),kinnames{:}});
            obj.Raw = kindataset;
            % Smoothed Data
            smoothData = zeros(size(kinimport.data(:,2:end)));
            for i = 1:size(smoothData,2)
                smoothData(:,i) = smooth(kinimport.data(:,i+1),13,'sgolay');
            end
            smoothDS = dataset({smoothData,kinnames{:}});
            obj.Data = smoothDS;
        end
    end
    
end
