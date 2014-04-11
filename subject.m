classdef subject < handle
    % SUBJECT - A class to store all modeling simulations for a subject.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-10


    %% Properties
    % Properties for the subject class

    properties (SetAccess = private)
        Walk            % Walking simulation
        SD2S            % Stair descent simulation
    end
    properties (Hidden = true, SetAccess = private)
        SubID           % Subject ID
        SubDir          % Directory where files are stored
        Group           % Group
%         ScaleFactor     % Mass of subject in kg (from personal information file) / Mass of generic model (75.337 kg)
    end


    %% Methods
    % Methods for the subject class

    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = subject(subID)
            % SUBJECT - Construct instance of class
            %

            % Subject ID
            obj.SubID = subID;
            % Subject directory
            obj.SubDir = Abaqus.getSubjectDir(subID);
            % Group
            if strcmp(subID(9),'C')
                obj.Group = 'Control';
            elseif strcmp(subID(10),'H')
                obj.Group = 'HamstringACL';
            elseif strcmp(subID(10),'P')
                obj.Group = 'PatellaACL';
            end
            % Walking simulation
            try 
                obj.Walk = Abaqus.simulation(subID,'Walk');                
            catch err
                obj.Walk = [];
            end
            % Stair descent simulation
            try
                obj.SD2S = Abaqus.simulation(subID,'SD2S');
            catch err
                obj.SD2S = [];
            end
            % ---------------
            % % Scale factor for subject
            % xmlFile = [obj.SubDir,filesep,obj.SubID,'__PersonalInformation.xml'];
            % domNode = xmlread(xmlFile);
            % mNodeList = domNode.getElementsByTagName('mass');
            % mass = str2double(char(mNodeList.item(0).getFirstChild.getData));
            % obj.ScaleFactor = mass/75.337;
        end
    end

end
