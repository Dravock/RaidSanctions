--[[
    RaidSanctions - Main Entry Point
    
    This file serves as the primary initialization point for the addon.
    It handles:
    - Event registration and routing
    - Module initialization coordination
    - Slash command registration
    - Global API exposure for third-party integration
    
    Architecture:
    - Modular design with separate concerns
    - Event-driven architecture
    - Clean separation between logic and UI
    - Professional error handling
    
    @author Drodar
    @version 1.2
    @since 2024
    @license MIT
]]

local addonName, addonTable = ...

-- ============================================================================
-- EVENT FRAME SETUP
-- ============================================================================

-- Create dedicated event handling frame
local eventFrame = CreateFrame("Frame", "RaidSanctionsEventFrame")
local isInitialized = false

-- ============================================================================
-- EVENT DISPATCHER
-- ============================================================================

--[[
    Central event handler
    
    Routes WoW events to appropriate module handlers. This provides
    a single point of control for all addon event processing.
    
    @param self Frame The event frame
    @param event string The event name
    @param ... any Event-specific arguments
    @return void
]]
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            OnAddonLoaded()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        OnPlayerEnteringWorld()
    elseif event == "GROUP_ROSTER_UPDATE" then
        OnGroupRosterUpdate()
    end
end

-- ============================================================================
-- INITIALIZATION HANDLERS
-- ============================================================================

--[[
    Handles addon loaded event
    
    Called once when the addon is first loaded. Initializes the logic
    module and marks the addon as ready.
    
    @return void
]]
function OnAddonLoaded()
    -- Initialize core logic module
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnAddonLoaded()
        isInitialized = true
    end
end

--[[
    Handles player entering world
    
    Called when player enters the game world or reloads UI.
    Updates raid roster if player is in a group.
    
    @return void
]]
function OnPlayerEnteringWorld()
    if not isInitialized then
        return
    end
    
    -- Forward to logic module
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnPlayerEnteringWorld()
    end
end

--[[
    Handles group roster updates
    
    Called whenever group composition changes. Updates member list
    and triggers cleanup when player leaves group.
    
    @return void
]]
function OnGroupRosterUpdate()
    if not isInitialized then
        return
    end
    
    -- Forward to logic module
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnGroupRosterUpdate()
        
        -- Clean up random players when leaving group
        if not IsInGroup() and not IsInRaid() then
            RaidSanctions.Logic:CleanupSeasonDataRandomPlayers()
        end
    end
end

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================

-- Register for critical WoW events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", OnEvent)

-- ============================================================================
-- SLASH COMMAND SYSTEM
-- ============================================================================

-- Register primary slash commands
SLASH_RAIDSANCTIONS1 = "/sanktions"
SLASH_RAIDSANCTIONS2 = "/rs"

--[[
    Slash command handler
    
    Processes user commands and routes them to appropriate functions.
    Supports multiple commands for different addon features.
    
    @param msg string The command string entered by user
    @return void
]]
SlashCmdList["RAIDSANCTIONS"] = function(msg)
    local command = msg:lower():trim()
    
    if command == "" or command == "show" then
        -- Toggle main UI window
        if RaidSanctions.UI then
            RaidSanctions.UI:Toggle()
        end
        
    elseif command == "reset" then
        -- Reset session data
        if RaidSanctions.Logic then
            RaidSanctions.Logic:ResetSessionData()
        end
        
    elseif command == "updatepenalties" then
        -- Force update penalty names to English
        if RaidSanctions.Logic then
            RaidSanctions.Logic:UpdatePenaltiesToEnglish()
        end
        
    elseif command == "debug" then
        -- Display debug information
        if RaidSanctions.Logic then
            local session = RaidSanctions.Logic:GetCurrentSession()
            if session then
                print("┌─ RaidSanctions Debug Info ─────────────")
                print("│ Session ID: " .. session.id)
                print("│ Detected Players:")
                
                for name, data in pairs(session.players) do
                    print("│   → " .. name .. " (" .. (data.class or "UNKNOWN") .. 
                          ", Level " .. (data.level or "?") .. ")")
                end
                
                print("└────────────────────────────────────────")
            else
                print("No active session found.")
            end
            
            -- Display group status
            if IsInRaid() then
                print("Status: In Raid (" .. GetNumGroupMembers() .. " members)")
            elseif IsInGroup() then
                print("Status: In Group (" .. GetNumGroupMembers() .. " members)")
            else
                print("Status: Solo")
            end
        end
        
    elseif command == "help" then
        -- Display help information
        print("┌─ RaidSanctions Commands ───────────────")
        print("│ /rs or /rs show    → Toggle UI")
        print("│ /rs reset          → Reset session data")
        print("│ /rs updatepenalties → Update penalty names")
        print("│ /rs debug          → Show debug info")
        print("│ /rs help           → Show this help")
        print("└────────────────────────────────────────")
        
    else
        print("Unknown command. Use '/rs help' for available commands.")
    end
end

-- ============================================================================
-- PUBLIC API (for third-party addons)
-- ============================================================================

--[[
    Applies a penalty to a player (Public API)
    
    This function can be called by other addons to integrate with
    RaidSanctions penalty tracking.
    
    @param playerName string The player to penalize
    @param reason string The penalty reason
    @param amount number The penalty amount in copper
    @return boolean True if penalty was applied successfully
]]
function RaidSanctions_ApplyPenalty(playerName, reason, amount)
    if RaidSanctions.Logic then
        return RaidSanctions.Logic:ApplyPenalty(playerName, reason, amount)
    end
    return false
end

--[[
    Gets the total penalty amount for a player (Public API)
    
    @param playerName string The player name
    @return number The total penalty amount in copper
]]
function RaidSanctions_GetPlayerTotal(playerName)
    if RaidSanctions.Logic then
        return RaidSanctions.Logic:GetPlayerTotal(playerName)
    end
    return 0
end

-- ============================================================================
-- LEGACY COMPATIBILITY
-- ============================================================================

--[[
    @deprecated Legacy initialization function
    Maintained for backward compatibility with older versions
]]
function RaidSanctions_OnLoad(self)
    print("Warning: RaidSanctions_OnLoad is deprecated. Addon auto-initializes.")
end

--[[
    @deprecated Legacy event handler
    Maintained for backward compatibility
]]
function RaidSanctions_OnEvent(self, event, ...)
    OnEvent(self, event, ...)
end

