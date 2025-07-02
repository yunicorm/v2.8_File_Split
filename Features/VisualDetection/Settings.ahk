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

; Validate flask configuration
ValidateFlaskConfig(flaskNumber) {
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
            if (ValidateFlaskConfig(A_Index)) {
                count++
            }
        }
        return count
        
    } catch as e {
        LogError("VisualDetection", "Failed to get configured flask count: " . e.Message)
        return 0
    }
}

; Apply preset configuration
ApplyPreset(presetName) {
    try {
        LogInfo("VisualDetection", Format("Applying preset: {}", presetName))
        
        switch presetName {
            case "standard":
                return ApplyStandardPreset()
            case "center":
                return ApplyCenterPreset()
            case "right":
                return ApplyRightPreset()
            case "current":
                return LoadCurrentConfig()
            default:
                LogError("VisualDetection", "Unknown preset: " . presetName)
                return false
        }
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to apply preset {}: {}", presetName, e.Message))
        return false
    }
}

; Apply standard bottom-left preset
ApplyStandardPreset() {
    try {
        monitors := GetCachedMonitorInfo()
        if (!monitors.Has("central")) {
            throw Error("Monitor info not available")
        }
        
        central := monitors["central"]
        
        ; Base settings for 3440x1440 resolution
        baseX := 100
        baseY := 1350
        spacing := 80
        width := 60
        height := 80
        
        ; Apply resolution scaling
        scaleX := central["width"] / 3440.0
        scaleY := central["height"] / 1440.0
        
        scaledBaseX := Round(baseX * scaleX)
        scaledBaseY := Round(baseY * scaleY)
        scaledSpacing := Round(spacing * scaleX)
        scaledWidth := Round(width * scaleX)
        scaledHeight := Round(height * scaleY)
        
        ; Configure each flask
        appliedCount := 0
        Loop 5 {
            flaskNum := A_Index
            x := scaledBaseX + (flaskNum - 1) * scaledSpacing
            y := scaledBaseY
            
            SetSetting(Format("Flask{}X", flaskNum), x)
            SetSetting(Format("Flask{}Y", flaskNum), y)
            SetSetting(Format("Flask{}Width", flaskNum), scaledWidth)
            SetSetting(Format("Flask{}Height", flaskNum), scaledHeight)
            
            appliedCount++
        }
        
        SaveVisualDetectionConfig()
        LogInfo("VisualDetection", Format("Applied standard preset: {} flasks", appliedCount))
        return appliedCount
        
    } catch as e {
        LogError("VisualDetection", "Failed to apply standard preset: " . e.Message)
        return 0
    }
}

; Apply center bottom preset
ApplyCenterPreset() {
    try {
        monitors := GetCachedMonitorInfo()
        if (!monitors.Has("central")) {
            throw Error("Monitor info not available")
        }
        
        central := monitors["central"]
        
        ; Center position for 3440x1440
        baseX := 1620  ; Center of 3440
        baseY := 1350
        spacing := 80
        width := 60
        height := 80
        
        ; Apply resolution scaling
        scaleX := central["width"] / 3440.0
        scaleY := central["height"] / 1440.0
        
        scaledBaseX := Round(baseX * scaleX)
        scaledBaseY := Round(baseY * scaleY)
        scaledSpacing := Round(spacing * scaleX)
        scaledWidth := Round(width * scaleX)
        scaledHeight := Round(height * scaleY)
        
        ; Configure each flask
        appliedCount := 0
        Loop 5 {
            flaskNum := A_Index
            x := scaledBaseX + (flaskNum - 3) * scaledSpacing  ; Center around middle flask
            y := scaledBaseY
            
            SetSetting(Format("Flask{}X", flaskNum), x)
            SetSetting(Format("Flask{}Y", flaskNum), y)
            SetSetting(Format("Flask{}Width", flaskNum), scaledWidth)
            SetSetting(Format("Flask{}Height", flaskNum), scaledHeight)
            
            appliedCount++
        }
        
        SaveVisualDetectionConfig()
        LogInfo("VisualDetection", Format("Applied center preset: {} flasks", appliedCount))
        return appliedCount
        
    } catch as e {
        LogError("VisualDetection", "Failed to apply center preset: " . e.Message)
        return 0
    }
}

; Apply right bottom preset
ApplyRightPreset() {
    try {
        monitors := GetCachedMonitorInfo()
        if (!monitors.Has("central")) {
            throw Error("Monitor info not available")
        }
        
        central := monitors["central"]
        
        ; Right position for 3440x1440
        baseX := 2940  ; Right side of 3440
        baseY := 1350
        spacing := -80  ; Negative spacing for right-to-left
        width := 60
        height := 80
        
        ; Apply resolution scaling
        scaleX := central["width"] / 3440.0
        scaleY := central["height"] / 1440.0
        
        scaledBaseX := Round(baseX * scaleX)
        scaledBaseY := Round(baseY * scaleY)
        scaledSpacing := Round(spacing * scaleX)
        scaledWidth := Round(width * scaleX)
        scaledHeight := Round(height * scaleY)
        
        ; Configure each flask
        appliedCount := 0
        Loop 5 {
            flaskNum := A_Index
            x := scaledBaseX + (flaskNum - 1) * scaledSpacing
            y := scaledBaseY
            
            SetSetting(Format("Flask{}X", flaskNum), x)
            SetSetting(Format("Flask{}Y", flaskNum), y)
            SetSetting(Format("Flask{}Width", flaskNum), scaledWidth)
            SetSetting(Format("Flask{}Height", flaskNum), scaledHeight)
            
            appliedCount++
        }
        
        SaveVisualDetectionConfig()
        LogInfo("VisualDetection", Format("Applied right preset: {} flasks", appliedCount))
        return appliedCount
        
    } catch as e {
        LogError("VisualDetection", "Failed to apply right preset: " . e.Message)
        return 0
    }
}

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

; Save custom preset
SaveCustomPreset() {
    try {
        LogInfo("VisualDetection", "Saving custom preset")
        
        ; Get current flask positions
        positions := []
        Loop 5 {
            flaskNum := A_Index
            if (ValidateFlaskConfig(flaskNum)) {
                pos := Map(
                    "x", GetSetting(Format("Flask{}X", flaskNum), 0),
                    "y", GetSetting(Format("Flask{}Y", flaskNum), 0),
                    "width", GetSetting(Format("Flask{}Width", flaskNum), 60),
                    "height", GetSetting(Format("Flask{}Height", flaskNum), 80)
                )
                positions.Push(pos)
            }
        }
        
        if (positions.Length == 0) {
            throw Error("No valid flask positions to save")
        }
        
        ; Calculate base position and spacing from first two flasks
        baseX := positions[1]["x"]
        baseY := positions[1]["y"]
        spacing := positions.Length > 1 ? (positions[2]["x"] - positions[1]["x"]) : 80
        
        ; Save custom preset settings
        SetSetting("CustomPresetBaseX", baseX)
        SetSetting("CustomPresetBaseY", baseY)
        SetSetting("CustomPresetSpacing", spacing)
        SetSetting("CustomPresetWidth", positions[1]["width"])
        SetSetting("CustomPresetHeight", positions[1]["height"])
        SetSetting("CustomPresetSaved", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"))
        
        SaveVisualDetectionConfig()
        
        LogInfo("VisualDetection", Format("Custom preset saved: {} flasks", positions.Length))
        return positions.Length
        
    } catch as e {
        LogError("VisualDetection", "Failed to save custom preset: " . e.Message)
        return 0
    }
}

; Export flask settings to clipboard
ExportFlaskSettings() {
    try {
        LogInfo("VisualDetection", "Exporting flask settings to clipboard")
        
        exportLines := []
        exportLines.Push("[VisualDetection Flask Settings Export]")
        exportLines.Push("Generated: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"))
        exportLines.Push("")
        
        ; Export flask configurations
        Loop 5 {
            flaskNum := A_Index
            if (ValidateFlaskConfig(flaskNum)) {
                exportLines.Push(Format("Flask{} Configuration:", flaskNum))
                exportLines.Push(Format("  X={}", GetSetting(Format("Flask{}X", flaskNum), 0)))
                exportLines.Push(Format("  Y={}", GetSetting(Format("Flask{}Y", flaskNum), 0)))
                exportLines.Push(Format("  Width={}", GetSetting(Format("Flask{}Width", flaskNum), 60)))
                exportLines.Push(Format("  Height={}", GetSetting(Format("Flask{}Height", flaskNum), 80)))
                exportLines.Push("")
            }
        }
        
        ; Export Wine settings
        exportLines.Push("Wine of the Prophet Settings:")
        exportLines.Push(Format("  WineGoldR={}", GetSetting("WineGoldR", 230)))
        exportLines.Push(Format("  WineGoldG={}", GetSetting("WineGoldG", 170)))
        exportLines.Push(Format("  WineGoldB={}", GetSetting("WineGoldB", 70)))
        exportLines.Push(Format("  WineColorTolerance={}", GetSetting("WineColorTolerance", 50)))
        
        ; Create export text
        exportText := ""
        for line in exportLines {
            exportText .= line . "`n"
        }
        
        ; Copy to clipboard
        A_Clipboard := exportText
        
        LogInfo("VisualDetection", "Settings exported to clipboard")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to export settings: " . e.Message)
        return false
    }
}

; Import flask settings (reload from Config.ini)
ImportFlaskSettings() {
    try {
        LogInfo("VisualDetection", "Importing flask settings from Config.ini")
        
        ; Reload configuration
        importedCount := LoadCurrentConfig()
        
        if (importedCount > 0) {
            LogInfo("VisualDetection", Format("Successfully imported {} settings", importedCount))
            return importedCount
        } else {
            throw Error("No settings imported")
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to import settings: " . e.Message)
        return 0
    }
}

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