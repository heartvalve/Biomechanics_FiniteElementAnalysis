classdef x20120919APLF < Abaqus.subject
    % X20120919APLF - A class to store all simulations for subject 20120919APLF
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-13


    %% Properties
    % Properties for the x20120919APLF class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
        A_Walk_04        
        A_SD2S_01
        A_SD2S_02
        A_SD2S_03
        A_SD2S_04
        A_SD2S_05        
    end


    %% Methods
    % Methods for the x20120919APLF class

    methods
        function obj = x20120919APLF()
            % X20120919APLF - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20120919APLF');
        end
    end


end
