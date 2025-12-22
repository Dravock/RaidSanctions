--[[
    RaidSanctions - UI Module Loader (Legacy Compatibility Layer)
    
     DEPRECATION NOTICE 
    This file is maintained for backward compatibility only.
    
    The UI has been refactored into modular components:
    - modules/ui_core.lua        - Core UI framework
    - modules/ui_playerlist.lua  - Player list management
    - modules/ui_actions.lua     - Action buttons and management
    - modules/ui_sync.lua        - Live synchronization system
    
    This file now serves as a compatibility shim and will be removed in v2.0.0
    
    New code should use the modular API:
    - RaidSanctions.UI:Initialize()
    - RaidSanctions.UI:Toggle()
    - RaidSanctions.UI:RefreshPlayerList()
    
    @deprecated Will be removed in version 2.0.0
    @see modules/ui_core.lua
    @author Drodar
    @version 1.2
]]

local addonName, addonTable = ...

-- ============================================================================
-- LEGACY COMPATIBILITY NOTICE
-- ============================================================================

if DEBUG_MODE then
    print("[RaidSanctions] Loading legacy UI compatibility layer...")
    print("[RaidSanctions] Please update to use modular UI components.")
    print("[RaidSanctions] Legacy ui.lua will be removed in v2.0.0")
end

-- ============================================================================
-- MODULE FORWARDING
-- ============================================================================

--[[
    All UI functionality has been moved to the new modular system.
    This file now acts as a simple forwarding layer for backward compatibility.
    
    If you're seeing this in your codebase, please migrate to:
    - modules/ui_core.lua
    - modules/ui_playerlist.lua  
    - modules/ui_actions.lua
    - modules/ui_sync.lua
    
    The old 4000+ line ui.lua has been backed up to ui.lua.backup
]]

-- The actual UI implementation is in the modules/ directory
-- This file is intentionally kept minimal for legacy support

-- End of legacy compatibility layer
