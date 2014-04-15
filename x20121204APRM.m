classdef x20121204APRM < Abaqus.subject
    % X20121204APRM - A class to store all simulations for subject 20121204APRM
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-14


    %% Properties
    % Properties for the x20121204APRM class

    properties
        % A_Walk_01
        % A_Walk_02
        % A_Walk_03 
        % A_Walk_04
        % A_Walk_05
        A_SD2S_01
        A_SD2S_02
        A_SD2S_03
        A_SD2S_04
        A_SD2S_05        
    end


    %% Methods
    % Methods for the x20121204APRM class

    methods
        function obj = x20121204APRM()
            % X20121204APRM - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20121204APRM');
        end
    end


end
