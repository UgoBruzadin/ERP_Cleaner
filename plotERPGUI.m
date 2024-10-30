% Main function to create GUI and plot ERPs
function plotERPGUI()
    % Create main figure
    mainFig = figure('Name', 'ERP Analysis Tool', ...
                    'Position', [100 100 1200 600], ...
                    'MenuBar', 'none', ...
                    'ToolBar', 'none');
    
    % Create panel for side menu
    sidePanel = uipanel('Parent', mainFig, ...
                       'Position', [0 0 0.2 1], ...
                       'BackgroundColor', [0.94 0.94 0.94]);
    
    % Create panel for plot
    plotPanel = uipanel('Parent', mainFig, ...
                       'Position', [0.2 0 0.8 1]);
    
    % Create two axes for plots
    axes1 = axes('Parent', plotPanel, ...
                'Position', [0.1 0.55 0.8 0.4]);
    axes2 = axes('Parent', plotPanel, ...
                'Position', [0.1 0.05 0.8 0.4]);
                   
    % File Selection Section
    createLabel(sidePanel, 'Select EEG File:', 20, 580);
    fileList = dir('*.set');
    fileNames = {fileList.name};
    fileDropdown = uicontrol('Parent', sidePanel, ...
                            'Style', 'popupmenu', ...
                            'String', fileNames, ...
                            'Position', [20 550 200 30], ...
                            'Callback', @fileSelected);
    
    % Event Selection Section
    createLabel(sidePanel, 'Select Event Types:', 20, 500);
    eventList = uicontrol('Parent', sidePanel, ...
                         'Style', 'listbox', ...
                         'String', {'Select a file first'}, ...
                         'Position', [20 440 200 60], ... % Made taller for multiple selections
                         'Max', 2, ... % Enable multiple selection
                         'Value', 1, ...
                         'Callback', @updatePlot);
    
    % Time Window Section
    createLabel(sidePanel, 'Time Window (ms):', 20, 420);
    startTime = uicontrol('Parent', sidePanel, ...
                         'Style', 'edit', ...
                         'String', '-200', ...
                         'Position', [20 390 95 30], ...
                         'Callback', @updatePlot);
    endTime = uicontrol('Parent', sidePanel, ...
                       'Style', 'edit', ...
                       'String', '800', ...
                       'Position', [125 390 95 30], ...
                       'Callback', @updatePlot);
    
    % Channel/Component Selection Section
    createLabel(sidePanel, 'Available Channels/ICs:', 20, 340);
    channelList = uicontrol('Parent', sidePanel, ...
                             'Style', 'listbox', ...
                             'String', {'Select a file first'}, ...
                             'Position', [20 240 80 100], ...
                             'Max', 2, ... % Enable multiple selection
                             'Value', 1);

%     channelList = uicontrol('Parent', sidePanel, ...
%                            'Style', 'listbox', ...
%                            'String', {'Select a file first'}, ...
%                            'Position', [20 240 200 100], ...
%                            'Max', 2, ... % Enable multiple selection
%                            'Value', 1, ...
%                            'Callback', @updatePlot);
    % Add forward/backward buttons
    forwardBtn = uicontrol('Parent', sidePanel, ...
                          'Style', 'pushbutton', ...
                          'String', '>>', ...
                          'Position', [105 280 30 20], ...
                          'Callback', @moveForward);
                          
    backwardBtn = uicontrol('Parent', sidePanel, ...
                           'Style', 'pushbutton', ...
                           'String', '<<', ...
                           'Position', [105 260 30 20], ...
                           'Callback', @moveBackward);
                           
    % Add rejected list
    rejectedList = uicontrol('Parent', sidePanel, ...
                            'Style', 'listbox', ...
                            'String', {}, ...
                            'Position', [140 240 80 100], ...
                            'Max', 2);
    
    % Select All/None Buttons for Channels
    selectAll = uicontrol('Parent', sidePanel, ...
                         'Style', 'pushbutton', ...
                         'String', 'Select All', ...
                         'Position', [20 210 95 30], ...
                         'Callback', {@selectChannels, 'all'});
    
    selectNone = uicontrol('Parent', sidePanel, ...
                          'Style', 'pushbutton', ...
                          'String', 'Select None', ...
                          'Position', [125 210 95 30], ...
                          'Callback', {@selectChannels, 'none'});
    
    % Data Type Toggle
    dataTypeToggle = uicontrol('Parent', sidePanel, ...
                              'Style', 'togglebutton', ...
                              'String', 'Show Component ERPs', ...
                              'Position', [20 160 200 30], ...
                              'Value', 0, ...
                              'Callback', @dataTypeToggled);

    createLabel(sidePanel, 'Data Modification:', 20, 140);

%     
%     rejectButton = uicontrol('Parent', sidePanel, ...
%                             'Style', 'pushbutton', ...
%                             'String', 'Reject Components', ...
%                             'Position', [20 110 95 30], ...
%                             'Callback', @rejectComponents);
%                             
%     interpolateButton = uicontrol('Parent', sidePanel, ...
%                                  'Style', 'pushbutton', ...
%                                  'String', 'Interpolate Channels', ...
%                                  'Position', [125 110 95 30], ...
%                                  'Callback', @interpolateChannels);
                                 
    % Save Section
    createLabel(sidePanel, 'Save Suffix:', 20, 80);
    suffixBox = uicontrol('Parent', sidePanel, ...
                         'Style', 'edit', ...
                         'String', 'New', ...
                         'Position', [20 60 200 20]);

    %createLabel(sidePanel, 'Save Dataset:', 20, 60);
    saveButton = uicontrol('Parent', sidePanel, ...
                          'Style', 'pushbutton', ...
                          'String', 'Save', ...
                          'Position', [20 10 200 30], ...
                          'Callback', @saveDataset);
    
    
    % Store handles and data in figure UserData
    userData.axes1 = axes1;
    userData.axes2 = axes2;
    userData.availableList = channelList;
    userData.rejectedList = rejectedList;
    userData.originalEEG = []; % Store original data

    userData.plotPanel = plotPanel;
    userData.fileDropdown = fileDropdown;
    userData.eventList = eventList;
    userData.suffixBox = suffixBox;
    userData.dataTypeToggle = dataTypeToggle;
    userData.channelList = channelList;
    userData.startTime = startTime;
    userData.endTime = endTime;
    userData.currentEEG = [];
    userData.tempEEG = [];
    set(mainFig, 'UserData', userData);
end


function rejectComponents(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    if ~isfield(userData.currentEEG, 'icaact')
        errordlg('No ICA data available', 'Error');
        return;
    end
    
    selectedComps = get(userData.channelList, 'Value');
    if isempty(selectedComps)
        return;
    end
    
    % Create a copy of the dataset
    EEG = userData.currentEEG;
    EEG = pop_subcomp(EEG, selectedComps, 0); % 0 means don't plot
    
    % Update the current dataset
    userData.currentEEG = EEG;
    set(mainFig, 'UserData', userData);
    
    % Update the plot
    updatePlot(source, []);
end

function interpolateChannels(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    if get(userData.dataTypeToggle, 'Value')
        errordlg('Switch to channel mode to interpolate channels', 'Error');
        return;
    end
    
    selectedChans = get(userData.channelList, 'Value');
    if isempty(selectedChans)
        return;
    end
    
    % Create a copy of the dataset
    EEG = userData.currentEEG;
    EEG = pop_interp(EEG, selectedChans, 'spherical');
    
    % Update the current dataset
    userData.currentEEG = EEG;
    set(mainFig, 'UserData', userData);
    
    % Update the plot
    updatePlot(source, []);
end

function saveDataset(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    if isempty(userData.currentEEG)
        return;
    end
    
    % Get the suffix from the textbox
    suffix = get(userData.suffixBox, 'String');
    
    % Get the current file name
    fileList = get(userData.fileDropdown, 'String');
    selectedIdx = get(userData.fileDropdown, 'Value');
    currentFile = fileList{selectedIdx};
    
    % Split the filename and extension
    [~, name, ext] = fileparts(currentFile);
    
    % Create new filename with suffix
    if ~isempty(suffix)
        newFilename = [name '_' suffix ext];
    else
        newFilename = [name '_modified' ext];
    end
    
    % Save the dataset in the current directory
    try
        EEG = userData.tempEEG;
        pop_saveset(EEG, 'filename', newFilename, 'filepath', pwd);
        msgbox(['File saved as: ' newFilename], 'Save Successful');
    catch err
        errordlg(['Error saving file: ' err.message], 'Error');
    end
end

% Helper function to create labels
function createLabel(parent, text, x, y)
    uicontrol('Parent', parent, ...
              'Style', 'text', ...
              'String', text, ...
              'Position', [x y 200 20], ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'HorizontalAlignment', 'left');
end

% Callback for file selection
function fileSelected(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    % Get selected file
    fileList = get(source, 'String');
    selectedIdx = get(source, 'Value');
    selectedFile = fileList{selectedIdx};
    
    try
        EEG = pop_loadset(selectedFile);
        userData.currentEEG = EEG;
        userData.originalEEG = EEG; % Store original data
        userData.tempEEG = EEG;
        
        % Update event type list
        eventTypes = unique({EEG.event.type});
        set(userData.eventList, 'String', eventTypes);
        %set(userData.eventList, 'Value', 1);
        
        items = {userData.currentEEG.chanlocs.labels};
        set(userData.availableList, 'String', items);
        %set(userData.rejectedList, 'Value', []); % Clear selection
        set(userData.rejectedList, 'String', {});
        
        
        % Update channel list based on current mode
        %updateChannelList(mainFig);
        
        % Update UserData and plot
        set(mainFig, 'UserData', userData);
        updatePlot(source, []);
    catch err
        errordlg(['Error loading file: ' err.message], 'Error');
    end
end


% Callback for data type toggle
function dataTypeToggled(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    % Clear rejected list when switching modes
    set(userData.rejectedList, 'String', {});
    
    % Update available list
    updateChannelList(mainFig);
    
    % Update plot with current settings
    updatePlot(source, []);
end

% Function to update channel/component list
function updateChannelList(mainFig)
    userData = get(mainFig, 'UserData');
    if isempty(userData.currentEEG)
        return;
    end
    
    % Get currently rejected items
    rejectedItems = get(userData.rejectedList, 'String');
    
    % Check if showing components or channels
    if get(userData.dataTypeToggle, 'Value') && isfield(userData.currentEEG, 'icaact')
        % Show components
        numComps = size(userData.currentEEG.icaact, 1);
        items = cellstr(num2str((1:numComps)', 'IC%d'));
    else
        % Show channels
        items = {userData.currentEEG.chanlocs.labels};
    end
    
    % Remove any items that are in the rejected list
    items = setdiff(items, rejectedItems, 'stable');
    
    % Update available list
    set(userData.channelList, 'String', items);
    %set(userData.availableList, 'String', items);
    %set(userData.rejectedList, 'Value', []); % Clear selection
end

% Callback for select all/none buttons
function selectChannels(source, ~, mode)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    items = get(userData.availableList, 'String');
    
    if strcmp(mode, 'all')
        set(userData.availableList, 'Value', 1:length(items));
    else % none
        set(userData.availableList, 'Value', []);
    end
    
    updatePlot(source, []);
end

% Helper function to get main figure handle
function mainFig = getMainFigure(source)
    mainFig = source;
    while ~strcmp(get(mainFig, 'Type'), 'figure')
        mainFig = get(mainFig, 'Parent');
    end
end

% Callback for plot updates

function updatePlot(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    if isempty(userData.currentEEG)
        return;
    end
    
    % Get current settings
    eventList = get(userData.eventList, 'String');
    selectedEventIdx = get(userData.eventList, 'Value');
    selectedEvent = eventList(selectedEventIdx);
    
    % Get time window
    startTime = str2double(get(userData.startTime, 'String'));
    endTime = str2double(get(userData.endTime, 'String'));
    timeWindow = [startTime endTime];
    
    % Get rejected items
    rejectedItems = get(userData.rejectedList, 'String');
    
    % Create temporary EEG with rejections applied
    tempEEG = userData.currentEEG;
    
    
    % Clear existing plots
    cla(userData.axes1);
    cla(userData.axes2);
    
    % Plot in both axes
    % For original data (top plot)
    axes(userData.axes1);
    if get(userData.dataTypeToggle, 'Value') && isfield(userData.currentEEG, 'icaact')
        plotComponentERP(userData.originalEEG, selectedEvent, timeWindow, 1:size(userData.originalEEG.icaact, 1));
    else
        plotEventERP(userData.originalEEG, selectedEvent, timeWindow, 1:userData.originalEEG.nbchan);
    end
    title('Original Data');
    
    % For modified data (bottom plot)
    axes(userData.axes2);
    if ~isempty(rejectedItems)
        % Separate ICs and channels
        icMask = cellfun(@(x) strncmp(x, ' IC', 2), rejectedItems);
        
        % Handle IC rejections
        if any(icMask)
            icNums = cellfun(@(x) str2double(x(4:end)), rejectedItems(icMask));
            tempEEG = pop_subcomp(tempEEG, icNums, 0);
            tempEEG.icaact = eeg_getdatact(tempEEG, 'component', [1:size(tempEEG.icaweights,1)]);
            userData.tempEEG = tempEEG;
        end
        
        % Handle channel interpolation
        chanLabels = rejectedItems(~icMask);
        if ~isempty(chanLabels)
            [~, chanInds] = ismember(chanLabels, {tempEEG.chanlocs.labels});
            chanInds = chanInds(chanInds > 0); % Remove any zero indices
            if ~isempty(chanInds)
                tempEEG = pop_interp(tempEEG, chanInds, 'spherical');
                userData.tempEEG = tempEEG;
            end
        end
    end
    
    % Plot the modified data
    if get(userData.dataTypeToggle, 'Value') && isfield(tempEEG, 'icaact')
        % Get remaining components (not rejected)
        allComps = 1:size(tempEEG.icaact, 1);
        if ~isempty(rejectedItems)
            rejectedComps = cellfun(@(x) str2double(x(3:end)), rejectedItems(icMask));
            remainingComps = setdiff(allComps, rejectedComps);

            plotComponentERP(tempEEG, selectedEvent, timeWindow, 1:size(tempEEG.icaact, 1));
        else
            plotComponentERP(userData.originalEEG, selectedEvent, timeWindow, 1:size(userData.originalEEG.icaact, 1));
        end
    else
        plotEventERP(tempEEG, selectedEvent, timeWindow, 1:tempEEG.nbchan);
        
    end
    title('Preview with Rejections');
    userData.tempEEG = tempEEG;
    set(mainFig, 'UserData', userData);
end

% Modified plotEventERP function with channel selection
function plotEventERP(EEG, eventType, timeWindow, selectedChannels)
    % Find indices of specified event type
    eventIndices = [];
    for i=1:length(eventType)
        eventIndices = [eventIndices, find(strcmp({EEG.event.type}, eventType(i)))];
    end
    % Calculate time vector
    times = linspace(timeWindow(1), timeWindow(2), diff(timeWindow)*EEG.srate/1000);
    
    % Initialize matrix for selected channels only
    numSamples = length(times);
    epochs = zeros(length(eventIndices), numSamples, length(selectedChannels));
    
    % Extract epochs for selected channels
    for i = 1:length(eventIndices)
        startSample = round(timeWindow(1)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);
        endSample = round(timeWindow(2)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);
        
        if startSample > 0 && endSample <= EEG.xmax*1000
            for chanIdx = 1:length(selectedChannels)
                chan = selectedChannels(chanIdx);
                epochs(i, :, chanIdx) = EEG.data(chan, startSample:endSample-1, EEG.event(i).epoch);
            end
        end
    end
    
    % Calculate average ERPs
    meanERP = squeeze(mean(epochs, 1));
    
    % Plot ERPs for selected channels
    h = plot(times, meanERP);
    grid on;
    xlabel('Time (ms)');
    ylabel('Amplitude (µV)');
    title(['Average ERP for Event ']);
    
    % Create custom data tips for selected channels
    for i = 1:length(h)
        set(h(i), 'UserData', EEG.chanlocs(selectedChannels(i)).labels);
    end
    
    
    datacursormode on;
    for i = 1:length(h)
        set(h(i), 'ButtonDownFcn', {@lineCallback, h(i)});
    end
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', @customDatatipFunction);

end

% Modified plotComponentERP function with component selection

% Modified plotComponentERP function with proper component plotting
function plotComponentERP(EEG, eventType, timeWindow, selectedComponents)
    % Find indices of specified event type
    eventIndices = [];
    for i=1:length(eventType)
        eventIndices = [eventIndices, find(strcmp({EEG.event.type}, eventType(i)))];
    end
    
    % Calculate time vector
    times = linspace(timeWindow(1), timeWindow(2), diff(timeWindow)*EEG.srate/1000);
    
    % Initialize matrix for selected components
    numSamples = length(times);
    compEpochs = zeros(length(eventIndices), numSamples, length(selectedComponents));
    
    % Calculate samples for extraction
    startSample = round(timeWindow(1)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);
    endSample = round(timeWindow(2)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);
    sampleLength = endSample - startSample;
    
    % Check if we have ICA weights and sphere
    if ~isempty(EEG.icaweights) && ~isempty(EEG.icasphere)
        % Extract epochs for selected components
        for epochIdx = 1:length(eventIndices)
            % Get the current epoch data
            epochData = EEG.data(:, startSample:endSample-1, EEG.event(epochIdx).epoch);
            
            % Transform data to component space for this epoch
            compData = (EEG.icaweights * EEG.icasphere) * epochData;
            
            % Store only selected components
            for compIdx = 1:length(selectedComponents)
                comp = selectedComponents(compIdx);
                compEpochs(epochIdx, :, compIdx) = compData(comp, :);
            end
        end
        
        % Calculate average component ERPs
        meanCompERP = squeeze(mean(compEpochs, 1));
        
        % If only one component is selected, ensure proper dimensionality
        if length(selectedComponents) == 1
            meanCompERP = meanCompERP(:)';
        end
        
        % Plot component ERPs
        h = plot(times, meanCompERP);
        grid on;
        xlabel('Time (ms)');
        ylabel('Component Amplitude');
        title(['Component ERPs for Event ']);
        
        % Create custom data tips for components
        for i = 1:length(h)
            set(h(i), 'UserData', ['IC' num2str(selectedComponents(i))]);
        end
        
        % Add legend with component numbers
        %legendLabels = arrayfun(@(x) ['IC' num2str(x)], selectedComponents, 'UniformOutput', false);
        %legend(legendLabels, 'Location', 'best');
        
        % Set custom datatip function
        dcm = datacursormode(gcf);
        set(dcm, 'UpdateFcn', @customDatatipFunction);
    else
        text(0.5, 0.5, 'No ICA data available', 'HorizontalAlignment', 'center');
        axis off;
    end

    datacursormode on;
    for i = 1:length(h)
        set(h(i), 'ButtonDownFcn', {@lineCallback, h(i)});
    end
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', @customDatatipFunction);
end

% Modified customDatatipFunction to handle both channels and components
function output_txt = customDatatipFunction(obj, event_obj)
    % Get the handle of the line that was clicked
    lineHandle = event_obj.Target;
    
    % Get the position of the click
    pos = event_obj.Position;
    
    % Get the label stored in UserData
    label = get(lineHandle, 'UserData');
    
    % Create the text cell array
    if strncmp(label, 'IC', 2)
        output_txt = {['Component: ' label], ...
                     ['Time: ' num2str(pos(1), '%.1f') ' ms'], ...
                     ['Amplitude: ' num2str(pos(2), '%.2f')]};
    else
        output_txt = {['Channel: ' label], ...
                     ['Time: ' num2str(pos(1), '%.1f') ' ms'], ...
                     ['Amplitude: ' num2str(pos(2), '%.2f') ' µV']};
    end
end

% Add this new function:
function lineCallback(src, ~, lineHandle)
    % Toggle line selection
    if strcmp(get(lineHandle, 'LineStyle'), '-')
        set(lineHandle, 'LineStyle', '--', 'LineWidth', 2);
    else
        set(lineHandle, 'LineStyle', '-', 'LineWidth', 0.5);
    end
end


% Update the moveForward function:
function moveForward(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    % Get selected items from available list
    availStr = get(userData.availableList, 'String');
    availVal = get(userData.availableList, 'Value');
    
    if isempty(availVal)
        return;
    end
    
    % Get current rejected items
    rejStr = get(userData.rejectedList, 'String');
    
    % Move selected items to rejected list
    selectedItems = availStr(availVal);
    rejStr = [rejStr; selectedItems(:)];  % Ensure column vector
    
    % Update rejected list
    set(userData.rejectedList, 'String', rejStr);
    
    % Update available list
    updateChannelList(mainFig);
    
    % Update plots
    updatePlot(source, []);
end

% Update the moveBackward function:
function moveBackward(source, ~)
    mainFig = getMainFigure(source);
    userData = get(mainFig, 'UserData');
    
    % Get selected items from rejected list
    rejStr = get(userData.rejectedList, 'String');
    rejVal = get(userData.rejectedList, 'Value');
    
    if isempty(rejVal)
        return;
    end
    
    % Remove selected items from rejected list
    rejStr(rejVal) = [];
    set(userData.rejectedList, 'String', rejStr, 'Value', []);
    
    % Update available list
    updateChannelList(mainFig);
    
    % Update plots
    updatePlot(source, []);
end
