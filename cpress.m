classdef cpress < handle
    % CPRESS
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-11
    
    
    %% Properties
    % Properties for the cpress class
    
    properties (SetAccess = private)        
        PerCycle    % Percent of cycle
        Data        % Data in local coordinate system
        Avg         % X, Y, Z position of weighted average location (based on magnitude)
        Max         % X, Y, Z position and Magnitude of maximum
    end
    properties (SetAccess = private, Hidden = true)
        Raw         % Data in global coordinate system
    end
    
    
    %% Methods
    % Methods for the cpress class
    
    methods
        function obj = cpress(subID,simName,type)
            % CPRESS - Construct instance of class
            %
            
            % Path
            if regexp(type,'Pat')
                cPath = [Abaqus.getSubjectDir(subID),subID,'_',simName,'_CPRESS_PatCart.data'];
                % Medial or Lateral -- one file, separate based on transformed coordinate system
                side = type(1);
            else
                cPath = [Abaqus.getSubjectDir(subID),subID,'_',simName,'_CPRESS_',type,'.data'];
            end
            % Import the file
            cimport = importdata(cPath,'\t',1);
            % Column headers
            cnames = cimport.colheaders;
            cnames{5} = 'Value';
            % Raw data            
            obj.Raw = dataset({cimport.data,cnames{:}});
            % Percent cycle
            time = cimport.data(:,1);
            time = unique(time);
            obj.PerCycle = round(time*100000)/100;            
            % -------------------------------------------------------------            
            % Convert to local coordinate system
            %   X - lat + / med - 
            %   Y - ant + / post - 
            %   Z - up + / down - 
            if regexp(type,'Tib')
                tibia_origin_inGlobal = [61.7139099151, 60.182088920908, 71.953967762324]';
                tibia_ankle_inGlobal = [1.61012197, 61.0149002, 75.8856506]';
                tibia_med_inGlobal = [53.33547347119, 48.476914724679, 54.560018565138]';
                tibia_lat_inGlobal = [57.765535421265, 58.684663398524, 92.727099668279]';
                tibia_z = tibia_origin_inGlobal-tibia_ankle_inGlobal;
                tibia_xtemp = tibia_lat_inGlobal-tibia_med_inGlobal;
                tibia_y = cross(tibia_z,tibia_xtemp);
                tibia_x = cross(tibia_y,tibia_z);
                tibia_ex = tibia_x/norm(tibia_x);
                tibia_ey = tibia_y/norm(tibia_y);
                tibia_ez = tibia_z/norm(tibia_z);
                tibiaLocalToGlobal = [tibia_ex tibia_ey tibia_ez];
                globalToTibiaLocal = transpose(tibiaLocalToGlobal);
                localData = double(obj.Raw);
                for i = 1:length(localData)
                    localData(i,2:4) = (globalToTibiaLocal*(cimport.data(i,2:4))'-globalToTibiaLocal*tibia_origin_inGlobal)';
                end
            elseif regexp(type,'Pat')
                patella_post_inGlobal = [94.4332962, 20.9962273, 74.311058]';
                patella_ant_inGlobal = [97.5204239, 2.44025111, 84.2418213]';
                patella_sup_inGlobal = [114.405914, 12.6245155, 80.8967972]';
                patella_inf_inGlobal = [76.0122299, 12.3632708, 83.3992157]';
                patella_med_inGlobal = [89.9378128, 7.58192873, 64.861145]';
                patella_lat_inGlobal = [92.0576401, 17.1576023, 101.126472]';                
                patella_origin_inGlobal = patella_post_inGlobal+0.5*(patella_ant_inGlobal-patella_post_inGlobal);
                patella_z = patella_sup_inGlobal-patella_inf_inGlobal;
                patella_xtemp = patella_lat_inGlobal-patella_med_inGlobal;
                patella_y = cross(patella_z,patella_xtemp);
                patella_x = cross(patella_y,patella_z);
                patella_ex = patella_x/norm(patella_x);
                patella_ey = patella_y/norm(patella_y);
                patella_ez = patella_z/norm(patella_z);
                patellaLocalToGlobal = [patella_ex patella_ey patella_ez];
                globalToPatellaLocal = transpose(patellaLocalToGlobal);
                localData = double(obj.Raw);
                for i = 1:length(localData)
                    localData(i,2:4) = (globalToPatellaLocal*(cimport.data(i,2:4))'-globalToPatellaLocal*patella_origin_inGlobal)';
                end
                % Extract data from one side or the other based on X location (origin isn't exactly in medial/lateral middle)
                if strcmp(side,'M')
                    localData(localData(:,2) > 3,:) = [];
                elseif strcmp(side,'L')
                    localData(localData(:,2) <= 3,:) = [];
                end                
            end
            obj.Data = dataset({localData,cnames{:}});
            % -------------------------------------------------------------
            % Get key information for each frame
            frameEndInd = find(diff(obj.Data.Time));
            frameEndInd = [frameEndInd; length(obj.Data.Time)];
            frameStartInd = [1; frameEndInd(1:end-1)+1];                        
            wAvgLoc = zeros(length(time),3);
            maxInfo = zeros(length(time),4);
            dofs = {'X','Y','Z'};
            for i = 1:length(frameStartInd)
                % Clean up region (negative values, stress concentration outliers)
                tempData = localData(frameStartInd(i):frameEndInd(i),:);
                tempData((tempData(:,5) < 1 | tempData(:,5) > 50),:) = [];                
                % Weighted average for location based on values
                for j = 1:3
                    wAvgLoc(i,j) = sum(tempData(:,j+1).*tempData(:,5))/...
                                   sum(tempData(:,5));
                end
                % Maximum location and magnitude
                tempData = localData(frameStartInd(i):frameEndInd(i),:);
                tempData(tempData(:,5) > 50,5) = NaN;
                [~,ind] = max(tempData(:,5));
                maxRowInd = frameStartInd(i) + ind - 1;
                maxInfo(i,:) = localData(maxRowInd,2:5);
            end
            % Save
            obj.Avg = dataset({wAvgLoc,dofs{:}});
            labels = {'X','Y','Z','Value'};
            obj.Max = dataset({maxInfo,labels{:}});
            
            % Normalize to tibia dimensions?
            
        end
    end
    
end
