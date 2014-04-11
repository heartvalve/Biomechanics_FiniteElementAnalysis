classdef cpress < handle
    % CPRESS
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-10
    
    
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
            cPath = [Abaqus.getSubjectDir(subID),subID,'_',simName,'_CPRESS_',type,'.data'];
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
                % Weighted average for location based on values
                for j = 1:3
                    wAvgLoc(i,j) = sum(obj.Data.(dofs{j})(frameStartInd(i):frameEndInd(i)).*obj.Data.Value(frameStartInd(i):frameEndInd(i)))/...
                                   sum(obj.Data.Value(frameStartInd(i):frameEndInd(i)));
                end
                % Maximum location and magnitude
                [~,ind] = max(localData(frameStartInd(i):frameEndInd(i),5));
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
