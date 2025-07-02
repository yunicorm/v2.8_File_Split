; Visual Detection Settings Module
; Configuration management, presets, and settings import/export
; v2.9.6 - Extracted from VisualDetection.ahk for better modularity

; Settings globals
global g_settings_cache := Map()
global g_preset_cache := Map()

; Configuration keys mapping
global FLASK_CONFIG_KEYS := [
    "Flask1X", "Flask1Y", "Flask1Width", "Flask1Height", "Flask1ChargedPattern",
    "Flask2X", "Flask2Y", "Flask2Width", "Flask2Height", "Flask2ChargedPattern", 
    "Flask3X", "Flask3Y", "Flask3Width", "Flask3Height", "Flask3ChargedPattern",
    "Flask4X", "Flask4Y", "Flask4Width", "Flask4Height", "Flask4ChargedPattern",
    "Flask5X", "Flask5Y", "Flask5Width", "Flask5Height", "Flask5ChargedPattern"
]

; Load visual detection configuration from file
LoadVisualDetectionConfig() {
    try {
        LogInfo("VisualDetection", "Loading visual detection configuration")
        
        configCount := 0
        
        ; Load basic settings
        basicSettings := Map(
            "EnableVisualDetection", "false",
            "DetectionMode", "Timer", 
            "DetectionInterval", "100",
            "ShowDetectionOverlay", "false",
            "OverlayDuration", "2000"
        )
        
        for key, defaultValue in basicSettings {
            value := ConfigManager.Get("VisualDetection", key, defaultValue)
            g_settings_cache[key] := value
            configCount++
        }
        
        ; Load flask configurations
        for configKey in FLASK_CONFIG_KEYS {
            value := ConfigManager.Get("VisualDetection", configKey, "")
            g_settings_cache[configKey] := value
            configCount++
        }
        
        ; Load Wine-specific settings
        wineSettings := Map(
            "WineChargeDetectionEnabled", "false",
            "WineMaxCharge", "140",
            "WineChargePerUse", "72", 
            "WineGoldR", "230",
            "WineGoldG", "170",
            "WineGoldB", "70",
            "WineColorTolerance", "50",
            "WineSamplingRate", "3"
        )
        
        for key, defaultValue in wineSettings {
            value := ConfigManager.Get("VisualDetection", key, defaultValue)
            g_settings_cache[key] := value
            configCount++
        }
        
        LogInfo("VisualDetection", Format("Loaded {} configuration settings", configCount))
        return configCount
        
    } catch as e {
        LogError("VisualDetection", "Failed to load configuration: " . e.Message)
        return 0
    }
}

; Save visual detection configuration to file
SaveVisualDetectionConfig() {
    try {
        LogInfo("VisualDetection", "Saving visual detection configuration")
        
        savedCount := 0
        
        ; Save all cached settings
        for key, value in g_settings_cache {
            ConfigManager.Set("VisualDetection", key, value)
            savedCount++
        }
        
        LogInfo("VisualDetection", Format("Saved {} configuration settings", savedCount))
        return savedCount
        
    } catch as e {
        LogError("VisualDetection", "Failed to save configuration: " . e.Message)
        return 0
    }
}

; Get setting value with caching
GetSetting(key, defaultValue := "") {
    try {
        if (g_settings_cache.Has(key)) {
            return g_settings_cache[key]
        }
        
        value := ConfigManager.Get("VisualDetection", key, defaultValue)
        g_settings_cache[key] := value
        return value
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to get setting {}: {}", key, e.Message))
        return defaultValue
    }
}

; Set setting value with caching
SetSetting(key, value) {
    try {
        g_settings_cache[key] := value
        ConfigManager.Set("VisualDetection", key, value)
        LogDebug("VisualDetection", Format("Setting {} = {}", key, value))
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to set setting {}: {}", key, e.Message))
        return false
    }
}

; Clear settings cache
ClearSettingsCache() {
    g_settings_cache.Clear()
    g_preset_cache.Clear()
    LogDebug("VisualDetection", "Settings cache cleared")
}

; Validate flask position configuration
ValidateFlaskPosition(flaskNumber) {
    try {
        if (flaskNumber < 1 || flaskNumber > 5) {
            return false
        }
        
        x := GetSetting(Format("Flask{}X", flaskNumber), 0)
        y := GetSetting(Format("Flask{}Y", flaskNumber), 0)
        width := GetSetting(Format("Flask{}Width", flaskNumber), 80)
        height := GetSetting(Format("Flask{}Height", flaskNumber), 120)
        
        ; Check if coordinates are set
        if (x == 0 && y == 0) {
            return false
        }
        
        ; Check if dimensions are reasonable
        if (width < 20 || width > 200 || height < 20 || height > 200) {
            return false
        }
        
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to validate Flask{} config: {}", flaskNumber, e.Message))
        return false
    }
}

; Get configured flask count
GetConfiguredFlaskCount() {
    try {
        count := 0
        Loop 5 {
            if (ValidateFlaskPosition(A_Index)) {
                count++
            }
        }
        return count
        
    } catch as e {
        LogError("VisualDetection", "Failed to get configured flask count: " . e.Message)
        return 0
    }
}

; Apply preset configuration (delegates to CoordinateManager)
ApplySettingsPreset(presetName) {
    try {
        LogInfo("VisualDetection", Format("Applying preset via CoordinateManager: {}", presetName))
        
        ; Delegate to CoordinateManager's ApplyPreset function
        result := ApplyPreset(presetName)
        
        if (result > 0) {
            ; Reload settings after coordinate changes
            LoadVisualDetectionConfig()
            LogInfo("VisualDetection", Format("Preset {} applied successfully", presetName))
        }
        
        return result
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to apply preset {}: {}", presetName, e.Message))
        return 0
    }
}

; Note: Preset application functions moved to CoordinateManager.ahk
; to avoid duplication and maintain proper separation of concerns.
; Use ApplyPreset() from CoordinateManager for coordinate-related operations.

; Load current configuration from Config.ini
LoadCurrentConfig() {
    try {
        LogInfo("VisualDetection", "Reloading current configuration from Config.ini")
        
        ; Clear cache to force reload
        ClearSettingsCache()
        
        ; Reload configuration
        loadedCount := LoadVisualDetectionConfig()
        
        LogInfo("VisualDetection", Format("Reloaded {} settings", loadedCount))
        return loadedCount
        
    } catch as e {
        LogError("VisualDetection", "Failed to reload current config: " . e.Message)
        return 0
    }
}

; Note: SaveCustomPreset() function moved to CoordinateManager.ahk
; to avoid duplication and maintain proper separation of concerns.

; Note: Export/Import functions moved to CoordinateManager.ahk
; Use ExportSettings() and ImportSettings() from CoordinateManager for these operations.

; Reset all flask settings to defaults
ResetFlaskSettings() {
    try {
        LogInfo("VisualDetection", "Resetting all flask settings to defaults")
        
        resetCount := 0
        
        ; Reset flask positions
        Loop 5 {
            flaskNum := A_Index
            SetSetting(Format("Flask{}X", flaskNum), 0)
            SetSetting(Format("Flask{}Y", flaskNum), 0)
            SetSetting(Format("Flask{}Width", flaskNum), 80)
            SetSetting(Format("Flask{}Height", flaskNum), 120)
            SetSetting(Format("Flask{}ChargedPattern", flaskNum), "")
            resetCount += 5
        }
        
        ; Reset Wine settings
        SetSetting("WineGoldR", 230)
        SetSetting("WineGoldG", 170)
        SetSetting("WineGoldB", 70)
        SetSetting("WineColorTolerance", 50)
        resetCount += 4
        
        SaveVisualDetectionConfig()
        
        LogInfo("VisualDetection", Format("Reset {} settings to defaults", resetCount))
        return resetCount
        
    } catch as e {
        LogError("VisualDetection", "Failed to reset settings: " . e.Message)
        return 0
    }
}