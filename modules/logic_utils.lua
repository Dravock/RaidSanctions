--[[
    RaidSanctions - Utility Module
    
    Common utility functions:
    - Gold formatting
    - Debug logging
    - Helper functions
    
    @author Drodar
    @version 1.2
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE
-- ============================================================================

RaidSanctions = RaidSanctions or {}
RaidSanctions.Utils = {}

local Utils = RaidSanctions.Utils

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local DEBUG_MODE = false

-- ============================================================================
-- FORMATTING
-- ============================================================================

--[[
    Formats copper amount to readable gold string
    
    @param amount number Amount in copper
    @return string Formatted string
]]
function Utils:FormatGold(amount)
    local gold = math.floor(amount / 10000)
    
    if gold >= 1000000 then
        local millions = math.floor(gold / 1000)
        return millions .. "k Gold"
    elseif gold >= 1000 then
        local thousands = gold / 1000
        if thousands == math.floor(thousands) then
            return math.floor(thousands) .. "k Gold"
        else
            return string.format("%.1fk Gold", thousands)
        end
    elseif gold > 0 then
        return gold .. " Gold"
    else
        return "0 Gold"
    end
end

-- ============================================================================
-- DEBUG
-- ============================================================================

--[[
    Debug logging
    
    @param message string Debug message
    @return void
]]
function Utils:Debug(message)
    if DEBUG_MODE then
        print("[RaidSanctions Debug]: " .. tostring(message))
    end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

RaidSanctions.Utils = Utils
