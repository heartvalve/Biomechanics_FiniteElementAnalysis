classdef summary < handle
    % SUMMARY - A class to store all Abaqus data.
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-04-10


    %% Properties
    % Properties for the summary class

    properties (SetAccess = private)
        Control             % Control group
        HamstringACL        % Hamstring tendon ACL-R
        PatellaACL          % Patella tendon ACL-R
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
            % --------------------
%             obj.Statistics = Abaqus.getSummaryStatistics(obj);
            % --------------------
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
            axes_handles = zeros(1,6);
            for j = 1:6
                axes_handles(j) = subplot(2,3,j);
            end
            % Plot
            figure(fig_handle);
            allNames = obj.Control.Summary.Mean.Kinematics{1}.Properties.VarNames;
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
                plot(x,obj.Control.Summary.Mean{Cycle,'Kinematics'}.(DOF),'Color',[0.15,0.15,0.15],'LineWidth',3); hold on;
                plot(x,obj.HamstringACL.Summary.Mean{Cycle,'Kinematics'}.(DOF),'Color','m','LineWidth',3,'LineStyle','--');
                plot(x,obj.PatellaACL.Summary.Mean{Cycle,'Kinematics'}.(DOF),'Color',[0 0.5 1],'LineWidth',3,'LineStyle',':');
                % Standard Deviation
                plusSDC = obj.Control.Summary.Mean{Cycle,'Kinematics'}.(DOF)+obj.Control.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
                minusSDC = obj.Control.Summary.Mean{Cycle,'Kinematics'}.(DOF)-obj.Control.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
                plusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)+obj.HamstringACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
                minusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)-obj.HamstringACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
                plusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)+obj.PatellaACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
                minusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Kinematics'}.(DOF)-obj.PatellaACL.Summary.StdDev{Cycle,'Kinematics'}.(DOF);
%                 % Standard Deviation Lines
%                 plot(x,plusSDC,'Color',[0.15 0.15 0.15]);
%                 plot(x,minusSDC,'Color',[0.15 0.15 0.15]);
%                 plot(x,plusSDH,'m--');
%                 plot(x,minusSDH,'m--');
%                 plot(x,plusSDP,'Color',[0 0.5 1],'LineStyle',':');
%                 plot(x,minusSDP,'Color',[0 0.5 1],'LineStyle',':');
                % Individual subjects
                plot(x,obj.Control.Cycles{Cycle,'Kinematics'}.(DOF),'Color',[0.15 0.15 0.15],'LineWidth',1.25);
                plot(x,obj.HamstringACL.Cycles{Cycle,'Kinematics'}.(DOF),'m--','LineWidth',1.25);
                plot(x,obj.PatellaACL.Cycles{Cycle,'Kinematics'}.(DOF),'Color',[0 0.5 1],'LineStyle',':','LineWidth',1.25);
                % Standard Deviation Fill
                xx = [x' fliplr(x')];
                yyC = [plusSDC' fliplr(minusSDC')];
                hFill = fill(xx,yyC,[0.15 0.15 0.15]); 
                set(hFill,'EdgeColor','none');
                alpha(0.125); % 0.25
                yyH = [plusSDH' fliplr(minusSDH')];
                hFill = fill(xx,yyH,[1 0 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.125);               
                yyP = [plusSDP' fliplr(minusSDP')];
                hFill = fill(xx,yyP,[0 0.5 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.125);
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);
                % Labels
                title(DOF(4:end),'FontWeight','bold');
                xlabel('% Stance');
                if strcmp(DOF,'TF_Flexion') || strcmp(DOF,'PF_Flexion')
                    ylabel(['\bfExt(',char(hex2dec('2013')),')    Flex(+)']);
                elseif strcmp(DOF,'TF_Adduction')
                    ylabel(['\bfAbd(',char(hex2dec('2013')),')    Add(+)']);
                elseif strcmp(DOF,'TF_External')
                    ylabel(['\bfInt(',char(hex2dec('2013')),')    Ext(+)']);
                elseif strcmp(DOF,'TF_Lateral') || strcmp(DOF,'PF_Lateral')
                    ylabel(['\bfMed(',char(hex2dec('2013')),')    Lat(+)']);
                elseif strcmp(DOF,'TF_Anterior') || strcmp(DOF,'PF_Anterior')
                    ylabel(['\bfPost(',char(hex2dec('2013')),')    Ant(+)']);                    
                elseif strcmp(DOF,'TF_Distraction')
                    ylabel(['\bfSup(',char(hex2dec('2013')),')    Inf(+)']);
                elseif strcmp(DOF,'PF_RotationM')
                    ylabel(['\bfLat(',char(hex2dec('2013')),')    Med(+)']);
                    title('Rotation','FontWeight','bold');
                elseif strcmp(DOF,'PF_TiltM')
                    ylabel(['\bfLat(',char(hex2dec('2013')),')    Med(+)']);
                    title('Tilt','FontWeight','bold');
                elseif strcmp(DOF,'PF_Superior')
                    ylabel(['\bfInf(',char(hex2dec('2013')),')    Sup(+)']);
                end
                if ~strcmp(DOF,'PF_RotationM') && ~strcmp(DOF,'PF_TiltM')
                    title(DOF(4:end),'FontWeight','bold');
                end
            end             
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotContact(obj,varargin)
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
            set(fig_handle,'Name',['Abaqus Contact ',p.Results.Cycle,' - ',p.Results.Area,' ',p.Results.Type]);
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
                plot(x,obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF),'Color',[0.15,0.15,0.15],'LineWidth',3); hold on;
                plot(x,obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF),'Color','m','LineWidth',3,'LineStyle','--');
                plot(x,obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF),'Color',[0 0.5 1],'LineWidth',3,'LineStyle',':');
                % Standard Deviation
                plusSDC = obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)+obj.Control.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF);
                minusSDC = obj.Control.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)-obj.Control.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF);
                plusSDH = obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)+obj.HamstringACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF);
                minusSDH = obj.HamstringACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)-obj.HamstringACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF);
                plusSDP = obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)+obj.PatellaACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF);
                minusSDP = obj.PatellaACL.Summary.Mean{Cycle,['CP',Type,'_',Area]}.(DOF)-obj.PatellaACL.Summary.StdDev{Cycle,['CP',Type,'_',Area]}.(DOF);
                % Standard Deviation Lines
                plot(x,plusSDC,'Color',[0.15 0.15 0.15]);
                plot(x,minusSDC,'Color',[0.15 0.15 0.15]);
                plot(x,plusSDH,'m--');
                plot(x,minusSDH,'m--');
                plot(x,plusSDP,'Color',[0 0.5 1],'LineStyle',':');
                plot(x,minusSDP,'Color',[0 0.5 1],'LineStyle',':');                
                % Standard Deviation Fill
                xx = [x' fliplr(x')];
                yyC = [plusSDC' fliplr(minusSDC')];
                hFill = fill(xx,yyC,[0.15 0.15 0.15]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                yyH = [plusSDH' fliplr(minusSDH')];
                hFill = fill(xx,yyH,[1 0 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);               
                yyP = [plusSDP' fliplr(minusSDP')];
                hFill = fill(xx,yyP,[0 0.5 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));                
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);
                % Labels
%                 title(DOF,'FontWeight','bold');
                xlabel('% Stance');
                if strcmp(DOF,'X')
%                     ylabel({['\bfMed(',char(hex2dec('2013')),')    Lat(+)'],'\rm(mm)'});
                    ylabel(['Med(',char(hex2dec('2013')),')    Lat(+)']);
                    title('ML Position','FontWeight','bold');
                elseif strcmp(DOF,'Y')
                    ylabel(['Post(',char(hex2dec('2013')),')   Ant(+)']);
                    title('AP Postion','FontWeight','bold');
                elseif strcmp(DOF,'Value')
                    ylabel('MPa');
                    title('Max CPress','FontWeight','bold');
                end
            end        
        end
    end

end
