# Contributing to RaidSanctions

First off, thank you for considering contributing to RaidSanctions! It's people like you that make this addon better for everyone.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Bug Reports](#bug-reports)
- [Feature Requests](#feature-requests)

---

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in all interactions.

### Expected Behavior

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment or discrimination of any kind
- Trolling or insulting/derogatory comments
- Public or private harassment
- Publishing others' private information

---

## 🤝 How Can I Contribute?

### Reporting Bugs

Found a bug? Please help us fix it!

1. **Check existing issues** - Someone might have already reported it
2. **Create a detailed bug report** - Use the bug report template
3. **Provide reproduction steps** - Help us reproduce the issue
4. **Include context** - WoW version, addon version, other addons

### Suggesting Features

Have an idea for a new feature?

1. **Check existing feature requests** - Avoid duplicates
2. **Describe the feature clearly** - What problem does it solve?
3. **Provide use cases** - How would you use it?
4. **Consider implementation** - Think about how it could work

### Improving Documentation

Documentation improvements are always welcome!

- Fix typos or clarify explanations
- Add examples or use cases
- Improve architecture documentation
- Create tutorials or guides

### Writing Code

Ready to contribute code? Awesome!

1. **Check open issues** - Find something to work on
2. **Comment on the issue** - Let others know you're working on it
3. **Follow coding standards** - See below
4. **Write tests** - If applicable
5. **Submit a pull request** - Follow the PR guidelines

---

## 💻 Development Setup

### Prerequisites

```bash
# Required
- World of Warcraft (Retail)
- Git
- Text editor (VS Code recommended)

# Optional
- Lua Language Server extension
- WoW API reference
```

### Setting Up Your Environment

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/RaidSanctions.git
cd RaidSanctions

# 3. Add upstream remote
git remote add upstream https://github.com/Dravock/RaidSanctions.git

# 4. Create symlink to WoW AddOns folder
# Windows (PowerShell as Admin):
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\World of Warcraft\_retail_\Interface\AddOns\RaidSanctions" -Target "$(Get-Location)"

# macOS/Linux:
ln -s "$(pwd)" "~/Applications/World of Warcraft/_retail_/Interface/AddOns/RaidSanctions"

# 5. Create a feature branch
git checkout -b feature/my-awesome-feature
```

### Testing Your Changes

```bash
# 1. Start World of Warcraft
# 2. Enable Developer mode: /console scriptErrors 1
# 3. Test your changes in-game
# 4. Check for Lua errors
# 5. Use /rs debug for debugging
```

---

## 📝 Coding Standards

### File Organization

```lua
--[[
    Module Name - Brief Description
    
    Detailed description of what this module does,
    its responsibilities, and any important notes.
    
    @author Your Name
    @version 1.x
    @since 2024
]]

local addonName, addonTable = ...

-- ============================================================================
-- NAMESPACE INITIALIZATION
-- ============================================================================

-- ============================================================================
-- LOCAL REFERENCES
-- ============================================================================

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================

-- ============================================================================
-- MAIN FUNCTIONS
-- ============================================================================

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================
```

### Naming Conventions

```lua
-- Constants: UPPERCASE_WITH_UNDERSCORES
local MAX_PLAYERS = 40
local DEFAULT_PENALTY = 10000

-- Functions: PascalCase for public, camelCase for private
function Module:PublicFunction()
    local privateHelper()
end

-- Variables: camelCase
local playerName = "Example"
local totalAmount = 0

-- Module namespace: PascalCase
RaidSanctions.Logic
RaidSanctions.UI
```

### Documentation Standards

```lua
--[[
    Brief one-line description of the function
    
    Detailed explanation of what the function does, when to use it,
    and any important implementation details or gotchas.
    
    @param paramName type Description of the parameter
    @param optionalParam type? Optional parameter description
    @return returnType Description of return value
    @throws errorType When this error might occur
    
    @example
    local result = Module:FunctionName("example", 42)
    
    @see RelatedFunction
    @since 1.2.0
]]
function Module:FunctionName(paramName, optionalParam)
    -- Implementation
end
```

### Code Style

```lua
-- Indentation: 4 spaces (no tabs)
function Example()
    if condition then
        doSomething()
    end
end

-- Line length: Max 100 characters (soft limit)
local longString = "This is a long string that should be broken up " ..
                   "into multiple lines for readability"

-- Spacing
local a = 1 + 2  -- Spaces around operators
local b = {1, 2, 3}  -- Spaces after commas

-- Brackets
if condition then
    -- Code
end

-- Function calls
someFunction(param1, param2)

-- Table definitions
local myTable = {
    key1 = value1,
    key2 = value2
}
```

### Error Handling

```lua
-- Validate input
function Module:ProcessData(data)
    -- Check for nil
    if not data then
        return false, "Data cannot be nil"
    end
    
    -- Type checking
    if type(data) ~= "table" then
        return false, "Data must be a table"
    end
    
    -- Proceed with processing
    return true, processedData
end

-- Use pcall for risky operations
local success, result = pcall(function()
    return riskyOperation()
end)

if not success then
    print("Error: " .. tostring(result))
    return
end
```

---

## 📊 Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```bash
# Feature
git commit -m "feat(ui): add season statistics window

Implements a new window displaying cumulative season statistics
with filtering by guild members vs random players.

Closes #42"

# Bug fix
git commit -m "fix(logic): prevent duplicate penalty processing

Adds uniqueId tracking to prevent the same penalty from being
processed multiple times during season data updates.

Fixes #38"

# Documentation
git commit -m "docs(readme): update installation instructions

Clarifies manual installation steps for Windows users."
```

---

## 🔄 Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] All functions are documented
- [ ] Changes are tested in-game
- [ ] No Lua errors in error log
- [ ] Commit messages follow guidelines
- [ ] Branch is up-to-date with main

### PR Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How has this been tested?
- [ ] Tested in solo play
- [ ] Tested in 5-man group
- [ ] Tested in raid
- [ ] Tested with other addons

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed the code
- [ ] Commented complex code sections
- [ ] Updated documentation
- [ ] No new warnings or errors

## Screenshots (if applicable)
Add screenshots of UI changes.

## Related Issues
Closes #issue_number
```

### Review Process

1. **Automated checks** - Code style, basic validation
2. **Maintainer review** - Code quality, architecture fit
3. **Testing** - In-game functionality testing
4. **Approval** - Merge when all checks pass

### After Merge

- Your contribution will be included in the next release
- You'll be added to the contributors list
- Thank you for making RaidSanctions better! 🎉

---

## 🐛 Bug Reports

### Before Reporting

1. **Update to latest version** - Bug might be fixed
2. **Check existing issues** - Avoid duplicates
3. **Disable other addons** - Isolate the problem
4. **Clear cache** - Delete Cache and WTF folders

### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - WoW Version: [e.g. 11.0.7]
 - Addon Version: [e.g. 1.2]
 - Other Addons: [list relevant addons]

**Error Message**
```lua
-- Paste any Lua errors here
```

**Additional context**
Any other context about the problem.
```

---

## 💡 Feature Requests

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Other solutions you've thought about.

**Additional context**
Any other context, screenshots, or examples.

**Would you be willing to implement this?**
- [ ] Yes, I can work on this
- [ ] No, but I can help test
- [ ] No, just suggesting
```

---

## 🎓 Learning Resources

### WoW AddOn Development

- [WoWpedia API](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [WoW Programming](https://wowprogramming.com/)
- [Lua Users Wiki](http://lua-users.org/wiki/)

### Software Engineering

- [Clean Code by Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Design Patterns](https://refactoring.guru/design-patterns)
- [Git Best Practices](https://git-scm.com/book/en/v2)

---

## 📞 Getting Help

### Community

- **GitHub Issues** - For bugs and features
- **GitHub Discussions** - For questions and ideas
- **Discord** - Real-time chat (link in README)

### Maintainers

- **@Dravock** - Project lead

---

## 🙏 Recognition

Contributors will be:
- Listed in the CONTRIBUTORS.md file
- Credited in release notes
- Thanked in the addon credits

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to RaidSanctions!** 🎉
