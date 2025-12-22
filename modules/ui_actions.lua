--[[
    RaidSanctions - Bottom Panel UI Module
    
    Manages the action panel at the bottom of the main window:
    - Penalty application buttons
    - Management buttons (Whisper, Post Stats, Sync, etc.)
    - Button state management
    - Authorization checks
    
    @author Drodar
    @version 1.1
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

local UI = RaidSanctions.UI
local Logic = RaidSanctions.Logic

-- ============================================================================
-- BOTTOM PANEL CREATION
-- ============================================================================

--[[
    Creates the bottom action panel
    
    This panel contains:
    - Penalty buttons (Late, AFK, Wrong Gear, etc.)
    - Penalty removal buttons (-)
    - Management tools (Whisper, Post, Sync, etc.)
    - Settings and information buttons
    
    @return void
]]
function UI:CreateBottomPanel()
    local mainFrame = self.mainFrame
    if not mainFrame then return end
    
    -- Create panel frame
    local bottomPanel = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    bottomPanel:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 10)
    bottomPanel:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)
    bottomPanel:SetHeight(self.BOTTOM_PANEL_HEIGHT)
    
    -- Panel backdrop
    bottomPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    bottomPanel:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    bottomPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Panel title
    local panelTitle = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panelTitle:SetPoint("TOP", bottomPanel, "TOP", 0, -8)
    panelTitle:SetText("Actions")
    
    -- Create sections
    self:CreatePenaltyButtons(bottomPanel)
    self:CreateManagementButtons(bottomPanel)
    
    -- Store reference
    mainFrame.bottomPanel = bottomPanel
end

-- ============================================================================
-- PENALTY BUTTONS
-- ============================================================================

--[[
    Creates penalty application buttons
    
    Generates buttons for each penalty type with:
    - Apply button (+)
    - Remove button (-)
    - Penalty name and amount display
    
    @param panel Frame The parent panel
    @return void
]]
function UI:CreatePenaltyButtons(panel)
    local penalties = Logic:GetPenalties()
    
    -- Section label
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", 15, -30)
    label:SetText("Apply Penalties:")
    
    -- Button layout configuration
    local startX = 15
    local startY = -50
    local buttonSpacing = 10
    local buttonWidth = 130
    local buttonHeight = 25
    local buttonsPerRow = 5
    
    local penalties_sorted = {}
    for reason, amount in pairs(penalties) do
        table.insert(penalties_sorted, {reason = reason, amount = amount})
    end
    
    -- Sort alphabetically for consistent layout
    table.sort(penalties_sorted, function(a, b) 
        return a.reason < b.reason 
    end)
    
    -- Create button pair for each penalty
    for i, penalty in ipairs(penalties_sorted) do
        local row = math.floor((i - 1) / buttonsPerRow)
        local col = (i - 1) % buttonsPerRow
        
        local xPos = startX + (col * (buttonWidth + buttonSpacing + 40))
        local yPos = startY - (row * (buttonHeight + 5))
        
        -- Apply penalty button (+)
        local applyBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        applyBtn:SetSize(buttonWidth, buttonHeight)
        applyBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", xPos, yPos)
        applyBtn:SetText(penalty.reason .. " (+" .. Logic:FormatGold(penalty.amount) .. ")")
        
        applyBtn:SetScript("OnClick", function()
            local selectedPlayer = UI:GetSelectedPlayer()
            if selectedPlayer then
                UI:ApplyPenaltyToSelectedPlayer(penalty.reason, penalty.amount)
            else
                print("Please select a player first!")
            end
        end)
        
        -- Tooltip
        applyBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Apply " .. penalty.reason .. " penalty", 1, 1, 1)
            GameTooltip:AddLine("Amount: " .. Logic:FormatGold(penalty.amount), 1, 0.82, 0)
            GameTooltip:AddLine("Click to apply to selected player", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)
        
        applyBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Remove penalty button (-)
        local removeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        removeBtn:SetSize(30, buttonHeight)
        removeBtn:SetPoint("LEFT", applyBtn, "RIGHT", 5, 0)
        removeBtn:SetText("-")
        
        removeBtn:SetScript("OnClick", function()
            local selectedPlayer = UI:GetSelectedPlayer()
            if selectedPlayer then
                UI:RemovePenaltyFromSelectedPlayer(penalty.reason, penalty.amount)
            else
                print("Please select a player first!")
            end
        end)
        
        -- Tooltip for remove button
        removeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Remove last " .. penalty.reason .. " penalty", 1, 0.3, 0.3)
            GameTooltip:AddLine("Removes the most recent penalty of this type", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)
        
        removeBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Store buttons for state management
        if not panel.penaltyButtons then
            panel.penaltyButtons = {}
        end
        table.insert(panel.penaltyButtons, applyBtn)
        table.insert(panel.penaltyButtons, removeBtn)
    end
end

-- ============================================================================
-- MANAGEMENT BUTTONS
-- ============================================================================

--[[
    Creates management and utility buttons
    
    Includes buttons for:
    - Whisper balance to player
    - Post stats to raid
    - Sync data
    - Reset player
    - Add player
    - Settings
    - Season stats
    
    @param panel Frame The parent panel
    @return void
]]
function UI:CreateManagementButtons(panel)
    -- Section label
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 15, 35)
    label:SetText("Management:")
    
    local buttonWidth = 100
    local buttonHeight = 22
    local spacing = 5
    local startX = 15
    local startY = 20
    
    -- Button configurations
    local buttons = {
        {
            text = "Whisper Balance",
            tooltip = "Send penalty balance to selected player via whisper",
            onClick = function() UI:WhisperPlayerBalance() end,
            requiresSelection = true
        },
        {
            text = "Post Stats",
            tooltip = "Post current penalty statistics to raid chat",
            onClick = function() UI:PostStatsToRaidChat() end,
            requiresSelection = false
        },
        {
            text = "Sync Data",
            tooltip = "Synchronize penalty data with other raid members",
            onClick = function() UI:SyncSessionData() end,
            requiresSelection = false,
            requiresAuth = true
        },
        {
            text = "Reset Player",
            tooltip = "Mark selected player as paid and reset their penalties",
            onClick = function() UI:ResetSelectedPlayerPenalties() end,
            requiresSelection = true,
            requiresAuth = true
        },
        {
            text = "Add Player",
            tooltip = "Manually add a player to the list",
            onClick = function() UI:ShowAddPlayerDialog() end,
            requiresSelection = false
        },
        {
            text = "Settings",
            tooltip = "Open addon settings and configuration",
            onClick = function() UI:ShowOptionsWindow() end,
            requiresSelection = false
        },
        {
            text = "Season Stats",
            tooltip = "View cumulative season statistics",
            onClick = function() UI:ShowSeasonStatsWindow() end,
            requiresSelection = false
        },
        {
            text = "Reset All",
            tooltip = "Reset all session data (requires confirmation)",
            onClick = function() UI:ShowResetConfirmation() end,
            requiresSelection = false,
            requiresAuth = true
        }
    }
    
    -- Create buttons
    for i, config in ipairs(buttons) do
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(buttonWidth, buttonHeight)
        btn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 
            startX + ((i - 1) * (buttonWidth + spacing)), startY)
        btn:SetText(config.text)
        btn:SetScript("OnClick", config.onClick)
        
        -- Tooltip
        if config.tooltip then
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(config.text, 1, 1, 1)
                GameTooltip:AddLine(config.tooltip, 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
        
        -- Store button for state management
        if not panel.managementButtons then
            panel.managementButtons = {}
        end
        table.insert(panel.managementButtons, {
            button = btn,
            config = config
        })
    end
end

-- ============================================================================
-- PENALTY APPLICATION
-- ============================================================================

--[[
    Applies a penalty to the currently selected player
    
    @param reason string The penalty reason
    @param amount number The penalty amount in copper
    @return void
]]
function UI:ApplyPenaltyToSelectedPlayer(reason, amount)
    local selectedPlayer = self:GetSelectedPlayer()
    if not selectedPlayer then
        print("No player selected!")
        return
    end
    
    if Logic:ApplyPenalty(selectedPlayer, reason, amount) then
        self:RefreshPlayerList()
        
        -- Send live sync update if enabled
        if self.IsLiveSyncActive and self:IsLiveSyncActive() then
            self:SendLiveSyncUpdate("APPLY_PENALTY", {
                playerName = selectedPlayer,
                reason = reason,
                amount = amount
            })
        end
    end
end

--[[
    Removes a penalty from the currently selected player
    
    @param reason string The penalty reason
    @param amount number The penalty amount in copper
    @return void
]]
function UI:RemovePenaltyFromSelectedPlayer(reason, amount)
    local selectedPlayer = self:GetSelectedPlayer()
    if not selectedPlayer then
        print("No player selected!")
        return
    end
    
    if Logic:RemovePenalty(selectedPlayer, reason, amount) then
        self:RefreshPlayerList()
        
        -- Send live sync update if enabled
        if self.IsLiveSyncActive and self:IsLiveSyncActive() then
            self:SendLiveSyncUpdate("REMOVE_PENALTY", {
                playerName = selectedPlayer,
                reason = reason,
                amount = amount
            })
        end
    end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

-- Functions are added to UI namespace
