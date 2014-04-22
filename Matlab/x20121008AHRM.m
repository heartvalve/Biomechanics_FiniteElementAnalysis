classdef x20121008AHRM < Abaqus.subject
    % X20121008AHRM - A class to store all simulations for subject 20121008AHRM
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-13


    %% Properties
    % Properties for the x20121008AHRM class

    properties
        A_Walk_02
        A_Walk_03
        A_Walk_04
        A_Walk_05
        A_SD2S_01
        A_SD2S_03
        A_SD2S_04
        A_SD2S_05        
    end


    %% Methods
    % Methods for the x20121008AHRM class

    methods
        function obj = x20121008AHRM()
            % X20121008AHRM - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20121008AHRM');
        end
    end


end
