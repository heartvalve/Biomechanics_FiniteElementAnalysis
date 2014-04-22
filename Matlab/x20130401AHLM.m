classdef x20130401AHLM < Abaqus.subject
    % X20130401AHLM - A class to store all simulations for subject 20130401AHLM
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-13


    %% Properties
    % Properties for the x20130401AHLM class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_05        
        A_SD2S_01
        A_SD2S_02
        A_SD2S_03
        A_SD2S_04
        A_SD2S_05        
    end


    %% Methods
    % Methods for the x20130401AHLM class

    methods
        function obj = x20130401AHLM
            % X20130401AHLM - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20130401AHLM');
        end
    end


end
