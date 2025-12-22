--[[
    RaidSanctions - Season Module
    
    Manages season statistics:
    - Cumulative penalty tracking
    - Season data management
    - Guild player categorization
    - Data cleanup
    
    @author Drodar
    @version 1.2
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

RaidSanctions = RaidSanctions or {}
RaidSanctions.Season = {}

local Season = RaidSanctions.Season

-- ============================================================================
-- SEASON DATA MANAGEMENT
-- ============================================================================

--[[
    Gets season data with migration
    
    @return table Season data
]]
function Season:GetData()
    if not RaidSanctionsCharDB.seasonData then
        RaidSanctionsCharDB.seasonData = {}
    end
    
    -- Migrate legacy data
    for playerName, playerData in pairs(RaidSanctionsCharDB.seasonData) do
        if not playerData.processedSessionPenalties then
            playerData.processedSessionPenalties = {}
            
            for i, penalty in ipairs(playerData.penalties or {}) do
                local penaltyId = penalty.uniqueId or 
                    (penalty.timestamp .. "_" .. penalty.reason .. "_" .. penalty.amount .. "_" .. i)
                playerData.processedSessionPenalties[penaltyId] = true
            end
        end
    end
    
    return RaidSanctionsCharDB.seasonData
end

--[[
    Updates season data from current session
    
    @return void
]]
function Season:Update()
    local session = RaidSanctions.Session:GetCurrent()
    if not session or not session.players then
        return
    end
    
    local seasonData = self:GetData()
    
    for playerName, playerData in pairs(session.players) do
        if not seasonData[playerName] then
            seasonData[playerName] = {
                class = playerData.class,
                penalties = {},
                totalAmount = 0,
                totalPenalties = 0,
                lastSeen = time(),
                processedSessionPenalties = {}
            }
        end
        
        local seasonPlayer = seasonData[playerName]
        seasonPlayer.class = playerData.class or seasonPlayer.class
        seasonPlayer.lastSeen = time()
        
        if not seasonPlayer.processedSessionPenalties then
            seasonPlayer.processedSessionPenalties = {}
        end
        
        for i, penalty in ipairs(playerData.penalties) do
            local penaltyId = penalty.uniqueId or 
                (penalty.timestamp .. "_" .. penalty.reason .. "_" .. penalty.amount .. "_" .. i)
            
            if not seasonPlayer.processedSessionPenalties[penaltyId] then
                table.insert(seasonPlayer.penalties, {
                    reason = penalty.reason,
                    amount = penalty.amount,
                    timestamp = penalty.timestamp,
                    date = penalty.date,
                    sessionId = session.id,
                    uniqueId = penalty.uniqueId
                })
                
                seasonPlayer.totalAmount = seasonPlayer.totalAmount + penalty.amount
                seasonPlayer.totalPenalties = seasonPlayer.totalPenalties + 1
                seasonPlayer.processedSessionPenalties[penaltyId] = true
            end
        end
    end
end

--[[
    Clears all season data
    
    @return void
]]
function Season:Clear()
    RaidSanctionsCharDB.seasonData = {}
    print("Season data has been cleared.")
end

--[[
    Gets players categorized by guild membership
    
    @return table, table Guild players and random players
]]
function Season:GetPlayersByCategory()
    local seasonData = self:GetData()
    local guildPlayers = {}
    local randomPlayers = {}
    
    for playerName, playerData in pairs(seasonData) do
        local isGuildMember = RaidSanctions.Guild:IsPlayerInGuild(playerName)
        
        local playerInfo = {
            name = playerName,
            class = playerData.class,
            totalAmount = playerData.totalAmount,
            totalPenalties = playerData.totalPenalties,
            lastSeen = playerData.lastSeen,
            penalties = playerData.penalties or {}
        }
        
        if isGuildMember then
            table.insert(guildPlayers, playerInfo)
        else
            table.insert(randomPlayers, playerInfo)
        end
    end
    
    table.sort(guildPlayers, function(a, b) return a.totalAmount > b.totalAmount end)
    table.sort(randomPlayers, function(a, b) return a.totalAmount > b.totalAmount end)
    
    return guildPlayers, randomPlayers
end

--[[
    Cleans up random players with zero penalties
    
    @return void
]]
function Season:CleanupRandomPlayers()
    local seasonData = self:GetData()
    local removedCount = 0
    local playersToRemove = {}
    
    for playerName, playerData in pairs(seasonData) do
        local isGuildMember = RaidSanctions.Guild:IsPlayerInGuild(playerName)
        
        if not isGuildMember and (playerData.totalAmount or 0) == 0 then
            table.insert(playersToRemove, playerName)
        end
    end
    
    for _, playerName in ipairs(playersToRemove) do
        seasonData[playerName] = nil
        removedCount = removedCount + 1
    end
    
    if removedCount > 0 then
        print("RaidSanctions: Cleaned up " .. removedCount .. 
              " random players with 0 penalties from season data.")
        
        if RaidSanctions.UI and RaidSanctions.UI.RefreshSeasonPlayerList then
            RaidSanctions.UI:RefreshSeasonPlayerList()
        end
    end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

RaidSanctions.Season = Season
