classdef simulation < handle
    % SIMULATION - A class to store an Abaqus modeling simulation.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-02
    
    
    %% Properties
    % Properties for the simulation class
    
    properties (SetAccess = private)        
        SubID               % Subject ID
        SimName             % Simulation name
    end
    properties (Hidden = true, SetAccess = private)
        SubDir              % Directory where files are stored
    end
    
    
    %% Methods
    % Methods for the simulation class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = simulation(subID,simName)
            % SIMULATION - Construct instance of class
            %
            
            % Subject ID
            obj.SubID = subID;
            % Simulation name (without subject ID)
            obj.SimName = simName;
            % Subject directory
            obj.SubDir = Abaqus.getSubjectDir(subID);            
        end        
    end
    
end

