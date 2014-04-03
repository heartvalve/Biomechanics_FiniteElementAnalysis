classdef summary < handle
    % SUMMARY - A class to store all Abaqus data.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-02


    %% Properties
    % Properties for the summary class

    properties (SetAccess = private)
        Control             % Control group
        HamstringACL        % Hamstring tendon ACL-R
        PatellaACL          % Patella tendon ACL-R
    end
    properties (SetAccess = public)
        Statistics          % Group comparison statistics
    end


    %% Methods
    % Methods for the summary class

    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = summary()
            % SUMMARY - Construct instance of class
            %

            % Time
            tic;
            disp('Please wait while the program runs -- it may take a few minutes.');
            % Add groups as properties
            obj.Control = Abaqus.controlGroup();
            obj.HamstringACL = Abaqus.hamstringGroup();
            obj.PatellaACL = Abaqus.patellaGroup();
            % --------------------
            obj.Statistics = Abaqus.getSummaryStatistics(obj);
            % --------------------
            % Elapsed time
            eTime = toc;
            disp(['Elapsed summary processing time is ',num2str(floor(eTime/60)),' minutes and ',num2str(round(mod(eTime,60))),' seconds.']);
        end
    end

end
