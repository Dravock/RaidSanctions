--[[
    RaidSanctions - Database Module
    
    Handles all database operations including:
    - Database initialization
    - Schema migrations
    - SavedVariables management
    - Version control
    
    @author Drodar
    @version 1.2
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

RaidSanctions = RaidSanctions or {}
RaidSanctions.Database = {}

local DB = RaidSanctions.Database

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local ADDON_VERSION = "1.2"
local DEBUG_MODE = false

-- Default penalty amounts in copper (10000 copper = 1 gold)
local DEFAULT_PENALTIES = {
    ["Late"] = 10000,
    ["AFK"] = 10000,
    ["Wrong Gear"] = 10000,
    ["Wrong Tactic"] = 10000,
    ["Disruption"] = 10000
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
    Initializes the addon database structures
    
    Creates two separate database tables:
    - RaidSanctionsDB: Global settings shared across all characters
    - RaidSanctionsCharDB: Character-specific session and season data
    
    @return void
]]
function DB:Initialize()
    -- Initialize global database with default settings
    RaidSanctionsDB = RaidSanctionsDB or {
        version = ADDON_VERSION,
        penalties = {},
        settings = {
            showInCombat = false,
            autoHide = true,
            soundEnabled = true
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
        sessions = {},
        currentSession = nil,
        seasonData = {}
    }
    
    -- Ensure season data table exists
    if not RaidSanctionsCharDB.seasonData then
        RaidSanctionsCharDB.seasonData = {}
    end
    
    -- Perform database migration if version mismatch detected
    if RaidSanctionsDB.version ~= ADDON_VERSION then
        self:Migrate()
    end
end

--[[
    Handles database schema migrations between addon versions
    
    @return void
]]
function DB:Migrate()
    -- Update penalties from German to English if necessary
    if RaidSanctionsDB.penalties then
        local hasGermanNames = false
        
        for name, _ in pairs(RaidSanctionsDB.penalties) do
            if name == "Zu spät" or name == "Falsche Taktik" or 
               name == "Falsches Gear" or name == "Störung" then
                hasGermanNames = true
                break
            end
        end
        
        if hasGermanNames then
            RaidSanctionsDB.penalties = {}
            for reason, amount in pairs(DEFAULT_PENALTIES) do
                RaidSanctionsDB.penalties[reason] = amount
            end
            print("RaidSanctions: Updated penalty names to English")
        end
    end
    
    RaidSanctionsDB.version = ADDON_VERSION
    if DEBUG_MODE then
        print("Database migrated to version " .. ADDON_VERSION)
    end
end

-- ============================================================================
-- PENALTY CONFIGURATION
-- ============================================================================

--[[
    Retrieves the current penalty configuration
    
    @return table Penalty configuration
]]
function DB:GetPenalties()
    return RaidSanctionsDB.penalties
end

--[[
    Updates penalty configuration with custom values
    
    @param newPenalties table Map of penalty reasons to amounts
    @return boolean Success status
]]
function DB:SetPenalties(newPenalties)
    if type(newPenalties) ~= "table" then
        return false
    end
    
    for reason, amount in pairs(newPenalties) do
        if type(reason) == "string" and type(amount) == "number" and amount >= 0 then
            RaidSanctionsDB.penalties[reason] = amount
        end
    end
    
    return true
end

--[[
    Sets a single penalty amount
    
    @param reason string The penalty reason
    @param amount number The amount in copper
    @return void
]]
function DB:SetPenalty(reason, amount)
    RaidSanctionsDB.penalties[reason] = amount
end

--[[
    Resets all penalties to defaults
    
    @return void
]]
function DB:ResetPenaltiesToDefault()
    RaidSanctionsDB.penalties = {}
    for reason, amount in pairs(DEFAULT_PENALTIES) do
        RaidSanctionsDB.penalties[reason] = amount
    end
end

-- ============================================================================
-- SETTINGS MANAGEMENT
-- ============================================================================

--[[
    Retrieves addon settings
    
    @return table Settings
]]
function DB:GetSettings()
    return RaidSanctionsDB.settings
end

--[[
    Updates a setting value
    
    @param key string Setting key
    @param value any Setting value
    @return void
]]
function DB:SetSetting(key, value)
    if RaidSanctionsDB.settings then
        RaidSanctionsDB.settings[key] = value
    end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

RaidSanctions.Database = DB
