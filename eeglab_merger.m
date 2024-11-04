function eeglab_merger
    % Create main figure
    fig = uifigure('Name', 'EEGLab File Merger', 'Position', [100 100 800 500]);
    
    % Create UI components
    loadBtn = uibutton(fig, 'Text', 'Load Folder', ...
        'Position', [50 450 100 30], ...
        'ButtonPushedFcn', @loadFolder);
    
    mergeBtn = uibutton(fig, 'Text', 'Merge Files', ...
        'Position', [350 450 100 30], ...
        'ButtonPushedFcn', @mergeFiles);
    
    % Create listboxes
    availableList = uilistbox(fig, ...
        'Position', [50 100 300 300], ...
        'ValueChangedFcn', @updateButtons);
    
    selectedList = uilistbox(fig, ...
        'Position', [450 100 300 300], ...
        'ValueChangedFcn', @updateButtons);
    
    % Create arrow buttons
    rightArrow = uibutton(fig, 'Text', '→', ...
        'Position', [360 250 30 30], ...
        'ButtonPushedFcn', @moveRight);
    
    leftArrow = uibutton(fig, 'Text', '←', ...
        'Position', [360 200 30 30], ...
        'ButtonPushedFcn', @moveLeft);
    
    % Store UI components in figure's UserData
    fig.UserData.availableList = availableList;
    fig.UserData.selectedList = selectedList;
    fig.UserData.rightArrow = rightArrow;
    fig.UserData.leftArrow = leftArrow;
    fig.UserData.mergeBtn = mergeBtn;
    
    % Initialize empty lists
    availableList.Items = {};
    selectedList.Items = {};
    
    % Initialize buttons state
    updateButtons();
    
    function loadFolder(~, ~)
        % Open folder selection dialog
        folder = uigetdir('', 'Select Folder with EEGLab Files');
        if folder == 0
            return;
        end
        
        % Get all .set files (EEGLab files)
        files = dir(fullfile(folder, '*.set'));
        fileNames = {files.name};
        
        % Update available files list
        availableList.Items = fileNames;
        fig.UserData.currentFolder = folder;
        
        % Clear selected list
        selectedList.Items = {};
        
        % Update buttons state
        updateButtons();
    end
    
    function moveRight(~, ~)
        % Move selected items from available to selected list
        if ~isempty(availableList.Value)
            % Get current items in both lists
            selectedItems = availableList.Value;
            if ~iscell(selectedItems)
                selectedItems = {selectedItems};
            end
            
            currentSelected = selectedList.Items;
            
            % Add selected items to selected list
            if isempty(currentSelected)
                selectedList.Items = selectedItems;
            else
                selectedList.Items = [currentSelected, selectedItems];
            end
            
            % Remove items from available list
            remainingItems = setdiff(availableList.Items, selectedItems, 'stable');
            availableList.Items = remainingItems;
            
            % Clear selection
            availableList.Value = {};
            
            % Update buttons state
            updateButtons();
        end
    end
    
    function moveLeft(~, ~)
        % Move selected items from selected to available list
        if ~isempty(selectedList.Value)
            % Get current items in both lists
            selectedItems = selectedList.Value;
            if ~iscell(selectedItems)
                selectedItems = {selectedItems};
            end
            
            currentAvailable = availableList.Items;
            
            % Add selected items to available list
            if isempty(currentAvailable)
                availableList.Items = selectedItems;
            else
                availableList.Items = [currentAvailable, selectedItems];
            end
            
            % Remove items from selected list
            remainingItems = setdiff(selectedList.Items, selectedItems, 'stable');
            selectedList.Items = remainingItems;
            
            % Clear selection
            selectedList.Value = {};
            
            % Update buttons state
            updateButtons();
        end
    end
    
    function updateButtons(~, ~)
        % Enable/disable right arrow based on available list selection
        rightArrow.Enable = ~isempty(availableList.Value);
        
        % Enable/disable left arrow based on selected list selection
        leftArrow.Enable = ~isempty(selectedList.Value);
        
        % Enable/disable merge button based on selected list items
        mergeBtn.Enable = ~isempty(selectedList.Items);
    end
    
    function mergeFiles(~, ~)
        if isempty(selectedList.Items)
            return;
        end
        
        try
            % Initialize merged EEG data with first file
            firstFile = fullfile(fig.UserData.currentFolder, selectedList.Items{1});
            EEG = pop_loadset(firstFile);
            
            % Merge remaining files
            for i = 2:length(selectedList.Items)
                % Load current file
                currentFile = fullfile(fig.UserData.currentFolder, selectedList.Items{i});
                currentEEG = pop_loadset(currentFile);
                
                % Merge with existing data
                EEG = pop_mergeset(EEG, currentEEG);
            end
            
            % Save merged file
            [file, path] = uiputfile('*.set', 'Save Merged File');
            if file ~= 0
                pop_saveset(EEG, 'filename', file, 'filepath', path);
                msgbox('Files merged successfully!', 'Success');
            end
        catch ME
            errordlg(['Error merging files: ' ME.message], 'Error');
        end
    end
end