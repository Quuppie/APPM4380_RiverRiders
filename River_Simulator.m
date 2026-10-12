% Author: Samuel Brauer
% Date: 9/30/2026
% Inputs: Takes in nx2 matrix of coordinates as well as a 1x1 cell
% containing the average width of the river.
% Outputs: Plots the original river coordinates put in and shows the
% progression of that river with time.
% Description: Takes in river coordinates and creates a spline to curve fit
% it. Then, shows how the river progresses in time.

clear
close all;
clc

% Useful constants
% Earth radius in kilometers
R = 6371;
Max_Rivers = 9; % Maximum num of rivers that are to be analyized

% Read in the data
filename = 'River_Data.xlsx';
Sheetname = {'Africa','Americas','Asia'};
cellRef = {'D3:D3', 'K3:K3', 'R3:R3'};
Name_Ranges = {'A1:A1','H1:H1','O1:O1'};
Ranges = {'B3:C306','I3:J388','P3:Q97';'B3:C272','I3:J581','';'B3:C181','',''};
ERV = zeros(3,1); % Empty River Vector counts num river vectors in the sheet are empty

for i=1:length(Sheetname)
    Sheet_num = i;
    for j=1:3
        if isempty(Ranges{i,j}) || (ischar(Ranges{i,j}) && isempty(strtrim(Ranges{i,j})))
            ERV(i) = ERV(i)+1;
            continue;
        end
        coords{i,j} = readmatrix(filename, 'Sheet', Sheetname{Sheet_num}, 'Range', Ranges{i,j});
        names{i,j} = readcell(filename, 'Sheet', Sheetname{Sheet_num}, 'Range', Name_Ranges{j});
        width{i,j} = readmatrix(filename, 'Sheet', Sheetname{Sheet_num}, 'Range', cellRef{j});
        coords{i,j} = coords{i,j}(~all(isnan(coords{i,j}), 2), :);
    end
    if i == 1 && ERV(i) < 3
        if ERV(i) == 3
            Africa_Coords = 0;
            Africa_Width = 0;
            continue;
        end
        for k=1:3-ERV(i)
            Africa_Coords{k} = coords{i,k};
        end
        Africa_Width = width{i,:};
    elseif i == 2
        if ERV(i) == 3
            Americas_Coords = 0;
            Americas_Width = 0;
            continue;
        end
        for k=1:3-ERV(i)
            Americas_Coords{k} = coords{i,k};
        end
        Americas_Width = vertcat(width{i,:});
    elseif i == 3
        if ERV(i) == 3
            Asia_Coords = 0;
            Asia_Width = 0;
            continue;
        end
        for k=1:3-ERV(i)
            Asia_Coords{k} = coords{i,k};
        end
        Asia_Width = width{i,:};
    end
end

% Test conversion and plotting
Rivers = {};
RiverNames = {};
RiverContinents = {};
for i = 1:length(Sheetname)

    for j = 1:3

        % Skip empty river entries
        if isempty(Ranges{i,j}) || (ischar(Ranges{i,j}) && isempty(strtrim(Ranges{i,j})))
            continue;
        end

        % Get latitude and longitude
        latitude = coords{i,j}(:,1);
        longitude = coords{i,j}(:,2);

        % Reference point for this river
        lat0 = latitude(1);
        lon0 = longitude(1);

        % Convert degrees to radians
        lat_rad = deg2rad(latitude);
        lon_rad = deg2rad(longitude);
        lat0_rad = deg2rad(lat0);

        % Convert to kilometers
        x = R * (lon_rad - deg2rad(lon0)) .* cos(lat0_rad);
        y = R * (lat_rad - lat0_rad);

        % Create a new figure for each river
        figure;
        hold on;
        
        % Plot original river measurements
        plot(x, y, 'k.', 'MarkerSize', 8);
        
        % Parameter based on cumulative distance along the river
        ds = hypot(diff(x), diff(y));
        s = [0; cumsum(ds)];
        
        % Remove consecutive duplicate points
        keep = [true; diff(s) > 1e-8];
        s = s(keep);
        xFit = x(keep);
        yFit = y(keep);

                % Get latitude and longitude
        latitude = coords{i,j}(:,1);
        longitude = coords{i,j}(:,2);

        % Reference point for local Cartesian coordinates
        lat0 = latitude(1);
        lon0 = longitude(1);

        if i==1
            l = 0;
        elseif i==2
            l = 3-ERV(i-1);
        elseif i==3
            l = 6-(ERV(i-2)+ERV(i-1));
        end

        % Convert to kilometers
        x = R * (deg2rad(longitude) - deg2rad(lon0)) ...
            .* cos(deg2rad(lat0));
        y = R * (deg2rad(latitude) - deg2rad(lat0));

        % Store this river's coordinates and identity
        Rivers{end+1,1} = [x, y];
        RiverNames{end+1,1} = names{i,j}{1};
        RiverContinents{end+1,1} = Sheetname{i};
        
        % Generate a densely sampled parameter for the spline
        sFine = linspace(s(1), s(end), max(500, 5*numel(s)));
        
        % Fit smoothing splines
        % Requires Curve Fitting Toolbox
        smoothingParameter = 0.99;
        
        splineX{j+l} = csaps(s, xFit', smoothingParameter, sFine);
        splineY{j+l} = csaps(s, yFit', smoothingParameter, sFine);
        
        % Plot smoothed river centerline
        plot(splineX{j+l}, splineY{j+l}, 'r-', 'LineWidth', 2);
        
        xlabel('X Distance (km)');
        ylabel('Y Distance (km)');
        
        title(sprintf('%s - %s', Sheetname{i}, names{i,j}{1}));
        
        legend('Original measurements', 'Smoothed spline', ...
            'Location', 'best');
        
        grid on;
        axis equal;
        hold off;

    end

end

%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculate radius of curvature for every river

% Compute radius of curvature for every river
[CurvatureResults, CurvatureData] = computeRiverRadiiToVars(Rivers);
% Store a separate radius vector for every river
RadiusOfCurvature = cell(length(Rivers),1);

% Display the river names and number of points analyzed
for i = 1:length(Rivers)
        RadiusOfCurvature{i} = CurvatureResults(i).radius;

    % Also store the river's name and continent with its results
    CurvatureResults(i).name = RiverNames{i};
    CurvatureResults(i).continent = RiverContinents{i};
    fprintf('%s (%s): %d points analyzed\n', ...
        RiverNames{i}, RiverContinents{i}, ...
        length(RadiusOfCurvature{i}));
end
%%%%%%%%%%%%%%%%%%%%


for i = 1:length(Rivers)
    kappa = CurvatureResults(i).kappa;
    figure;
    hold on;
    plot(splineX{i}, splineY{i}, 'k-', 'LineWidth', 1.5);
    
    % Plot curvature at the original river measurement locations
    scatter(Rivers{i}(:,1), Rivers{i}(:,2), 35, CurvatureResults(i).kappa, 'filled');
    % Add a colorbar to indicate curvature magnitude
    cb = colorbar;
    cb.Label.String = 'Curvature, \kappa (1/km)';
    
    xlabel('X Distance (km)');
    ylabel('Y Distance (km)');
    %title(sprintf('%s - %s Curvature',Sheetname{i}, names{i,j}{1}));
    
    grid on;
    axis equal;
    hold off;
end


% calc radius of curvature with 3 points
% UPDATE THIS CODE TO WORK WITH MINE PLEASE


function [results, allData] = computeRiverRadiiToVars(rivers)
% computeRiverRadiiToVars
% Calculate radius of curvature at every point of every river.
%
% INPUT:
%   rivers  - Cell array; each cell contains an Nx2 matrix [x y]
%
% OUTPUT:
%   results - Struct array containing coordinates, curvature,
%             and radius for each river
%   allData - Combined table of all river points and their results
%
% Radius is expressed in the same units as x and y.
% For your main code, this means kilometers.

nR = numel(rivers);

results = struct( ...
    'coords', cell(nR,1), ...
    'kappa', cell(nR,1), ...
    'radius', cell(nR,1));

riverID = [];
xcol = [];
ycol = [];
kcol = [];
rcol = [];

for i = 1:nR

    % Get coordinates for this river
    pts = rivers{i};

    x = pts(:,1);
    y = pts(:,2);

    N = size(pts,1);

    % Initialize outputs
    kappa = nan(N,1);
    radius = nan(N,1);

    if N >= 3

        % Calculate curvature from three consecutive points.
        % Use the first three points for the first point,
        % the last three points for the last point,
        % and centered triples for interior points.

        for k = 1:N

            if k == 1
                idx = 1:3;
            elseif k == N
                idx = N-2:N;
            else
                idx = k-1:k+1;
            end

            x1 = x(idx(1));
            y1 = y(idx(1));

            x2 = x(idx(2));
            y2 = y(idx(2));

            x3 = x(idx(3));
            y3 = y(idx(3));

            % Side lengths of the triangle
            a = hypot(x2-x3, y2-y3);
            b = hypot(x1-x3, y1-y3);
            c = hypot(x1-x2, y1-y2);

            % Twice the signed triangle area
            crossProduct = ...
                (x2-x1)*(y3-y1) - ...
                (y2-y1)*(x3-x1);

            % Radius of the circumcircle:
            % R = (a*b*c)/(4*triangle area)
            %
            % Since abs(crossProduct) = 2*triangle area:
            % R = a*b*c/(2*abs(crossProduct))

            if abs(crossProduct) > 1e-12

                radius(k) = ...
                    (a*b*c)/(2*abs(crossProduct));

                kappa(k) = 1/radius(k);

            else
                % Collinear or nearly collinear points
                radius(k) = Inf;
                kappa(k) = 0;
            end
        end

    elseif N == 2

        % Two points are insufficient to define curvature
        radius(:) = NaN;
        kappa(:) = NaN;

    elseif N == 1

        % One point is insufficient to define curvature
        radius(:) = NaN;
        kappa(:) = NaN;

    end

    % Save results for this river
    results(i).coords = pts;
    results(i).kappa = kappa;
    results(i).radius = radius;

    % Append data to the combined table
    riverID = [riverID; repmat(i,N,1)];
    xcol = [xcol; x];
    ycol = [ycol; y];
    kcol = [kcol; kappa];
    rcol = [rcol; radius];

end

% Create a table containing every river point
allData = table( ...
    riverID, xcol, ycol, kcol, rcol, ...
    'VariableNames', ...
    {'riverID','x','y','kappa','radius'});

end
 

