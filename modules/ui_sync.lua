--[[
    RaidSanctions - Live Sync Module
    
    Handles real-time data synchronization between raid members:
    - Multi-user penalty tracking
    - Automatic conflict resolution
    - Network message handling
    - Host/client architecture
    
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

-- Sync state tracking
local liveSyncEnabled = false
local isLiveSyncHost = false
local liveSyncParticipants = {}
local lastSyncTimestamp = 0

-- Communication constants
local SYNC_PREFIX = "RaidSanctions"
local MESSAGE_THROTTLE = 0.5 -- seconds between messages

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
    Initializes the live sync system
    
    Sets up addon communication channels and registers message handlers.
    Must be called before any sync operations.
    
    @return void
]]
function UI:InitializeLiveSync()
    -- Register addon communication prefix
    C_ChatInfo.RegisterAddonMessagePrefix(SYNC_PREFIX)
    
    -- Register message handler
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    
    eventFrame:SetScript("OnEvent", function(self, event, prefix, message, distribution, sender)
        if event == "CHAT_MSG_ADDON" and prefix == SYNC_PREFIX then
            UI:HandleSyncMessage(message, sender, distribution)
        end
    end)
    
    self.syncEventFrame = eventFrame
end

-- ============================================================================
-- HOST MANAGEMENT
-- ============================================================================

--[[
    Starts live sync as the host
    
    The host is responsible for:
    - Broadcasting initial state
    - Resolving conflicts
    - Accepting new participants
    
    @return void
]]
function UI:StartLiveSyncAsHost()
    if not (IsInRaid() or IsInGroup()) then
        print("You must be in a group to start Live Sync!")
        return
    end
    
    liveSyncEnabled = true
    isLiveSyncHost = true
    wipe(liveSyncParticipants)
    
    -- Add self to participants
    local playerName = UnitName("player")
    liveSyncParticipants[playerName] = true
    
    print("[Live Sync] Started as HOST. Broadcasting to group...")
    self:SendLiveSyncAnnouncement()
end

--[[
    Sends sync start announcement to group
    
    Broadcasts that this player is now the sync host and includes
    the current session data.
    
    @return void
]]
function UI:SendLiveSyncAnnouncement()
    local channel = IsInRaid() and "RAID" or "PARTY"
    local timestamp = time()
    
    -- Get current data
    local session = Logic:GetCurrentSession()
    local penalties = Logic:GetPenalties()
    local seasonData = Logic:GetSeasonData()
    
    -- Build announcement message
    local message = string.format("SYNC_START|%d", timestamp)
    
    -- Send announcement
    C_ChatInfo.SendAddonMessage(SYNC_PREFIX, message, channel)
    
    -- Follow up with full data sync
    C_Timer.After(1.0, function()
        self:SendMultiMessageSync(session, penalties, seasonData)
    end)
end

-- ============================================================================
-- DATA SYNCHRONIZATION
-- ============================================================================

--[[
    Sends a live sync update for a specific action
    
    Used for real-time updates when penalties are applied/removed.
    
    @param actionType string Type of action ("APPLY_PENALTY", "REMOVE_PENALTY", etc.)
    @param data table Action-specific data
    @return void
]]
function UI:SendLiveSyncUpdate(actionType, data)
    if not liveSyncEnabled then
        return
    end
    
    -- Throttle messages to prevent spam
    local currentTime = GetTime()
    if currentTime - lastSyncTimestamp < MESSAGE_THROTTLE then
        return
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local timestamp = time()
    
    -- Build update message
    local message = string.format("SYNC_UPDATE|%s|%d|%s|%d|%s",
        actionType,
        timestamp,
        data.playerName or "",
        data.amount or 0,
        data.reason or ""
    )
    
    C_ChatInfo.SendAddonMessage(SYNC_PREFIX, message, channel)
    lastSyncTimestamp = currentTime
end

--[[
    Sends a complete data sync in multiple messages
    
    Breaks down large data sets into manageable chunks to avoid
    hitting chat message size limits.
    
    @param session table Current session data
    @param penalties table Penalty configuration
    @param seasonData table Season statistics
    @return void
]]
function UI:SendMultiMessageSync(session, penalties, seasonData)
    if not (IsInRaid() or IsInGroup()) then
        return
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local timestamp = time()
    
    -- Split data into manageable chunks
    local messageQueue = {}
    
    -- Message 1: Header
    table.insert(messageQueue, string.format("SYNC_MULTI|START|%d", timestamp))
    
    -- Message 2: Penalties configuration
    local penaltyData = self:SerializePenalties(penalties)
    table.insert(messageQueue, "SYNC_MULTI|PENALTIES|" .. penaltyData)
    
    -- Message 3+: Player data (chunked if necessary)
    if session and session.players then
        for playerName, playerData in pairs(session.players) do
            local playerChunk = self:SerializePlayerData(playerName, playerData)
            table.insert(messageQueue, "SYNC_MULTI|PLAYER|" .. playerChunk)
        end
    end
    
    -- Final message: Complete
    table.insert(messageQueue, string.format("SYNC_MULTI|END|%d", timestamp))
    
    -- Send messages with delays
    self:SendMessagesWithDelay(messageQueue, channel, timestamp)
end

--[[
    Sends queued messages with appropriate delays
    
    @param messageQueue table Array of messages to send
    @param channel string Chat channel ("RAID" or "PARTY")
    @param sessionTimestamp number Session identifier
    @return void
]]
function UI:SendMessagesWithDelay(messageQueue, channel, sessionTimestamp)
    local currentIndex = 1
    local MESSAGE_DELAY = 0.3 -- seconds between messages
    
    local function sendNextMessage()
        if currentIndex > #messageQueue then
            return -- All messages sent
        end
        
        local message = messageQueue[currentIndex]
        C_ChatInfo.SendAddonMessage(SYNC_PREFIX, message, channel)
        
        currentIndex = currentIndex + 1
        
        if currentIndex <= #messageQueue then
            C_Timer.After(MESSAGE_DELAY, sendNextMessage)
        end
    end
    
    sendNextMessage()
end

-- ============================================================================
-- MESSAGE HANDLING
-- ============================================================================

--[[
    Handles incoming sync messages
    
    Routes messages to appropriate handlers based on message type.
    
    @param message string The received message
    @param sender string Name of the sender
    @param distribution string Distribution channel
    @return void
]]
function UI:HandleSyncMessage(message, sender, distribution)
    -- Ignore own messages
    local playerName = UnitName("player")
    if sender == playerName then
        return
    end
    
    -- Parse message type
    local parts = {strsplit("|", message)}
    local messageType = parts[1]
    
    if messageType == "SYNC_START" then
        self:HandleSyncStart(message, sender)
    elseif messageType == "SYNC_UPDATE" then
        self:HandleSyncUpdate(message, sender)
    elseif messageType == "SYNC_MULTI" then
        self:HandleMultiSyncMessage(message, sender, distribution)
    elseif messageType == "SYNC_JOIN" then
        self:HandleSyncJoin(message, sender)
    end
end

--[[
    Handles SYNC_START message
    
    Called when another player becomes sync host.
    
    @param message string The message content
    @param sender string Name of the sender
    @return void
]]
function UI:HandleSyncStart(message, sender)
    if liveSyncEnabled and isLiveSyncHost then
        -- Already a host, ignore
        return
    end
    
    -- Join the sync session
    liveSyncEnabled = true
    isLiveSyncHost = false
    wipe(liveSyncParticipants)
    liveSyncParticipants[sender] = true
    
    local playerName = UnitName("player")
    liveSyncParticipants[playerName] = true
    
    print("[Live Sync] Joined sync session hosted by " .. sender)
    
    -- Send join confirmation
    self:SendLiveSyncJoinConfirmation()
end

--[[
    Handles SYNC_UPDATE message
    
    Applies real-time updates from other players.
    
    @param message string The message content
    @param sender string Name of the sender
    @return void
]]
function UI:HandleSyncUpdate(message, sender)
    if not liveSyncEnabled then
        return
    end
    
    -- Parse update: SYNC_UPDATE|ACTION|TIMESTAMP|PLAYER|AMOUNT|REASON
    local parts = {strsplit("|", message)}
    local actionType = parts[2]
    local timestamp = tonumber(parts[3]) or 0
    local playerName = parts[4] or ""
    local amount = tonumber(parts[5]) or 0
    local reason = parts[6] or ""
    
    -- Apply the update
    if actionType == "APPLY_PENALTY" then
        Logic:ApplyPenalty(playerName, reason, amount)
        self:RefreshPlayerList()
    elseif actionType == "REMOVE_PENALTY" then
        Logic:RemovePenalty(playerName, reason, amount)
        self:RefreshPlayerList()
    end
    
    lastSyncTimestamp = timestamp
end

-- ============================================================================
-- SERIALIZATION HELPERS
-- ============================================================================

--[[
    Serializes penalty configuration for transmission
    
    @param penalties table Penalty configuration
    @return string Serialized data
]]
function UI:SerializePenalties(penalties)
    local parts = {}
    for reason, amount in pairs(penalties) do
        table.insert(parts, string.format("%s:%d", reason, amount))
    end
    return table.concat(parts, ",")
end

--[[
    Serializes player data for transmission
    
    @param playerName string The player's name
    @param playerData table The player's data
    @return string Serialized data
]]
function UI:SerializePlayerData(playerName, playerData)
    -- Format: NAME|CLASS|TOTAL|PENALTY_COUNT|PENALTIES
    local penaltyCount = #(playerData.penalties or {})
    local penaltiesData = {}
    
    for _, penalty in ipairs(playerData.penalties or {}) do
        table.insert(penaltiesData, string.format("%s:%d:%d",
            penalty.reason,
            penalty.amount,
            penalty.timestamp or 0
        ))
    end
    
    return string.format("%s|%s|%d|%d|%s",
        playerName,
        playerData.class or "UNKNOWN",
        playerData.total or 0,
        penaltyCount,
        table.concat(penaltiesData, ",")
    )
end

-- ============================================================================
-- SYNC CONTROL
-- ============================================================================

--[[
    Stops live sync
    
    @return void
]]
function UI:StopLiveSync()
    liveSyncEnabled = false
    isLiveSyncHost = false
    wipe(liveSyncParticipants)
    print("[Live Sync] Stopped")
end

--[[
    Checks if live sync is currently active
    
    @return boolean True if sync is enabled
]]
function UI:IsLiveSyncActive()
    return liveSyncEnabled
end

--[[
    Toggles live sync on/off
    
    @return void
]]
function UI:ToggleLiveSync()
    if liveSyncEnabled then
        self:StopLiveSync()
    else
        self:StartLiveSyncAsHost()
    end
    
    if self.UpdateLiveSyncButtonStatus then
        self:UpdateLiveSyncButtonStatus()
    end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

-- Functions are added to UI namespace
