classdef x20120912AHRF < Abaqus.subject
    % X20120912AHRF - A class to store all simulations for subject 20120912AHRF
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-13


    %% Properties
    % Properties for the x20120912AHRF class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
        A_Walk_05        
        A_SD2S_01
        A_SD2S_02
        A_SD2S_03
        A_SD2S_04
        A_SD2S_05        
    end


    %% Methods
    % Methods for the x20120912AHRF class

    methods
        function obj = x20120912AHRF()
            % X20120912AHRF - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20120912AHRF');
        end
    end


end
