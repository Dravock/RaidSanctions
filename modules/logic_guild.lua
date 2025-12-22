--[[
    RaidSanctions - Guild Module
    
    Handles guild-related operations:
    - Guild membership checks
    - Guild roster lookups
    - Cross-realm player handling
    
    @author Drodar
    @version 1.2
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

RaidSanctions = RaidSanctions or {}
RaidSanctions.Guild = {}

local Guild = RaidSanctions.Guild

-- ============================================================================
-- GUILD OPERATIONS
-- ============================================================================

--[[
    Checks if a player is in the same guild
    
    @param playerName string Player name to check
    @return boolean True if in same guild
]]
function Guild:IsPlayerInGuild(playerName)
    if not IsInGuild() then
        return false
    end
    
    local numGuildMembers = GetNumGuildMembers()
    
    for i = 1, numGuildMembers do
        local name = GetGuildRosterInfo(i)
        if name then
            -- Remove realm suffix for cross-realm players
            local guildMemberName = name:match("([^-]+)")
            if guildMemberName == playerName then
                return true
            end
        end
    end
    
    return false
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

RaidSanctions.Guild = Guild
