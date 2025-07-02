; Coordinate Manager Module
; Handles coordinate transformations, monitor management, and position presets
; v2.9.6 - Extracted from VisualDetection.ahk for better modularity

; Coordinate transformation globals
global g_coordinate_cache := Map()
global g_monitor_info_cache := Map()
global g_cache_timeout := 5000  ; 5 seconds

; Base resolution for scaling calculations
global BASE_RESOLUTION := Map(
    "width", 3440,
    "height", 1440
)

; Preset position configurations
global FLASK_PRESETS := Map(
    "standard_bottom_left", Map(
        "name", "標準左下配置",
        "description", "PoE標準的な左下配置",
        "baseX", 100,
        "baseY", 1350,
        "spacing", 80,
        "width", 60,
        "height", 80
    ),
    "center_bottom", Map(
        "name", "中央下配置", 
        "description", "画面中央下部配置",
        "baseX", 1620,  ; 3440の中央付近
        "baseY", 1350,
        "spacing", 80,
        "width", 60,
        "height", 80
    ),
    "right_bottom", Map(
        "name", "右下配置",
        "description", "画面右下配置", 
        "baseX", 2940,  ; 右端付近
        "baseY", 1350,
        "spacing", 80,
        "width", 60,
        "height", 80
    )
)

; 中央モニター相対座標から絶対座標に変換
ConvertRelativeToAbsolute(relativeX, relativeY) {
    try {
        monitors := GetCachedMonitorInfo()
        if (!monitors.Has("central")) {
            throw Error("Central monitor not found")
        }
        
        centralMonitor := monitors["central"]
        absoluteX := centralMonitor["left"] + relativeX
        absoluteY := centralMonitor["top"] + relativeY
        
        LogDebug("CoordinateManager", Format("Converted relative ({},{}) to absolute ({},{})", 
            relativeX, relativeY, absoluteX, absoluteY))
        
        return Map("x", absoluteX, "y", absoluteY)
        
    } catch as e {
        LogError("CoordinateManager", "Failed to convert relative coordinates: " . e.Message)
        return Map("x", relativeX, "y", relativeY)  ; フォールバック
    }
}

; 絶対座標から中央モニター相対座標に変換
ConvertAbsoluteToRelative(absoluteX, absoluteY) {
    try {
        monitors := GetCachedMonitorInfo()
        if (!monitors.Has("central")) {
            throw Error("Central monitor not found")
        }
        
        centralMonitor := monitors["central"]
        relativeX := absoluteX - centralMonitor["left"]
        relativeY := absoluteY - centralMonitor["top"]
        
        LogDebug("CoordinateManager", Format("Converted absolute ({},{}) to relative ({},{})", 
            absoluteX, absoluteY, relativeX, relativeY))
        
        return Map("x", relativeX, "y", relativeY)
        
    } catch as e {
        LogError("CoordinateManager", "Failed to convert absolute coordinates: " . e.Message)
        return Map("x", absoluteX, "y", absoluteY)  ; フォールバック
    }
}

; 解像度スケーリング適用
ApplyResolutionScaling(x, y, targetWidth, targetHeight) {
    try {
        scaleX := targetWidth / BASE_RESOLUTION["width"]
        scaleY := targetHeight / BASE_RESOLUTION["height"]
        
        scaledX := Round(x * scaleX)
        scaledY := Round(y * scaleY)
        
        LogDebug("CoordinateManager", Format("Applied scaling {}x{}: ({},{}) -> ({},{})", 
            scaleX, scaleY, x, y, scaledX, scaledY))
        
        return Map("x", scaledX, "y", scaledY)
        
    } catch as e {
        LogError("CoordinateManager", "Failed to apply resolution scaling: " . e.Message)
        return Map("x", x, "y", y)
    }
}

; キャッシュ付きモニター情報取得
GetCachedMonitorInfo() {
    global g_monitor_info_cache, g_cache_timeout
    
    try {
        currentTime := A_TickCount
        
        ; キャッシュが有効かチェック
        if (g_monitor_info_cache.Has("timestamp") && 
            (currentTime - g_monitor_info_cache["timestamp"]) < g_cache_timeout) {
            LogDebug("CoordinateManager", "Using cached monitor info")
            return g_monitor_info_cache["data"]
        }
        
        ; 新しいモニター情報を取得
        LogDebug("CoordinateManager", "Refreshing monitor info cache")
        monitors := GetDetailedMonitorInfo()
        
        ; 中央モニター（3440x1440）を特定
        centralMonitor := ""
        for monitor in monitors {
            if (monitor.bounds.width == 3440 && monitor.bounds.height == 1440) {
                centralMonitor := monitor
                break
            }
        }
        
        ; 見つからない場合は最大のモニターを選択
        if (!centralMonitor) {
            largestArea := 0
            for monitor in monitors {
                area := monitor.bounds.width * monitor.bounds.height
                if (area > largestArea) {
                    largestArea := area
                    centralMonitor := monitor
                }
            }
        }
        
        if (!centralMonitor) {
            throw Error("No suitable monitor found")
        }
        
        ; モニター情報をMapで構築
        monitorData := Map()
        monitorData["central"] := Map(
            "left", centralMonitor.bounds.left,
            "top", centralMonitor.bounds.top,
            "right", centralMonitor.bounds.right,
            "bottom", centralMonitor.bounds.bottom,
            "width", centralMonitor.bounds.width,
            "height", centralMonitor.bounds.height,
            "centerX", centralMonitor.bounds.left + (centralMonitor.bounds.width // 2),
            "centerY", centralMonitor.bounds.top + (centralMonitor.bounds.height // 2)
        )
        
        ; キャッシュに保存
        g_monitor_info_cache["data"] := monitorData
        g_monitor_info_cache["timestamp"] := currentTime
        
        LogInfo("CoordinateManager", Format("Monitor info cached: {}x{} at {},{}", 
            centralMonitor.bounds.width, centralMonitor.bounds.height, 
            centralMonitor.bounds.left, centralMonitor.bounds.top))
        
        return monitorData
        
    } catch as e {
        LogError("CoordinateManager", "Failed to get monitor info: " . e.Message)
        
        ; フォールバック
        fallbackData := Map()
        fallbackData["central"] := Map(
            "left", 0, "top", 0, "right", A_ScreenWidth, "bottom", A_ScreenHeight,
            "width", A_ScreenWidth, "height", A_ScreenHeight,
            "centerX", A_ScreenWidth // 2, "centerY", A_ScreenHeight // 2
        )
        return fallbackData
    }
}

; プリセット位置を適用
ApplyPreset(presetName) {
    try {
        if (!FLASK_PRESETS.Has(presetName)) {
            throw Error("Unknown preset: " . presetName)
        }
        
        preset := FLASK_PRESETS[presetName]
        monitors := GetCachedMonitorInfo()
        centralMonitor := monitors["central"]
        
        ; 解像度スケーリング適用
        scaledBase := ApplyResolutionScaling(
            preset["baseX"], preset["baseY"],
            centralMonitor["width"], centralMonitor["height"]
        )
        
        scaledSpacing := Round(preset["spacing"] * (centralMonitor["width"] / BASE_RESOLUTION["width"]))
        scaledWidth := Round(preset["width"] * (centralMonitor["width"] / BASE_RESOLUTION["width"]))
        scaledHeight := Round(preset["height"] * (centralMonitor["height"] / BASE_RESOLUTION["height"]))
        
        ; 各フラスコ位置を計算して保存
        savedCount := 0
        Loop 5 {
            flaskNumber := A_Index
            relativeX := scaledBase["x"] + (flaskNumber - 1) * scaledSpacing
            relativeY := scaledBase["y"]
            
            ; 設定に保存
            ConfigManager.Set("VisualDetection", Format("Flask{}X", flaskNumber), relativeX)
            ConfigManager.Set("VisualDetection", Format("Flask{}Y", flaskNumber), relativeY)
            ConfigManager.Set("VisualDetection", Format("Flask{}Width", flaskNumber), scaledWidth)
            ConfigManager.Set("VisualDetection", Format("Flask{}Height", flaskNumber), scaledHeight)
            
            savedCount++
        }
        
        ; 中央モニター情報も保存
        ConfigManager.Set("VisualDetection", "CentralMonitorWidth", centralMonitor["width"])
        ConfigManager.Set("VisualDetection", "CentralMonitorHeight", centralMonitor["height"])
        
        LogInfo("CoordinateManager", Format("Applied preset '{}': {} flasks configured", 
            preset["name"], savedCount))
        
        return savedCount
        
    } catch as e {
        LogError("CoordinateManager", "Failed to apply preset: " . e.Message)
        return 0
    }
}

; カスタムプリセットを保存
SaveCustomPreset(name, description := "") {
    try {
        monitors := GetCachedMonitorInfo()
        centralMonitor := monitors["central"]
        
        ; 現在の設定を読み込み
        positions := []
        Loop 5 {
            flaskNumber := A_Index
            x := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
            y := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
            width := ConfigManager.Get("VisualDetection", Format("Flask{}Width", flaskNumber), 60)
            height := ConfigManager.Get("VisualDetection", Format("Flask{}Height", flaskNumber), 80)
            
            positions.Push(Map("x", x, "y", y, "width", width, "height", height))
        }
        
        ; 最初のフラスコから基準位置を計算
        if (positions.Length > 0 && positions[1]["x"] != 0) {
            baseX := positions[1]["x"]
            baseY := positions[1]["y"]
            spacing := positions.Length > 1 ? positions[2]["x"] - positions[1]["x"] : 80
            
            customPreset := Map(
                "name", name,
                "description", description != "" ? description : "カスタム設定",
                "baseX", baseX,
                "baseY", baseY,
                "spacing", spacing,
                "width", positions[1]["width"],
                "height", positions[1]["height"],
                "created", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
            )
            
            ; カスタムプリセットを保存
            ConfigManager.Set("VisualDetection", "CustomPresetName", name)
            ConfigManager.Set("VisualDetection", "CustomPresetBaseX", baseX)
            ConfigManager.Set("VisualDetection", "CustomPresetBaseY", baseY)
            ConfigManager.Set("VisualDetection", "CustomPresetSpacing", spacing)
            ConfigManager.Set("VisualDetection", "CustomPresetWidth", positions[1]["width"])
            ConfigManager.Set("VisualDetection", "CustomPresetHeight", positions[1]["height"])
            
            LogInfo("CoordinateManager", Format("Custom preset '{}' saved", name))
            return true
        } else {
            throw Error("No flask positions configured to save")
        }
        
    } catch as e {
        LogError("CoordinateManager", "Failed to save custom preset: " . e.Message)
        return false
    }
}

; カスタムプリセットを読み込み
LoadCustomPreset() {
    try {
        name := ConfigManager.Get("VisualDetection", "CustomPresetName", "")
        if (name == "") {
            throw Error("No custom preset found")
        }
        
        baseX := ConfigManager.Get("VisualDetection", "CustomPresetBaseX", 0)
        baseY := ConfigManager.Get("VisualDetection", "CustomPresetBaseY", 0)
        spacing := ConfigManager.Get("VisualDetection", "CustomPresetSpacing", 80)
        width := ConfigManager.Get("VisualDetection", "CustomPresetWidth", 60)
        height := ConfigManager.Get("VisualDetection", "CustomPresetHeight", 80)
        
        if (baseX == 0 && baseY == 0) {
            throw Error("Invalid custom preset data")
        }
        
        ; カスタム設定を適用
        savedCount := 0
        Loop 5 {
            flaskNumber := A_Index
            x := baseX + (flaskNumber - 1) * spacing
            y := baseY
            
            ConfigManager.Set("VisualDetection", Format("Flask{}X", flaskNumber), x)
            ConfigManager.Set("VisualDetection", Format("Flask{}Y", flaskNumber), y)
            ConfigManager.Set("VisualDetection", Format("Flask{}Width", flaskNumber), width)
            ConfigManager.Set("VisualDetection", Format("Flask{}Height", flaskNumber), height)
            
            savedCount++
        }
        
        LogInfo("CoordinateManager", Format("Custom preset '{}' loaded: {} flasks", name, savedCount))
        return savedCount
        
    } catch as e {
        LogError("CoordinateManager", "Failed to load custom preset: " . e.Message)
        return 0
    }
}

; 設定のエクスポート（クリップボード）
ExportSettings() {
    try {
        exportData := []
        exportData.Push("[VisualDetection Flask Settings]")
        exportData.Push("Generated: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"))
        exportData.Push("")
        
        Loop 5 {
            flaskNumber := A_Index
            x := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
            y := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
            width := ConfigManager.Get("VisualDetection", Format("Flask{}Width", flaskNumber), 60)
            height := ConfigManager.Get("VisualDetection", Format("Flask{}Height", flaskNumber), 80)
            
            exportData.Push(Format("Flask{}X={}", flaskNumber, x))
            exportData.Push(Format("Flask{}Y={}", flaskNumber, y))
            exportData.Push(Format("Flask{}Width={}", flaskNumber, width))
            exportData.Push(Format("Flask{}Height={}", flaskNumber, height))
        }
        
        ; モニター情報も追加
        monitors := GetCachedMonitorInfo()
        if (monitors.Has("central")) {
            central := monitors["central"]
            exportData.Push("")
            exportData.Push(Format("CentralMonitorWidth={}", central["width"]))
            exportData.Push(Format("CentralMonitorHeight={}", central["height"]))
        }
        
        ; クリップボードにコピー
        exportText := ""
        for line in exportData {
            exportText .= line . "`n"
        }
        
        A_Clipboard := exportText
        
        LogInfo("CoordinateManager", "Settings exported to clipboard")
        return true
        
    } catch as e {
        LogError("CoordinateManager", "Failed to export settings: " . e.Message)
        return false
    }
}

; 設定のインポート（Config.iniから再読み込み）
ImportSettings() {
    try {
        ; ConfigManagerに再読み込みを要求
        ; これによりConfig.iniから最新の設定が読み込まれる
        
        importedCount := 0
        Loop 5 {
            flaskNumber := A_Index
            x := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
            y := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
            
            if (x != 0 || y != 0) {
                importedCount++
            }
        }
        
        LogInfo("CoordinateManager", Format("Settings imported: {} flasks configured", importedCount))
        return importedCount
        
    } catch as e {
        LogError("CoordinateManager", "Failed to import settings: " . e.Message)
        return 0
    }
}

; 座標の妥当性チェック
ValidateCoordinates(x, y, width, height) {
    try {
        monitors := GetCachedMonitorInfo()
        if (!monitors.Has("central")) {
            return false
        }
        
        central := monitors["central"]
        
        ; 境界チェック
        if (x - width/2 < central["left"] || 
            x + width/2 > central["right"] ||
            y - height/2 < central["top"] ||
            y + height/2 > central["bottom"]) {
            return false
        }
        
        return true
        
    } catch as e {
        LogError("CoordinateManager", "Failed to validate coordinates: " . e.Message)
        return false
    }
}

; キャッシュクリア
ClearCoordinateCache() {
    global g_monitor_info_cache, g_coordinate_cache
    
    g_monitor_info_cache.Clear()
    g_coordinate_cache.Clear()
    
    LogDebug("CoordinateManager", "Coordinate cache cleared")
}