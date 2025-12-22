--[[
    RaidSanctions - UI Core Module
    
    This module handles the core UI framework including:
    - Main frame creation and management
    - Window show/hide logic
    - Frame positioning and styling
    - Base UI event handling
    
    @author Drodar
    @version 1.1
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE INITIALIZATION
-- ============================================================================

RaidSanctions = RaidSanctions or {}
RaidSanctions.UI = RaidSanctions.UI or {}

-- ============================================================================
-- LOCAL REFERENCES
-- ============================================================================

local UI = RaidSanctions.UI
local format = string.format

-- ============================================================================
-- UI CONSTANTS
-- ============================================================================

-- Frame dimensions
UI.FRAME_WIDTH = 1000
UI.FRAME_HEIGHT = 700
UI.ROW_HEIGHT = 30
UI.BUTTON_WIDTH = 80
UI.BUTTON_HEIGHT = 25
UI.BOTTOM_PANEL_HEIGHT = 160

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================

-- Main frame reference
UI.mainFrame = nil

-- Frame state tracking
local isInitialized = false

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
    Initializes the UI system
    
    This is the entry point for the UI module. It creates all UI elements
    and sets up event handlers. Should only be called once.
    
    @return void
]]
function UI:Initialize()
    if isInitialized then
        return
    end
    
    -- Create UI components in order
    self:CreateMainFrame()
    self:CreateHeader()
    self:CreateScrollFrame()
    self:CreateBottomPanel()
    self:SetupEventHandlers()
    
    -- Initialize sub-modules
    if self.InitializeLiveSync then
        C_Timer.After(2.0, function()
            if IsInRaid() or IsInGroup() then
                self:InitializeLiveSync()
            end
        end)
    end
    
    isInitialized = true
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

--[[
    Creates the main addon frame
    
    Sets up the primary UI window with:
    - Backdrop and border styling
    - Drag functionality
    - ESC key handling
    - Proper stacking and layering
    
    @return void
]]
function UI:CreateMainFrame()
    local mainFrame = CreateFrame("Frame", "RaidSanctionsMainFrame", UIParent, "BackdropTemplate")
    
    -- Set frame properties
    mainFrame:SetSize(self.FRAME_WIDTH, self.FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(100)
    
    -- Apply backdrop styling
    mainFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    mainFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    mainFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Enable dragging
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    
    mainFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Create close button
    local closeButton = CreateFrame("Button", "RaidSanctionsMainFrameCloseButton", mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        UI:Hide()
    end)
    
    -- ESC key handling
    mainFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            UI:Hide()
        end
    end)
    
    -- Start hidden
    mainFrame:Hide()
    
    -- Store reference
    self.mainFrame = mainFrame
end

-- ============================================================================
-- VISIBILITY CONTROL
-- ============================================================================

--[[
    Toggles the main frame visibility
    
    @return void
]]
function UI:Toggle()
    if not self.mainFrame then
        self:Initialize()
    end
    
    if self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

--[[
    Shows the main frame
    
    Also refreshes the player list and handles authorization checks.
    
    @return void
]]
function UI:Show()
    if not self.mainFrame then
        self:Initialize()
    end
    
    self.mainFrame:Show()
    self.mainFrame:EnableKeyboard(true)
    
    -- Refresh player list
    if self.RefreshPlayerList then
        self:RefreshPlayerList()
    end
end

--[[
    Hides the main frame
    
    @return void
]]
function UI:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
        self.mainFrame:EnableKeyboard(false)
    end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

-- Export module
RaidSanctions.UI = UI
