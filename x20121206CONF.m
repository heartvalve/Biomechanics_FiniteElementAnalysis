classdef x20121206CONF < Abaqus.subject
    % X20121206CONF - A class to store all simulations for subject 20121206CONF
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-13


    %% Properties
    % Properties for the x20121206CONF class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
        A_Walk_04
        A_Walk_05
        % U_Walk_01
        % U_Walk_03
        % U_Walk_04
        % U_Walk_05
        A_SD2S_01
        A_SD2S_02
        A_SD2S_04
        A_SD2S_05
        % U_SD2S_01
        % U_SD2S_02
        % U_SD2S_03
        % U_SD2S_04
        % U_SD2S_05
    end


    %% Methods
    % Methods for the x20121206CONF class

    methods
        function obj = x20121206CONF()
            % X20121206CONF - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20121206CONF');
        end
    end


end
