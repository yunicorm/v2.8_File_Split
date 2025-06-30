; VisualDetection.ahk
; Visual detection system for Flask charge monitoring using FindText
; Provides wrapper functions for FindText integration with error handling

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
global g_flask_rect_width := 60
global g_flask_rect_height := 100

; 複数フラスコオーバーレイ管理
global g_flask_overlay_guis := []
global g_flask_spacing := 20

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
        LogInfo("VisualDetection", "Initializing default visual detection configuration")
        
        ; Default configuration values for [VisualDetection] section
        defaults := Map(
            "Enabled", "false",
            "DetectionMode", "Timer",
            "Flask1X", "0",
            "Flask1Y", "0", 
            "Flask1ChargedPattern", "",
            "Flask2X", "0",
            "Flask2Y", "0",
            "Flask2ChargedPattern", "",
            "Flask3X", "0", 
            "Flask3Y", "0",
            "Flask3ChargedPattern", "",
            "Flask4X", "0",
            "Flask4Y", "0", 
            "Flask4ChargedPattern", "",
            "Flask5X", "0",
            "Flask5Y", "0",
            "Flask5ChargedPattern", "",
            "DetectionTimeout", "1000",
            "SearchAreaSize", "25",
            "DetectionInterval", "100",
            ; 拡張設定項目
            "ShowDetectionOverlay", "false",
            "OverlayDuration", "2000",
            "DebugMode", "false",
            "Flask1Name", "Life Flask",
            "Flask2Name", "Mana Flask",
            "Flask3Name", "Utility Flask 1",
            "Flask4Name", "Utility Flask 2",
            "Flask5Name", "Unique Flask"
        )
        
        ; Set defaults if section doesn't exist
        for key, value in defaults {
            if (!ConfigManager.HasKey("VisualDetection", key)) {
                ConfigManager.Set("VisualDetection", key, value)
                LogDebug("VisualDetection", "Set default " . key . " = " . value)
            }
        }
        
        LogInfo("VisualDetection", "Default configuration initialized successfully")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to initialize default config: " . e.Message)
        return false
    }
}

; Initialize visual detection system
InitializeVisualDetection() {
    try {
        LogInfo("VisualDetection", "Initializing visual detection system")
        
        ; Check if FindText.ahk exists first
        if (!CheckFindTextFile()) {
            LogError("VisualDetection", "FindText.ahk not available, visual detection disabled")
            g_visual_detection_state["enabled"] := false
            return false
        }
        
        ; Initialize default config first
        InitializeDefaultVisualDetectionConfig()
        
        ; Get configuration
        g_visual_detection_state["enabled"] := ConfigManager.Get("VisualDetection", "Enabled", false)
        g_visual_detection_state["detection_mode"] := ConfigManager.Get("VisualDetection", "DetectionMode", "Timer")
        g_visual_detection_state["detection_interval"] := ConfigManager.Get("VisualDetection", "DetectionInterval", 100)
        
        ; Initialize FindText instance if enabled
        if (g_visual_detection_state["enabled"]) {
            try {
                g_visual_detection_state["findtext_instance"] := FindText()
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
        g_visual_detection_state["enabled"] := false
        return false
    }
}

; Check if visual detection is available and enabled
IsVisualDetectionEnabled() {
    return g_visual_detection_state["enabled"] && g_visual_detection_state["findtext_instance"] != ""
}

; Detect flask charge status visually
; Returns: 1 if flask has charges, 0 if empty, -1 if detection failed
DetectFlaskCharge(flaskNumber) {
    if (!IsVisualDetectionEnabled()) {
        LogDebug("VisualDetection", "Visual detection not enabled, skipping detection")
        return -1
    }
    
    ; Check detection interval
    if (!CanPerformDetection()) {
        return -1  ; Too soon since last detection
    }
    
    try {
        ; Update last detection time
        g_visual_detection_state["last_detection_time"] := A_TickCount
        
        ; Get flask position from config
        xPos := ConfigManager.Get("VisualDetection", "Flask" . flaskNumber . "X", 0)
        yPos := ConfigManager.Get("VisualDetection", "Flask" . flaskNumber . "Y", 0)
        
        if (xPos == 0 || yPos == 0) {
            LogError("VisualDetection", "Flask" . flaskNumber . " position not configured")
            return -1
        }
        
        ; Get search area size from config
        searchSize := ConfigManager.Get("VisualDetection", "SearchAreaSize", 25)
        
        ; Define search area around flask position
        searchArea := Map(
            "left", xPos - searchSize,
            "top", yPos - searchSize,
            "right", xPos + searchSize,
            "bottom", yPos + searchSize
        )
        
        ; Check if flask has charges
        result := DetectFlaskChargeInternal(searchArea, flaskNumber)
        
        ; Store result for debugging
        g_visual_detection_state["detection_results"][flaskNumber] := Map(
            "result", result,
            "timestamp", A_TickCount,
            "position", Map("x", xPos, "y", yPos)
        )
        
        LogDebug("VisualDetection", "Flask" . flaskNumber . " charge detection result: " . result)
        return result
        
    } catch as e {
        LogError("VisualDetection", "Flask charge detection failed for Flask" . flaskNumber . ": " . e.Message)
        return -1
    }
}

; Internal function to perform actual charge detection using FindText
DetectFlaskChargeInternal(searchArea, flaskNumber) {
    try {
        LogDebug("VisualDetection", "Attempting charge detection in area: " . 
                 searchArea["left"] . "," . searchArea["top"] . " to " . 
                 searchArea["right"] . "," . searchArea["bottom"])
        
        ; Get FindText instance
        ft := g_visual_detection_state["findtext_instance"]
        if (ft == "") {
            LogError("VisualDetection", "FindText instance not available")
            return -1
        }
        
        ; Get charged pattern for this flask
        chargedPattern := ConfigManager.Get("VisualDetection", 
            "Flask" . flaskNumber . "ChargedPattern", "")
        
        if (chargedPattern == "") {
            LogDebug("VisualDetection", "No charged pattern configured for Flask" . flaskNumber)
            return -1
        }
        
        ; Perform FindText search for charged pattern
        x := 0, y := 0
        if (ft.FindText(&x, &y, 
            searchArea["left"], searchArea["top"], 
            searchArea["right"], searchArea["bottom"], 
            0, 0, chargedPattern)) {
            
            LogDebug("VisualDetection", "Flask" . flaskNumber . " charged pattern found at " . x . "," . y)
            result := 1  ; チャージあり

            ; デバッグオーバーレイ表示
            if (ConfigManager.Get("VisualDetection", "ShowDetectionOverlay", false)) {
                ShowOverlay(Format("Flask{}: {}", flaskNumber, "Charged"),
                    ConfigManager.Get("VisualDetection", "OverlayDuration", 2000))
            }

            return result
        }
        
        LogDebug("VisualDetection", "Flask" . flaskNumber . " charged pattern not found")
        result := 0  ; 空の状態
        
        ; デバッグオーバーレイ表示
        if (ConfigManager.Get("VisualDetection", "ShowDetectionOverlay", false)) {
            ShowOverlay(Format("Flask{}: {}", flaskNumber, "Empty"), 
                ConfigManager.Get("VisualDetection", "OverlayDuration", 2000))
        }
        
        return result
        
    } catch as e {
        LogError("VisualDetection", "Internal detection error: " . e.Message)
        result := -1
        
        ; デバッグオーバーレイ表示
        if (ConfigManager.Get("VisualDetection", "ShowDetectionOverlay", false)) {
            ShowOverlay(Format("Flask{}: {}", flaskNumber, "Failed"), 
                ConfigManager.Get("VisualDetection", "OverlayDuration", 2000))
        }
        
        return result
    }
}

; Get detection mode for flask system
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

; Test visual detection for a specific flask
TestFlaskDetection(flaskNumber) {
    if (!IsVisualDetectionEnabled()) {
        LogInfo("VisualDetection", "Visual detection not enabled - cannot test")
        return false
    }
    
    try {
        LogInfo("VisualDetection", "Testing detection for Flask" . flaskNumber)
        
        ; Perform detection
        result := DetectFlaskCharge(flaskNumber)
        
        ; Log result
        switch result {
            case 1:
                LogInfo("VisualDetection", "Flask" . flaskNumber . " test result: HAS CHARGES")
            case 0:
                LogInfo("VisualDetection", "Flask" . flaskNumber . " test result: EMPTY")
            case -1:
                LogInfo("VisualDetection", "Flask" . flaskNumber . " test result: DETECTION FAILED")
        }
        
        return result != -1
        
    } catch as e {
        LogError("VisualDetection", "Test detection failed: " . e.Message)
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
        
        LogInfo("VisualDetection", "Visual detection cleanup completed")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Cleanup failed: " . e.Message)
        return false
    }
}

; サイズ変更用ヘルパー関数（グローバル）
ResizeWithLog(dw, dh, key) {
    LogDebug("VisualDetection", key . " key pressed")
    ResizeOverlay(dw, dh)
}

; フラスコ座標取得開始
StartFlaskPositionCapture() {
    global g_current_flask_index
    
    ShowOverlay("矢印:移動 +/-:間隔 =/- :サイズ Space:保存", 3000)
    g_current_flask_index := 1
    CreateAllFlaskOverlays(1720, 1300)
    
    ; ホットキー設定
    LogDebug("VisualDetection", "Setting up hotkeys for flask position capture")
    Hotkey("Up", (*) => MoveAllOverlays(0, -10), "On")
    Hotkey("Down", (*) => MoveAllOverlays(0, 10), "On")
    Hotkey("Left", (*) => MoveAllOverlays(-10, 0), "On")
    Hotkey("Right", (*) => MoveAllOverlays(10, 0), "On")
    Hotkey("Space", (*) => SaveAllFlaskPositions(), "On")  ; 一括保存
    Hotkey("Enter", (*) => SaveFlaskPosition(), "On")      ; 個別保存（念のため残す）
    Hotkey("Tab", (*) => NextFlask(), "On")
    Hotkey("Escape", (*) => EndOverlayCapture(), "On")
    LogDebug("VisualDetection", "Movement and control hotkeys set")
    
    ; サイズ変更（一括操作版）
    Hotkey("=", (*) => ResizeAllOverlays(5, 5), "On")      ; 全体拡大
    LogDebug("VisualDetection", "Hotkey '=' set for all overlays resize +5,+5")
    Hotkey("-", (*) => ResizeAllOverlays(-5, -5), "On")    ; 全体縮小
    LogDebug("VisualDetection", "Hotkey '-' set for all overlays resize -5,-5")
    Hotkey("]", (*) => ResizeAllOverlays(10, 0), "On")     ; 幅拡大
    LogDebug("VisualDetection", "Hotkey ']' set for all overlays width +10")
    Hotkey("[", (*) => ResizeAllOverlays(-10, 0), "On")    ; 幅縮小
    LogDebug("VisualDetection", "Hotkey '[' set for all overlays width -10")
    Hotkey("'", (*) => ResizeAllOverlays(0, 10), "On")     ; 高さ拡大
    LogDebug("VisualDetection", "Hotkey ''' set for all overlays height +10")
    Hotkey(";", (*) => ResizeAllOverlays(0, -10), "On")    ; 高さ縮小
    LogDebug("VisualDetection", "Hotkey ';' set for all overlays height -10")
    LogDebug("VisualDetection", "All resize hotkeys configured successfully")
    
    ; 間隔調整
    Hotkey("+", (*) => AdjustFlaskSpacing(2), "On")    ; 5→2に変更
    Hotkey("_", (*) => AdjustFlaskSpacing(-2), "On")   ; -5→-2に変更
    LogDebug("VisualDetection", "Flask spacing hotkeys set")
}

; オーバーレイ作成
CreateFlaskOverlay(x, y) {
    global g_flask_overlay_gui, g_flask_rect_width, g_flask_rect_height
    
    LogDebug("VisualDetection", Format("CreateFlaskOverlay called: x={}, y={}, size={}x{}", x, y, g_flask_rect_width, g_flask_rect_height))
    
    if (g_flask_overlay_gui) {
        LogDebug("VisualDetection", "Destroying existing overlay GUI")
        g_flask_overlay_gui.Destroy()
    }
    
    g_flask_overlay_gui := Gui()
    g_flask_overlay_gui.Opt("+AlwaysOnTop -Caption +ToolWindow")
    g_flask_overlay_gui.BackColor := "Red"
    g_flask_overlay_gui.Show(Format("x{} y{} w{} h{} NA", 
        x, y, g_flask_rect_width, g_flask_rect_height))
    WinSetTransparent(100, g_flask_overlay_gui)
    
    LogDebug("VisualDetection", Format("Flask overlay created successfully at {},{} with size {}x{}", x, y, g_flask_rect_width, g_flask_rect_height))
}

; 複数フラスコオーバーレイ一括作成
CreateAllFlaskOverlays(startX, startY) {
    global g_flask_overlay_guis, g_flask_rect_width, g_flask_rect_height, g_flask_spacing
    
    LogDebug("VisualDetection", Format("Creating all flask overlays starting at {},{}", startX, startY))
    
    ; 既存のオーバーレイをクリア
    for existingGui in g_flask_overlay_guis {
        if (existingGui) {
            existingGui.Destroy()
        }
    }
    g_flask_overlay_guis := []
    
    Loop 5 {
        x := startX + (A_Index - 1) * (g_flask_rect_width + g_flask_spacing)
        newGui := Gui()  ; 変数名を変更
        newGui.Opt("+AlwaysOnTop -Caption +ToolWindow")
        newGui.BackColor := "Red"
        newGui.Show(Format("x{} y{} w{} h{} NA", x, startY, g_flask_rect_width, g_flask_rect_height))
        WinSetTransparent(100, newGui)
        g_flask_overlay_guis.Push(newGui)
        
        LogDebug("VisualDetection", Format("Flask{} overlay created at {},{}", A_Index, x, startY))
    }
    
    LogDebug("VisualDetection", "All flask overlays created successfully")
}

; 移動
MoveOverlay(dx, dy) {
    global g_flask_overlay_gui
    if (!g_flask_overlay_gui || g_flask_overlay_gui == "") {
        return
    }
    
    g_flask_overlay_gui.GetPos(&x, &y)
    g_flask_overlay_gui.Move(x + dx, y + dy)
}

; 全オーバーレイ一括移動
MoveAllOverlays(dx, dy) {
    global g_flask_overlay_guis
    
    LogDebug("VisualDetection", Format("Moving all overlays by dx={}, dy={}", dx, dy))
    
    for gui in g_flask_overlay_guis {
        if (gui) {
            gui.GetPos(&x, &y)
            gui.Move(x + dx, y + dy)
            LogDebug("VisualDetection", Format("Moved overlay to {},{}", x + dx, y + dy))
        }
    }
}

; サイズ変更
ResizeOverlay(dw, dh) {
    global g_flask_overlay_gui, g_flask_rect_width, g_flask_rect_height
    LogDebug("VisualDetection", Format("ResizeOverlay called: dw={}, dh={}", dw, dh))
    
    if (!g_flask_overlay_gui) {
        LogDebug("VisualDetection", "ResizeOverlay: No overlay GUI exists")
        return
    }
    
    ; 最小20ピクセル
    old_width := g_flask_rect_width
    old_height := g_flask_rect_height
    g_flask_rect_width := Max(20, g_flask_rect_width + dw)
    g_flask_rect_height := Max(20, g_flask_rect_height + dh)
    
    LogDebug("VisualDetection", Format("Size changed: {}x{} -> {}x{}", old_width, old_height, g_flask_rect_width, g_flask_rect_height))
    
    ; 再作成
    g_flask_overlay_gui.GetPos(&x, &y)
    LogDebug("VisualDetection", Format("Recreating overlay at: {}, {}", x, y))
    CreateFlaskOverlay(x, y)
    
    ; サイズ表示
    ToolTip(Format("Size: {}x{}", g_flask_rect_width, g_flask_rect_height))
    SetTimer(() => ToolTip(), -1000)
}

; 全オーバーレイ一括サイズ変更
ResizeAllOverlays(dw, dh) {
    global g_flask_overlay_guis, g_flask_rect_width, g_flask_rect_height
    
    LogDebug("VisualDetection", Format("Resizing all overlays: dw={}, dh={}", dw, dh))
    
    ; サイズ更新（最小20ピクセル）
    old_width := g_flask_rect_width
    old_height := g_flask_rect_height
    g_flask_rect_width := Max(20, g_flask_rect_width + dw)
    g_flask_rect_height := Max(20, g_flask_rect_height + dh)
    
    LogDebug("VisualDetection", Format("Size changed: {}x{} -> {}x{}", old_width, old_height, g_flask_rect_width, g_flask_rect_height))
    
    ; 最初のオーバーレイの位置を基準に再作成
    if (g_flask_overlay_guis.Length > 0 && g_flask_overlay_guis[1]) {
        g_flask_overlay_guis[1].GetPos(&startX, &startY)
        LogDebug("VisualDetection", Format("Recreating all overlays from position {},{}", startX, startY))
        CreateAllFlaskOverlays(startX, startY)
        
        ; サイズ表示
        ToolTip(Format("All Flasks: {}x{}", g_flask_rect_width, g_flask_rect_height))
        SetTimer(() => ToolTip(), -1000)
    }
}

; フラスコ間隔調整
AdjustFlaskSpacing(delta) {
    global g_flask_spacing, g_flask_overlay_guis
    
    LogDebug("VisualDetection", Format("Adjusting flask spacing by delta={}", delta))
    
    ; 間隔更新（最小5ピクセル）
    old_spacing := g_flask_spacing
    g_flask_spacing := Max(5, g_flask_spacing + delta)
    
    LogDebug("VisualDetection", Format("Spacing changed: {} -> {}", old_spacing, g_flask_spacing))
    
    ; 最初のオーバーレイの位置を基準に再配置
    if (g_flask_overlay_guis.Length > 0 && g_flask_overlay_guis[1]) {
        g_flask_overlay_guis[1].GetPos(&startX, &startY)
        LogDebug("VisualDetection", Format("Recreating all overlays with new spacing from {},{}", startX, startY))
        CreateAllFlaskOverlays(startX, startY)
        
        ; 間隔表示
        ToolTip(Format("Flask Spacing: {} pixels", g_flask_spacing))
        SetTimer(() => ToolTip(), -1000)
    }
}

; 位置保存
SaveFlaskPosition() {
    global g_flask_overlay_gui, g_current_flask_index
    if (!g_flask_overlay_gui || g_flask_overlay_gui == "") {
        return
    }
    
    g_flask_overlay_gui.GetPos(&x, &y, &w, &h)
    centerX := x + w // 2
    centerY := y + h // 2
    
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "X", centerX)
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "Y", centerY)
    
    ShowOverlay(Format("Flask{} 保存", g_current_flask_index), 1500)
}

; 全フラスコ位置一括保存
SaveAllFlaskPositions() {
    global g_flask_overlay_guis
    
    LogDebug("VisualDetection", "Starting to save all flask positions")
    
    if (g_flask_overlay_guis.Length != 5) {
        LogError("VisualDetection", Format("Invalid overlay count: {} (expected 5)", g_flask_overlay_guis.Length))
        ShowOverlay("エラー: 5つのオーバーレイが必要です", 2000)
        return
    }
    
    successCount := 0
    Loop 5 {
        gui := g_flask_overlay_guis[A_Index]
        if (gui) {
            gui.GetPos(&x, &y, &w, &h)
            centerX := x + w // 2
            centerY := y + h // 2
            
            ConfigManager.Set("VisualDetection", "Flask" . A_Index . "X", centerX)
            ConfigManager.Set("VisualDetection", "Flask" . A_Index . "Y", centerY)
            
            LogDebug("VisualDetection", Format("Flask{} saved at center: {},{}", A_Index, centerX, centerY))
            successCount++
        } else {
            LogError("VisualDetection", Format("Flask{} overlay is invalid", A_Index))
        }
    }
    
    if (successCount == 5) {
        ShowOverlay("全フラスコ位置を保存しました", 2000)
        LogInfo("VisualDetection", "All flask positions saved successfully")
    } else {
        ShowOverlay(Format("警告: {}/5 フラスコのみ保存", successCount), 2000)
        LogWarn("VisualDetection", Format("Only {}/5 flask positions saved", successCount))
    }
}

; 次へ
NextFlask() {
    global g_current_flask_index
    g_current_flask_index++
    if (g_current_flask_index > 5) {
        EndOverlayCapture()
    }
}

; マウス位置表示
ShowMousePosition() {
    MouseGetPos(&x, &y)
    ToolTip(Format("X: {} Y: {}", x, y))
}

; フラスコ位置をキャプチャ
CaptureFlaskPosition(flaskNumber) {
    MouseGetPos(&x, &y)
    
    ; Config.iniに座標を保存
    ConfigManager.Set("VisualDetection", "Flask" . flaskNumber . "X", x)
    ConfigManager.Set("VisualDetection", "Flask" . flaskNumber . "Y", y)
    
    ; フラスコ名を取得
    flaskName := ConfigManager.Get("VisualDetection", "Flask" . flaskNumber . "Name", "Flask" . flaskNumber)
    
    ShowOverlay(Format("{} 位置保存: {}, {}", flaskName, x, y), 1500)
    LogInfo("VisualDetection", Format("Flask{} position captured: {}, {}", flaskNumber, x, y))
}

; 終了
EndOverlayCapture(*) {
    global g_flask_overlay_gui
    if (g_flask_overlay_gui) {
        g_flask_overlay_gui.Destroy()
        g_flask_overlay_gui := ""
    }
    
    ; ホットキー無効化
    for key in ["Up","Down","Left","Right","Space","Enter","Tab","Escape",
               "=","-","]","[","'",";","+","_"] {
        try Hotkey(key, "Off")
    }
    
    ShowOverlay("設定完了", 1500)
    LogInfo("VisualDetection", "Flask overlay capture ended")
}

; Test visual detection for all flasks
TestAllFlaskDetection() {
    if (!IsVisualDetectionEnabled()) {
        LogInfo("VisualDetection", "Visual detection not enabled - cannot test all flasks")
        ShowOverlay("Visual Detection is disabled", 2000)
        return false
    }
    
    try {
        LogInfo("VisualDetection", "Testing visual detection for all flasks")
        ShowOverlay("Testing all flask detection...", 1000)
        
        results := []
        successCount := 0
        
        ; Test each flask
        Loop 5 {
            flaskNumber := A_Index
            result := TestFlaskDetection(flaskNumber)
            
            if (result) {
                successCount++
                ; Get the actual detection result for display
                chargeStatus := DetectFlaskCharge(flaskNumber)
                switch chargeStatus {
                    case 1:
                        status := "HAS CHARGES"
                    case 0:
                        status := "EMPTY"
                    case -1:
                        status := "FAILED"
                }
                results.Push(Format("Flask{}: {}", flaskNumber, status))
            } else {
                results.Push(Format("Flask{}: TEST FAILED", flaskNumber))
            }
        }
        
        ; Display results
        results.InsertAt(1, "=== Flask Detection Test Results ===")
        results.Push("")
        results.Push(Format("Success: {}/5 flasks", successCount))
        
        ShowMultiLineOverlay(results, 5000)
        LogInfo("VisualDetection", Format("All flask test completed: {}/5 successful", successCount))
        
        return successCount > 0
        
    } catch as e {
        LogError("VisualDetection", "Test all flasks failed: " . e.Message)
        ShowOverlay("Flask detection test failed", 2000)
        return false
    }
}