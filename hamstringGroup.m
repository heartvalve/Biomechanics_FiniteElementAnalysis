classdef hamstringGroup < Abaqus.group
    % HAMSTRINGGROUP - A class to store all hamstring tendon subjects.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-02


    %% Properties
    % Properties for the hamstringGroup class

    properties
        x20120912AHRF
        x20121008AHRM
        x20121108AHRM
        x20121110AHRM
        x20130401AHLM
    end


    %% Methods
    % Methods for the hamstringGroup class

    methods
        function obj = hamstringGroup()
            % HAMSTRINGGROUP - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.group();
            % Add group ID
            obj.GroupID = 'HamstringACL';
        end
    end

end
