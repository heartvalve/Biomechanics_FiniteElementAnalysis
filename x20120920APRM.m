classdef x20120920APRM < Abaqus.subject
    % X20120920APRM - A class to store all simulations for subject 20120920APRM
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-13

    
    %% Properties
    % Properties for the x20120920APRM class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
        A_SD2S_01      
        A_SD2S_03
    end


    %% Methods
    % Methods for the x20120920APRM class

    methods
        function obj = x20120920APRM()
            % X20120920APRM - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20120920APRM');
        end
    end


end
