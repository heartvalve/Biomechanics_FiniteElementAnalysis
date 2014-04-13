classdef group < handle
    % GROUP - A class to store all subjects (and simulations) for a specific population group
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-10


    %% Properties
    % Properties for the group class

    properties (SetAccess = private)
        Cycles          % Individual subject simulations
        Summary         % Summary of subjects
    end
    properties (Hidden = true, SetAccess = protected)
        GroupID         % Group type
    end


    %% Methods
    % Methods for the group class

    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = group()
            % GROUP - Construct instance of class
            %

            % Properties of current group subclass
            allProps = properties(obj);
            % Subject properties
            subjects = allProps(strncmp(allProps,'x',1));
            % Preallocate and do a parallel loop
            tempData = cell(length(subjects),1);
            parfor j = 1:length(subjects)
                % Subject class
                subjectClass = str2func('Abaqus.subject');
                % Create subject object
                tempData{j} = subjectClass(subjects{j}(2:end));
            end
            % Assign subjects as properties
            for i = 1:length(subjects)
                obj.(subjects{i}) = tempData{i};
            end
            % -------------------------------------------------------------
            %       Subject Simulations
            % -------------------------------------------------------------
            cstruct = struct();
            cycleNames = {'Walk','SD2S'};
            % Loop through subjects
            for j = 1:length(subjects)
                % Loop through cycles
                for k = 1:length(cycleNames)
                    % Make sure simulation didn't crash
                    if ~isempty(obj.(subjects{j}).(cycleNames{k}))
                        % Check if field exists (if not, create)
                        if ~isfield(cstruct,cycleNames{k})
                            cstruct.(cycleNames{k}) = struct();
                            % Subject 
                            cstruct.(cycleNames{k}).Subjects = {obj.(subjects{j}).SubID};                            
                            % Kinematics
                            cstruct.(cycleNames{k}).Kinematics = obj.(subjects{j}).(cycleNames{k}).SimKIN.Data;
                            % Contact Average Location
                            cstruct.(cycleNames{k}).CPAvg_TL = obj.(subjects{j}).(cycleNames{k}).CP_TL.Avg;
                            cstruct.(cycleNames{k}).CPAvg_TM = obj.(subjects{j}).(cycleNames{k}).CP_TM.Avg;
                            cstruct.(cycleNames{k}).CPAvg_TLregion = obj.(subjects{j}).(cycleNames{k}).CP_TLregion.Avg;
                            cstruct.(cycleNames{k}).CPAvg_TMregion = obj.(subjects{j}).(cycleNames{k}).CP_TMregion.Avg;
                            cstruct.(cycleNames{k}).CPAvg_PL = obj.(subjects{j}).(cycleNames{k}).CP_PL.Avg;
                            cstruct.(cycleNames{k}).CPAvg_PM = obj.(subjects{j}).(cycleNames{k}).CP_PM.Avg;
                            % Contact Maximum - Location and Value
                            cstruct.(cycleNames{k}).CPMax_TL = obj.(subjects{j}).(cycleNames{k}).CP_TL.Max;
                            cstruct.(cycleNames{k}).CPMax_TM = obj.(subjects{j}).(cycleNames{k}).CP_TM.Max;
                            cstruct.(cycleNames{k}).CPMax_TLregion = obj.(subjects{j}).(cycleNames{k}).CP_TLregion.Max;
                            cstruct.(cycleNames{k}).CPMax_TMregion = obj.(subjects{j}).(cycleNames{k}).CP_TMregion.Max;   
                            cstruct.(cycleNames{k}).CPMax_PL = obj.(subjects{j}).(cycleNames{k}).CP_PL.Max;
                            cstruct.(cycleNames{k}).CPMax_PM = obj.(subjects{j}).(cycleNames{k}).CP_PM.Max;
                        % If field exists, append new to existing
                        else
                            % Subject
                            oldNames = cstruct.(cycleNames{k}).Subjects;
                            newName = {obj.(subjects{j}).SubID};
                            cstruct.(cycleNames{k}).Subjects = [oldNames; newName];
                            % Kinematics
                            oldK = cstruct.(cycleNames{k}).Kinematics;
                            newK = obj.(subjects{j}).(cycleNames{k}).SimKIN.Data;
                            kProps = newK.Properties.VarNames;
                            for m = 1:length(kProps)
                                newK.(kProps{m}) = [oldK.(kProps{m}) newK.(kProps{m})];
                            end
                            cstruct.(cycleNames{k}).Kinematics = newK;
                            % Contact Average Location
                            vars = {'TL','TM','TLregion','TMregion','PL','PM'};
                            for v = 1:length(vars)
                                oldC = cstruct.(cycleNames{k}).(['CPAvg_',vars{v}]);
                                newC = obj.(subjects{j}).(cycleNames{k}).(['CP_',vars{v}]).Avg;
                                cProps = newC.Properties.VarNames;
                                for m = 1:length(cProps)
                                    newC.(cProps{m}) = [oldC.(cProps{m}) newC.(cProps{m})];
                                end
                                cstruct.(cycleNames{k}).(['CPAvg_',vars{v}]) = newC;
                            end
                            % Contact Maximum - Location and Value
                            for v = 1:length(vars)
                                oldC = cstruct.(cycleNames{k}).(['CPMax_',vars{v}]);
                                newC = obj.(subjects{j}).(cycleNames{k}).(['CP_',vars{v}]).Max;
                                cProps = newC.Properties.VarNames;
                                for m = 1:length(cProps)
                                    newC.(cProps{m}) = [oldC.(cProps{m}) newC.(cProps{m})];
                                end
                                cstruct.(cycleNames{k}).(['CPMax_',vars{v}]) = newC;
                            end                            
                        end                
                    end
                end
            end
            % Convert structure to dataset
            varnames = {'Subjects','Kinematics','CPAvg_TL','CPAvg_TM','CPAvg_TLregion','CPAvg_TMregion','CPAvg_PL','CPAvg_PM',...
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
            % -------------------------------------------------------------
            %       Summary
            % -------------------------------------------------------------
            % Set up struct
            sumStruct = struct();
            varnames = {'Kinematics','CPAvg_TL','CPAvg_TM','CPAvg_TLregion','CPAvg_TMregion','CPAvg_PL','CPAvg_PM',...
                                     'CPMax_TL','CPMax_TM','CPMax_TLregion','CPMax_TMregion','CPMax_PL','CPMax_PM'};
            obsnames = get(cdataset,'ObsNames');
            % Averages and standard deviations
            adata = cell(length(obsnames),length(varnames));
            sdata = cell(length(obsnames),length(varnames));
            adataset = dataset({adata,varnames{:}});
            sdataset = dataset({sdata,varnames{:}});
            % Calculate
            for i = 1:length(obsnames)
                for j = 1:length(varnames)                    
                    adataset{i,varnames{j}} = Abaqus.getDatasetMean(cdataset{i,varnames{j}});
                    sdataset{i,varnames{j}} = Abaqus.getDatasetStdDev(cdataset{i,varnames{j}});
                end
            end
            adataset = set(adataset,'ObsNames',obsnames);
            sdataset = set(sdataset,'ObsNames',obsnames);
            % Add to struct
            sumStruct.Mean = adataset;
            sumStruct.StdDev = sdataset;
            % Assign property
            obj.Summary = sumStruct;
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotKinematics(obj,varargin)
            %
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.group');
            validCycles = {'Walk','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            validJoints = {'TF','PF'};
            defaultJoint = 'TF';
            checkJoint = @(x) any(validatestring(x,validJoints));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('Joint',defaultJoint,checkJoint);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            set(fig_handle,'Name',['Group Kinematics ',p.Results.Cycle,' - ',p.Results.Joint,' Joint']);
            axes_handles = zeros(1,6);
            for j = 1:6
                axes_handles(j) = subplot(2,3,j);
            end
            % Plot
            figure(fig_handle);
            allNames = obj.Summary.Mean.Kinematics{1}.Properties.VarNames;
            if strcmp(p.Results.Joint,'TF')
                dofs = allNames(1:6);
            elseif strcmp(p.Results.Joint,'PF')
                dofs = allNames(7:12);
            end
            for j = 1:6
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotKinematics(obj,p.Results.Cycle,dofs{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotKinematics(obj,Cycle,DOF)
                %
                %
                
                % Percent cycle
                x = (0:25)';
                % Mean
                h = plot(x,obj.Summary.Mean{Cycle,'Kinematics'}.(DOF),'Color',[0.15,0.15,0.15],'LineWidth',3); hold on;
                set(h,'DisplayName','Mean');
                % Individual subjects
                % Colors
                colors = colormap(hsv(length(obj.Cycles{Cycle,'Subjects'})));  
                for i = 1:length(obj.Cycles{Cycle,'Subjects'})
                    h = plot(x,obj.Cycles{Cycle,'Kinematics'}.(DOF)(:,i),'Color',colors(i,:),'LineWidth',1);
                    set(h,'DisplayName',obj.Cycles{Cycle,'Subjects'}{i});
                end
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);
                % Labels
                title(DOF(4:end),'FontWeight','bold');
                xlabel('% Stance');
                ylabel('Angle / Position');
            end             
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotContact(obj,varargin)
            %
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.group');
            validCycles = {'Walk','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            validTypes = {'Avg','Max'};
            defaultType = 'Avg';
            checkType = @(x) any(validatestring(x,validTypes));
            validAreas = {'TL','TLregion','TM','TMregion'};
            defaultArea = 'TL';
            checkArea = @(x) any(validatestring(x,validAreas));            
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('Type',defaultType,checkType);
            p.addOptional('Area',defaultArea,checkArea);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            set(fig_handle,'Name',['Group Contact ',p.Results.Cycle,' - ',p.Results.Area,' ',p.Results.Type]);
            if strcmp(p.Results.Type,'Avg')
                numplots = 2;
                dofs = {'X','Y'};
            elseif strcmp(p.Results.Type,'Max')
                numplots = 3;
                dofs = {'X','Y','Value'};
            end
            axes_handles = zeros(1,numplots);
            for j = 1:numplots
                axes_handles(j) = subplot(1,numplots,j);
            end
            % Plot
            figure(fig_handle);            
            for j = 1:numplots
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotContact(obj,p.Results.Cycle,p.Results.Type,p.Results.Area,dofs{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotContact(obj,Cycle,Type,Area,DOF)
                %
                %
                
                % Percent cycle
                x = (linspace(0,25,21))';
                % Mean
                h = plot(x,obj.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF),'Color',[0.15,0.15,0.15],'LineWidth',3); hold on;
                set(h,'DisplayName','Mean');
                % Individual subjects
                % Colors
                colors = colormap(hsv(length(obj.Cycles{Cycle,'Subjects'})));  
                for i = 1:length(obj.Cycles{Cycle,'Subjects'})
                    h = plot(x,obj.Cycles{Cycle,['CP',Type,'_',Area]}.(DOF)(:,i),'Color',colors(i,:),'LineWidth',1);
                    set(h,'DisplayName',obj.Cycles{Cycle,'Subjects'}{i});
                end
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);
                % Labels
                title(DOF,'FontWeight','bold');
                xlabel('% Stance');
                ylabel('Position...');
            end        
        end
    end

end
