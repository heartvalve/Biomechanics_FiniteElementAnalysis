function subDir = getSubjectDir(subID)
    % GETSUBJECTDIR - A function to get the Abaqus subject directory.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-02


    %% Main
    % Main function definition

    % Subject directory
    wpath = regexp(pwd,'Northwestern-RIC','split');
    subDir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'Abaqus',...
              filesep,'Subjects',filesep,subID,filesep];

end
