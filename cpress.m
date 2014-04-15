classdef cpress < handle
    % CPRESS
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-13
    
    
    %% Properties
    % Properties for the cpress class
    
    properties (SetAccess = private)        
        PerCycle    % Percent of cycle
        Data        % Normalized data in local coordinate system
        Avg         % X, Y, Z position of weighted average location (based on magnitude)
        Max         % X, Y, Z position and Magnitude of maximum
    end
    properties (SetAccess = private, Hidden = true)
        Raw         % Data in global coordinate system
        Local       % Data in local coordinate system
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
            localData = double(obj.Raw);
            % Convert to local coordinate system
            %   X - lat + / med - 
            %   Y - ant + / post - 
            %   Z - up + / down - 
            if regexp(type,'Tib')
                tibia_sup_inGlobal = [61.7139099151, 60.182088920908, 71.953967762324]';
                tibia_inf_inGlobal = [1.61012197, 61.0149002, 75.8856506]';
                tibia_med_inGlobal = [53.33547347119, 48.476914724679, 54.560018565138]';
                tibia_lat_inGlobal = [57.765535421265, 58.684663398524, 92.727099668279]';
                tibia_z = tibia_sup_inGlobal-tibia_inf_inGlobal;
                tibia_xtemp = tibia_lat_inGlobal-tibia_med_inGlobal;
                tibia_y = cross(tibia_z,tibia_xtemp);
                tibia_x = cross(tibia_y,tibia_z);
                tibia_ex = tibia_x/norm(tibia_x);
                tibia_ey = tibia_y/norm(tibia_y);
                tibia_ez = tibia_z/norm(tibia_z);
                tibiaLocalToGlobal = [tibia_ex tibia_ey tibia_ez];
                globalToTibiaLocal = transpose(tibiaLocalToGlobal);                               
                for i = 1:length(localData)
                    localData(i,2:4) = (globalToTibiaLocal*(cimport.data(i,2:4))')';
                end
                % Origin
                % Most medial point on Tibia Cartilage
                medTibCart_inGlobal = [51.847, 46.826, 39.52]';
                latTibCart_inGlobal = [57.038, 66.177, 106.629]';
                % Most posterior point on Tibia Cartilage
                postTibCart_inGlobal = [52.942, 71.099, 52.230]';
                antTibCart_inGlobal = [58.5, 24.864, 71.152]';
                % Convert to Local
                medTibCart_inLocal = globalToTibiaLocal*medTibCart_inGlobal;
                latTibCart_inLocal = globalToTibiaLocal*latTibCart_inGlobal;
                postTibCart_inLocal = globalToTibiaLocal*postTibCart_inGlobal;
                antTibCart_inLocal = globalToTibiaLocal*antTibCart_inGlobal;
                % Now look at X-Y positions only (X for medial, Y for posterior); set Z as minimum (most inferior)
                tibia_origin_inLocal = [medTibCart_inLocal(1); postTibCart_inLocal(2); min(localData(:,4))];                
                localOffsetData = localData;
                for i = 1:length(localData)
                    localOffsetData(i,2:4) = ((localData(i,2:4))'-tibia_origin_inLocal)';
                end
            elseif regexp(type,'Pat')
%                 patella_post_inGlobal = [94.4332962, 20.9962273, 74.311058]';
%                 patella_ant_inGlobal = [97.5204239, 2.44025111, 84.2418213]';
                patella_sup_inGlobal = [114.405914, 12.6245155, 80.8967972]';
                patella_inf_inGlobal = [76.0122299, 12.3632708, 83.3992157]';
                patella_med_inGlobal = [89.9378128, 7.58192873, 64.861145]';
                patella_lat_inGlobal = [92.0576401, 17.1576023, 101.126472]';
%                 patella_origin_inGlobal = patella_post_inGlobal+0.5*(patella_ant_inGlobal-patella_post_inGlobal);
%                 patellaCart_center_inGlobal = [94.2, 24.8, 78.5]';
                patella_z = patella_sup_inGlobal-patella_inf_inGlobal;
                patella_xtemp = patella_lat_inGlobal-patella_med_inGlobal;
                patella_y = cross(patella_z,patella_xtemp);
                patella_x = cross(patella_y,patella_z);
                patella_ex = patella_x/norm(patella_x);
                patella_ey = patella_y/norm(patella_y);
                patella_ez = patella_z/norm(patella_z);
                patellaLocalToGlobal = [patella_ex patella_ey patella_ez];
                globalToPatellaLocal = transpose(patellaLocalToGlobal);                             
                for i = 1:length(localData)
                    localData(i,2:4) = (globalToPatellaLocal*(cimport.data(i,2:4))')';
                end
                % Origin
                % Most medial point on cartilage / lateral point
                medPatCart_inGlobal = [87.123, 9.745, 63.316]';
                latPatCart_inGlobal = [96.887, 24.192, 100.822]';
                % Most inferior point on cartilage
                infPatCart_inGlobal = [74.554, 14.062, 83.087]';
                supPatCart_inGlobal = [116.422, 17.713, 78.488]';
                % Convert to Local
                medPatCart_inLocal = globalToPatellaLocal*medPatCart_inGlobal;
                latPatCart_inLocal = globalToPatellaLocal*latPatCart_inGlobal;
                halfX = (latPatCart_inLocal(1)-medPatCart_inLocal(1))/2;
                infPatCart_inLocal = globalToPatellaLocal*infPatCart_inGlobal;
                supPatCart_inLocal = globalToPatellaLocal*supPatCart_inGlobal;
                % Now look at X-Z positions only (X for medial, Z for inferior; set Y as minimum (most posterior)
                patella_origin_inLocal = [medPatCart_inLocal(1); min(localData(:,3)); infPatCart_inLocal(3)];   
                localOffsetData = localData;
                for i = 1:length(localData)
                    localOffsetData(i,2:4) = ((localData(i,2:4))'-patella_origin_inLocal)';
                end                
                % Extract data from one side or the other based on X location
                if strcmp(side,'M')
                    localOffsetData(localOffsetData(:,2) > halfX,2:5) = NaN;
                elseif strcmp(side,'L')
                    localOffsetData(localOffsetData(:,2) <= halfX,2:5) = NaN;
                end                
            end
            obj.Local = dataset({localOffsetData,cnames{:}});
            % -------------------------------------------------------------
            % Normalize to dimensions of tibia / patella
            normData = localOffsetData;
            if regexp(type,'Tib')
                % X width (med/lat) = 70.0
                xWidth = latTibCart_inLocal(1)-medTibCart_inLocal(1);
                % Y width (ant/post) = 49.6
                yWidth = antTibCart_inLocal(2)-postTibCart_inLocal(2);
                normData(:,2) = normData(:,2)/xWidth*100;
                normData(:,3) = normData(:,3)/yWidth*100;                
            elseif regexp(type,'Pat')
                % X width (med/lat) = 40.5
                xWidth = latPatCart_inLocal(1)-medPatCart_inLocal(1);
                % Z width (inf/sup) = 42.1
                zWidth = supPatCart_inLocal(3)-infPatCart_inLocal(3);
                normData(:,2) = normData(:,2)/xWidth*100;
                normData(:,4) = normData(:,4)/zWidth*100;
            end
            obj.Data = dataset({normData,cnames{:}});
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
                tempData = normData(frameStartInd(i):frameEndInd(i),:);
                tempData((tempData(:,5) < 0.1 | tempData(:,5) > 50),:) = NaN;                
                % Weighted average for location based on values
                for j = 1:3
                    wAvgLoc(i,j) = nansum(tempData(:,j+1).*tempData(:,5))/...
                                   nansum(tempData(:,5));
                end
                % Maximum location and magnitude
                tempData = normData(frameStartInd(i):frameEndInd(i),:);
                tempData(tempData(:,5) > 50,5) = NaN;
                [~,ind] = max(tempData(:,5));
                maxRowInd = frameStartInd(i) + ind - 1;
                maxInfo(i,:) = normData(maxRowInd,2:5);
            end
            % Fill in NaNs
            xi = (0:20)';
            wAvgSpline = zeros(size(wAvgLoc));
            for j = 1:3
               wAvgSpline(:,j) = interp1(xi(~isnan(wAvgLoc(:,j))),wAvgLoc(~isnan(wAvgLoc(:,j)),j),xi,'spline',NaN);               
            end
            % Save
            obj.Avg = dataset({wAvgSpline,dofs{:}});
            labels = {'X','Y','Z','Value'};
            obj.Max = dataset({maxInfo,labels{:}});
        end
    end
    
end
