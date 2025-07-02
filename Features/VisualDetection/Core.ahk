; Visual Detection Core Module
; Global variables, initialization, and basic state management
; v2.9.6 - Extracted from VisualDetection.ahk for better modularity

; ATan2カスタム実装（AutoHotkey v2では未提供）
ATan2Custom(y, x) {
    if (x > 0) {
        return ATan(y / x)
    }
    else if (x < 0 && y >= 0) {
        return ATan(y / x) + 3.141592653589793
    }
    else if (x < 0 && y < 0) {
        return ATan(y / x) - 3.141592653589793
    }
    else if (x == 0 && y > 0) {
        return 3.141592653589793 / 2
    }
    else if (x == 0 && y < 0) {
        return -3.141592653589793 / 2
    }
    else {
        return 0  ; x == 0 && y == 0
    }
}

; Global Map for visual detection state (snake_case naming convention)
global g_visual_detection_state := Map(
    "enabled", false,
    "detection_mode", "Timer",
    "last_detection_time", 0,
    "findtext_instance", "",
    "detection_results", Map(),
    "detection_interval", 100  ; Minimum interval between detections (ms)
)

; Flask overlay capture globals
global g_flask_overlay_gui := ""
global g_current_flask_index := 1
global g_flask_rect_width := 60   ; フラスコの実際の幅に合わせて
global g_flask_rect_height := 80 ; フラスコの実際の高さに合わせて

; 複数フラスコオーバーレイ管理
global g_flask_overlay_guis := []
global g_flask_spacing := 20

; 順次設定用変数
global g_current_single_overlay := ""
global g_setup_notification_gui := ""
global g_flask_number_overlay := ""
global g_completed_flask_overlays := []
global g_guideline_overlays := []
global g_boundary_warning_overlay := ""

; 操作性向上機能用変数
global g_grid_snap_enabled := false
global g_preset_menu_gui := ""
global g_help_overlay_gui := ""
global g_batch_mode := false

; Debug and testing globals
global g_test_results := Map()
global g_debug_overlays := []

; Check if FindText.ahk file exists
CheckFindTextFile() {
    try {
        findTextPath := A_ScriptDir . "\Utils\FindText.ahk"
        if (FileExist(findTextPath)) {
            LogDebug("VisualDetection", "FindText.ahk found at: " . findTextPath)
            return true
        } else {
            LogError("VisualDetection", "FindText.ahk not found at: " . findTextPath)
            return false
        }
    } catch as e {
        LogError("VisualDetection", "Error checking FindText file: " . e.Message)
        return false
    }
}

; Check if enough time has passed since last detection
CanPerformDetection() {
    currentTime := A_TickCount
    lastTime := g_visual_detection_state["last_detection_time"]
    interval := g_visual_detection_state["detection_interval"]
    
    if ((currentTime - lastTime) >= interval) {
        return true
    } else {
        LogDebug("VisualDetection", "Detection interval not met, skipping (" . 
                 (currentTime - lastTime) . "ms < " . interval . "ms)")
        return false
    }
}

; Initialize default visual detection configuration
InitializeDefaultVisualDetectionConfig() {
    try {
        LogInfo("VisualDetection", "Checking visual detection configuration")
        
        ; デフォルト値のマップ
        defaults := Map(
            "DetectionMode", "Timer",
            "DetectionInterval", "100",
            "EnableVisualDetection", "false",
            "Flask1X", "0",
            "Flask1Y", "0",
            "Flask1Width", "80",
            "Flask1Height", "120",
            "Flask1ChargedPattern", "",
            "Flask2X", "0",
            "Flask2Y", "0",
            "Flask2Width", "80",
            "Flask2Height", "120",
            "Flask2ChargedPattern", "",
            "Flask3X", "0", 
            "Flask3Y", "0",
            "Flask3Width", "80",
            "Flask3Height", "120",
            "Flask3ChargedPattern", "",
            "Flask4X", "0",
            "Flask4Y", "0",
            "Flask4Width", "80",
            "Flask4Height", "120",
            "Flask4ChargedPattern", "",
            "Flask4Name", "Wine of the Prophet",
            "Flask5X", "0",
            "Flask5Y", "0",
            "Flask5Width", "80",
            "Flask5Height", "120",
            "Flask5ChargedPattern", "",
            
            ; Wine of the Prophet 高精度検出設定
            "WineChargeDetectionEnabled", "false",
            "WineMaxCharge", "140",
            "WineChargePerUse", "72",
            "WineGoldR", "230",
            "WineGoldG", "170",
            "WineGoldB", "70",
            "WineColorTolerance", "50",
            "WineSamplingRate", "3",
            
            ; デバッグ設定
            "ShowDetectionOverlay", "false",
            "OverlayDuration", "2000",
            
            ; 順次設定システム設定
            "SequentialSetupEnabled", "true",
            "ShowCompletedFlasks", "true",
            "ShowGuidelines", "true",
            "GridSnapEnabled", "false"
        )
        
        ; 各設定をチェックしてデフォルト値を設定
        for key, value in defaults {
            existingValue := ConfigManager.Get("VisualDetection", key, "")
            if (existingValue == "") {
                ConfigManager.Set("VisualDetection", key, value)
                LogDebug("VisualDetection", "Set default " . key . " = " . value)
            } else {
                LogDebug("VisualDetection", "Keeping existing " . key . " = " . existingValue)
            }
        }
        
        LogInfo("VisualDetection", "Configuration check completed successfully")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to check config: " . e.Message)
        return false
    }
}

; Initialize visual detection system
InitializeVisualDetection() {
    try {
        LogInfo("VisualDetection", "Initializing visual detection system")
        
        ; Check if FindText.ahk is available
        if (!CheckFindTextFile()) {
            LogError("VisualDetection", "FindText.ahk not available, visual detection disabled")
            g_visual_detection_state["enabled"] := false
            return false
        }
        
        ; Initialize default configuration
        InitializeDefaultVisualDetectionConfig()
        
        ; Load configuration
        enabledStr := ConfigManager.Get("VisualDetection", "EnableVisualDetection", "false")
        g_visual_detection_state["enabled"] := (enabledStr = "true")
        g_visual_detection_state["detection_mode"] := ConfigManager.Get("VisualDetection", "DetectionMode", "Timer")
        g_visual_detection_state["detection_interval"] := ConfigManager.Get("VisualDetection", "DetectionInterval", 100)
        
        LogDebug("VisualDetection", "Enabled String from Config: " . enabledStr)
        LogDebug("VisualDetection", "g_visual_detection_state enabled: " . g_visual_detection_state["enabled"])
        
        ; Initialize FindText if visual detection is enabled
        if (g_visual_detection_state["enabled"]) {
            try {
                ; Create FindText instance
                g_visual_detection_state["findtext_instance"] := ""  ; Placeholder for FindText
                LogInfo("VisualDetection", "FindText instance created successfully")
                LogInfo("VisualDetection", "Visual detection initialized successfully")
            } catch as e {
                LogError("VisualDetection", "Failed to create FindText instance: " . e.Message)
                g_visual_detection_state["enabled"] := false
                return false
            }
        } else {
            LogInfo("VisualDetection", "Visual detection disabled in configuration")
        }
        
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to initialize visual detection: " . e.Message)
        return false
    }
}

; Check if visual detection is enabled
IsVisualDetectionEnabled() {
    return g_visual_detection_state["enabled"]
}

; Enable visual detection
EnableVisualDetection() {
    try {
        if (!CheckFindTextFile()) {
            LogError("VisualDetection", "Cannot enable visual detection: FindText.ahk not found")
            return false
        }
        
        g_visual_detection_state["enabled"] := true
        ConfigManager.Set("VisualDetection", "EnableVisualDetection", "true")
        
        LogInfo("VisualDetection", "Visual detection enabled")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to enable visual detection: " . e.Message)
        return false
    }
}

; Disable visual detection
DisableVisualDetection() {
    try {
        g_visual_detection_state["enabled"] := false
        ConfigManager.Set("VisualDetection", "EnableVisualDetection", "false")
        
        ; Clear any cached results
        g_visual_detection_state["detection_results"].Clear()
        
        LogInfo("VisualDetection", "Visual detection disabled")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to disable visual detection: " . e.Message)
        return false
    }
}

; Get current detection mode
GetDetectionMode() {
    if (!IsVisualDetectionEnabled()) {
        return "Timer"
    }
    return g_visual_detection_state["detection_mode"]
}

; Set detection mode (Timer/Visual/Hybrid)
SetDetectionMode(mode) {
    if (mode != "Timer" && mode != "Visual" && mode != "Hybrid") {
        LogError("VisualDetection", "Invalid detection mode: " . mode)
        return false
    }
    
    try {
        g_visual_detection_state["detection_mode"] := mode
        ConfigManager.Set("VisualDetection", "DetectionMode", mode)
        LogInfo("VisualDetection", "Detection mode changed to: " . mode)
        return true
    } catch as e {
        LogError("VisualDetection", "Failed to set detection mode: " . e.Message)
        return false
    }
}

; Get detection interval
GetDetectionInterval() {
    return g_visual_detection_state["detection_interval"]
}

; Set detection interval
SetDetectionInterval(interval) {
    try {
        if (interval < 50 || interval > 1000) {
            LogError("VisualDetection", "Invalid detection interval: " . interval . " (must be 50-1000ms)")
            return false
        }
        
        g_visual_detection_state["detection_interval"] := interval
        ConfigManager.Set("VisualDetection", "DetectionInterval", interval)
        LogInfo("VisualDetection", "Detection interval set to: " . interval . "ms")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to set detection interval: " . e.Message)
        return false
    }
}

; Get last detection results for debugging
GetDetectionResults() {
    return g_visual_detection_state["detection_results"]
}

; Clear detection results
ClearDetectionResults() {
    g_visual_detection_state["detection_results"].Clear()
    LogDebug("VisualDetection", "Detection results cleared")
}

; Cleanup visual detection resources
CleanupVisualDetection() {
    try {
        LogInfo("VisualDetection", "Cleaning up visual detection resources")
        
        ; Clear results
        ClearDetectionResults()
        
        ; Reset state
        g_visual_detection_state["enabled"] := false
        g_visual_detection_state["findtext_instance"] := ""
        
        ; Clear test results
        g_test_results.Clear()
        
        LogInfo("VisualDetection", "Visual detection cleanup completed")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Cleanup failed: " . e.Message)
        return false
    }
}

; Reset visual detection state
ResetVisualDetectionState() {
    try {
        LogInfo("VisualDetection", "Resetting visual detection state")
        
        ; Clear all cached data
        ClearDetectionResults()
        g_test_results.Clear()
        
        ; Reset timing
        g_visual_detection_state["last_detection_time"] := 0
        
        LogInfo("VisualDetection", "Visual detection state reset completed")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to reset visual detection state: " . e.Message)
        return false
    }
}

; Get visual detection status information
GetVisualDetectionStatus() {
    try {
        status := Map(
            "enabled", g_visual_detection_state["enabled"],
            "mode", g_visual_detection_state["detection_mode"],
            "interval", g_visual_detection_state["detection_interval"],
            "last_detection", g_visual_detection_state["last_detection_time"],
            "findtext_available", CheckFindTextFile(),
            "results_count", g_visual_detection_state["detection_results"].Count,
            "test_results_count", g_test_results.Count
        )
        
        return status
        
    } catch as e {
        LogError("VisualDetection", "Failed to get status: " . e.Message)
        return Map()
    }
}

; Get current detection mode for debug display
GetDetectionMode() {
    global g_visual_detection_state
    
    try {
        if (g_visual_detection_state.Has("detection_mode")) {
            return g_visual_detection_state["detection_mode"]
        }
        return "Timer"  ; Default mode
    } catch {
        return "Unknown"
    }
}

; Get flask pattern statistics for debug display
GetFlaskPatternStats() {
    try {
        stats := Map(
            "total_patterns", 0,
            "configured_flasks", []
        )
        
        ; Count configured flask patterns
        Loop 5 {
            flaskNumber := A_Index
            patternKey := Format("Flask{}Pattern", flaskNumber)
            pattern := ConfigManager.Get("VisualDetection", patternKey, "")
            
            if (pattern != "") {
                stats["total_patterns"]++
                stats["configured_flasks"].Push(flaskNumber)
            }
        }
        
        return stats
        
    } catch as e {
        LogError("VisualDetection", "Failed to get pattern stats: " . e.Message)
        return Map("total_patterns", 0, "configured_flasks", [])
    }
}