--[[
    RaidSanctions - Core Logic Module
    
    This module handles all business logic for the RaidSanctions addon, including:
    - Database initialization and migration
    - Session management
    - Penalty application and removal
    - Season statistics tracking
    - Group/raid member detection
    - Data persistence
    
    @author Drodar
    @version 1.1
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE INITIALIZATION
-- ============================================================================

-- Initialize addon namespace to avoid global pollution
RaidSanctions = RaidSanctions or {}
RaidSanctions.Logic = {}

-- ============================================================================
-- LOCAL REFERENCES
-- ============================================================================

-- Cache frequently used functions for performance optimization
local Logic = RaidSanctions.Logic
local format = string.format
local pairs, ipairs = pairs, ipairs
local wipe = table.wipe or wipe

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Addon version for database migration tracking
local ADDON_VERSION = "1.1"

-- Debug mode toggle (set to true to enable console logging)
local DEBUG_MODE = false

-- Default penalty amounts in copper (10000 copper = 1 gold)
-- These values can be modified through the UI settings
local DEFAULT_PENALTIES = {
    ["Late"] = 10000,          -- 1 gold - For arriving late to raid
    ["AFK"] = 10000,           -- 1 gold - For going AFK without notice
    ["Wrong Gear"] = 10000,    -- 1 gold - For wearing inappropriate gear
    ["Wrong Tactic"] = 10000,  -- 1 gold - For not following raid tactics
    ["Disruption"] = 10000     -- 1 gold - For disruptive behavior
}

-- ============================================================================
-- LOCALIZATION
-- ============================================================================

-- Localization table for UI strings
-- Currently supports English; can be extended for other languages
local L = {
    ["LATE"] = "Late",
    ["AFK"] = "AFK", 
    ["WRONG_GEAR"] = "Wrong Gear",
    ["WRONG_TACTIC"] = "Wrong Tactic",
    ["DISRUPTION"] = "Disruption",
    ["TOTAL"] = "Total",
    ["ADDON_LOADED"] = "RaidSanctions v%s loaded.",
    ["PENALTY_APPLIED"] = "%s penalized with '%s': +%s | Total: %s",
    ["DATA_RESET"] = "All sanction data has been reset."
}

-- ============================================================================
-- DATABASE MANAGEMENT
-- ============================================================================

--[[
    Initializes the addon database structures
    
    Creates two separate database tables:
    - RaidSanctionsDB: Global settings shared across all characters
    - RaidSanctionsCharDB: Character-specific session and season data
    
    @return void
]]
function Logic:InitializeDatabase()
    -- Initialize global database with default settings
    RaidSanctionsDB = RaidSanctionsDB or {
        version = ADDON_VERSION,
        penalties = {},
        settings = {
            showInCombat = false,  -- Whether to show UI during combat
            autoHide = true,       -- Automatically hide UI when leaving group
            soundEnabled = true    -- Play sound effects on penalty application
        }
    }
    
    -- Initialize penalties if they don't exist or are empty
    if not RaidSanctionsDB.penalties or next(RaidSanctionsDB.penalties) == nil then
        RaidSanctionsDB.penalties = {}
        for reason, amount in pairs(DEFAULT_PENALTIES) do
            RaidSanctionsDB.penalties[reason] = amount
        end
    end
    
    -- Initialize character-specific database
    RaidSanctionsCharDB = RaidSanctionsCharDB or {
        sessions = {},          -- Stores all raid sessions
        currentSession = nil,   -- ID of the active session
        seasonData = {}         -- Cumulative season statistics
    }
    
    -- Ensure season data table exists
    if not RaidSanctionsCharDB.seasonData then
        RaidSanctionsCharDB.seasonData = {}
    end
    
    -- Perform database migration if version mismatch detected
    if RaidSanctionsDB.version ~= ADDON_VERSION then
        self:MigrateDatabase()
    end
end

--[[
    Handles database schema migrations between addon versions
    
    This function is called when the saved database version doesn't match
    the current addon version. It handles backward compatibility and data
    structure updates.
    
    @return void
]]
function Logic:MigrateDatabase()
    -- Update penalties from German to English if necessary
    if RaidSanctionsDB.penalties then
        -- Check for legacy German penalty names
        local oldPenalties = RaidSanctionsDB.penalties
        local hasGermanNames = false
        
        -- Detect German penalty names
        for name, _ in pairs(oldPenalties) do
            if name == "Zu spät" or name == "Falsche Taktik" or 
               name == "Falsches Gear" or name == "Störung" then
                hasGermanNames = true
                break
            end
        end
        
        -- Replace German names with English defaults
        if hasGermanNames then
            RaidSanctionsDB.penalties = DEFAULT_PENALTIES
            print("RaidSanctions: Updated penalty names to English")
        end
    end
    
    RaidSanctionsDB.version = ADDON_VERSION
    if DEBUG_MODE then
        print("Database migrated to version " .. ADDON_VERSION)
    end
end

-- ============================================================================
-- SESSION MANAGEMENT
-- ============================================================================

--[[
    Creates a new raid session
    
    Sessions are used to track penalties within a single raid instance.
    Each session has a unique timestamp-based ID and stores all player data.
    
    @return table The newly created session object
]]
function Logic:CreateNewSession()
    local sessionId = date("%Y%m%d_%H%M%S")
    local session = {
        id = sessionId,
        date = date(),
        timestamp = time(),
        players = {},
        isActive = true
    }
    
    RaidSanctionsCharDB.sessions[sessionId] = session
    RaidSanctionsCharDB.currentSession = sessionId
    
    return session
end

--[[
    Retrieves the currently active session
    
    @return table|nil The current session object or nil if no active session
]]
function Logic:GetCurrentSession()
    local sessionId = RaidSanctionsCharDB.currentSession
    if sessionId and RaidSanctionsCharDB.sessions[sessionId] then
        return RaidSanctionsCharDB.sessions[sessionId]
    end
    return nil
end

--[[
    Updates the raid member list in the current session
    
    This function is called whenever the group roster changes. It detects
    all members in the current group (raid or party) and adds them to the
    active session if they're not already present.
    
    Supports:
    - Full raid groups (up to 40 players)
    - Party groups (up to 5 players)
    - Automatic detection of player class, level, and rank
    
    @return void
]]
function Logic:UpdateRaidMembers()
    -- Only proceed if player is in a group
    if not (IsInRaid() or IsInGroup()) then
        return
    end
    
    -- Get or create active session
    local session = self:GetCurrentSession()
    if not session then
        session = self:CreateNewSession()
    end
    
    -- Iterate through all group members
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local name, rank, subgroup, level, class
        
        if IsInRaid() then
            -- Raid mode
            name, rank, subgroup, level, class = GetRaidRosterInfo(i)
        else
            -- Party mode
            if i == 1 then
                -- Own player
                name = UnitName("player")
                class = select(2, UnitClass("player"))
                level = UnitLevel("player")
                rank = 0
                subgroup = 1
            else
                -- Party members
                local unitId = "party" .. (i - 1)
                if UnitExists(unitId) then
                    name = UnitName(unitId)
                    class = select(2, UnitClass(unitId))
                    level = UnitLevel(unitId)
                    rank = 0
                    subgroup = 1
                end
            end
        end
        
        if name and not session.players[name] then
            session.players[name] = {
                class = class or "UNKNOWN",
                level = level or 0,
                subgroup = subgroup or 1,
                rank = rank or 0,
                penalties = {},
                total = 0,
                joinedAt = time()
            }
        end
    end
end

-- ============================================================================
-- PENALTY MANAGEMENT
-- ============================================================================

--[[
    Applies a penalty to a specific player
    
    This is the core function for penalty tracking. It:
    - Creates a unique penalty record
    - Updates the player's total penalty amount
    - Triggers season data update
    - Provides user feedback
    - Plays audio confirmation (if enabled)
    
    @param playerName string The name of the player to penalize
    @param reason string The reason for the penalty (e.g., "Late", "AFK")
    @param amount number The penalty amount in copper (10000 = 1 gold)
    @return boolean True if penalty was successfully applied, false otherwise
]]
function Logic:ApplyPenalty(playerName, reason, amount)
    local session = self:GetCurrentSession()
    if not session or not session.players[playerName] then
        return false
    end
    
    local player = session.players[playerName]
    local timestamp = time()
    
    -- Generate unique ID to prevent duplicate processing
    local uniqueId = timestamp .. "_" .. math.random(1000, 9999)
    
    -- Create penalty record
    local penaltyEntry = {
        reason = reason,
        amount = amount,
        timestamp = timestamp,
        date = date("%H:%M:%S"),
        uniqueId = uniqueId -- Add unique identifier
    }
    
    table.insert(player.penalties, penaltyEntry)
    player.total = player.total + amount
    
    -- Update season data automatically
    self:UpdateSeasonData()
    
    -- Feedback
    local message = format(L["PENALTY_APPLIED"], 
        playerName, reason, 
        self:FormatGold(amount), 
        self:FormatGold(player.total)
    )
    print(message)
    
    -- Play sound if enabled
    if RaidSanctionsDB.settings.soundEnabled then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    
    return true
end

--[[
    Removes the most recent matching penalty from a player
    
    Searches backwards through the player's penalty list to find and remove
    the most recent penalty that matches the specified reason and amount.
    This allows users to undo mistakes.
    
    @param playerName string The player whose penalty should be removed
    @param reason string The penalty reason to match
    @param amount number The penalty amount to match
    @return boolean True if a penalty was found and removed, false otherwise
]]
function Logic:RemovePenalty(playerName, reason, amount)
    local session = self:GetCurrentSession()
    if not session or not session.players[playerName] then
        return false
    end
    
    local player = session.players[playerName]
    
    -- Search backwards (most recent first)
    for i = #player.penalties, 1, -1 do
        local penalty = player.penalties[i]
        if penalty.reason == reason and penalty.amount == amount then
            -- Remove the penalty
            table.remove(player.penalties, i)
            player.total = math.max(0, player.total - amount) -- Ensure total doesn't go negative
            
            -- Update season data automatically
            self:UpdateSeasonData()
            
            -- Feedback
            print("Removed penalty '" .. reason .. "' from " .. playerName .. " (-" .. self:FormatGold(amount) .. ")")
            
            -- Play sound if enabled
            if RaidSanctionsDB.settings.soundEnabled then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            end
            
            return true
        end
    end
    
    -- No matching penalty found
    return false
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--[[
    Gets the total penalty amount for a specific player
    
    @param playerName string The player name to query
    @return number The total penalty amount in copper (0 if player not found)
]]
function Logic:GetPlayerTotal(playerName)
    local session = self:GetCurrentSession()
    if session and session.players[playerName] then
        return session.players[playerName].total
    end
    return 0
end

--[[
    Resets all session data
    
    Clears all player data from the current session while preserving
    season statistics. This is typically used at the end of a raid night.
    
    @return void
]]
function Logic:ResetSessionData()
    -- Add current session data to season data before resetting
    self:UpdateSeasonData()
    local session = self:GetCurrentSession()
    if session then
        session.players = {}
    end
    print(L["DATA_RESET"])
end

--[[
    Resets all penalties for a specific player
    
    Marks a player as "paid" by clearing their penalty history while
    preserving their entry in the session. Commonly used after a player
    has paid their accumulated fines.
    
    @param playerName string The player whose penalties should be reset
    @return boolean True if reset successful, false otherwise
]]
function Logic:ResetPlayerPenalties(playerName)
    if not playerName then
        return false
    end
    
    local session = self:GetCurrentSession()
    if not session or not session.players[playerName] then
        return false
    end
    
    -- Reset player data
    session.players[playerName].penalties = {}
    session.players[playerName].total = 0
    
    print("Penalties for " .. playerName .. " have been reset - Player marked as paid.")
    return true
end

--[[
    Manually adds a player to the current session
    
    Allows raid leaders to add players who aren't currently in the group,
    useful for applying penalties to players who have already left or for
    pre-raid penalty setup.
    
    @param playerName string The name of the player to add
    @return boolean True if player was added, false if already exists or invalid name
]]
function Logic:AddPlayerManually(playerName)
    if not playerName or playerName:trim() == "" then
        return false
    end
    
    local session = self:GetCurrentSession()
    if not session then
        session = self:CreateNewSession()
    end
    
    -- Check if player already exists
    if session.players[playerName] then
        return false -- Player already exists
    end
    
    -- Add player with default data
    session.players[playerName] = {
        class = "UNKNOWN", -- Class unknown as manually added
        level = 0,
        subgroup = 0,
        rank = 0,
        penalties = {},
        total = 0,
        joinedAt = time(),
        addedManually = true
    }
    
    return true
end

--[[
    Formats a copper amount into a human-readable gold string
    
    Converts raw copper values into formatted gold strings with appropriate
    suffixes for large amounts:
    - Values >= 1,000,000g: "1500k Gold"
    - Values >= 1,000g: "1.5k Gold"
    - Values < 1,000g: "500 Gold"
    
    @param amount number The amount in copper (10000 copper = 1 gold)
    @return string Formatted gold string
]]
function Logic:FormatGold(amount)
    local gold = math.floor(amount / 10000)
    
    -- Handle millions of gold
    if gold >= 1000000 then
        local millions = math.floor(gold / 1000)
        return millions .. "k Gold"
    elseif gold >= 1000 then
        -- Thousands: 1500g -> 1.5k Gold or 1000g -> 1k Gold
        local thousands = gold / 1000
        if thousands == math.floor(thousands) then
            -- Whole thousands
            return math.floor(thousands) .. "k Gold"
        else
            -- Decimal thousands (1 decimal place)
            return string.format("%.1fk Gold", thousands)
        end
    elseif gold > 0 then
        -- Regular gold amounts
        return gold .. " Gold"
    else
        return "0 Gold"
    end
end

--[[
    Retrieves the current penalty configuration
    
    @return table Penalty configuration mapping reasons to amounts
]]
function Logic:GetPenalties()
    return RaidSanctionsDB.penalties
end

--[[
    Updates penalty configuration with custom values
    
    Validates and applies custom penalty amounts. All values must be
    non-negative numbers with string keys.
    
    @param newPenalties table Map of penalty reasons to amounts
    @return boolean True if update successful, false if validation failed
]]
function Logic:SetCustomPenalties(newPenalties)
    -- Validate and set custom penalties
    if type(newPenalties) ~= "table" then
        return false
    end
    
    -- Update the database with new penalties
    for reason, amount in pairs(newPenalties) do
        if type(reason) == "string" and type(amount) == "number" and amount >= 0 then
            RaidSanctionsDB.penalties[reason] = amount
        end
    end
    
    return true
end

--[[
    Resets all penalties to their default values
    
    Discards any custom penalty configuration and restores the original
    default penalty amounts.
    
    @return void
]]
function Logic:ResetPenaltiesToDefault()
    RaidSanctionsDB.penalties = {}
    for reason, amount in pairs(DEFAULT_PENALTIES) do
        RaidSanctionsDB.penalties[reason] = amount
    end
end

--[[
    Forces penalty names to English (migration helper)
    
    Legacy function to update older installations that used German
    penalty names. Should not be needed for new installations.
    
    @deprecated Migration tool for legacy versions
    @return void
]]
function Logic:UpdatePenaltiesToEnglish()
    -- Force update penalties to English names
    RaidSanctionsDB.penalties = DEFAULT_PENALTIES
    print("RaidSanctions: Penalty names updated to English. Please reload the UI (/rs show).")
end

--[[
    Sets a single penalty amount
    
    @param reason string The penalty reason/category
    @param amount number The penalty amount in copper
    @return void
]]
function Logic:SetPenalty(reason, amount)
    RaidSanctionsDB.penalties[reason] = amount
end

--[[
    Retrieves the addon settings
    
    @return table Settings table with showInCombat, autoHide, soundEnabled
]]
function Logic:GetSettings()
    return RaidSanctionsDB.settings
end

--[[
    Outputs debug information to console
    
    Only produces output when DEBUG_MODE is enabled at the top of this file.
    
    @param message string The debug message to output
    @return void
]]
function Logic:Debug(message)
    if DEBUG_MODE then
        print("[RaidSanctions Debug]: " .. tostring(message))
    end
end

-- ============================================================================
-- SEASON STATISTICS MANAGEMENT
-- ============================================================================

--[[
    Retrieves and initializes season data
    
    Season data accumulates penalties across multiple raid sessions,
    providing long-term statistics. This function also handles migration
    of older data formats to include penalty deduplication tracking.
    
    @return table Season data indexed by player name
]]
function Logic:GetSeasonData()
    -- Initialize if needed
    if not RaidSanctionsCharDB.seasonData then
        RaidSanctionsCharDB.seasonData = {}
    end
    
    -- Migrate legacy data to add penalty tracking
    for playerName, playerData in pairs(RaidSanctionsCharDB.seasonData) do
        if not playerData.processedSessionPenalties then
            playerData.processedSessionPenalties = {}
            
            -- Mark all existing penalties as processed to avoid duplicates
            for i, penalty in ipairs(playerData.penalties or {}) do
                -- Use uniqueId if available, fallback to old system for compatibility
                local penaltyId = penalty.uniqueId or (penalty.timestamp .. "_" .. penalty.reason .. "_" .. penalty.amount .. "_" .. i)
                playerData.processedSessionPenalties[penaltyId] = true
            end
        end
    end
    
    return RaidSanctionsCharDB.seasonData
end

--[[
    Updates season data with current session penalties
    
    Incrementally adds new penalties from the active session to the cumulative
    season statistics. Uses unique penalty IDs to prevent duplicate processing.
    Automatically called after each penalty application/removal.
    
    @return void
]]
function Logic:UpdateSeasonData()
    -- Get current session data
    local session = self:GetCurrentSession()
    if not session or not session.players then
        return
    end
    
    -- Initialize season data if needed
    local seasonData = self:GetSeasonData()
    
    -- Update season data with current session
    for playerName, playerData in pairs(session.players) do
        if not seasonData[playerName] then
            seasonData[playerName] = {
                class = playerData.class,
                penalties = {},
                totalAmount = 0,
                totalPenalties = 0,
                lastSeen = time(),
                processedSessionPenalties = {} -- Track which penalties we've already processed
            }
        end
        
        -- Update player's season data
        local seasonPlayer = seasonData[playerName]
        seasonPlayer.class = playerData.class or seasonPlayer.class
        seasonPlayer.lastSeen = time()
        
        -- Initialize processed penalties tracker if it doesn't exist
        if not seasonPlayer.processedSessionPenalties then
            seasonPlayer.processedSessionPenalties = {}
        end
        
        -- Add new penalties from current session to season data (avoid duplicates)
        for i, penalty in ipairs(playerData.penalties) do
            -- Use uniqueId if available, fallback to old system for compatibility
            local penaltyId = penalty.uniqueId or (penalty.timestamp .. "_" .. penalty.reason .. "_" .. penalty.amount .. "_" .. i)
            
            -- Check if we've already processed this penalty
            if not seasonPlayer.processedSessionPenalties[penaltyId] then
                -- Add penalty to season data
                table.insert(seasonPlayer.penalties, {
                    reason = penalty.reason,
                    amount = penalty.amount,
                    timestamp = penalty.timestamp,
                    date = penalty.date,
                    sessionId = session.id,
                    uniqueId = penalty.uniqueId -- Preserve uniqueId
                })
                
                -- Update totals
                seasonPlayer.totalAmount = seasonPlayer.totalAmount + penalty.amount
                seasonPlayer.totalPenalties = seasonPlayer.totalPenalties + 1
                
                -- Mark penalty as processed
                seasonPlayer.processedSessionPenalties[penaltyId] = true
            end
        end
    end
end

--[[
    Clears all season statistics
    
    Permanently deletes all accumulated season data. This is typically
    used at the end of a raid tier or season.
    
    @return void
]]
function Logic:ClearSeasonData()
    RaidSanctionsCharDB.seasonData = {}
    print("Season data has been cleared.")
end

--[[
    Retrieves season players categorized by guild membership
    
    Separates season statistics into two lists: guild members and
    random/non-guild players. Both lists are sorted by total penalty
    amount in descending order.
    
    @return table, table Two arrays: guildPlayers and randomPlayers
]]
function Logic:GetSeasonPlayersByCategory()
    local seasonData = self:GetSeasonData()
    local guildPlayers = {}
    local randomPlayers = {}
    
    for playerName, playerData in pairs(seasonData) do
        local isGuildMember = self:IsPlayerInGuild(playerName)
        
        local playerInfo = {
            name = playerName,
            class = playerData.class,
            totalAmount = playerData.totalAmount,
            totalPenalties = playerData.totalPenalties,
            lastSeen = playerData.lastSeen,
            penalties = playerData.penalties or {} -- Include penalties array for counter calculation
        }
        
        if isGuildMember then
            table.insert(guildPlayers, playerInfo)
        else
            table.insert(randomPlayers, playerInfo)
        end
    end
    
    -- Sort both categories by total amount (highest first)
    table.sort(guildPlayers, function(a, b) return a.totalAmount > b.totalAmount end)
    table.sort(randomPlayers, function(a, b) return a.totalAmount > b.totalAmount end)
    
    return guildPlayers, randomPlayers
end

--[[
    Checks if a player is in the same guild as the current player
    
    Searches the guild roster for the specified player name. Handles
    cross-realm players by stripping realm suffixes.
    
    @param playerName string The player name to check
    @return boolean True if player is in the same guild, false otherwise
]]
function Logic:IsPlayerInGuild(playerName)
    -- Check if player is in the same guild as the current player
    if not IsInGuild() then
        return false -- Player is not in a guild
    end
    
    -- Get number of guild members
    local numGuildMembers = GetNumGuildMembers()
    
    -- Search through guild roster
    for i = 1, numGuildMembers do
        local name = GetGuildRosterInfo(i)
        if name then
            -- Remove realm name if present (handle cross-realm players)
            local guildMemberName = name:match("([^-]+)")
            if guildMemberName == playerName then
                return true
            end
        end
    end
    
    return false
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

--[[
    Handles ADDON_LOADED event
    
    Called when the addon is first loaded. Initializes the database
    and displays a welcome message.
    
    @return void
]]
function Logic:OnAddonLoaded()
    self:InitializeDatabase()
    print(format(L["ADDON_LOADED"], ADDON_VERSION))
end

--[[
    Handles PLAYER_ENTERING_WORLD event
    
    Called when the player enters the game world or reloads UI.
    Updates the raid member list if player is in a group.
    
    @return void
]]
function Logic:OnPlayerEnteringWorld()
    if IsInRaid() or IsInGroup() then
        self:UpdateRaidMembers()
    end
end

--[[
    Handles GROUP_ROSTER_UPDATE event
    
    Called whenever the group composition changes (members join/leave).
    Updates the member list and refreshes the UI.
    
    @return void
]]
function Logic:OnGroupRosterUpdate()
    if IsInRaid() or IsInGroup() then
        self:UpdateRaidMembers()
        -- Update season data when group changes
        self:UpdateSeasonData()
        -- Update UI if visible
        if RaidSanctions.UI and RaidSanctions.UI.RefreshPlayerList then
            RaidSanctions.UI:RefreshPlayerList()
        end
        -- Refresh Season Stats window if open
        if RaidSanctions.UI and RaidSanctions.UI.RefreshSeasonPlayerList then
            RaidSanctions.UI:RefreshSeasonPlayerList()
        end
    else
        -- No longer in group - mark session as inactive
        local session = self:GetCurrentSession()
        if session then
            session.isActive = false
        end
    end
end

--[[
    Removes random players with zero penalties from season data
    
    Cleanup function that removes non-guild players who have accumulated
    no penalties. Guild members are always retained regardless of penalty
    amount. Called automatically when player leaves a group.
    
    @return void
]]
function Logic:CleanupSeasonDataRandomPlayers()
    -- Clean up season data by removing random players with 0 penalties
    -- Guild members are always kept regardless of penalty amount
    local seasonData = self:GetSeasonData()
    local removedCount = 0
    
    local playersToRemove = {}
    
    for playerName, playerData in pairs(seasonData) do
        -- Check if player is NOT a guild member and has no penalties
        local isGuildMember = self:IsPlayerInGuild(playerName)
        
        if not isGuildMember and (playerData.totalAmount or 0) == 0 then
            table.insert(playersToRemove, playerName)
        end
    end
    
    -- Remove players from season data
    for _, playerName in ipairs(playersToRemove) do
        seasonData[playerName] = nil
        removedCount = removedCount + 1
    end
    
    -- Save updated season data
    if removedCount > 0 then
        -- Season data is already modified in place, no need to save separately
        print("RaidSanctions: Cleaned up " .. removedCount .. " random players with 0 penalties from season data.")
        
        -- Refresh season stats window if it's open
        if RaidSanctions.UI and RaidSanctions.UI.seasonStatsFrame and RaidSanctions.UI.seasonStatsFrame:IsShown() then
            RaidSanctions.UI:RefreshSeasonPlayerList()
        end
    end
end

-- Export for other modules
RaidSanctions.Logic = Logic
