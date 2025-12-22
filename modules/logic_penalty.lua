--[[
    RaidSanctions - Penalty Module
    
    Handles penalty operations:
    - Applying penalties
    - Removing penalties
    - Penalty calculations
    - Player penalty management
    
    @author Drodar
    @version 1.2
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

RaidSanctions = RaidSanctions or {}
RaidSanctions.Penalty = {}

local Penalty = RaidSanctions.Penalty
local format = string.format

-- ============================================================================
-- LOCALIZATION
-- ============================================================================

local L = {
    ["PENALTY_APPLIED"] = "%s penalized with '%s': +%s | Total: %s"
}

-- ============================================================================
-- PENALTY OPERATIONS
-- ============================================================================

--[[
    Applies a penalty to a player
    
    @param playerName string Player name
    @param reason string Penalty reason
    @param amount number Amount in copper
    @return boolean Success status
]]
function Penalty:Apply(playerName, reason, amount)
    local session = RaidSanctions.Session:GetCurrent()
    if not session or not session.players[playerName] then
        return false
    end
    
    local player = session.players[playerName]
    local timestamp = time()
    local uniqueId = timestamp .. "_" .. math.random(1000, 9999)
    
    local penaltyEntry = {
        reason = reason,
        amount = amount,
        timestamp = timestamp,
        date = date("%H:%M:%S"),
        uniqueId = uniqueId
    }
    
    table.insert(player.penalties, penaltyEntry)
    player.total = player.total + amount
    
    -- Update season data
    if RaidSanctions.Season then
        RaidSanctions.Season:Update()
    end
    
    -- Feedback
    local message = format(L["PENALTY_APPLIED"],
        playerName,
        reason,
        RaidSanctions.Utils:FormatGold(amount),
        RaidSanctions.Utils:FormatGold(player.total)
    )
    print(message)
    
    -- Play sound if enabled
    local settings = RaidSanctions.Database:GetSettings()
    if settings and settings.soundEnabled then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    
    return true
end

--[[
    Removes a penalty from a player
    
    @param playerName string Player name
    @param reason string Penalty reason
    @param amount number Amount in copper
    @return boolean Success status
]]
function Penalty:Remove(playerName, reason, amount)
    local session = RaidSanctions.Session:GetCurrent()
    if not session or not session.players[playerName] then
        return false
    end
    
    local player = session.players[playerName]
    
    for i = #player.penalties, 1, -1 do
        local penalty = player.penalties[i]
        if penalty.reason == reason and penalty.amount == amount then
            table.remove(player.penalties, i)
            player.total = math.max(0, player.total - amount)
            
            if RaidSanctions.Season then
                RaidSanctions.Season:Update()
            end
            
            print("Removed penalty '" .. reason .. "' from " .. playerName .. 
                  " (-" .. RaidSanctions.Utils:FormatGold(amount) .. ")")
            
            local settings = RaidSanctions.Database:GetSettings()
            if settings and settings.soundEnabled then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            end
            
            return true
        end
    end
    
    return false
end

--[[
    Gets total penalty for a player
    
    @param playerName string Player name
    @return number Total amount
]]
function Penalty:GetTotal(playerName)
    local session = RaidSanctions.Session:GetCurrent()
    if session and session.players[playerName] then
        return session.players[playerName].total
    end
    return 0
end

--[[
    Resets all penalties for a player
    
    @param playerName string Player name
    @return boolean Success status
]]
function Penalty:ResetPlayer(playerName)
    if not playerName then
        return false
    end
    
    local session = RaidSanctions.Session:GetCurrent()
    if not session or not session.players[playerName] then
        return false
    end
    
    session.players[playerName].penalties = {}
    session.players[playerName].total = 0
    
    print("Penalties for " .. playerName .. " have been reset - Player marked as paid.")
    return true
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

RaidSanctions.Penalty = Penalty
