classdef x20121110AHRM < Abaqus.subject
    % X20121110AHRM - A class to store all simulations for subject 20121110AHRM
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-14


    %% Properties
    % Properties for the x20121110AHRM class

    properties
% %         A_Walk_01
% %         A_Walk_02
% %         A_Walk_03
        A_Walk_04
% %         A_Walk_05        
        A_SD2S_01
% %         A_SD2S_02
        A_SD2S_03
        A_SD2S_04
% %         A_SD2S_05        
    end


    %% Methods
    % Methods for the x20121110AHRM class

    methods
        function obj = x20121110AHRM()
            % X20121110AHRM - Construct instance of class
            %

            % Create instance of class from superclass
            readCMCstate = true;
            obj = obj@Abaqus.subject('20121110AHRM');
        end
    end


end
