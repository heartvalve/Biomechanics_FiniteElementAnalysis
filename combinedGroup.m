classdef combinedGroup < Abaqus.group
    % COMBINEDGROUP - A class to store all aclR subjects.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-11


    %% Properties
    % Properties for the combinedGroup class

    properties
        x20120912AHRF
        x20121008AHRM
        x20121108AHRM
        x20121110AHRM
        x20130401AHLM
        x20120919APLF
%         x20120920APRM
        x20121204APRM
%         x20130207APRM
    end


    %% Methods
    % Methods for the combinedGroup class

    methods
        function obj = combinedGroup()
            % COMBINEDGROUP - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.group();
            % Add group ID
            obj.GroupID = 'Combined';
        end
    end

end
