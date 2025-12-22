# RaidSanctions - Architecture Documentation

## 📐 System Architecture Overview

RaidSanctions follows a **layered, modular architecture** with clear separation of concerns. This document provides an in-depth look at the system design, data flow, and architectural decisions.

---

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
│  ┌────────────┬──────────────┬────────────┬──────────────┐ │
│  │  UI Core   │  Player List │   Actions  │  Live Sync   │ │
│  └────────────┴──────────────┴────────────┴──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                             ▲
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                    │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  Session Management │ Penalty System │ Season Stats  │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                             ▲
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Persistence                       │
│  ┌──────────────────────┬────────────────────────────────┐ │
│  │  RaidSanctionsDB     │  RaidSanctionsCharDB           │ │
│  │  (Global Settings)   │  (Character Sessions & Seasons)│ │
│  └──────────────────────┴────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                             ▲
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                     WoW API & Event System                   │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  ADDON_LOADED │ GROUP_ROSTER_UPDATE │ CHAT_MSG_ADDON │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Module Breakdown

### 1. **Entry Point (`RaidSanctions.lua`)**

**Responsibility**: Application bootstrap and event routing

```lua
-- Key components:
- Event frame registration
- Slash command handlers
- Module initialization coordination
- Public API exposure
```

**Design Pattern**: *Event Dispatcher Pattern*

**Key Functions**:
- `OnEvent()` - Central event router
- `OnAddonLoaded()` - Initialization trigger
- Slash command processor

---

### 2. **Business Logic (`logic.lua`)**

**Responsibility**: Core business rules and data management

```lua
-- Modules within logic.lua:
├── Database Management
│   ├── InitializeDatabase()
│   └── MigrateDatabase()
├── Session Management
│   ├── CreateNewSession()
│   ├── GetCurrentSession()
│   └── UpdateRaidMembers()
├── Penalty System
│   ├── ApplyPenalty()
│   ├── RemovePenalty()
│   └── FormatGold()
└── Season Statistics
    ├── GetSeasonData()
    ├── UpdateSeasonData()
    └── GetSeasonPlayersByCategory()
```

**Design Patterns**:
- *Repository Pattern* for data access
- *Strategy Pattern* for penalty calculations
- *Observer Pattern* for data updates

---

### 3. **UI Core Module (`modules/ui_core.lua`)**

**Responsibility**: Window management and framework

```lua
-- Features:
- Frame creation and lifecycle
- Window positioning and dragging
- Show/hide logic
- ESC key handling
```

**Design Pattern**: *Facade Pattern*

**Key Properties**:
```lua
UI.FRAME_WIDTH = 1000
UI.FRAME_HEIGHT = 700
UI.ROW_HEIGHT = 30
```

---

### 4. **Player List Module (`modules/ui_playerlist.lua`)**

**Responsibility**: Player roster display and interaction

```lua
-- Components:
├── Scroll Frame Management
├── Header Creation
├── Player Row Rendering
│   ├── Class coloring
│   ├── Penalty counters
│   └── Total calculations
└── Player Selection
    ├── SelectPlayer()
    └── DeselectPlayer()
```

**Design Patterns**:
- *Factory Pattern* for row creation
- *Template Method* for rendering

**Rendering Algorithm**:
```lua
1. Get current session data
2. Build player list array
3. Sort by total penalties
4. Create UI row for each player
5. Apply class colors and highlights
6. Update scroll frame height
```

---

### 5. **Actions Module (`modules/ui_actions.lua`)**

**Responsibility**: Penalty buttons and management actions

```lua
-- Button Categories:
├── Penalty Application Buttons
│   ├── Apply (+)
│   └── Remove (-)
├── Management Buttons
│   ├── Whisper Balance
│   ├── Post Stats
│   ├── Sync Data
│   ├── Reset Player
│   └── Settings
```

**Design Pattern**: *Command Pattern*

**Button State Management**:
- Authorization checking
- Selection validation
- Enable/disable logic

---

### 6. **Live Sync Module (`modules/ui_sync.lua`)**

**Responsibility**: Real-time data synchronization

```lua
-- Architecture:
┌──────────────┐         ┌──────────────┐
│     Host     │ ◄─────► │   Client 1   │
│  (Raid Lead) │         └──────────────┘
└──────────────┘         
       ▲                  ┌──────────────┐
       └─────────────────►│   Client 2   │
                          └──────────────┘
```

**Protocol**:
```lua
-- Message Types:
SYNC_START       - Host announces sync session
SYNC_UPDATE      - Real-time penalty update
SYNC_MULTI       - Chunked full sync
SYNC_JOIN        - Client joins session
```

**Design Patterns**:
- *Publish-Subscribe* for updates
- *Message Queue* for throttling

---

## 🔄 Data Flow

### Penalty Application Flow

```
User Action (Click Button)
         │
         ▼
UI:ApplyPenaltyToSelectedPlayer()
         │
         ▼
Logic:ApplyPenalty()
         │
         ├─► Create penalty record
         ├─► Update player total
         ├─► Update season data
         └─► Trigger UI refresh
         │
         ▼
UI:RefreshPlayerList()
         │
         ▼
Display Updated (Visual Feedback)
         │
         ▼
[If Live Sync Enabled]
         │
         ▼
SendLiveSyncUpdate()
         │
         ▼
Broadcast to Group
```

### Session Lifecycle

```
Player Enters World
         │
         ▼
OnPlayerEnteringWorld()
         │
         ▼
Check IsInRaid() || IsInGroup()
         │
         ├─► YES: UpdateRaidMembers()
         │         │
         │         ▼
         │    GetCurrentSession()
         │         │
         │         ├─► Exists: Use existing
         │         └─► None: CreateNewSession()
         │                   │
         │                   ▼
         │              Initialize session.players
         │                   │
         │                   ▼
         │              Detect group members
         │                   │
         │                   ▼
         │              Add to session.players
         │
         └─► NO: Do nothing
```

---

## 💾 Data Persistence

### Database Schema

#### `RaidSanctionsDB` (Global)
```lua
{
    version = "1.2",
    penalties = {
        ["Late"] = 10000,
        ["AFK"] = 10000,
        -- ... more penalties
    },
    settings = {
        showInCombat = false,
        autoHide = true,
        soundEnabled = true
    }
}
```

#### `RaidSanctionsCharDB` (Per-Character)
```lua
{
    sessions = {
        ["20241222_183045"] = {
            id = "20241222_183045",
            timestamp = 1703267445,
            players = {
                ["PlayerName"] = {
                    class = "WARRIOR",
                    level = 70,
                    penalties = {
                        {
                            reason = "Late",
                            amount = 10000,
                            timestamp = 1703267500,
                            uniqueId = "1703267500_1234"
                        }
                    },
                    total = 10000
                }
            }
        }
    },
    currentSession = "20241222_183045",
    seasonData = {
        ["PlayerName"] = {
            class = "WARRIOR",
            totalAmount = 50000,
            totalPenalties = 5,
            lastSeen = 1703267445,
            penalties = [...],
            processedSessionPenalties = {
                ["1703267500_1234"] = true
            }
        }
    }
}
```

### Schema Migration

```lua
function Logic:MigrateDatabase()
    -- Version checking
    if RaidSanctionsDB.version ~= ADDON_VERSION then
        -- Perform migrations
        - Update penalty names
        - Add new fields
        - Transform data structures
        
        -- Update version
        RaidSanctionsDB.version = ADDON_VERSION
    end
end
```

---

## 🎯 Design Principles Applied

### 1. **SOLID Principles**

#### Single Responsibility
- Each module has one well-defined purpose
- Logic module: Business rules only
- UI modules: Presentation only

#### Open/Closed
- Extensible through module system
- New penalty types without core changes
- Plugin architecture ready

#### Liskov Substitution
- UI modules can be swapped
- Compatible interface contracts

#### Interface Segregation
- Public API is minimal
- Internal functions are private

#### Dependency Inversion
- Modules depend on abstractions (namespaces)
- No direct coupling between modules

### 2. **DRY (Don't Repeat Yourself)**

```lua
-- Centralized formatting
Logic:FormatGold(amount)  -- Used throughout

-- Shared constants
UI.FRAME_WIDTH, UI.BUTTON_HEIGHT

-- Common patterns abstracted
UI:CreatePlayerRow()
```

### 3. **KISS (Keep It Simple, Stupid)**

- Clear function names
- Single-purpose functions
- Minimal complexity per function

### 4. **YAGNI (You Aren't Gonna Need It)**

- Features implemented only when needed
- No speculative generalization
- Pragmatic approach

---

## 🔐 Security Considerations

### Authorization System

```lua
function UI:IsPlayerAuthorized()
    -- Check raid rank
    local rank = UnitGroupRolesAssigned("player")
    
    -- Check guild officer status
    local guildRank = C_GuildInfo.GetGuildRankOrder()
    
    -- Authorization logic
    return isRaidLeader or isGuildOfficer
end
```

### Data Validation

```lua
-- All user input is validated
if not playerName or playerName:trim() == "" then
    return false
end

-- Amount validation
if type(amount) ~= "number" or amount < 0 then
    return false
end
```

---

## 🚀 Performance Optimizations

### 1. **Local Caching**

```lua
-- Cache frequently used functions
local format = string.format
local pairs, ipairs = pairs, ipairs
```

### 2. **Event Throttling**

```lua
-- Prevent message spam
if currentTime - lastSyncTimestamp < MESSAGE_THROTTLE then
    return
end
```

### 3. **Lazy Initialization**

```lua
-- Create UI only when needed
function UI:Show()
    if not self.mainFrame then
        self:Initialize()
    end
    self.mainFrame:Show()
end
```

### 4. **Efficient Rendering**

```lua
-- Recycle UI frames instead of creating new ones
for _, row in ipairs(playerRows) do
    row:Hide()  -- Reuse
end
```

---

## 🧪 Testing Strategy

### Debug Mode

```lua
local DEBUG_MODE = true

function Logic:Debug(message)
    if DEBUG_MODE then
        print("[RaidSanctions Debug]: " .. tostring(message))
    end
end
```

### Manual Testing Checklist

- [ ] Player detection (raid/party)
- [ ] Penalty application
- [ ] Penalty removal
- [ ] Session persistence
- [ ] Season statistics
- [ ] Live sync functionality
- [ ] UI responsiveness
- [ ] Authorization checks

---

## 📈 Scalability Considerations

### Horizontal Scaling
- Supports up to 40 raid members
- Chunked sync for large datasets
- Throttled network messages

### Vertical Scaling
- Efficient data structures
- Minimal memory footprint
- Optimized rendering

### Future-Proofing
- Modular architecture allows easy extension
- Version migration system in place
- Public API for integration

---

## 🔮 Future Enhancements

### Planned Features
- [ ] Web dashboard integration
- [ ] Export to CSV/JSON
- [ ] Advanced filtering and sorting
- [ ] Penalty templates
- [ ] Multi-language support
- [ ] Integration with popular raid tools

### Technical Debt
- [ ] Deprecate legacy UI module
- [ ] Unit test framework
- [ ] Automated integration tests
- [ ] Performance profiling

---

## 📚 Additional Resources

- [WoW API Documentation](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [Lua Programming Guide](https://www.lua.org/manual/5.1/)
- [Software Architecture Patterns](https://www.oreilly.com/library/view/software-architecture-patterns/9781491971437/)

---

**Built with ❤️ and professional software engineering practices**
