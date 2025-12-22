--[[
    RaidSanctions - Player List UI Module
    
    Manages the player list display including:
    - Scrollable player roster
    - Penalty counters per category
    - Player selection
    - Row highlighting and colors
    - Class-based coloring
    
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
-- LOCAL VARIABLES
-- ============================================================================

-- Track all player row UI elements
local playerRows = {}
local selectedPlayer = nil

-- ============================================================================
-- SCROLL FRAME CREATION
-- ============================================================================

--[[
    Creates the scrollable frame for the player list
    
    Sets up a scroll frame with child content frame that dynamically
    adjusts height based on the number of players.
    
    @return void
]]
function UI:CreateScrollFrame()
    local mainFrame = self.mainFrame
    if not mainFrame then return end
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "RaidSanctionsScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, self.BOTTOM_PANEL_HEIGHT + 10)
    
    -- Create content frame
    local contentFrame = CreateFrame("Frame", "RaidSanctionsContentFrame", scrollFrame)
    contentFrame:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(contentFrame)
    
    -- Store references
    mainFrame.scrollFrame = scrollFrame
    mainFrame.contentFrame = contentFrame
end

-- ============================================================================
-- HEADER CREATION
-- ============================================================================

--[[
    Creates the header row with column titles
    
    Displays column headers for:
    - Player name
    - Penalty counters (Late, AFK, Wrong Gear, etc.)
    - Total amount
    
    @return void
]]
function UI:CreateHeader()
    local mainFrame = self.mainFrame
    if not mainFrame then return end
    
    -- Title text
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -15)
    title:SetText("Raid Sanctions - Penalty Management")
    
    -- Header background
    local headerBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    headerBg:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -45)
    headerBg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -30, -45)
    headerBg:SetHeight(30)
    
    -- Column headers
    local penalties = Logic:GetPenalties()
    local xOffset = 15
    local columnWidth = 100
    
    -- Player name header
    local nameHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("TOPLEFT", headerBg, "TOPLEFT", xOffset, -8)
    nameHeader:SetText("Player")
    nameHeader:SetWidth(150)
    nameHeader:SetJustifyH("LEFT")
    xOffset = xOffset + 150
    
    -- Penalty category headers
    for reason, amount in pairs(penalties) do
        local header = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOPLEFT", headerBg, "TOPLEFT", xOffset, -8)
        header:SetText(reason)
        header:SetWidth(columnWidth)
        header:SetJustifyH("CENTER")
        xOffset = xOffset + columnWidth
    end
    
    -- Total header
    local totalHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalHeader:SetPoint("TOPLEFT", headerBg, "TOPLEFT", xOffset, -8)
    totalHeader:SetText("Total")
    totalHeader:SetWidth(120)
    totalHeader:SetJustifyH("CENTER")
end

-- ============================================================================
-- PLAYER LIST MANAGEMENT
-- ============================================================================

--[[
    Refreshes the entire player list
    
    Clears existing rows and recreates them based on current session data.
    Applies proper sorting, coloring, and selection states.
    
    @return void
]]
function UI:RefreshPlayerList()
    local mainFrame = self.mainFrame
    if not mainFrame or not mainFrame.contentFrame then return end
    
    -- Get current session
    local session = Logic:GetCurrentSession()
    if not session then return end
    
    -- Clear existing rows
    for _, row in ipairs(playerRows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(playerRows)
    
    -- Build player list
    local playerList = {}
    for name, data in pairs(session.players) do
        table.insert(playerList, {
            name = name,
            data = data
        })
    end
    
    -- Sort by total penalties (highest first)
    table.sort(playerList, function(a, b)
        return a.data.total > b.data.total
    end)
    
    -- Create rows
    local yOffset = -5
    for i, player in ipairs(playerList) do
        local row = self:CreatePlayerRow(player.name, player.data, yOffset)
        table.insert(playerRows, row)
        yOffset = yOffset - self.ROW_HEIGHT
    end
    
    -- Update content frame height
    local contentHeight = (#playerList * self.ROW_HEIGHT) + 10
    mainFrame.contentFrame:SetHeight(math.max(contentHeight, mainFrame.scrollFrame:GetHeight()))
end

--[[
    Creates a single player row
    
    @param playerName string The player's name
    @param playerData table The player's penalty data
    @param yOffset number Vertical position offset
    @return Frame The created row frame
]]
function UI:CreatePlayerRow(playerName, playerData, yOffset)
    local contentFrame = self.mainFrame.contentFrame
    
    -- Create row button
    local row = CreateFrame("Button", nil, contentFrame)
    row:SetSize(contentFrame:GetWidth(), self.ROW_HEIGHT)
    row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    
    -- Row background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
    row.bg = bg
    
    -- Highlight texture
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(row)
    highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    
    -- Player name with class color
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", row, "LEFT", 15, 0)
    nameText:SetWidth(150)
    nameText:SetJustifyH("LEFT")
    
    local classColor = RAID_CLASS_COLORS[playerData.class] or {r=1, g=1, b=1}
    nameText:SetText(playerName)
    nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
    
    -- Penalty counters
    local penalties = Logic:GetPenalties()
    local xOffset = 165
    local columnWidth = 100
    
    row.counters = {}
    for reason, _ in pairs(penalties) do
        local counter = self:CreatePenaltyCounter(row, reason, playerData, xOffset)
        row.counters[reason] = counter
        xOffset = xOffset + columnWidth
    end
    
    -- Total amount
    local totalText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    totalText:SetPoint("LEFT", row, "LEFT", xOffset, 0)
    totalText:SetWidth(120)
    totalText:SetJustifyH("CENTER")
    totalText:SetText(Logic:FormatGold(playerData.total))
    
    -- Color code based on total
    if playerData.total > 50000 then
        totalText:SetTextColor(1, 0, 0) -- Red for high amounts
    elseif playerData.total > 20000 then
        totalText:SetTextColor(1, 0.5, 0) -- Orange for medium
    else
        totalText:SetTextColor(1, 1, 1) -- White for low
    end
    
    -- Click handler
    row:SetScript("OnClick", function()
        UI:SelectPlayer(playerName)
    end)
    
    -- Store player name reference
    row.playerName = playerName
    
    return row
end

--[[
    Creates a penalty counter display for a specific category
    
    @param parent Frame The parent frame
    @param reason string The penalty reason/category
    @param playerData table The player's data
    @param xOffset number Horizontal position
    @return FontString The counter text element
]]
function UI:CreatePenaltyCounter(parent, reason, playerData, xOffset)
    -- Count penalties of this type
    local count = 0
    for _, penalty in ipairs(playerData.penalties) do
        if penalty.reason == reason then
            count = count + 1
        end
    end
    
    -- Create counter text
    local counter = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    counter:SetPoint("LEFT", parent, "LEFT", xOffset, 0)
    counter:SetWidth(100)
    counter:SetJustifyH("CENTER")
    counter:SetText(count > 0 and count or "-")
    
    -- Color code: red if count > 0, gray otherwise
    if count > 0 then
        counter:SetTextColor(1, 0.3, 0.3)
    else
        counter:SetTextColor(0.5, 0.5, 0.5)
    end
    
    return counter
end

-- ============================================================================
-- PLAYER SELECTION
-- ============================================================================

--[[
    Selects a player in the list
    
    Highlights the selected row and enables penalty buttons.
    
    @param playerName string The player to select
    @return void
]]
function UI:SelectPlayer(playerName)
    -- Clear previous selection
    if selectedPlayer then
        self:DeselectPlayer(selectedPlayer)
    end
    
    -- Find and highlight new selection
    for _, row in ipairs(playerRows) do
        if row.playerName == playerName then
            row.bg:SetColorTexture(0.2, 0.4, 0.6, 0.7)
            selectedPlayer = playerName
            break
        end
    end
    
    -- Update UI state
    if self.UpdateButtonStates then
        self:UpdateButtonStates()
    end
end

--[[
    Deselects a player
    
    @param playerName string The player to deselect
    @return void
]]
function UI:DeselectPlayer(playerName)
    for _, row in ipairs(playerRows) do
        if row.playerName == playerName then
            row.bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
            break
        end
    end
    selectedPlayer = nil
end

--[[
    Gets the currently selected player
    
    @return string|nil The selected player name or nil
]]
function UI:GetSelectedPlayer()
    return selectedPlayer
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

-- Store player rows for external access
UI.playerRows = playerRows
