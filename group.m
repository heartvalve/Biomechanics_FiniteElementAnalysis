classdef group < handle
    % GROUP - A class to store all subjects (and simulations) for a specific population group
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-02


    %% Properties
    % Properties for the group class

    properties (Hidden = true, SetAccess = protected)
        GroupID     % Group type
    end


    %% Methods
    % Methods for the group class

    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = group()
            % GROUP - Construct instance of class
            %

            % Properties of current group subclass
            allProps = properties(obj);
            % Subject properties
            subjects = allProps(strncmp(allProps,'x',1));
            % Preallocate and do a parallel loop
            tempData = cell(length(subjects),1);
            parfor j = 1:length(subjects)
                % Subject class
                subjectClass = str2func('Abaqus.subject');
                % Create subject object
                tempData{j} = subjectClass(subjects{j}(2:end));
            end
            % Assign subjects as properties
            for i = 1:length(subjects)
                obj.(subjects{i}) = tempData{i};
            end
        end
    end

end
