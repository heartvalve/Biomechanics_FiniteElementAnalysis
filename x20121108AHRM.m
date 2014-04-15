classdef x20121108AHRM < Abaqus.subject
    % X20121108AHRM - A class to store all simulations for subject 20121108AHRM
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-14


    %% Properties
    % Properties for the x20121108AHRM class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
        A_Walk_05
%         A_SD2S_01  lat cartilage
        A_SD2S_04
    end


    %% Methods
    % Methods for the x20121108AHRM class

    methods
        function obj = x20121108AHRM()
            % X20121108AHRM - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@Abaqus.subject('20121108AHRM');
        end
    end


end
