function subDir = getSubjectDir(subID)
    % GETSUBJECTDIR - A function to get the Abaqus subject directory.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-09


    %% Main
    % Main function definition

    % Subject directory
    wpath = regexp(pwd,'Northwestern-RIC','split');
    subDir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'Abaqus',...
              filesep,'Subjects_NeoHookean',filesep,subID,filesep];
%     subDir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'Abaqus',...
%               filesep,'Subjects',filesep,subID,filesep];          
% %     subDir = [wpath{1},'Northwestern-RIC',filesep,'SVN',filesep,'Working',...
% %               filesep,'FiniteElement',filesep,'Subjects',filesep,subID,filesep];

end
