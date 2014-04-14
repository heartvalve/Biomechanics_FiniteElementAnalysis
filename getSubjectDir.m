function subDir = getSubjectDir(subID)
    % GETSUBJECTDIR - A function to get the Abaqus subject directory.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-13


    %% Main
    % Main function definition

    % Subject directory
    wpath = regexp(pwd,'Northwestern-RIC','split');
    subDir = ['I:\Subjects_TransverseIsotropic',filesep,subID,filesep];
%     subDir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'Abaqus',...
%               filesep,'Subjects',filesep,subID,filesep];

end
