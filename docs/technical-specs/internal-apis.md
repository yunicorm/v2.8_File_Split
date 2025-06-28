# Internal APIs and Implicit Interfaces

This document details the undocumented internal APIs, hidden dependencies, and implicit interfaces within the Path of Exile automation macro codebase.

## Module Dependencies and Initialization Order

### Hidden Dependencies Through Global Variables

#### Flask System Dependencies
- **g_macro_active** - Master control flag from MacroController
- **g_flask_timer_active** - Flask automation state
- **KEY_MANA_FLASK** - Key binding constant
- **TIMING_FLASK** - Timing configuration object
- **ConfigManager** - Configuration management system
- **Logging functions**: LogInfo, LogError, LogDebug, LogWarn
- **Timer functions**: StartManagedTimer, StopManagedTimer
- **Performance functions**: StartPerfTimer, EndPerfTimer

#### Skills System Dependencies
- **g_macro_active** - Master control flag
- **g_macro_start_time** - Used for Wine stage timing calculations
- **KEY_SKILL_E, KEY_SKILL_R, KEY_SKILL_T, KEY_WINE_PROPHET** - Key constants
- **TIMING_SKILL_ER, TIMING_SKILL_T** - Timing constants
- **ConfigManager** - Configuration management system
- **Logging and timer functions** (same as Flask system)

#### Core AutoHotkey Dependencies
- **Send()** - Game input function
- **Map()** - Data structure constructor
- **Random()** - Interval randomization
- **SetTimer()** - Windows timer management
- **A_TickCount** - System timing
- **Format()** - String formatting

### Critical Initialization Order

```
Utils (foundational) → UI → Config → Core → Features → Hotkeys (final)
```

#### Flask Module Initialization Sequence
1. **FlaskConfiguration.ahk** - Must run first (defines g_flask_configs)
2. **FlaskChargeManager.ahk** - Depends on g_flask_configs
3. **FlaskConditions.ahk** - Independent, registers helper functions
4. **FlaskController.ahk** - Depends on all previous modules
5. **FlaskStatistics.ahk** - Can run after configuration

#### Skills Module Initialization Sequence
1. **SkillConfigurator.ahk** - Must run first (defines g_skill_configs)
2. **SkillStatistics.ahk** - Should run after configurator
3. **WineManager.ahk** - Depends on configurator and g_macro_start_time
4. **SkillController.ahk** - Depends on all previous modules
5. **SkillHelpers.ahk** - Independent utility functions

## Private Helper Functions and Side Effects

### Global State Modifying Functions

#### ColorDetection.ahk Cache Management
- **CleanupPixelCache()** - Removes expired cache entries
  - **Side Effect**: Modifies g_pixel_cache global
  - **Usage**: Called by SafePixelGetColor() when cache > 1000 entries
  - **Purpose**: Memory management

- **ResetColorDetectionCache()** - Clears all caches and statistics
  - **Side Effects**: Resets g_pixel_cache, g_cache_hit_count, g_cache_miss_count, g_slow_detection_count
  - **Usage**: Debug functions, macro reset operations

#### Logger.ahk Buffer Management
- **RemoveLowPriorityLogs()** - Drops DEBUG logs when buffer full
  - **Side Effects**: Modifies g_log_buffer, increments g_log_stats.droppedLogs
  - **Usage**: Called by WriteLog() when buffer exceeds limits
  - **Purpose**: Prevents memory overflow

- **FlushLogBuffer()** - Writes buffered logs to disk
  - **Side Effects**: File I/O, clears g_log_buffer, updates g_log_write_count
  - **Usage**: Timer callback (1 second), error logs, shutdown
  - **Purpose**: Batched I/O for performance

- **ReopenLogFile()** - Re-establishes file handle after errors
  - **Side Effects**: Closes/opens file handles, resets error counters
  - **Usage**: Called after 5 consecutive write errors
  - **Purpose**: Self-healing for file system issues

#### TimerManager.ahk Internal Functions
- **CreateTimerWrapper(timerName, callback)** - Creates error-handling wrapper
  - **Returns**: Closure that calls ExecuteTimerCallback()
  - **Usage**: Internal to StartManagedTimer()
  - **Purpose**: Adds error handling and performance monitoring

- **ExecuteTimerCallback(timerName, callback)** - Core timer execution
  - **Side Effects**: Updates multiple global tracking variables
  - **Features**: Prevents concurrent execution, tracks errors/performance
  - **Auto-stop**: Timers with >10 errors

#### ManaMonitor.ahk State Functions
- **CheckManaQuick()** - Fast 3-point mana check
  - **Usage**: Internal to CheckManaRadialOptimized() for performance mode
  - **Returns**: Boolean mana state
  - **Purpose**: Performance optimization

- **RestorePerformanceMode()** - Re-enables performance optimizations
  - **Side Effect**: Sets g_performance_mode based on config
  - **Usage**: Called 5 seconds after mana depletion events
  - **Purpose**: Balance accuracy vs performance

- **AdjustMonitoringInterval(newInterval)** - Dynamic frequency changes
  - **Side Effects**: Stops and restarts mana monitoring timer
  - **Usage**: When errors accumulate to reduce load

## Callback Conventions and Naming Rules

### Timer Callback Patterns

#### Anonymous Arrow Functions (Most Common)
```ahk
SetTimer(() => RemoveOverlay(), -duration)
SetTimer(() => RetryFlaskStart(flaskName, config), -1000)
SetTimer(() => DestroyGui(customGui), -options.duration)
```

#### Named Function References
```ahk
SetTimer(TryAutoStart, -autoStartDelay)
SetTimer(MonitorPerformance, 10000)
```

#### Wrapped Callbacks via Factory
```ahk
wrappedCallback := CreateTimerWrapper(timerName, callback)
SetTimer(wrappedCallback, period)
```

### Error Handler Conventions

#### Global Error Handler Pattern
```ahk
OnError(GlobalErrorHandler)

GlobalErrorHandler(exception, mode) {
    return true  ; Continue execution
    return false ; Stop/terminate
    ; No return = Default behavior
}
```

#### GUI Event Registration
```ahk
button.OnEvent("Click", SaveSettings)
tab.OnEvent("Change", Tab_Change)
gui.OnEvent("Close", SettingsWindow_Close)
gui.OnEvent("Size", SettingsWindow_Resize)
```

### Naming Conventions

#### Timer Names
- **Format**: "Category_Identifier"
- **Examples**: "Flask_" . flaskName, "Skill_" . skill

#### Callback Functions
- **Action-based**: ExecuteSkill(), UseFlask(), UpdateStats()
- **Event-based**: FlaskTimerCallback(), SkillTimerCallback()
- **Handler suffix**: ExitHandler(), GlobalErrorHandler()

#### Event Handlers
- **OnXXX pattern**: OnExit(), OnError(), gui.OnEvent()
- **HandleXXX pattern**: Less common, OnXXX preferred

## Data Exchange Protocols

### Global Collections for Inter-Module Communication

#### Flask System Data Exchange
```ahk
global g_flask_configs := Map()         ; Configuration data
global g_flask_charge_tracker := Map()  ; Charge state data
global g_flask_use_count := Map()       ; Usage statistics
global g_flask_timer_handles := Map()   ; Timer references
global g_flask_active_flasks := Map()   ; Active flask tracking
```

#### Skill System Data Exchange
```ahk
global g_skill_configs := Map()         ; Skill configurations
global g_skill_timers := Map()          ; Timer handles
global g_skill_stats := Map()           ; Performance statistics
global g_skill_enabled := Map()         ; Enable/disable states
```

#### Timer Management Data Exchange
```ahk
global g_active_timers := Map()         ; Timer registry
global g_timer_performance := Map()     ; Performance metrics
global g_timer_priorities := Map()      ; Priority assignments
global g_timer_executing := Map()       ; Execution guards
```

### Configuration Data Flow

#### Centralized Pattern
1. **Main.ahk** loads configuration via ConfigManager.Load()
2. **Individual modules** query configuration on demand
3. **Hot-reload capability** via ConfigManager.Reload()

#### Configuration Query Pattern
```ahk
ConfigManager.Get(section, key, defaultValue)
ConfigManager.Set(section, key, value)
```

### Return Value Conventions

#### Boolean Success Pattern
```ahk
try {
    // Implementation
    return true
} catch Error as e {
    LogError("Module", "Failed: " . e.Message)
    return false
}
```

#### Structured Data Returns
```ahk
GetDetailedStats(name) {
    return {
        name: name,
        efficiency: efficiency,
        uses: uses,
        usesPerMinute: Round(uses / (uptime / 60000), 2)
    }
}
```

### Statistics and Metrics Sharing

#### Hierarchical Statistics Architecture
- **Module-Level**: Individual usage counts and timing data
- **Cross-Module**: Aggregation functions collect from multiple sources
- **Performance**: Timer manager collects metrics across all timers

#### Status Display Integration
```ahk
ComputeStatusHash() {
    stateString := Format("{}-{}-{}-{}", 
        g_macro_active ? "ON" : "OFF",     ; MacroController
        g_mana_fill_rate,                  ; ManaMonitor
        tinctureStatus.status,             ; TinctureManager
        g_flask_timer_active ? "ON" : "OFF") ; FlaskManager
}
```

## Extension Points and Hook Functions

### Configuration-Driven Extension System

#### Primary Extension Point: ConfigManager
```ahk
; Add new configuration sections
this.validationRules["YourModule"] := Map(
    "EnabledFeatures", {type: "string"},
    "Timeout", {min: 100, max: 10000, type: "integer"}
)
```

### Timer Management Hook System
```ahk
; Register custom automation with priority
StartManagedTimer("CustomFeature", () => MyCustomFunction(), 
                  1000, TimerPriority.NORMAL)
```

### Modular Feature Registration
```ahk
; Add to Main.ahk include chain
#Include "Features\YourNewFeature.ahk"
```

### Flask Condition System (Highly Extensible)
```ahk
; Register custom conditions
RegisterConditionFunction("customCondition", () => MyCustomCheck())

; TODO implementations ready for extension:
; - GetHealthPercentage(), IsMoving(), GetManaPercentage()
; - IsInCombat(), and 8 more status detection functions
```

### Skill System Factory Pattern
```ahk
; Define custom skill configurations
skillConfig := Map(
    "CustomSkill_1", {
        name: "Custom Ability", 
        key: "F", 
        minInterval: 2000, 
        maxInterval: 3000, 
        enabled: true, 
        priority: 2
    }
)
ConfigureSkills(skillConfig)
```

### UI Extension System
```ahk
; Add new tabs to settings window
g_settings_tab := g_settings_gui.Add("Tab3", "x15 y15 w770 h520", 
    ["フラスコ", "スキル", "一般", "YourNewTab"])

; Create corresponding tab content function
CreateYourNewTab()
```

### Performance Monitoring Extension
```ahk
; Hook into performance monitoring system
CollectMetrics() ; Add custom metrics collection
```

## Internal Communication Patterns

### Between Flask Modules
- **FlaskController** → **FlaskChargeManager**: Calls UpdateFlaskCharges() via timer
- **FlaskController** → **FlaskConfiguration**: Reads g_flask_configs for settings
- **FlaskController** → **FlaskStatistics**: Updates g_flask_use_count, g_flask_stats
- **FlaskConfiguration** → **FlaskChargeManager**: Calls InitializeChargeTracker()
- **FlaskConfiguration** → **FlaskConditions**: References condition functions

### Between Skills Modules
- **SkillController** → **SkillConfigurator**: Reads g_skill_configs for settings
- **SkillController** → **WineManager**: Calls InitializeWineSystem(), ExecuteWineOfProphet()
- **SkillController** → **SkillStatistics**: Calls UpdateSkillStats()
- **WineManager** → **SkillController**: Calls ScheduleNextSkillExecution()
- **All modules** → **SkillHelpers**: Utility functions like Array2String()

## Implicit Preconditions

### Flask Modules Expect
- g_flask_timer_active to be false initially
- g_macro_active to be set by MacroController
- Timer management functions available from TimerManager
- Configuration values loaded from Config.ini
- Logging system initialized

### Skills Modules Expect
- g_macro_start_time to be set when macro starts
- g_macro_active to be set by MacroController
- Timer management functions available
- Configuration values loaded
- Wine stages configuration in Config.ini

## Error Handling and Recovery

### Try-Catch Pattern
```ahk
ExecuteTimerCallback(timerName, callback) {
    try {
        callback()
    } catch Error as e {
        g_timer_errors[timerName]++
        LogError("TimerManager", Format("Error in timer '{}': {}", 
            timerName, e.Message))
        
        ; Auto-stop after too many errors
        if (g_timer_errors[timerName] > 10) {
            StopManagedTimer(timerName)
        }
    } finally {
        g_timer_executing[timerName] := false
    }
}
```

### State Management Guards
```ahk
if (g_timer_executing[timerName]) {
    LogWarn("Timer already executing, skipping")
    return
}
g_timer_executing[timerName] := true
```

## Performance Considerations

### Execution Time Tracking
```ahk
startTime := A_TickCount
callback()
executionTime := A_TickCount - startTime
UpdateTimerPerformance(timerName, executionTime)
```

### Priority-Based Execution
```ahk
class TimerPriority {
    static CRITICAL := 1    ; Mana monitoring
    static HIGH := 2        ; Tincture management
    static NORMAL := 3      ; Skill execution
    static LOW := 4         ; UI updates
}
```

## Recommended Development Patterns

### For New Features
1. Follow modular include pattern in appropriate dependency layer
2. Use ConfigManager for all settings (no hard-coding)
3. Implement comprehensive error handling
4. Add to appropriate global Maps for state sharing
5. Use managed timer system with appropriate priority

### For Extending Existing Systems
1. Use RegisterConditionFunction() for flask conditions
2. Add new tabs to settings window system
3. Use timer hook system for automation
4. Add configuration sections with validation rules
5. Follow established naming conventions

This internal API documentation provides the foundation for extending and maintaining the Path of Exile automation macro while preserving its architectural integrity and performance characteristics.