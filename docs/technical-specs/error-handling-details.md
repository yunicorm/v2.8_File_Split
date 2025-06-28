# Error Handling Implementation Details

This document provides comprehensive details on the error handling patterns, recovery strategies, and fault tolerance mechanisms implemented in the Path of Exile automation macro.

## Error Classification and Handling Strategies

### Critical Errors (Immediate Termination Required)
- **Memory allocation failures** - Force application termination
- **Critical system resource access denied** - Trigger EmergencyStopMacro()
- **Configuration corruption preventing startup** - User intervention required
- **Multiple consecutive system failures** - Cascading failure prevention

### Recoverable Errors (Retry/Fallback Strategies)
- **Individual feature failures** - Graceful degradation with reduced functionality
- **Temporary resource unavailability** - Automatic retry with exponential backoff
- **Performance threshold breaches** - Dynamic adjustment of intervals/parameters
- **File I/O errors** - Handle recovery with alternative paths or defaults

### Warning Level (Log Only)
- **Performance degradation** - Monitor but continue operation
- **Non-critical timer errors** - Log and track statistics
- **Cache misses or timeouts** - Note for optimization
- **Minor configuration issues** - Auto-correct with logging

### Module-Specific Error Classifications

#### ManaMonitor Errors
- **Pixel detection failures**: Return previous known state
- **Performance degradation**: Switch to faster checking mode
- **Coordinate out of bounds**: Return safe default values

#### TimerManager Errors
- **Callback execution failures**: Count errors and auto-stop after 10 failures
- **Concurrent execution**: Prevent timer overlap, track execution state
- **Resource cleanup**: Dependency-aware cleanup order

#### TinctureManager Errors
- **Usage verification failures**: Retry with exponential backoff (max 5 attempts)
- **State synchronization**: Extended cooldown on max retry failures
- **Input simulation**: Automatic retry with state verification

#### ConfigManager Errors
- **File corruption**: Generate default configuration
- **Validation failures**: Auto-correct with safe values
- **Backup operation failures**: Continue with warning

## Error Propagation Patterns

### Multi-Layered Error Handling Hierarchy

```
Global Level (Main.ahk)
├── GlobalErrorHandler() - Final safety net
├── Critical error detection by message content
├── Emergency actions (EmergencyStopMacro)
└── Application termination for severe errors

Core Systems Level (TimerManager, ConfigManager)
├── Managed error recovery with statistics
├── Performance monitoring and intervention
├── State management and cleanup procedures
└── Graceful degradation mechanisms

Feature Level (ManaMonitor, TinctureManager, SkillController)
├── Domain-specific error responses
├── Operational continuity maintenance
├── Statistical tracking and reporting
└── Context-aware recovery strategies
```

### Error Re-throwing vs Local Handling

#### Always Propagated (Re-thrown)
```ahk
// Initialization failures in Main.ahk
catch Error as e {
    g_macro_active := false
    StopAllTimers()
    ShowOverlay("マクロ開始エラー: " . e.Message, 3000)
    LogError("Main", "Failed to start macro: " . e.Message)
    throw  // Re-throws to global handler
}
```

#### Always Handled Locally
```ahk
// ManaMonitor operational errors
catch Error as e {
    LogError("ManaMonitor", "Monitor cycle failed: " . e.Message)
    if (g_mana_check_errors > 10) {
        AdjustMonitoringInterval(200)
    }
    return g_last_mana_state  // Continue with previous state
}
```

### Decision Criteria for Error Propagation

**Upward Propagation Triggers:**
- Errors that prevent system initialization
- Corrupted configuration requiring user intervention
- Critical resource access failures
- User interface validation errors

**Local Handling Triggers:**
- Operational errors that can be worked around
- Performance issues that can be optimized
- Temporary resource conflicts
- Individual feature failures not affecting core functionality

## Automatic Recovery Mechanisms

### Tincture Retry Logic (Most Sophisticated)

```ahk
// Maximum retry attempts with configurable limits
if (g_tincture_retry_count >= g_tincture_retry_max) {
    HandleMaxRetryReached()  // Extended cooldown (2x normal)
    return
}

// Exponential backoff with verification
retryInterval := ConfigManager.Get("Tincture", "RetryInterval", 500)
StartManagedTimer("TinctureRetry", () => AttemptTinctureUse(), -retryInterval)
```

**Retry Algorithm Details:**
- **Maximum attempts**: Configurable (default: 5)
- **Verification system**: Two-stage (mana state + optional buff detection)
- **Timeout handling**: 3-second timeout per attempt
- **Failure escalation**: Extended cooldown on max retries reached

### Timer Auto-Stop Conditions

```ahk
// Automatic timer termination based on error rate
if (g_timer_errors[timerName] > 10) {
    LogError("TimerManager", Format("Timer '{}' has too many errors, stopping", timerName))
    StopManagedTimer(timerName)
}
```

**Auto-Stop Thresholds:**
- **Timer errors**: 10 consecutive failures trigger automatic stop
- **Mana check errors**: >10 errors trigger interval adjustment
- **Log monitoring errors**: >5 errors trigger file handle reopening
- **Log write errors**: >5 errors trigger log file reopening

### Fallback Value Determination

#### Configuration Recovery
```ahk
// Automatic correction of invalid values
if (screenWidth < 800 || screenWidth > 7680) {
    this.Set("Resolution", "ScreenWidth", 3440)  // Safe default
    modified := true
}
```

#### Color Detection Fallback
```ahk
// Safe color return on pixel detection failure
catch Error as e {
    LogError("ColorDetection", Format("Failed to get pixel at {},{}: {}", x, y, e.Message))
    g_pixel_cache[cacheKey] := {color: 0x000000, time: currentTime}
    return 0x000000  // Black color fallback
}
```

### File Handle Recovery

```ahk
// Automatic file handle reopening after multiple errors
if (g_monitor_errors > 5) {
    ReopenClientLogFile()  // Complete reinitialize
}
```

**Recovery Strategies:**
- **Client log monitoring**: Auto-reopen file handles after 5 consecutive errors
- **Configuration files**: Fallback to default profile on corruption
- **Log files**: Fallback to OutputDebug if file writing fails
- **Cache management**: Auto-cleanup on size limits or corruption

### Performance Mode Adaptations

```ahk
// Dynamic performance adjustment based on stability
if (g_performance_mode && g_mana_state_stable_count > 5) {
    if (currentTime - g_last_full_check_time < 1000) {
        return CheckManaQuick()  // Fast check mode
    }
}
```

**Adaptation Mechanisms:**
- **Stability optimization**: Quick checks when system is stable
- **Error-based scaling**: Interval increases with error rate
- **Temporary accuracy mode**: Disabled performance mode for 5s after errors
- **Dynamic intervals**: Automatic adjustment based on error patterns

## Error State Management

### Global Error Counter Variables

#### Primary Error Counters
- **g_mana_check_errors** - Mana detection failures
- **g_timer_errors** (Map) - Per-timer error counts
- **g_monitor_errors** - Log monitoring errors
- **g_tincture_failure_count** - Tincture operation failures
- **g_log_stats.writeErrors** - Log write failures
- **g_slow_detection_count** - Performance monitoring

#### Derived Statistics
- **Error rates**: Calculated as (errors / total_attempts) * 100
- **Success rates**: For tincture and flask operations
- **Performance metrics**: Average execution times and failure rates

### Error History and Buffer Management

```ahk
// Limited history buffers with automatic cleanup
if (g_tincture_history.Length > 50) {
    g_tincture_history.RemoveAt(1)  // Remove oldest entry
}
```

**Buffer Policies:**
- **Tincture history**: 50 entries maximum
- **Flask usage history**: 100 entries maximum
- **Area history**: 10 entries maximum
- **Pixel cache**: 1000 entries with cleanup on overflow

### Error State Reset Mechanisms

```ahk
// Successful operations reset error counts
g_monitor_errors := 0  // On successful log read
g_log_stats.writeErrors := 0  // On successful log write
g_tincture_retry_count := 0  // On successful tincture use
```

**Reset Functions:**
- **ResetTinctureState()** - Clears all tincture error counters
- **ResetFlaskStats()** - Resets flask error statistics
- **ResetAllSkillStats()** - Clears skill error counts
- **ResetColorDetectionCache()** - Clears detection error counters

## Special Error Cases

### PixelGetColor Timeout Handling

```ahk
// Color detection with configurable timeout
timeout := ConfigManager.Get("Performance", "ColorDetectTimeout", 50)
if (elapsed > timeout) {
    g_slow_detection_count++
    LogWarn("ColorDetection", Format("Slow pixel detection: {}ms", elapsed))
}
```

**Timeout Strategy:**
- **Default timeout**: 50ms for color detection operations
- **Performance tracking**: Count and warn on slow operations
- **Fallback**: Return safe black color (0x000000) on failure
- **Cache integration**: Error results cached to prevent repeated failures

### File I/O Error Handling

#### Config.ini Specific Handling
```ahk
// Robust configuration file operations
try {
    IniWrite(String(value), configPath, section, key)
    return true
} catch Error as e {
    LogError("ConfigManager", "Failed to save config: " . e.Message)
    return false
}
```

**Recovery Features:**
- **Automatic backup creation** before modifications
- **Profile system** with fallback to default
- **Validation and auto-correction** of corrupted values
- **Hot-reload capability** without macro restart

#### Client.txt Specific Handling
```ahk
// Log monitoring with robust error recovery
} catch Error as e {
    g_monitor_errors++
    LogError("ClientLogMonitor", Format("Log check failed (errors: {}): {}", 
        g_monitor_errors, e.Message))
    
    if (g_monitor_errors > 5) {
        ReopenClientLogFile()
    }
}
```

**Recovery Features:**
- **Alternative path searching** for Steam installations
- **Log rotation detection** and automatic reconnection
- **Shared mode access** to prevent conflicts with game client
- **Buffer management** for partial reads

### Window Detection Failures

```ahk
// Safe window detection with fallback
IsTargetWindowActive() {
    try {
        return WinActive("ahk_group TargetWindows")
    } catch Error as e {
        LogError("WindowManager", "Window check failed: " . e.Message)
        return false  // Safe default
    }
}
```

**Recovery Strategy:**
- **Multiple window targets** (PathOfExileSteam.exe, Steam Remote Play)
- **Coordinate validation** with bounds checking
- **Multi-monitor support** with error recovery
- **Graceful degradation** to safe defaults

## Anticipated Errors from Catch Blocks

### By Module and Error Type

#### ConfigManager Anticipated Errors
```ahk
"Failed to read section {}: {}"
"Failed to load config: {}"
"Failed to save config: {}"
"Failed to create backup: {}"
```

#### ColorDetection Anticipated Errors
```ahk
"Failed to get pixel at {},{}: {}"
"Coordinates out of bounds: {},{} (Screen: {}x{})"
"Brightness calculation failed: {}"
"Similarity calculation failed: {}"
```

#### TimerManager Anticipated Errors
```ahk
"Failed to start timer '{}': {}"
"Error in timer '{}' (errors: {}): {}"
"Failed to stop timer '{}': {}"
"Timer '{}' has too many errors, stopping"
```

#### TinctureManager Anticipated Errors
```ahk
"Initial Tincture use failed: {}"
"Error in AttemptTinctureUse: {}"
"Error in VerifyTinctureUse: {}"
"Max retry attempts reached for Tincture"
```

#### ClientLogMonitor Anticipated Errors
```ahk
"Failed to start monitoring: {}"
"Log check failed (errors: {}): {}"
"Failed to read log entries: {}"
"Failed to reopen log file: {}"
```

### Error Suppression Patterns

```ahk
// Strategic silent error suppression for non-critical operations
catch {
    // Used for:
    // - Directory creation (already exists)
    // - File handle cleanup during shutdown
    // - GUI operations (window already closed)
    // - Optional feature initialization failures
}
```

**Suppression Guidelines:**
- Only for truly non-critical operations
- Never suppress errors that affect core functionality
- Always document why errors are suppressed
- Use sparingly (< 5% of all catch blocks)

## Error Detection and Condition Checking

### String-Based Error Detection
```ahk
// Critical error pattern detection
if (InStr(exception.Message, "Critical") || 
    InStr(exception.Message, "Access") || 
    InStr(exception.Message, "Memory")) {
    EmergencyStopMacro()
    ExitApp()
}
```

### Performance-Based Error Detection
```ahk
// Execution time monitoring
if (executionTime > 200) {
    LogWarn("TimerManager", Format("Slow timer execution: {}ms for '{}'", 
        executionTime, timerName))
}
```

### Resource-Based Error Detection
```ahk
// Memory usage monitoring
if (g_pixel_cache.Count > 1000) {
    CleanupPixelCache()  // Automatic cleanup
}
```

## Key Architecture Strengths

### Comprehensive Error Coverage
- **125+ catch blocks** across all modules
- **Multiple error detection mechanisms** (try-catch, performance monitoring, resource tracking)
- **Hierarchical error handling** with appropriate escalation
- **Context-aware error responses** based on module and operation type

### Intelligent Recovery Systems
- **Multi-stage retry mechanisms** with exponential backoff
- **Automatic performance adaptation** based on error patterns
- **Resource cleanup and reinitialization** on failures
- **Graceful degradation** maintaining core functionality

### Observability and Debugging
- **Detailed error logging** with context and statistics
- **Performance monitoring** integrated into error handling
- **Error rate calculations** for trend analysis
- **Debug displays** showing real-time error information

### User Experience Protection
- **Transparent error handling** for non-critical failures
- **Clear error messages** for user-actionable issues
- **Automatic recovery** without user intervention
- **System stability** maintained despite component failures

This comprehensive error handling system demonstrates enterprise-level robustness suitable for long-running automation systems that must operate reliably under varying conditions and recover gracefully from both expected and unexpected failure scenarios.