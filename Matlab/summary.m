classdef summary < handle
    % SUMMARY - A class to store all Abaqus data.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-15


    %% Properties
    % Properties for the summary class

    properties (SetAccess = private)
        Control             % Control group
        HamstringACL        % Hamstring tendon ACL-R
        PatellaACL          % Patellar tendon ACL-R
    end
    properties (SetAccess = public)
        Statistics          % Group comparison statistics
    end


    %% Methods
    % Methods for the summary class

    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = summary()
            % SUMMARY - Construct instance of class
            %

            % Time
            tic;
            disp('Please wait while the program runs.');
            % Add groups as properties
            obj.Control = Abaqus.controlGroup();
            obj.HamstringACL = Abaqus.hamstringGroup();
            obj.PatellaACL = Abaqus.patellaGroup();
            % -------------------------------------------------------------
            %       Statistics
            % -------------------------------------------------------------          
            cycleTypes = {'Walk','SD2S'};
            varnames = obj.Control.Summary.Mean.Properties.VarNames;
            hdata = cell(length(cycleTypes),length(varnames));
            chdataset = dataset({hdata,varnames{:}});
            cpdataset = dataset({hdata,varnames{:}});
            for i = 1:length(cycleTypes)
                for j = 1:length(varnames)
                    % Control vs. Hamstring
                    chdataset{i,j} = XrunTTest(obj.Control.Cycles{cycleTypes{i},varnames{j}},obj.HamstringACL.Cycles{cycleTypes{i},varnames{j}});
                    % Control vs. Patella
                    cpdataset{i,j} = XrunTTest(obj.Control.Cycles{cycleTypes{i},varnames{j}},obj.PatellaACL.Cycles{cycleTypes{i},varnames{j}});
                end
            end
            % Add to dataset
            chdataset = set(chdataset,'ObsNames',cycleTypes);
            cpdataset = set(cpdataset,'ObsNames',cycleTypes);
            % Struct
            stats = struct();
            stats.CtoH = chdataset;
            stats.CtoP = cpdataset;            
            % Assign Property
            obj.Statistics = stats;
            % Elapsed time
            eTime = toc;
            disp(['Elapsed summary processing time is ',num2str(round(mod(eTime,60))),' seconds.']);
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotKinematics(obj,varargin)
            %
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.summary');
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
            set(fig_handle,'Name',['Abaqus Kinematics ',p.Results.Cycle,' - ',p.Results.Joint,' Joint']);
            axes_handles = zeros(1,3);
            for j = 1:3
                axes_handles(j) = subplot(1,3,j);
            end
            allNames = obj.Control.Summary.Mean.Kinematics{1}.Properties.VarNames;
            if strcmp(p.Results.Joint,'TF')
                dofs = [allNames(2:3) allNames(5)];
            elseif strcmp(p.Results.Joint,'PF')
                dofs = allNames(8:10);
            end
            % Plot
            figure(fig_handle);                        
            for j = 1:3
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotKinematics(obj,p.Results.Cycle,dofs{j});
            end
            % Update y limits and plot statistics
            for j = 1:3
                set(fig_handle,'CurrentAxes',axes_handles(j));
                yLim = get(gca,'YLim');
                yTick = get(gca,'YTick');
                yNewMax = yLim(2)+0.9*(yTick(2)-yTick(1));
                yNewMin = yLim(1)-0.1*(yTick(2)-yTick(1));
                set(gca,'YLim',[yNewMin,yNewMax]);
                XplotStatistics(obj,[yLim(2) yNewMax],p.Results.Cycle,'Kinematics',[],dofs{j});
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
                plot(x,obj.Control.Summary.Mean{Cycle,'Kinematics'}.(DOF),'Color',[0.15,0.15,0.15],'LineWidth',3); hold on;
                plot(x,obj.HamstringACL.Summary.Mean{Cycle,'Kinematics'}.(DOF),'Color','m','LineWidth',3,'LineStyle','--');
                plot(x,obj.PatellaACL.Summary.Mean{Cycle,'Kinematics'}.(DOF),'Color',[0 0.5 1],'LineWidth',3,'LineStyle',':');
%                 % Standard Deviation
%                 plusSDC = obj.Control.Summary.Mean{Cycle,'Kinematics'}.(DOF)+obj.Control.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
%                 minusSDC = obj.Control.Summary.Mean{Cycle,'Kinematics'}.(DOF)-obj.Control.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
%                 plusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)+obj.HamstringACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
%                 minusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)-obj.HamstringACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
%                 plusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)+obj.PatellaACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
%                 minusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)-obj.PatellaACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
%                 % Standard Deviation Lines
%                 plot(x,plusSDC,'Color',[0.15 0.15 0.15]);
%                 plot(x,minusSDC,'Color',[0.15 0.15 0.15]);
%                 plot(x,plusSDH,'m--');
%                 plot(x,minusSDH,'m--');
%                 plot(x,plusSDP,'Color',[0 0.5 1],'LineStyle',':');
%                 plot(x,minusSDP,'Color',[0 0.5 1],'LineStyle',':');
% %                 % Individual subjects
% %                 plot(x,obj.Control.Cycles{Cycle,'Kinematics'}.(DOF),'Color',[0.15 0.15 0.15],'LineWidth',1.25);
% %                 plot(x,obj.HamstringACL.Cycles{Cycle,'Kinematics'}.(DOF),'m--','LineWidth',1.25);
% %                 plot(x,obj.PatellaACL.Cycles{Cycle,'Kinematics'}.(DOF),'Color',[0 0.5 1],'LineStyle',':','LineWidth',1.25);
%                 % Standard Deviation Fill
%                 xx = [x' fliplr(x')];
%                 yyC = [plusSDC' fliplr(minusSDC')];
%                 hFill = fill(xx,yyC,[0.15 0.15 0.15]); 
%                 set(hFill,'EdgeColor','none');
%                 alpha(0.25);
%                 yyH = [plusSDH' fliplr(minusSDH')];
%                 hFill = fill(xx,yyH,[1 0 1]);
%                 set(hFill,'EdgeColor','none');
%                 alpha(0.25);               
%                 yyP = [plusSDP' fliplr(minusSDP')];
%                 hFill = fill(xx,yyP,[0 0.5 1]);
%                 set(hFill,'EdgeColor','none');
%                 alpha(0.25);
%                 % Reverse children order (so mean is on top and shaded region is in back)
%                 set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);                
                % Labels                               
                if strcmp(DOF,'TF_Flexion') || strcmp(DOF,'PF_Flexion')
                    title(DOF(4:end),'FontWeight','bold'); 
                    ylabel(['Ext(',char(hex2dec('2013')),')    Flex(+)']);
                elseif strcmp(DOF,'TF_Adduction')
                    title(DOF(4:end),'FontWeight','bold'); 
                    ylabel({['Abd(',char(hex2dec('2013')),')    Add(+)'],'(deg)'});
                    ylim([-1 1.5]);
                elseif strcmp(DOF,'TF_External')
                    title('Rotation','FontWeight','bold'); 
                    ylabel({['Int(',char(hex2dec('2013')),')    Ext(+)'],'(deg)'});
                    ylim([-16 0]);
                elseif strcmp(DOF,'TF_Lateral')
                    ylabel(['Med(',char(hex2dec('2013')),')    Lat(+)']);
                    title('Shift','FontWeight','bold');
                    xlabel('% Stance');
                elseif strcmp(DOF,'TF_Anterior')
                    ylabel({['Post(',char(hex2dec('2013')),')    Ant(+)'],'(mm)'}); 
                    title('Drawer','FontWeight','bold');
                    xlabel('% Stance');
                    ylim([-8 6]);
                elseif strcmp(DOF,'TF_Superior')                  
                    ylabel(['Inf(',char(hex2dec('2013')),')    Sup(+)']);
                    title('Distraction','FontWeight','bold');
                    xlabel('% Stance');
                elseif strcmp(DOF,'PF_Lateral')
                    ylabel({['Med(',char(hex2dec('2013')),')    Lat(+)'],'(mm)'});                    
                    title('Shift','FontWeight','bold');
                    xlabel('% Stance');
                    ylim([-1.2 0.2]);
                elseif strcmp(DOF,'PF_Anterior')
                    ylabel(['Post(',char(hex2dec('2013')),')    Ant(+)']); 
                    title('Anterior-Posterior','FontWeight','bold');
                    xlabel('% Stance'); 
                elseif strcmp(DOF,'PF_Superior')                  
                    ylabel(['Inf(',char(hex2dec('2013')),')    Sup(+)']);
                    title('Superior-Inferior','FontWeight','bold');
                    xlabel('% Stance');    
                elseif strcmp(DOF,'PF_RotationM')
                    ylabel({['Lat(',char(hex2dec('2013')),')    Med(+)'],'(deg)'});
                    title('Rotation','FontWeight','bold');
                    ylim([0 3.5])
                elseif strcmp(DOF,'PF_TiltM')
                    ylabel({['Lat(',char(hex2dec('2013')),')    Med(+)'],'(deg)'});
                    title('Tilt','FontWeight','bold');
                    ylim([-0.5 2.5]);
                end
                xlabel('% Stance');
            end             
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotTibContact(obj,varargin)
            %
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.summary');
            validCycles = {'Walk','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            validTypes = {'Avg','Max'};
            defaultType = 'Avg';
            checkType = @(x) any(validatestring(x,validTypes));           
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('Type',defaultType,checkType);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            set(fig_handle,'Name',['Abaqus Tibiofemoral Contact ',p.Results.Cycle,' - ',p.Results.Type]);
            if strcmp(p.Results.Type,'Avg')
                numplots = 4;
                sides = {'TM','TL','TM','TL'};
                dofs = {'Y','Y','X','X'};
            elseif strcmp(p.Results.Type,'Max')
                numplots = 2;
                sides = {'TM','TL'};
                dofs = {'Value','Value'};
%                 sides = {'TM','TL','TM','TL','TM','TL'};
%                 dofs = {'Y','Y','X','X','Value','Value'};
            end
            axes_handles = zeros(1,numplots);
            for j = 1:numplots
                axes_handles(j) = subplot(numplots/2,2,j);
            end
            % Plot
            figure(fig_handle);            
            for j = 1:numplots
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotContact(obj,p.Results.Cycle,p.Results.Type,sides{j},dofs{j});
            end
            % Update y limits and plot statistics
            for j = 1:numplots
                set(fig_handle,'CurrentAxes',axes_handles(j));
                yLim = get(gca,'YLim');
                yTick = get(gca,'YTick');
                yNewMax = yLim(2)+0.9*(yTick(2)-yTick(1));
                yNewMin = yLim(1)-0.1*(yTick(2)-yTick(1));
                set(gca,'YLim',[yNewMin,yNewMax]);
                XplotStatistics(obj,[yLim(2) yNewMax],p.Results.Cycle,p.Results.Type,sides{j},dofs{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotContact(obj,Cycle,Type,Area,DOF)
                %
                %
                
                % Percent cycle
                x = (linspace(0,25,21))';
                % Norm factor
                if strcmp(Type,'Max')
                    scaleF = 1/50;
                else
                    scaleF = 1;
                end
                % Mean
                plot(x,obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF,'Color',[0 0.5 1],'LineWidth',3,'LineStyle',':'); hold on;
                plot(x,obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF,'Color','m','LineWidth',3,'LineStyle','--'); 
                plot(x,obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF,'Color',[0.15,0.15,0.15],'LineWidth',3);
                % Standard Deviation
                plusSDP = obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF+obj.PatellaACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                minusSDP = obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF-obj.PatellaACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;                
                plusSDH = obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF+obj.HamstringACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                minusSDH = obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF-obj.HamstringACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                plusSDC = obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF+obj.Control.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                minusSDC = obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF-obj.Control.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                % Standard Deviation Lines
                plot(x,plusSDP,'Color',[0 0.5 1],'LineStyle',':','LineWidth',0.25);
                plot(x,minusSDP,'Color',[0 0.5 1],'LineStyle',':','LineWidth',0.25);
                plot(x,plusSDH,'m--','LineWidth',0.25);
                plot(x,minusSDH,'m--','LineWidth',0.25);                
                plot(x,plusSDC,'Color',[0.15 0.15 0.15],'LineWidth',0.25);
                plot(x,minusSDC,'Color',[0.15 0.15 0.15],'LineWidth',0.25);
                % Standard Deviation Fill
                xx = [x' fliplr(x')];
                yyP = [plusSDP' fliplr(minusSDP')];
                hFill = fill(xx,yyP,[0 0.5 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                yyH = [plusSDH' fliplr(minusSDH')];
                hFill = fill(xx,yyH,[1 0 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25); 
                yyC = [plusSDC' fliplr(minusSDC')];
                hFill = fill(xx,yyC,[0.15 0.15 0.15]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));                
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);
                % Labels
                if strcmp(DOF,'Y') && strcmp(Area,'TM')
                    ylabel({'\bfPosterior     Anterior','\rm(% P-A Width)'});
                    title('Medial Tibia Cartilage','FontWeight','bold');
                    ylim([15 60]);
                elseif strcmp(DOF,'Y') && strcmp(Area,'TL')
                    title('Lateral Tibia Cartilage','FontWeight','bold');
                    ylim([15 60]);
                elseif strcmp(DOF,'X') && strcmp(Area,'TM')                    
                    ylabel({'\bfMedial       Lateral','\rm(% M-L Width)'});
                    ylim([10 30]);
                    if ~strcmp(Type,'Max')
                        xlabel('% Stance');
                    end
                elseif strcmp(DOF,'X') && strcmp(Area,'TL')
                    ylim([65 80]);
                    if ~strcmp(Type,'Max')
                        xlabel('% Stance');
                    end                
                elseif strcmp(DOF,'Value') && strcmp(Area,'TM')  
                    title('Medial Tibia Cartilage','FontWeight','bold');
                    ylabel({'\bfMax Contact Pressure','\rm(Normalized)'},'FontWeight','bold');
                    xlabel('% Stance');
                    ylim([0 1]);                    
                elseif strcmp(DOF,'Value') && strcmp(Area,'TL')
                    title('Lateral Tibia Cartilage','FontWeight','bold');
                    xlabel('% Stance');
                    ylim([0 1]);
                end
            end        
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotPatContact(obj,varargin)
            %
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.summary');
            validCycles = {'Walk','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            validTypes = {'Avg','Max'};
            defaultType = 'Avg';
            checkType = @(x) any(validatestring(x,validTypes));           
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('Type',defaultType,checkType);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            set(fig_handle,'Name',['Abaqus Patellofemoral Contact ',p.Results.Cycle,' - ',p.Results.Type]);
            if strcmp(p.Results.Type,'Avg')
                numplots = 4;
                sides = {'PM','PL','PM','PL'};
                dofs = {'Z','Z','X','X'};
            elseif strcmp(p.Results.Type,'Max')
                numplots = 2;
                sides = {'PM','PL'};
                dofs = {'Value','Value'};
            end
            axes_handles = zeros(1,numplots);
            for j = 1:numplots
                axes_handles(j) = subplot(numplots/2,2,j);
            end
            % Plot
            figure(fig_handle);            
            for j = 1:numplots
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotContact(obj,p.Results.Cycle,p.Results.Type,sides{j},dofs{j});
            end
            % Update y limits and plot statistics
            for j = 1:numplots
                set(fig_handle,'CurrentAxes',axes_handles(j));
                yLim = get(gca,'YLim');
                yTick = get(gca,'YTick');
                yNewMax = yLim(2)+0.9*(yTick(2)-yTick(1));
                yNewMin = yLim(1)-0.1*(yTick(2)-yTick(1));
                set(gca,'YLim',[yNewMin,yNewMax]);
                XplotStatistics(obj,[yLim(2) yNewMax],p.Results.Cycle,p.Results.Type,sides{j},dofs{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotContact(obj,Cycle,Type,Area,DOF)
                %
                %
                
                % Percent cycle
                x = (linspace(0,25,21))';
                % Norm factor
                if strcmp(Type,'Max')
                    scaleF = 1/50;
                else
                    scaleF = 1;
                end
                % Mean
                plot(x,obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF,'Color',[0 0.5 1],'LineWidth',3,'LineStyle',':'); hold on;
                plot(x,obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF,'Color','m','LineWidth',3,'LineStyle','--');
                plot(x,obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF,'Color',[0.15,0.15,0.15],'LineWidth',3);
                % Standard Deviation
                plusSDP = obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF+obj.PatellaACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                minusSDP = obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF-obj.PatellaACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                plusSDH = obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF+obj.HamstringACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                minusSDH = obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF-obj.HamstringACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                plusSDC = obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF+obj.Control.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                minusSDC = obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF-obj.Control.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF)*scaleF;
                % Standard Deviation Lines
                plot(x,plusSDP,'Color',[0 0.5 1],'LineStyle',':','LineWidth',0.25);
                plot(x,minusSDP,'Color',[0 0.5 1],'LineStyle',':','LineWidth',0.25);
                plot(x,plusSDH,'m--','LineWidth',0.25);
                plot(x,minusSDH,'m--','LineWidth',0.25);
                plot(x,plusSDC,'Color',[0.15 0.15 0.15],'LineWidth',0.25);
                plot(x,minusSDC,'Color',[0.15 0.15 0.15],'LineWidth',0.25);             
                % Standard Deviation Fill
                xx = [x' fliplr(x')];
                yyP = [plusSDP' fliplr(minusSDP')];
                hFill = fill(xx,yyP,[0 0.5 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                yyH = [plusSDH' fliplr(minusSDH')];
                hFill = fill(xx,yyH,[1 0 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                yyC = [plusSDC' fliplr(minusSDC')];
                hFill = fill(xx,yyC,[0.15 0.15 0.15]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));                
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);
                % Labels
                if strcmp(DOF,'Z') && strcmp(Area,'PM')
                    ylabel({'\bfInferior     Superior','\rm(% I-S Width)'});
                    title('Medial Patella Cartilage','FontWeight','bold');
                    ylim([25 65]);
                elseif strcmp(DOF,'Z') && strcmp(Area,'PL')
                    title('Lateral Patella Cartilage','FontWeight','bold');
                    ylim([25 65]);
                elseif strcmp(DOF,'X') && strcmp(Area,'PM')                    
                    ylabel({'\bfMedial       Lateral','\rm(% M-L Width)'});
                    ylim([24 32]);
                    if ~strcmp(Type,'Max')
                        xlabel('% Stance');
                    end
                elseif strcmp(DOF,'X') && strcmp(Area,'PL')
                    ylim([80 92]);
                    if ~strcmp(Type,'Max')
                        xlabel('% Stance');
                    end
                elseif strcmp(DOF,'Value') && strcmp(Area,'PM')  
                    title('Medial Patella Cartilage','FontWeight','bold');
                    ylabel({'\bfMax Contact Pressure','\rm(Normalized)'},'FontWeight','bold');
                    xlabel('% Stance');
                    ylim([0 1]);
                elseif strcmp(DOF,'Value') && strcmp(Area,'PL')
                    title('Lateral Patella Cartilage','FontWeight','bold');
                    xlabel('% Stance');
                    ylim([0 1]);
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotTibCartOverlay(obj,varargin)
            %
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.summary');
            validCycles = {'Walk','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            defaultSave = false;
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('SaveAI',defaultSave);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            set(fig_handle,'Name',['Tibiofemoral Contact Overlay ',p.Results.Cycle]);
            Cycle = p.Results.Cycle;
            % Plot
            figure(fig_handle);            
            set(fig_handle,'CurrentAxes',p.Results.axes_handles);
            set(gcf,'Units','Inches');
            set(gcf,'Position',[1 3 7 6]);
            scaleFactorYtoX = 49.6/70;
            % Mean data points
            plot(obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TM'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TM'}.Y,'Color',[0 0.5 1],'LineWidth',1,'Marker','x'); hold on;
            plot(obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TM'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TM'}.Y,'mo-','LineWidth',1);
            plot(obj.Control.Summary.Mean{Cycle,'CPAvg_TM'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_TM'}.Y,'Color',[0.15,0.15,0.15],'LineWidth',1,'Marker','s');
            plot(obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TL'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TL'}.Y,'Color',[0 0.5 1],'LineWidth',1,'Marker','x');
            plot(obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TL'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TL'}.Y,'mo-','LineWidth',1);
            plot(obj.Control.Summary.Mean{Cycle,'CPAvg_TL'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_TL'}.Y,'Color',[0.15,0.15,0.15],'LineWidth',1,'Marker','s');                        
            % Ellipses for standard deviation
            ellipse(obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_TM'}.X,obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_TM'}.Y,zeros(21,1),...
                    obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TM'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TM'}.Y,[0 0.5 1]);
            ellipse(obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_TM'}.X,obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_TM'}.Y,zeros(21,1),...
                    obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TM'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TM'}.Y,'m');
            ellipse(obj.Control.Summary.StdDev{Cycle,'CPAvg_TM'}.X,obj.Control.Summary.StdDev{Cycle,'CPAvg_TM'}.Y,zeros(21,1),...
                    obj.Control.Summary.Mean{Cycle,'CPAvg_TM'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_TM'}.Y,[0.15 0.15 0.15]);
            ellipse(obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_TL'}.X,obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_TL'}.Y,zeros(21,1),...
                    obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TL'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_TL'}.Y,[0 0.5 1]);
            ellipse(obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_TL'}.X,obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_TL'}.Y,zeros(21,1),...
                    obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TL'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_TL'}.Y,'m');
            ellipse(obj.Control.Summary.StdDev{Cycle,'CPAvg_TL'}.X,obj.Control.Summary.StdDev{Cycle,'CPAvg_TL'}.Y,zeros(21,1),...
                    obj.Control.Summary.Mean{Cycle,'CPAvg_TL'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_TL'}.Y,[0.15 0.15 0.15]);
            % Reverse children order (so mean is on top and shaded region is in back)
            set(gca,'Children',flipud(get(gca,'Children')));
            % Axes properties
            set(gca,'box','off');
            % Axes limits / scale
%             set(gca,'XLim',[0 100],'XTick',[0; 20; 40; 60; 80; 100]);
%             set(gca,'YLim',[0 100],'YTick',[0; 20; 40; 60; 80; 100]);
            set(gca,'XLim',[0 100],'XTick',[],'YLim',[0 100],'YTick',[]);
            set(gca,'DataAspectRatio',[1 1/scaleFactorYtoX 1]);
            if p.Results.SaveAI
                set(gcf,'PaperPositionMode','auto');  % won't resize the figure when printing
                set(gcf,'Renderer','painters');    
                warning('off','MATLAB:print:Illustrator:DeprecatedDevice');    
                figDir = 'H:\Dropbox\Northwestern\Figures\';
                print(gcf,'-dill',[figDir,'Tibiofemoral Contact Overlay ',p.Results.Cycle,'.ai']);
                % Return to normal view
                set(gcf,'RendererMode','auto');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotPatCartOverlay(obj,varargin)
            %
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.summary');
            validCycles = {'Walk','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            defaultSave = false;
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('SaveAI',defaultSave);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            set(fig_handle,'Name',['Patellofemoral Contact Overlay ',p.Results.Cycle]);
            Cycle = p.Results.Cycle;
            % Plot
            figure(fig_handle);            
            set(fig_handle,'CurrentAxes',p.Results.axes_handles);
            set(gcf,'Units','Inches');
            set(gcf,'Position',[1 3 6 6]);
            scaleFactorZtoX = 42.1/40.5;
            % Mean data points
            plot(obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PM'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PM'}.Z,'Color',[0 0.5 1],'LineWidth',1,'Marker','x'); hold on;
            plot(obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PM'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PM'}.Z,'mo-','LineWidth',1);
            plot(obj.Control.Summary.Mean{Cycle,'CPAvg_PM'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_PM'}.Z,'Color',[0.15,0.15,0.15],'LineWidth',1,'Marker','s');
            plot(obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PL'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PL'}.Z,'Color',[0 0.5 1],'LineWidth',1,'Marker','x');
            plot(obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PL'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PL'}.Z,'mo-','LineWidth',1); 
            plot(obj.Control.Summary.Mean{Cycle,'CPAvg_PL'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_PL'}.Z,'Color',[0.15,0.15,0.15],'LineWidth',1,'Marker','s');                       
            % Ellipses for standard deviation
            ellipse(obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_PM'}.X,obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_PM'}.Z,zeros(21,1),...
                    obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PM'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PM'}.Z,[0 0.5 1]);
            ellipse(obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_PM'}.X,obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_PM'}.Z,zeros(21,1),...
                    obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PM'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PM'}.Z,'m');
            ellipse(obj.Control.Summary.StdDev{Cycle,'CPAvg_PM'}.X,obj.Control.Summary.StdDev{Cycle,'CPAvg_PM'}.Z,zeros(21,1),...
                    obj.Control.Summary.Mean{Cycle,'CPAvg_PM'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_PM'}.Z,[0.15 0.15 0.15]);
            ellipse(obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_PL'}.X,obj.PatellaACL.Summary.StdDev{Cycle,'CPAvg_PL'}.Z,zeros(21,1),...
                    obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PL'}.X,obj.PatellaACL.Summary.Mean{Cycle,'CPAvg_PL'}.Z,[0 0.5 1]);
            ellipse(obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_PL'}.X,obj.HamstringACL.Summary.StdDev{Cycle,'CPAvg_PL'}.Z,zeros(21,1),...
                    obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PL'}.X,obj.HamstringACL.Summary.Mean{Cycle,'CPAvg_PL'}.Z,'m');
            ellipse(obj.Control.Summary.StdDev{Cycle,'CPAvg_PL'}.X,obj.Control.Summary.StdDev{Cycle,'CPAvg_PL'}.Z,zeros(21,1),...
                    obj.Control.Summary.Mean{Cycle,'CPAvg_PL'}.X,obj.Control.Summary.Mean{Cycle,'CPAvg_PL'}.Z,[0.15 0.15 0.15]);
            % Reverse children order (so mean is on top and shaded region is in back)
            set(gca,'Children',flipud(get(gca,'Children')));
            % Axes properties
            set(gca,'box','off');
            % Axes limits / scale
%             set(gca,'XLim',[0 100],'XTick',[0; 20; 40; 60; 80; 100]);
%             set(gca,'YLim',[0 100],'YTick',[0; 20; 40; 60; 80; 100]);
            set(gca,'XLim',[0 100],'XTick',[],'YLim',[0 100],'YTick',[]);
            set(gca,'DataAspectRatio',[1 1/scaleFactorZtoX 1]);
            if p.Results.SaveAI
                set(gcf,'PaperPositionMode','auto');  % won't resize the figure when printing
                set(gcf,'Renderer','painters');    
                warning('off','MATLAB:print:Illustrator:DeprecatedDevice');    
                figDir = 'H:\Dropbox\Northwestern\Figures\';
                print(gcf,'-dill',[figDir,'Patellofemoral Contact Overlay ',p.Results.Cycle,'.ai']);
                % Return to normal view
                set(gcf,'RendererMode','auto');
            end            
        end
    end

end


%% Subfunctions
% Subfunctions called from the main class definition

function dsH = XrunTTest(dSet1,dSet2)
    % XRUNTTEST
    %
    
    dsnames = dSet1.Properties.VarNames;
    newdata = NaN(size(dSet1));
    for j = 1:length(dsnames)
        newdata(:,j) = (ttest2(dSet1.(dsnames{j})',dSet2.(dsnames{j})'))';        
    end
    % Return
    dsH = dataset({newdata,dsnames{:}});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function XplotStatistics(obj,yPos,Cycle,Type,Area,DOF)
    % XPLOTSTATISTICS
    %

    % Stats
    if ~isempty(Area)
        stats = [obj.Statistics.CtoP{Cycle,['CP',Type,'_',Area]}.(DOF), ...
                 obj.Statistics.CtoH{Cycle,['CP',Type,'_',Area]}.(DOF)];    
    else
        stats = [obj.Statistics.CtoP{Cycle,Type}.(DOF), ...
                 obj.Statistics.CtoH{Cycle,Type}.(DOF)];
    end
    % Prepare line positions
    yvalues = yPos(1)+(yPos(2)-yPos(1))*[0.6 0.2];
    % Significant results are when 'stats' = 1
    sig = stats;
    sig(sig == 0) = NaN;
    for i = 1:2
        sig(sig(:,i) == 1,i) = yvalues(i);
    end    
    % Find endpoints of lines
    endpoints = cell(size(stats));
    endlines = NaN(size(stats));
    for i = 1:2
        diffV = diff([0; stats(:,i); 0]);
        transitions = find(diffV);
        for j = 1:length(transitions)
            if diffV(transitions(j)) == 1
                endpoints{transitions(j),i} = 'L';
                endlines(transitions(j),i) = yvalues(i);
            elseif diffV(transitions(j)) == -1
                if ~isempty(endpoints{transitions(j)-1,i})
                    % Get rid of single points...
                    sig(transitions(j)-1,i) = NaN;
                    stats(transitions(j)-1,i) = 0;
                    endpoints{transitions(j)-1,i} = 'delete';
                    endlines(transitions(j)-1,i) = NaN;
                else
                    endpoints{transitions(j)-1,i} = 'R';
                    endlines(transitions(j)-1,i) = yvalues(i);
                end
            end
        end
        clear diffV transitions
        % Determine if regions are larger than a threshold
        diffV = diff([0; stats(:,i); 0]);
        transitions = find(diffV);
        diffT = diff(transitions);
        pairDiff = diffT(1:2:end);
        for j = 1:length(pairDiff)
            if pairDiff(j) < 4
                % Left
                endpoints{transitions(j*2-1),i} = 'delete';
                endlines(transitions(j*2-1),i) = NaN;
                % Right
                endpoints{transitions(j*2)-1,i} = 'delete';
                endlines(transitions(j*2)-1,i) = NaN;
                % In between
                sig(transitions(j*2-1):transitions(j*2)-1,i) = NaN;
            end
        end
    end
    % Add labels over regions of significance
    endX = repmat(linspace(0,25,length(stats))',1,2);
    for i = 1:2
        endX(isnan(endlines(:,i)),i) = NaN;
    end
    [labelX1,labelpoints1] = XgetStatLabels(endX(:,1),endpoints(:,1),yvalues(1));
    [labelX2,labelpoints2] = XgetStatLabels(endX(:,2),endpoints(:,2),yvalues(2));
    % Plot
    text(labelX1,labelpoints1,'*','Color',[0 0.5 1],'FontSize',16,'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','SignificanceLabel1');
    text(labelX2,labelpoints2,'+','Color',[1 0 1],'FontSize',12,'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','SignificanceLabel2');
    % Plot endpoints as vertical lines    
    text(endX(:,1),endlines(:,1),'I','Color',[0 0.5 1],'FontSize',14,'HorizontalAlignment','center','Tag','SignificanceEnd');
    text(endX(:,2),endlines(:,2),'I','Color',[1 0 1],'FontSize',14,'HorizontalAlignment','center','Tag','SignificanceEnd'); 
    % Plot horizontal line
    line(linspace(0,25,length(sig))',sig(:,1),'Color',[0 0.5 1],'Tag','SignificanceLine');
    line(linspace(0,25,length(sig))',sig(:,2),'Color',[1 0 1],'Tag','SignificanceLine');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [labelX,labelpoints] = XgetStatLabels(endX,endpoints,yvalues)
    % XGETSTATLABELS
    %

    % Get rid of NaNs
    endpoints(isnan(endX)) = [];
    endX(isnan(endX)) = [];
    % Preallocate
    labelX = NaN(size(endX));   
    labelpoints = yvalues*ones(size(endX));
    % Add values    
    if ~isempty(endX)
        % Midpoints of pairs
        if ~isempty(endX)
            midX = endX(1:end-1)+diff(endX)/2;
            midX = midX(1:2:end);
            labelX(strcmp('L',endpoints)) = midX;
        end
    end
end
