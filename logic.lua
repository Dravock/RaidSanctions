--[[
    RaidSanctions - Legacy Logic Compatibility Layer
    
    ⚠️ DEPRECATION NOTICE ⚠️
    
    This file is maintained for backward compatibility only.
    All logic has been refactored into modular components:
    
    - modules/logic_database.lua   → Database operations
    - modules/logic_session.lua    → Session management
    - modules/logic_penalty.lua    → Penalty operations
    - modules/logic_season.lua     → Season statistics
    - modules/logic_guild.lua      → Guild integration
    - modules/logic_utils.lua      → Utility functions
    
    @author Drodar
    @version 1.2
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- BACKWARD COMPATIBILITY LAYER
-- ============================================================================

-- Ensure namespace exists
RaidSanctions = RaidSanctions or {}

--[[
    Initialize the database
    Forwards to Database module
]]
function RaidSanctions:InitializeDatabase()
    return self.Database:Initialize()
end

--[[
    Migrate database schema
    Forwards to Database module
]]
function RaidSanctions:MigrateDatabase()
    return self.Database:Migrate()
end

--[[
    Create a new session
    Forwards to Session module
]]
function RaidSanctions:CreateNewSession()
    return self.Session:Create()
end

--[[
    Get current session
    Forwards to Session module
]]
function RaidSanctions:GetCurrentSession()
    return self.Session:GetCurrent()
end

--[[
    Update raid members
    Forwards to Session module
]]
function RaidSanctions:UpdateRaidMembers()
    return self.Session:UpdateMembers()
end

--[[
    Apply a penalty to a player
    Forwards to Penalty module
]]
function RaidSanctions:ApplyPenalty(playerName, reason, amount)
    return self.Penalty:Apply(playerName, reason, amount)
end

--[[
    Remove a penalty from a player
    Forwards to Penalty module
]]
function RaidSanctions:RemovePenalty(playerName, reason, amount)
    return self.Penalty:Remove(playerName, reason, amount)
end

--[[
    Format gold amount
    Forwards to Utils module
]]
function RaidSanctions:FormatGold(amount)
    return self.Utils:FormatGold(amount)
end

--[[
    Get season data
    Forwards to Season module
]]
function RaidSanctions:GetSeasonData()
    return self.Season:GetData()
end

--[[
    Update season data
    Forwards to Season module
]]
function RaidSanctions:UpdateSeasonData()
    return self.Season:Update()
end

--[[
    Check if player is in guild
    Forwards to Guild module
]]
function RaidSanctions:IsPlayerInGuild(playerName)
    return self.Guild:IsPlayerInGuild(playerName)
end

--[[
    Reset all session data
    Forwards to Session module
]]
function RaidSanctions:ResetAllData()
    return self.Session:Reset()
end

--[[
    Clear season data
    Forwards to Season module
]]
function RaidSanctions:ClearSeasonData()
    return self.Season:Clear()
end

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- All logic modules are now loaded separately via RaidSanctions.toc
-- This file only provides backward compatibility wrappers
