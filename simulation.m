classdef simulation < handle
    % SIMULATION - A class to store an Abaqus modeling simulation.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-02
    
    
    %% Properties
    % Properties for the simulation class
    
    properties (SetAccess = private)        
        SubID               % Subject ID
        SimName             % Simulation name
        ExpKIN              % Experimental kinematics
        SimKIN              % Simulation kinematics
    end
    properties (Hidden = true, SetAccess = private)
        SubDir              % Directory where files are stored
    end
    
    
    %% Methods
    % Methods for the simulation class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = simulation(subID,simName)
            % SIMULATION - Construct instance of class
            %
            
            % Subject ID
            obj.SubID = subID;
            % Simulation name (without subject ID)
            obj.SimName = simName;
            % Subject directory
            obj.SubDir = Abaqus.getSubjectDir(subID);
            % Experimental kinematics
            obj.ExpKIN = Abaqus.expKin(subID,simName);
            % Simulation kinematics
            obj.SimKIN = Abaqus.simKin(subID,simName);
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotKinematics(obj,varargin)
            % PLOTKINEMATICS
            %
            
            p = inputParser;
            checkObj = @(x) isa(x,'Abaqus.simulation');
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments (and updates)
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)                
                set(fig_handle,'Name',[obj.SubID,'_',obj.SimName,' - Kinematics']);
                axes_handles = zeros(1,3);
                for k = 1:3
                    axes_handles(k) = subplot(1,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end
            kinNames = obj.ExpKIN.Data.Properties.VarNames;
            % Plot
            figure(fig_handle);
            for j = 1:length(kinNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotKinematics(obj,kinNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotKinematics(obj,Kin)
                % XPLOTKINEMATICS
                %
               
                % Plot Experiment
                plot((0:25)',obj.ExpKIN.Data.(Kin),'Color',[0.15 0.15 0.15],'LineWidth',3); hold on;
                % Plot Simulation
                plot((0:25)',obj.SimKIN.Data.(Kin),'Color',[0.65 0.65 0.65],'LineWidth',3,'LineStyle','--');
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 25]);               
                % Labels                
                title(Kin,'FontWeight','bold');
                xlabel('% Stance');
                if strcmp(Kin,'Flexion')
                    ylabel('Angle (deg)');
                end
            end            
        end
    end
    
end

