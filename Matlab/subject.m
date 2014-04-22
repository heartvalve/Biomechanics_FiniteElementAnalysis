classdef subject < handle
    % SUBJECT - A class to store all modeling simulations for a subject.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-14


    %% Properties
    % Properties for the subject class

    properties (SetAccess = protected)
        Cycles          % Cycles (individual trials)
    end
    properties (Hidden = true, SetAccess = private)
        SubID           % Subject ID
        SubDir          % Directory where files are stored
        Group           % Group
    end


    %% Methods
    % Methods for the subject class

    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = subject(subID)
            % SUBJECT - Construct instance of class
            %

            % Subject ID
            obj.SubID = subID;
            % Subject directory
            obj.SubDir = Abaqus.getSubjectDir(subID);
            % Group
            if strcmp(subID(9),'C')
                obj.Group = 'Control';
            elseif strcmp(subID(10),'H')
                obj.Group = 'HamstringACL';
            elseif strcmp(subID(10),'P')
                obj.Group = 'PatellaACL';
            end
            % Identify simulation names
            allProps = properties(obj);
            simNames = allProps(1:end-1);
            % Preallocate and do a parallel loop
            tempData = cell(length(simNames),1);
            parfor i = 1:length(simNames)
                % Create simulation object
                tempData{i} = Abaqus.simulation(subID,simNames{i});                
            end
            % Assign properties
            for i = 1:length(simNames)
                obj.(simNames{i}) = tempData{i};
            end
            % -------------------------------------------------------------
            %       Individual Simulations
            % -------------------------------------------------------------
            sims = properties(obj);
            checkSim = @(x) isa(obj.(x{1}),'Abaqus.simulation');
            sims(~arrayfun(checkSim,sims)) = [];
            cstruct = struct();
            % Loop through simulations
            for i = 1:length(sims)
                cycleName = sims{i}(3:end-3);                
                % Check if field exists (if not, create)
                if ~isfield(cstruct,cycleName)
                    cstruct.(cycleName) = struct();
                    % Simulation 
                    cstruct.(cycleName).Simulations = {sims{i}};                            
                    % Kinematics
                    cstruct.(cycleName).Kinematics = obj.(sims{i}).SimKIN.Data;
                    % Contact Average Location
                    cstruct.(cycleName).CPAvg_TL = obj.(sims{i}).CP_TL.Avg;
                    cstruct.(cycleName).CPAvg_TM = obj.(sims{i}).CP_TM.Avg;
                    cstruct.(cycleName).CPAvg_TLregion = obj.(sims{i}).CP_TLregion.Avg;
                    cstruct.(cycleName).CPAvg_TMregion = obj.(sims{i}).CP_TMregion.Avg;
                    cstruct.(cycleName).CPAvg_PL = obj.(sims{i}).CP_PL.Avg;
                    cstruct.(cycleName).CPAvg_PM = obj.(sims{i}).CP_PM.Avg;
                    % Contact Maximum - Location and Value
                    cstruct.(cycleName).CPMax_TL = obj.(sims{i}).CP_TL.Max;
                    cstruct.(cycleName).CPMax_TM = obj.(sims{i}).CP_TM.Max;
                    cstruct.(cycleName).CPMax_TLregion = obj.(sims{i}).CP_TLregion.Max;
                    cstruct.(cycleName).CPMax_TMregion = obj.(sims{i}).CP_TMregion.Max;   
                    cstruct.(cycleName).CPMax_PL = obj.(sims{i}).CP_PL.Max;
                    cstruct.(cycleName).CPMax_PM = obj.(sims{i}).CP_PM.Max;
                % If field exists, append new to existing
                else
                    % Simulations
                    oldNames = cstruct.(cycleName).Simulations;
                    cstruct.(cycleName).Simulations = [oldNames; {sims{i}}];
                    % Kinematics
                    oldK = cstruct.(cycleName).Kinematics;
                    newK = obj.(sims{i}).SimKIN.Data;
                    kProps = newK.Properties.VarNames;
                    for m = 1:length(kProps)
                        newK.(kProps{m}) = [oldK.(kProps{m}) newK.(kProps{m})];
                    end
                    cstruct.(cycleName).Kinematics = newK;
                    % Contact Average Location
                    vars = {'TL','TM','TLregion','TMregion','PL','PM'};
                    for v = 1:length(vars)
                        oldC = cstruct.(cycleName).(['CPAvg_',vars{v}]);
                        newC = obj.(sims{i}).(['CP_',vars{v}]).Avg;
                        cProps = newC.Properties.VarNames;
                        for m = 1:length(cProps)
                            newC.(cProps{m}) = [oldC.(cProps{m}) newC.(cProps{m})];
                        end
                        cstruct.(cycleName).(['CPAvg_',vars{v}]) = newC;
                    end
                    % Contact Maximum - Location and Value
                    for v = 1:length(vars)
                        oldC = cstruct.(cycleName).(['CPMax_',vars{v}]);
                        newC = obj.(sims{i}).(['CP_',vars{v}]).Max;
                        cProps = newC.Properties.VarNames;
                        for m = 1:length(cProps)
                            newC.(cProps{m}) = [oldC.(cProps{m}) newC.(cProps{m})];
                        end
                        cstruct.(cycleName).(['CPMax_',vars{v}]) = newC;
                    end                            
                end

            end
            % Convert structure to dataset
            varnames = {'Simulations','Kinematics','CPAvg_TL','CPAvg_TM','CPAvg_TLregion','CPAvg_TMregion','CPAvg_PL','CPAvg_PM',...
                                                'CPMax_TL','CPMax_TM','CPMax_TLregion','CPMax_TMregion','CPMax_PL','CPMax_PM'};
            obsnames = fieldnames(cstruct);
            cdata = cell(length(obsnames),length(varnames));
            cdataset = dataset({cdata,varnames{:}});
            for i = 1:length(obsnames)
                for j = 1:length(varnames)
                    cdataset{i,j} = cstruct.(obsnames{i}).(varnames{j});
                end
            end
            cdataset = set(cdataset,'ObsNames',obsnames);
            % Assign property
            obj.Cycles = cdataset;
        end
    end

end
