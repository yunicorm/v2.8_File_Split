# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a sophisticated **Path of Exile automation macro** written in **AutoHotkey v2** (v2.9.2), specifically designed for the "Wine of the Prophet" build. The codebase features robust error handling, modular architecture, and comprehensive game automation capabilities.

## Development Commands

### Execution
```bash
# Run the macro (requires AutoHotkey v2.0+)
# Double-click Main.ahk or run via AutoHotkey
Main.ahk
```

### Configuration Management
- **Settings GUI**: `Ctrl+Shift+S` (opens graphical settings window)
- **Hot reload config**: `Alt+F12` (reloads Config.ini without restart)
- **Settings file**: `Config.ini` (auto-generated on first run)
- **Reset macro state**: `Ctrl+R`

### Debugging Commands
- **Debug mana detection**: `F11`
- **Timer debug info**: `F8` (shows priority, execution times)
- **Full debug display**: `F7` (comprehensive system status)
- **View logs**: `F6` (opens log viewer)
- **Test performance**: `Ctrl+P`

### No Build/Test System
- This is a direct-execution AutoHotkey script
- No compilation or build process required
- Testing done through built-in debug modes and live monitoring

## Architecture Overview

### Module Structure
```
Utils (foundational) → UI → Config → Core → Features → Hotkeys (final)
```

**Critical Dependency Order**: The include sequence in `Main.ahk` must be preserved - each layer depends on the previous ones.

### Key Directories

**Core/** - Central control systems
- `MacroController.ahk`: State management and initial actions
- `TimerManager.ahk`: Priority-based timer system with performance monitoring
- `WindowManager.ahk`: Window detection and target application management

**Features/** - Domain-specific automation modules
- `ManaMonitor.ahk`: Circular mana orb sampling with optimization modes
- `TinctureManager.ahk`: Complex cooldown/retry logic with usage statistics
- `FlaskManager.ahk`: Configurable flask automation
- `SkillAutomation.ahk`: Dynamic skill timing management
- `ClientLogMonitor.ahk`: Log file parsing for area transitions

**Utils/** - Foundational services
- `ConfigManager.ahk`: INI management with validation and hot-reloading
- `Logger.ahk`: Comprehensive logging with rotation and buffering
- `ColorDetection.ahk`: Optimized pixel color detection
- `HotkeyValidator.ahk`: Conflict detection and registration

**UI/** - User interface components
- `Overlay.ahk`: Temporary message displays
- `StatusDisplay.ahk`: Persistent status information
- `DebugDisplay.ahk`: Development interfaces
- `SettingsWindow.ahk`: Graphical settings configuration interface

## Configuration System

### Primary Config File: `Config.ini`
- **Auto-generated** on first run with sensible defaults
- **Validation rules** enforce valid ranges and types
- **Resolution scaling** automatically adjusts coordinates for different screen sizes
- **Profile support** with backup/restore capabilities

### Key Configuration Sections
```ini
[General]    - Debug, logging, auto-start settings
[Mana]       - Mana orb detection parameters (coordinates, thresholds)
[Timing]     - Skill and flask intervals
[Keys]       - Key mappings for all game actions
[Wine]       - Dynamic timing stages for Wine of the Prophet
[ClientLog]  - Log monitoring for area detection
```

### Resolution Independence
- **Base resolution**: 3440x1440 (ultrawide)
- **Auto-scaling**: Coordinates automatically scale for other resolutions
- **Manual override**: Adjust coordinates in `[Mana]` section if needed

### Settings GUI Interface
- **Access**: Press `Ctrl+Shift+S` to open the graphical settings window
- **Window size**: 800x600 pixels with resizable interface
- **Tab organization**: Three main tabs for different setting categories
  - **フラスコ (Flask)**: Flask timing, keys, and Tincture configuration
  - **スキル (Skill)**: ER/T skill timing and Wine of the Prophet settings
  - **一般 (General)**: Debug, logging, auto-start, and mana detection settings
- **Save/Cancel/Reset**: Standard dialog buttons with confirmation for destructive operations
- **Real-time validation**: Settings are validated before saving
- **Hot-reload integration**: Changes are immediately available after saving

## Development Patterns

### Error Handling
- **Comprehensive try-catch blocks** throughout all modules
- **Global error handler** with graceful degradation
- **Automatic recovery** mechanisms for non-critical failures
- **Error statistics** tracking per component

### Timer Management
- **Priority system**: Critical > High > Normal > Low
- **Performance monitoring**: Execution time tracking and warnings
- **Concurrent execution prevention**: Timers cannot overlap
- **Graceful shutdown**: Dependency-aware cleanup order

### Configuration-Driven Design
- **Minimize hard-coded values** - use `ConfigManager.Get()` instead
- **Validation at load time** prevents runtime errors
- **Hot-reloading support** for rapid development iteration

### Logging Best Practices
```ahk
LogInfo("ModuleName", "Operation completed successfully")
LogError("ModuleName", "Error message with context")
LogDebug("ModuleName", "Detailed diagnostic information")
```

## Working with This Codebase

### Adding New Features
1. **Create module** in appropriate directory (usually `Features/`)
2. **Add include** to `Main.ahk` in dependency order
3. **Use ConfigManager** for all settings rather than hard-coding
4. **Implement error handling** following existing patterns
5. **Add configuration section** to Config.ini if needed
6. **Register hotkeys** through `HotkeyValidator` if required

### Common Operations
- **Get config value**: `ConfigManager.Get("Section", "Key", defaultValue)`
- **Create timer**: Use `TimerManager` with appropriate priority
- **Add logging**: Use appropriate log level (Debug/Info/Warn/Error)
- **Display message**: `ShowOverlay("message", duration)`
- **Check game window**: `IsTargetWindowActive()`

### Target Game Setup Requirements
- **Game**: Path of Exile (PathOfExileSteam.exe) or Steam Remote Play
- **Resolution**: Optimized for 3440x1440, configurable for others
- **Game settings**: "Always Show Mana Cost" must be OFF
- **UI scaling**: Designed for 100% UI scale

### Performance Considerations
- **Mana monitoring**: 100ms intervals with optimization modes
- **Log monitoring**: 250ms intervals for file changes
- **Color detection**: 50ms timeout (configurable)
- **Timer priorities**: Use appropriately to avoid performance issues

## Important Notes

### Target Application
- Designed specifically for **Path of Exile automation**
- **Game-specific coordinates and timing** optimized for "Wine of the Prophet" build
- **Client.txt log parsing** for reliable area detection

### AutoHotkey Version
- **Requires AutoHotkey v2.0+** (not compatible with v1.x)
- **Modern syntax** and error handling patterns
- **Single instance enforcement** prevents multiple runs

### Debugging Workflow
1. **Enable debug mode**: Set `DebugMode=true` in Config.ini
2. **Monitor logs**: Use F6 to view real-time log output
3. **Check system status**: F7 for comprehensive debug info
4. **Performance analysis**: F8 for timer statistics, Ctrl+P for performance tests
5. **Configuration issues**: Alt+F12 to reload settings after changes