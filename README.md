# 🎮 RaidSanctions - World of Warcraft Addon

[![WoW Version](https://img.shields.io/badge/WoW-11.0.7-blue.svg)](https://worldofwarcraft.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Code Quality](https://img.shields.io/badge/code%20quality-A-brightgreen.svg)](https://github.com/Dravock/RaidSanctions)

A professional, enterprise-grade World of Warcraft addon for managing raid penalties and sanctions. Built with modern software engineering practices, featuring real-time synchronization, modular architecture, and comprehensive data persistence.

---

## 🌟 Key Features

### 💼 Professional Architecture
- **Modular Design**: Clean separation of concerns with dedicated modules for logic, UI, sync, and actions
- **Event-Driven**: Efficient event-based architecture for real-time updates
- **Data Persistence**: Robust SavedVariables system with automatic migration
- **Error Handling**: Comprehensive validation and fallback mechanisms

### ⚡ Real-Time Synchronization
- **Live Sync**: Multi-user penalty tracking across raid members
- **Conflict Resolution**: Automatic handling of concurrent updates
- **Network Optimization**: Throttled messaging with chunk-based transmission
- **Host/Client Architecture**: Scalable synchronization model

### 📊 Advanced Statistics
- **Session Tracking**: Isolated penalty tracking per raid session
- **Season Analytics**: Cumulative statistics across multiple raids
- **Guild Integration**: Automatic categorization of guild vs. random players
- **Historical Data**: Complete penalty history with timestamps

### 🎨 Modern UI/UX
- **Responsive Design**: Adaptive layouts with smooth scrolling
- **Class Coloring**: Automatic class-based color coding
- **Tooltips**: Contextual help on all interactive elements
- **Keyboard Support**: Full ESC key handling and shortcuts

---

## 📋 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Usage Guide](#-usage-guide)
- [API Documentation](#-api-documentation)
- [Configuration](#-configuration)
- [Development](#-development)
- [Contributing](#-contributing)

---

## 🚀 Installation

### Via CurseForge Client (Recommended)
1. Open CurseForge or WoWUp client
2. Search for "RaidSanctions"
3. Click Install
4. Restart World of Warcraft

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/Dravock/RaidSanctions.git

# Copy to WoW AddOns folder
cp -r RaidSanctions "World of Warcraft/_retail_/Interface/AddOns/"
```

### Verify Installation
1. Launch World of Warcraft
2. Open AddOns menu (Character Select screen)
3. Ensure "RaidSanctions" is enabled
4. Type `/rs` in-game to open the addon

---

## ⚡ Quick Start

```lua
-- Open the main UI
/rs
/rs show

-- View debug information
/rs debug

-- Reset current session
/rs reset

-- Show help
/rs help
```

### First-Time Setup
1. Join a raid or party group
2. Type `/rs` to open the main window
3. Players will be automatically detected
4. Click a player to select them
5. Click penalty buttons to apply sanctions
6. Use management buttons for advanced features

---

## 🏗️ Architecture

### Project Structure
```
RaidSanctions/
├── RaidSanctions.lua           # Main entry point & event dispatcher
├── RaidSanctions.toc           # Addon manifest
├── logic.lua                   # Core business logic
├── modules/
│   ├── ui_core.lua            # UI framework & window management
│   ├── ui_playerlist.lua      # Player list rendering & interaction
│   ├── ui_actions.lua         # Action panel & penalty buttons
│   └── ui_sync.lua            # Real-time synchronization system
├── ui.lua                      # Legacy UI (deprecated, backward compat)
└── README.md                   # This file
```

### Design Patterns

#### **Modular Architecture**
- Each module has a single, well-defined responsibility
- Loose coupling through namespace-based communication
- High cohesion within modules

#### **Event-Driven Design**
```lua
-- Central event dispatcher
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", OnEvent)

-- Route to appropriate handler
function OnEvent(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        RaidSanctions.Logic:OnGroupRosterUpdate()
    end
end
```

#### **Data Layer Separation**
- **RaidSanctionsDB**: Global settings (penalties, preferences)
- **RaidSanctionsCharDB**: Character-specific data (sessions, seasons)
- Automatic schema migration on version changes

---

## 📖 Usage Guide

### Penalty Management

#### Apply Penalty
1. Select player from the list (click their row)
2. Click the desired penalty button in the bottom panel
3. Penalty is instantly applied and synced (if enabled)

#### Remove Penalty
1. Select player
2. Click the `-` button next to the penalty type
3. Most recent penalty of that type is removed

#### Reset Player
```lua
-- Mark player as "paid" and clear their penalties
1. Select player
2. Click "Reset Player"
3. Confirm the action
```

### Synchronization

#### Start Live Sync (as Host)
```lua
1. Ensure you're in a raid/party
2. Open RaidSanctions (/rs)
3. Click "Live Sync" button
4. Other members will automatically join
```

#### Join Existing Sync
- Automatic when another player starts sync
- No manual action required
- UI shows sync status

### Statistics & Reporting

#### View Session Statistics
- Main window shows current session
- Counters per penalty category
- Total amount per player

#### Season Statistics
```lua
/rs               # Open main window
Click "Season Stats"  # Opens season window
View cumulative data across all raids
```

#### Post to Raid Chat
```lua
Click "Post Stats"    # Sends summary to raid/party chat
```

### Advanced Features

#### Whisper Balance
```lua
1. Select player
2. Click "Whisper Balance"
3. Player receives private message with their total
```

#### Mail Penalties (Guild Officers)
```lua
-- Requires guild officer rank
1. Click "Send Mails"
2. Review guild players with penalties
3. Confirm to send in-game mail reminders
```

---

## 🔧 API Documentation

### Public API for Third-Party Addons

#### Apply Penalty
```lua
-- Apply a penalty to a player
-- @param playerName string Player name
-- @param reason string Penalty reason
-- @param amount number Amount in copper (10000 = 1g)
-- @return boolean Success status
RaidSanctions_ApplyPenalty("PlayerName", "Late", 10000)
```

#### Get Player Total
```lua
-- Get total penalty amount for a player
-- @param playerName string Player name
-- @return number Total in copper
local total = RaidSanctions_GetPlayerTotal("PlayerName")
print("Total: " .. total .. " copper")
```

### Internal Module API

#### Logic Module
```lua
-- Initialize database
RaidSanctions.Logic:InitializeDatabase()

-- Create new session
local session = RaidSanctions.Logic:CreateNewSession()

-- Apply penalty
local success = RaidSanctions.Logic:ApplyPenalty(playerName, reason, amount)

-- Get season data
local seasonData = RaidSanctions.Logic:GetSeasonData()

-- Format gold amount
local formatted = RaidSanctions.Logic:FormatGold(10000) -- "1 Gold"
```

#### UI Module
```lua
-- Toggle main window
RaidSanctions.UI:Toggle()

-- Refresh player list
RaidSanctions.UI:RefreshPlayerList()

-- Get selected player
local player = RaidSanctions.UI:GetSelectedPlayer()

-- Start live sync
RaidSanctions.UI:StartLiveSyncAsHost()
```

---

## ⚙️ Configuration

### Penalty Customization

Edit penalties in the addon settings or modify `logic.lua`:

```lua
local DEFAULT_PENALTIES = {
    ["Late"] = 10000,          -- 1 gold
    ["AFK"] = 10000,           -- 1 gold
    ["Wrong Gear"] = 10000,    -- 1 gold
    ["Wrong Tactic"] = 10000,  -- 1 gold
    ["Disruption"] = 10000     -- 1 gold
}
```

### Addon Settings
```lua
RaidSanctionsDB.settings = {
    showInCombat = false,    -- Show UI during combat
    autoHide = true,         -- Auto-hide when leaving group
    soundEnabled = true      -- Play sound effects
}
```

---

## 💻 Development

### Prerequisites
- World of Warcraft Client (Retail)
- Text editor (VS Code recommended)
- Git
- Basic Lua knowledge

### Setup Development Environment

```bash
# Clone repository
git clone https://github.com/Dravock/RaidSanctions.git
cd RaidSanctions

# Create symlink to WoW AddOns folder
# Windows (PowerShell as Administrator):
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\World of Warcraft\_retail_\Interface\AddOns\RaidSanctions" -Target "$(Get-Location)"

# macOS/Linux:
ln -s "$(pwd)" "~/Applications/World of Warcraft/_retail_/Interface/AddOns/RaidSanctions"
```

### Code Style Guidelines

#### Commenting Standards
```lua
--[[
    Function description
    
    Detailed explanation of what the function does,
    its purpose, and any important implementation details.
    
    @param paramName type Description of parameter
    @return type Description of return value
]]
function ModuleName:FunctionName(paramName)
    -- Implementation
end
```

#### Module Structure
```lua
-- ============================================================================
-- SECTION NAME
-- ============================================================================

-- Brief section description

-- Code here...
```

### Testing

```lua
-- Enable debug mode in logic.lua
local DEBUG_MODE = true

-- Use debug command
/rs debug

-- Check console for debug output
```

### Building for Release

```bash
# Ensure version is updated in:
# - RaidSanctions.toc (## Version:)
# - logic.lua (ADDON_VERSION)
# - README.md (Badges)

# Create release package
zip -r RaidSanctions-v1.2.zip RaidSanctions/ -x "*.git*" "*.vscode*"
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Standards

- Follow existing code style and conventions
- Add comprehensive comments for new functions
- Update documentation for API changes
- Test thoroughly before submitting

### Bug Reports

Use GitHub Issues with:
- Clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- WoW version and addon version
- Relevant error messages

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Drodar

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

---

## 👤 Author

**Drodar**
- GitHub: [@Dravock](https://github.com/Dravock)
- Specializing in: Lua, WoW API, Software Architecture, Real-time Systems

---

## 🙏 Acknowledgments

- **Blizzard Entertainment** - For the comprehensive WoW API
- **WoW Community** - For feedback and testing
- **Contributors** - For improvements and bug fixes

---

## 📊 Technical Highlights for Recruiters

This project demonstrates:

✅ **Clean Code Principles**: SOLID principles, DRY, separation of concerns  
✅ **Modular Architecture**: Scalable, maintainable codebase  
✅ **Real-Time Systems**: Network synchronization, conflict resolution  
✅ **Data Persistence**: Database design, schema migration  
✅ **Event-Driven Design**: Asynchronous event handling  
✅ **API Design**: Public API for third-party integration  
✅ **Documentation**: Comprehensive inline and external documentation  
✅ **Version Control**: Git workflow, semantic versioning  
✅ **Testing & Debugging**: Debug modes, error handling  

---

<div align="center">

**⚡ Built with professional software engineering practices for optimal raid discipline! ⚡**

[Report Bug](https://github.com/Dravock/RaidSanctions/issues) · [Request Feature](https://github.com/Dravock/RaidSanctions/issues) · [Documentation](https://github.com/Dravock/RaidSanctions/wiki)

</div>
