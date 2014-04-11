classdef controlGroup < Abaqus.group
    % CONTROLGROUP - A class to store all control subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-10
    
    
    %% Properties
    % Properties for the controlGroup class
    
    properties
        x20121204CONF
        x20121205CONF
        x20121205CONM
        x20121206CONF
        x20130221CONF
%         x20130401CONM
    end
    
    
    %% Methods
    % Methods for the controlGroup class
    
    methods
        function obj = controlGroup()
            % CONTROLGROUP - Construct instance of class
            %
            
            % Create instance of class from superclass
            obj = obj@Abaqus.group();
            % Add group ID
            obj.GroupID = 'Control';            
        end
    end
    
end
