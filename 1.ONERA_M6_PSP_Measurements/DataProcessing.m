% Define the directory containing the .tif files
folderPath = fullfile(pwd, 'ONERA_M6_Surface_Pressure_Data'); 

% List all .tif files in the directory
filePattern = fullfile(folderPath, '*.tif');
tiffFiles = dir(filePattern);

% Dimensions of the wing 
realChordLength_mm = 101.6; % [mm] 
realSpanLength_mm = 152.4;  % [mm] 
rho = 1.225;                % [kg/m^3]

% Check if there are any .tif files in the directory
if isempty(tiffFiles)
    error('No .tif files found in the directory: %s', folderPath);
end

% Loop through each .tif file
for k = 1:length(tiffFiles)
    % Get the file name and full path
    baseFileName = tiffFiles(k).name;
    fullFilePath = fullfile(folderPath, baseFileName);
    
    % Read the .tif file
    dataArray = double(imread(fullFilePath));
    
    % Create binary mask for non zero and non NaN data
    validMask = (dataArray > 0) & ~isnan(dataArray);
    
    % Detect edges of the wing
    [nonZeroRows, nonZeroCols] = find(validMask); % Indices of valid data
    tipChordCol = min(nonZeroCols);               % Leftmost column 
    rootChordCol = max(nonZeroCols);              % Rightmost column 
    leadingEdgeRow = min(nonZeroRows);            % Topmost row 
    trailingEdgeRow = max(nonZeroRows);           % Bottommost row 
    
    % Bounding box dimensions in pixels
    spanLength_pixels = rootChordCol - tipChordCol;        % Horizontal span length
    chordLength_pixels = trailingEdgeRow - leadingEdgeRow; % Vertical chord length
    
    % Compute scaling factors (mm/pixel)
    xScalingFactor = realSpanLength_mm / spanLength_pixels;   % Spanwise scaling [mm/pixel]
    yScalingFactor = realChordLength_mm / chordLength_pixels; % Chordwise scaling [mm/pixel]
    
    % Generate calibrated coordinate grids 
    [rows, cols] = size(dataArray);
    xCoords_mm = ((1:cols) - tipChordCol) * xScalingFactor;     % Horizontal span coordinates
    yCoords_mm = ((1:rows)' - leadingEdgeRow) * yScalingFactor; % Vertical chord coordinates
    
    % Plotting
    figure;
    imagesc(xCoords_mm, yCoords_mm, dataArray); 
    colormap('turbo'); 
    colorbar('eastoutside');
    xlabel('Spanwise Distance (mm)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Chordwise Distance (mm)', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Calibrated PSP Image: ', baseFileName], 'Interpreter', 'none', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    xlim([min(xCoords_mm(:)), max(xCoords_mm(:))]); 
    ylim([min(yCoords_mm(:)), max(yCoords_mm(:))]); 

end

% ----------------------------- %
% Pressure Coefficient Contours %
% ----------------------------- %

% Initialize a map to store P_inf values for each velocity
P_inf_map = containers.Map('KeyType', 'double', 'ValueType', 'double');

% Loop through each .tif file
for k = 1:length(tiffFiles)
    % Get the file name and full path
    baseFileName = tiffFiles(k).name;
    fullFilePath = fullfile(folderPath, baseFileName);
    
    % Extract velocity and AoA from file name
    velocity_ft_s = sscanf(baseFileName, 'V%d_');   % Extract velocity [ft/s]
    AoA_deg = sscanf(baseFileName, '%*[^_]_%fdeg'); % Extract AoA [deg]
    V_inf = velocity_ft_s * 0.3048;                 % Convert velocity [m/s]
    
    fprintf('Processing file: %s | Velocity: %.2f m/s | AoA: %.2f°\n', baseFileName, V_inf, AoA_deg);
    
    % Read the .tif file
    dataArray = double(imread(fullFilePath));
    
    % Create binary mask for non zero and non NaN data
    validMask = (dataArray > 0) & ~isnan(dataArray);
    
    % Detect edges of the wing
    [nonZeroRows, nonZeroCols] = find(validMask); % Indices of valid data
    trailingEdgeRow = max(nonZeroRows);           % Bottommost row 
    tipChordCol = min(nonZeroCols);               % Leftmost column 
    rootChordCol = max(nonZeroCols);              % Rightmost column 
    
    % Define trailing edge region (bottom 10% of the chord)
    trailingEdgeStartRow = trailingEdgeRow - round(0.1 * (trailingEdgeRow - min(nonZeroRows)));
    trailingEdgeEndRow = trailingEdgeRow;
    
    % Create a mask for the trailing edge region
    trailingEdgeMask = false(size(dataArray));
    trailingEdgeMask(trailingEdgeStartRow:trailingEdgeEndRow, tipChordCol:rootChordCol) = true;
    
    % Determine P_inf for matching velocity and 0 deg AoA
    if contains(baseFileName, '0deg', 'IgnoreCase', true) && ~isKey(P_inf_map, V_inf)
        % Extract trailing edge region values
        trailingEdgeValues = dataArray(trailingEdgeMask);
        trailingEdgeValues = trailingEdgeValues(trailingEdgeValues > 0); % Exclude zero values
        
        % Compute P_inf as the mean of trailing edge pressures
        P_inf = mean(trailingEdgeValues, 'all');
        P_inf_map(V_inf) = P_inf; % Store P_inf for this velocity
        fprintf('Determined P_inf for velocity %.2f m/s: %.2f\n', V_inf, P_inf);
    end
    
    % Check if a matching P_inf exists for the current velocity
    if ~isKey(P_inf_map, V_inf)
        error('No P_inf found for velocity %.2f m/s. Ensure matching 0 AoA data is available.', V_inf);
    end
    P_inf = P_inf_map(V_inf); % Retrieve the matching P_inf
    
    % Compute Cp for the current image
    Cp = (dataArray - P_inf) / (0.5 * rho * V_inf^2); 
    
    % Generate calibrated coordinate grids 
    [rows, cols] = size(dataArray);
    xCoords_mm = ((1:cols) - tipChordCol) * (realSpanLength_mm / (rootChordCol - tipChordCol));                % Horizontal span [mm]
    yCoords_mm = ((1:rows)' - min(nonZeroRows)) * (realChordLength_mm / (trailingEdgeRow - min(nonZeroRows))); % Vertical chord [mm]
    
    % Plotting
    figure;
    imagesc(xCoords_mm, yCoords_mm, Cp); 
    colormap('turbo'); 
    colorbar('eastoutside'); 
    caxis([prctile(Cp(:), 5), prctile(Cp(:), 95)]);
    xlabel('Spanwise Distance (mm)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Chordwise Distance (mm)', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Pressure Coefficient (Cp): ', baseFileName], 'Interpreter', 'none', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    xlim([min(xCoords_mm(:)), max(xCoords_mm(:))]); 
    ylim([min(yCoords_mm(:)), max(yCoords_mm(:))]); 
    
end

% ----------------------------- %
%       Pressure Profiles       %
% ----------------------------- %

% Define the velocity 
targetVelocity_ft_s = 200; % [ft/s]
targetVelocity_m_s = targetVelocity_ft_s * 0.3048; % [m/s]

% Define spanwise locations 
spanwiseStations = [0.2, 0.44, 0.6, 0.8, 0.9];

% Loop through each .tif file
for k = 1:length(tiffFiles)
    % Get the file name and full path
    baseFileName = tiffFiles(k).name;
    fullFilePath = fullfile(folderPath, baseFileName);
    
    % Extract velocity and AoA from file name
    fileVelocity = sscanf(baseFileName, 'V%d_');    % Extract velocity [ft/s]
    fileAoA = sscanf(baseFileName, '%*[^_]_%fdeg'); % Extract AoA [deg]
    V_inf = fileVelocity * 0.3048;                  % Convert velocity to [m/s]
    
    % Skip files that don't match target velocity
    if fileVelocity ~= targetVelocity_ft_s
        continue;
    end
        
    % Read the matching file
    dataArray = double(imread(fullFilePath));
    
    % Create binary mask for non zero and non NaN data
    validMask = (dataArray > 0) & ~isnan(dataArray);
    
    % Detect edges of the wing
    [nonZeroRows, nonZeroCols] = find(validMask); % Indices of valid data
    trailingEdgeRow = max(nonZeroRows);           % Bottommost row 
    tipChordCol = min(nonZeroCols);               % Leftmost column 
    rootChordCol = max(nonZeroCols);              % Rightmost column
    
    % Compute scaling factors
    xScalingFactor = realSpanLength_mm / (rootChordCol - tipChordCol);          % Span scaling [mm/pixel]
    yScalingFactor = realChordLength_mm / (trailingEdgeRow - min(nonZeroRows)); % Chord scaling [mm/pixel]
    
    % Generate calibrated coordinate grids 
    [rows, cols] = size(dataArray);
    xCoords_mm = ((1:cols) - tipChordCol) * xScalingFactor;       % Horizontal span [mm]
    yCoords_mm = ((1:rows)' - min(nonZeroRows)) * yScalingFactor; % Vertical chord [mm]
    
    % Retrieve freestream pressure for the current velocity
    if ~isKey(P_inf_map, V_inf)
        error('P_inf not found for velocity %.2f m/s. Ensure matching 0 AoA data is available.', V_inf);
    end
    P_inf = P_inf_map(V_inf);
    
    % Compute Cp
    Cp = (dataArray - P_inf) / (0.5 * rho * V_inf^2); 
    
    % Determine spanwise positions in pixels
    spanLengthPixels = rootChordCol - tipChordCol;                              % Total span in pixels
    spanwiseIndices = round(spanwiseStations * spanLengthPixels) + tipChordCol; % Translate x/b to pixel indices
    
    % Plot pressure profiles at each spanwise station
    figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]); 
    hold on;
    
    for stationIdx = 1:length(spanwiseStations)
        spanwiseCol = spanwiseIndices(stationIdx); % Column index for spanwise station
        CpProfile = Cp(:, spanwiseCol);            % Extract Cp along the chord at spanwise location
        
        % Convert chordwise distance to non-dimensional x/c
        chordwiseDistance = yCoords_mm; % [mm]
        xOverC = (chordwiseDistance - min(chordwiseDistance)) / realChordLength_mm;
        
        % Plot the Cp profile
        plot(xOverC, CpProfile, 'DisplayName', sprintf('x/b = %.2f', spanwiseStations(stationIdx)));
    end
    
    xlabel('x/c (Non-Dimensional Chordwise Distance)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('C_p (Pressure Coefficient)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Pressure Profiles at Different Spanwise Stations for V = 200 ft/s | AoA = %.1f°', fileAoA), 'FontSize', 16, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 10);
    grid on;
    axis tight;
    hold off;
    
end


