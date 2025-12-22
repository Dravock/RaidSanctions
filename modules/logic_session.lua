--[[
    RaidSanctions - Session Module
    
    Handles raid session management:
    - Session creation and retrieval
    - Player roster management
    - Session lifecycle
    
    @author Drodar
    @version 1.2
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

RaidSanctions = RaidSanctions or {}
RaidSanctions.Session = {}

local Session = RaidSanctions.Session

-- ============================================================================
-- SESSION MANAGEMENT
-- ============================================================================

--[[
    Creates a new raid session
    
    @return table The newly created session
]]
function Session:Create()
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
    Retrieves the current active session
    
    @return table|nil Current session or nil
]]
function Session:GetCurrent()
    local sessionId = RaidSanctionsCharDB.currentSession
    if sessionId and RaidSanctionsCharDB.sessions[sessionId] then
        return RaidSanctionsCharDB.sessions[sessionId]
    end
    return nil
end

--[[
    Updates the raid member list
    
    @return void
]]
function Session:UpdateMembers()
    if not (IsInRaid() or IsInGroup()) then
        return
    end
    
    local session = self:GetCurrent()
    if not session then
        session = self:Create()
    end
    
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local name, rank, subgroup, level, class
        
        if IsInRaid() then
            name, rank, subgroup, level, class = GetRaidRosterInfo(i)
        else
            if i == 1 then
                name = UnitName("player")
                class = select(2, UnitClass("player"))
                level = UnitLevel("player")
                rank = 0
                subgroup = 1
            else
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

--[[
    Adds a player manually to the session
    
    @param playerName string Player name
    @return boolean Success status
]]
function Session:AddPlayer(playerName)
    if not playerName or playerName:trim() == "" then
        return false
    end
    
    local session = self:GetCurrent()
    if not session then
        session = self:Create()
    end
    
    if session.players[playerName] then
        return false
    end
    
    session.players[playerName] = {
        class = "UNKNOWN",
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
    Resets all session data
    
    @return void
]]
function Session:Reset()
    -- Update season before reset
    if RaidSanctions.Season then
        RaidSanctions.Season:Update()
    end
    
    local session = self:GetCurrent()
    if session then
        session.players = {}
    end
    print("All session data has been reset.")
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

RaidSanctions.Session = Session
