# RaidSanctions UI Modules

This directory contains the refactored UI components of RaidSanctions, split into logical, maintainable modules following SOLID principles and modern software engineering practices.

---

## 📦 Module Overview

### ui_core.lua (198 lines)
**Core UI Framework & Window Management**

Responsibilities:
- Main frame creation and lifecycle management
- Window positioning and dragging
- Show/hide logic
- ESC key handling
- Base UI event setup

Key Functions:
```lua
UI:Initialize()        -- Initializes the UI system
UI:CreateMainFrame()   -- Creates the main window
UI:Toggle()            -- Toggles window visibility
UI:Show()              -- Shows the window
UI:Hide()              -- Hides the window
```

---

### ui_playerlist.lua (334 lines)
**Player List Rendering & Interaction**

Responsibilities:
- Scrollable player roster
- Header creation with column titles
- Player row rendering with class colors
- Penalty counter display per category
- Player selection management

Key Functions:
```lua
UI:CreateScrollFrame()      -- Creates scrollable content area
UI:CreateHeader()           -- Creates column headers
UI:RefreshPlayerList()      -- Refreshes the entire list
UI:CreatePlayerRow()        -- Creates individual player row
UI:SelectPlayer()           -- Selects a player
UI:GetSelectedPlayer()      -- Gets currently selected player
```

---

### ui_actions.lua (357 lines)
**Action Panel & Button Management**

Responsibilities:
- Bottom action panel creation
- Penalty application buttons (+)
- Penalty removal buttons (-)
- Management buttons (Whisper, Post, Sync, etc.)
- Button state management and authorization

Key Functions:
```lua
UI:CreateBottomPanel()           -- Creates action panel
UI:CreatePenaltyButtons()        -- Creates penalty buttons
UI:CreateManagementButtons()     -- Creates management buttons
UI:ApplyPenaltyToSelectedPlayer() -- Applies penalty
UI:RemovePenaltyFromSelectedPlayer() -- Removes penalty
```

---

### ui_sync.lua (407 lines)
**Real-Time Data Synchronization**

Responsibilities:
- Live sync initialization
- Host/client architecture
- Network message handling
- Data serialization
- Conflict resolution

Key Functions:
```lua
UI:InitializeLiveSync()      -- Sets up sync system
UI:StartLiveSyncAsHost()     -- Starts as host
UI:SendLiveSyncUpdate()      -- Sends update
UI:HandleSyncMessage()       -- Handles incoming messages
UI:StopLiveSync()            -- Stops synchronization
UI:IsLiveSyncActive()        -- Checks sync status
```

---

## 🏗️ Architecture

### Module Dependencies
```
ui_core.lua
    ↓
    ├─→ ui_playerlist.lua
    ├─→ ui_actions.lua
    └─→ ui_sync.lua
```

### Data Flow
```
User Action → ui_actions.lua → RaidSanctions.Logic → Data Layer
                   ↓                                      ↓
              ui_sync.lua                         ui_playerlist.lua
                   ↓                                      ↓
            Network Broadcast                      UI Refresh
```

---

## 📝 Coding Standards

### Function Documentation
All functions use JSDoc-style documentation:
```lua
--[[
    Brief description of function
    
    Detailed explanation of what the function does and when to use it.
    
    @param paramName type Description
    @return type Description
]]
function UI:FunctionName(paramName)
    -- Implementation
end
```

### Section Markers
```lua
-- ============================================================================
-- SECTION NAME
-- ============================================================================
```

### Constants
```lua
-- Defined in ui_core.lua
UI.FRAME_WIDTH = 1000
UI.FRAME_HEIGHT = 700
UI.ROW_HEIGHT = 30
UI.BUTTON_WIDTH = 80
```

---

## 🔧 Adding New Features

### To Add a New Button
1. Edit `ui_actions.lua`
2. Add button config to `CreateManagementButtons()`
3. Create handler function
4. Update tooltip

### To Modify Player List
1. Edit `ui_playerlist.lua`
2. Modify `CreatePlayerRow()` for row changes
3. Update `RefreshPlayerList()` for data changes

### To Add Sync Feature
1. Edit `ui_sync.lua`
2. Define message type
3. Create handler function
4. Update serialization if needed

---

## 🧪 Testing

### Manual Testing Checklist
- [ ] Window opens and closes properly
- [ ] Player list displays all group members
- [ ] Penalties apply correctly
- [ ] Penalty removal works
- [ ] Live sync broadcasts updates
- [ ] Selection highlights work
- [ ] Tooltips display correctly
- [ ] Authorization checks work

### Debug Mode
Enable in each module or globally:
```lua
local DEBUG_MODE = true
```

---

## 📊 Performance Metrics

| Module | Lines | Functions | Complexity |
|--------|-------|-----------|------------|
| ui_core | 198 | 8 | Low |
| ui_playerlist | 334 | 12 | Medium |
| ui_actions | 357 | 10 | Medium |
| ui_sync | 407 | 15 | High |

---

## 🔮 Future Enhancements

### Planned Features
- [ ] Settings window module
- [ ] Season stats module
- [ ] Mail system module
- [ ] Options panel module
- [ ] Context menu module

### Refactoring Opportunities
- [ ] Extract StaticPopup dialogs to separate module
- [ ] Create UI utility library for common functions
- [ ] Implement UI component factory pattern
- [ ] Add UI state machine for complex flows

---

## 📚 Additional Resources

- [WoW UI Documentation](https://wowpedia.fandom.com/wiki/UI_FAQ)
- [Frame API](https://wowpedia.fandom.com/wiki/Widget_API)
- [Event System](https://wowpedia.fandom.com/wiki/Events)

---

## 👥 Contributing

When modifying modules:
1. Follow existing code style
2. Add comprehensive comments
3. Update this README if adding new modules
4. Test thoroughly in-game
5. Check for Lua errors

---

**Built with modern software engineering practices for maintainability and scalability.**
