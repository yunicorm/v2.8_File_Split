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
global g_flask_rect_width := 80   ; 60→80（画像の幅に合わせて）
global g_flask_rect_height := 120 ; 100→120（画像の高さに合わせて）

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
        LogInfo("VisualDetection", "Checking visual detection configuration")
        
        ; デフォルト値のマップ
        defaults := Map(
            "Enabled", "false",
            "DetectionMode", "Timer",
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
            "Flask5X", "0",
            "Flask5Y", "0",
            "Flask5Width", "80",
            "Flask5Height", "120",
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
            "Flask4Name", "Wine of the Prophet",
            "Flask5Name", "Unique Flask",
            ; Wine of the Prophet 高精度検出設定
            "WineChargeDetectionEnabled", "false",
            "WineMaxCharge", "140",
            "WineChargePerUse", "72",
            "WineGoldR", "255",
            "WineGoldG", "215",
            "WineGoldB", "0",
            "WineColorTolerance", "30",
            "WineSamplingRate", "3",
            "WineRecheckDelay", "5000"
        )
        
        ; 既存の値がない場合のみ設定
        for key, value in defaults {
            ; ConfigManager.Get()でデフォルト値チェック用の特別な値を使用
            existingValue := ConfigManager.Get("VisualDetection", key, "___DEFAULT___")
            
            if (existingValue == "___DEFAULT___") {
                ; 設定が存在しない場合のみデフォルト値を設定
                ConfigManager.Set("VisualDetection", key, value)
                LogDebug("VisualDetection", "Set default " . key . " = " . value)
            } else {
                ; 既存の値を保持（空文字列や0も有効な設定値として扱う）
                ; 特に、trueに設定された値をfalseで上書きしない
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
        
        ; Check if FindText.ahk exists first
        if (!CheckFindTextFile()) {
            LogError("VisualDetection", "FindText.ahk not available, visual detection disabled")
            g_visual_detection_state["enabled"] := false
            return false
        }
        
        ; Initialize default config first
        InitializeDefaultVisualDetectionConfig()
        
        ; Get configuration
        enabledStr := ConfigManager.Get("VisualDetection", "Enabled", "false")
        g_visual_detection_state["enabled"] := (enabledStr == "true" || enabledStr == "1" || enabledStr == 1)
        g_visual_detection_state["detection_mode"] := ConfigManager.Get("VisualDetection", "DetectionMode", "Timer")
        g_visual_detection_state["detection_interval"] := ConfigManager.Get("VisualDetection", "DetectionInterval", 100)
        
        ; デバッグ情報を追加
        LogDebug("VisualDetection", "Enabled String from Config: " . enabledStr)
        LogDebug("VisualDetection", "g_visual_detection_state enabled: " . g_visual_detection_state["enabled"])
        
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
        
        ; Get flask position and dimensions from config
        centerX := ConfigManager.Get("VisualDetection", "Flask" . flaskNumber . "X", 0)
        centerY := ConfigManager.Get("VisualDetection", "Flask" . flaskNumber . "Y", 0)
        width := ConfigManager.Get("VisualDetection", "Flask" . flaskNumber . "Width", 80)
        height := ConfigManager.Get("VisualDetection", "Flask" . flaskNumber . "Height", 120)
        
        if (centerX == 0 || centerY == 0) {
            LogError("VisualDetection", "Flask" . flaskNumber . " position not configured")
            return -1
        }
        
        ; Calculate charge detection area (upper 1/3 of flask)
        searchArea := CalculateChargeDetectionArea(centerX, centerY, width, height)
        
        if (searchArea.Count == 0) {
            LogError("VisualDetection", "Failed to calculate search area for Flask" . flaskNumber)
            return -1
        }
        
        ; Check if flask has charges
        result := DetectFlaskChargeInternal(searchArea, flaskNumber)
        
        ; Store result for debugging
        g_visual_detection_state["detection_results"][flaskNumber] := Map(
            "result", result,
            "timestamp", A_TickCount,
            "position", Map("x", centerX, "y", centerY),
            "dimensions", Map("width", width, "height", height),
            "search_area", searchArea
        )
        
        LogDebug("VisualDetection", "Flask" . flaskNumber . " charge detection result: " . result)
        return result
        
    } catch as e {
        LogError("VisualDetection", "Flask charge detection failed for Flask" . flaskNumber . ": " . e.Message)
        return -1
    }
}

; Calculate charge detection area (upper 60% of flask - liquid part)
CalculateChargeDetectionArea(centerX, centerY, width, height) {
    try {
        halfWidth := width // 2
        halfHeight := height // 2
        
        ; チャージ検出エリア（液体部分：上部60%、枠を除外）
        chargeArea := Map(
            "left", centerX - halfWidth + 5,    ; 枠を除外
            "top", centerY - halfHeight + 5,     
            "right", centerX + halfWidth - 5,
            "bottom", centerY - height // 6    ; 上部60%まで
        )
        
        LogDebug("VisualDetection", Format("Charge area calculated (liquid 60%): {},{} to {},{}", 
            chargeArea["left"], chargeArea["top"], chargeArea["right"], chargeArea["bottom"]))
        
        return chargeArea
        
    } catch as e {
        LogError("VisualDetection", "Failed to calculate charge detection area: " . e.Message)
        return Map()
    }
}

; Calculate progress bar detection area (lower 20% of flask - bar part)
CalculateProgressDetectionArea(centerX, centerY, width, height) {
    try {
        halfWidth := width // 2
        halfHeight := height // 2
        
        ; プログレスバー検出エリア（下部20%、装飾部分を除外）
        progressArea := Map(
            "left", centerX - halfWidth + 5,
            "top", centerY + height // 3,          ; 下部1/3から開始
            "right", centerX + halfWidth - 5,
            "bottom", centerY + halfHeight - 5     ; 下端から少し上
        )
        
        LogDebug("VisualDetection", Format("Progress area calculated (bar 20%): {},{} to {},{}", 
            progressArea["left"], progressArea["top"], progressArea["right"], progressArea["bottom"]))
        
        return progressArea
        
    } catch as e {
        LogError("VisualDetection", "Failed to calculate progress detection area: " . e.Message)
        return Map()
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
    
    ; 中心座標を保存
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "X", centerX)
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "Y", centerY)
    
    ; 幅と高さを保存
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "Width", w)
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "Height", h)
    
    ShowOverlay(Format("Flask{} 位置・サイズ保存", g_current_flask_index), 1500)
}

; 全フラスコ位置一括保存
SaveAllFlaskPositions() {
    global g_flask_overlay_guis
    
    LogDebug("VisualDetection", "Starting to save all flask positions with dimensions")
    
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
            
            ; 中心座標を保存
            ConfigManager.Set("VisualDetection", "Flask" . A_Index . "X", centerX)
            ConfigManager.Set("VisualDetection", "Flask" . A_Index . "Y", centerY)
            
            ; 幅と高さを保存
            ConfigManager.Set("VisualDetection", "Flask" . A_Index . "Width", w)
            ConfigManager.Set("VisualDetection", "Flask" . A_Index . "Height", h)
            
            LogDebug("VisualDetection", Format("Flask{} saved: center={},{}, size={}x{}", A_Index, centerX, centerY, w, h))
            successCount++
        } else {
            LogError("VisualDetection", Format("Flask{} overlay is invalid", A_Index))
        }
    }
    
    if (successCount == 5) {
        ShowOverlay("全フラスコ位置・サイズを保存しました", 2000)
        LogInfo("VisualDetection", "All flask positions and dimensions saved successfully")
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
    global g_flask_overlay_gui, g_flask_overlay_guis
    
    ; 単一オーバーレイを閉じる（旧方式）
    if (g_flask_overlay_gui && g_flask_overlay_gui != "") {
        try {
            g_flask_overlay_gui.Destroy()
        } catch {
            ; 既に閉じられている場合は無視
        }
        g_flask_overlay_gui := ""
    }
    
    ; 複数オーバーレイを閉じる（新方式）
    if (g_flask_overlay_guis.Length > 0) {
        for gui in g_flask_overlay_guis {
            if (gui) {
                try {
                    gui.Destroy()
                } catch {
                    ; 既に閉じられている場合は無視
                }
            }
        }
        g_flask_overlay_guis := []  ; 配列をクリア
    }
    
    ; ホットキー無効化
    for key in ["Up","Down","Left","Right","Space","Enter","Tab","Escape",
               "=","-","]","[","'",";","+","_"] {
        try Hotkey(key, "Off")
    }
    
    ShowOverlay("座標設定モード終了", 1500)
    LogInfo("VisualDetection", "Overlay capture mode ended")
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

; ===================================================================
; フラスコパターンキャプチャ機能 (v2.9.4)
; ===================================================================

; パターンキャプチャモード状態管理
global g_pattern_capture_state := Map(
    "active", false,
    "current_flask", 1,
    "capture_gui", "",
    "instruction_gui", ""
)

; フラスコパターンキャプチャ開始
StartFlaskPatternCapture() {
    try {
        LogInfo("VisualDetection", "Starting flask pattern capture mode")
        
        ; 既にアクティブな場合は終了
        if (g_pattern_capture_state["active"]) {
            StopFlaskPatternCapture()
            return
        }
        
        ; FindText.ahkの存在確認
        if (!CheckFindTextFile()) {
            ShowOverlay("FindText.ahkが見つかりません", 3000)
            LogError("VisualDetection", "Cannot start pattern capture: FindText.ahk not found")
            return
        }
        
        ; キャプチャモード開始
        g_pattern_capture_state["active"] := true
        g_pattern_capture_state["current_flask"] := 1
        
        ; 操作ガイドを表示
        ShowPatternCaptureInstructions()
        
        ; Flask1から開始
        StartSingleFlaskCapture(1)
        
        LogInfo("VisualDetection", "Pattern capture mode started successfully")
        
    } catch as e {
        LogError("VisualDetection", "Failed to start pattern capture: " . e.Message)
        ShowOverlay("パターンキャプチャ開始に失敗", 2000)
    }
}

; パターンキャプチャモード終了
StopFlaskPatternCapture() {
    try {
        LogInfo("VisualDetection", "Stopping flask pattern capture mode")
        
        g_pattern_capture_state["active"] := false
        
        ; ガイドGUIを閉じる
        if (g_pattern_capture_state["instruction_gui"]) {
            try {
                g_pattern_capture_state["instruction_gui"].Close()
            } catch {
                ; GUI が既に閉じられている場合は無視
            }
            g_pattern_capture_state["instruction_gui"] := ""
        }
        
        ; キャプチャGUIを閉じる
        if (g_pattern_capture_state["capture_gui"]) {
            try {
                g_pattern_capture_state["capture_gui"].Close()
            } catch {
                ; GUI が既に閉じられている場合は無視
            }
            g_pattern_capture_state["capture_gui"] := ""
        }
        
        ShowOverlay("パターンキャプチャモード終了", 2000)
        LogInfo("VisualDetection", "Pattern capture mode stopped")
        
    } catch as e {
        LogError("VisualDetection", "Error stopping pattern capture: " . e.Message)
    }
}

; 操作ガイド表示
ShowPatternCaptureInstructions() {
    try {
        ; 既存のガイドGUIを閉じる
        if (g_pattern_capture_state["instruction_gui"]) {
            try {
                g_pattern_capture_state["instruction_gui"].Close()
            } catch {
                ; GUI が既に閉じられている場合は無視
            }
        }
        
        ; 新しいガイドGUIを作成
        instructionGui := Gui("+AlwaysOnTop +ToolWindow", "フラスコパターンキャプチャ - 操作ガイド")
        instructionGui.BackColor := "0x1E1E1E"
        instructionGui.MarginX := 15
        instructionGui.MarginY := 15
        
        ; タイトル
        instructionGui.SetFont("s14 Bold", "Segoe UI")
        instructionGui.Add("Text", "cWhite w400 Center", "フラスコパターンキャプチャモード")
        
        ; 説明テキスト
        instructionGui.SetFont("s10", "Segoe UI")
        instructionGui.Add("Text", "cWhite w400 xm y+10", 
            "各フラスコのチャージ状態パターンをキャプチャします。`n" .
            "チャージありの状態でキャプチャしてください。")
        
        ; 操作方法
        instructionGui.SetFont("s10 Bold", "Segoe UI")
        instructionGui.Add("Text", "cYellow w400 xm y+15", "操作方法:")
        
        instructionGui.SetFont("s9", "Segoe UI")
        instructions := [
            "• 数字キー 1-5: 対象フラスコを選択",
            "• Enter: 選択したフラスコのパターンをキャプチャ",
            "• Space: 全フラスコのパターンを順次キャプチャ",
            "• F10: キャプチャモード終了",
            "• Escape: キャプチャモード終了"
        ]
        
        for instruction in instructions {
            instructionGui.Add("Text", "cWhite w400 xm y+3", instruction)
        }
        
        ; 現在の状態
        instructionGui.SetFont("s10 Bold", "Segoe UI")
        instructionGui.Add("Text", "cLime w400 xm y+15", 
            Format("現在: Flask{} のパターンキャプチャ待機中", g_pattern_capture_state["current_flask"]))
        
        ; GUIを表示（右上に配置）
        instructionGui.Show("x" . (A_ScreenWidth - 450) . " y50 w430 h280")
        g_pattern_capture_state["instruction_gui"] := instructionGui
        
        LogDebug("VisualDetection", "Pattern capture instructions displayed")
        
    } catch as e {
        LogError("VisualDetection", "Failed to show capture instructions: " . e.Message)
    }
}

; 単一フラスコのキャプチャ開始
StartSingleFlaskCapture(flaskNumber) {
    try {
        LogInfo("VisualDetection", Format("Starting capture for Flask{}", flaskNumber))
        
        g_pattern_capture_state["current_flask"] := flaskNumber
        
        ; フラスコ位置と寸法を取得
        flaskX := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
        flaskY := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
        flaskWidth := ConfigManager.Get("VisualDetection", Format("Flask{}Width", flaskNumber), 80)
        flaskHeight := ConfigManager.Get("VisualDetection", Format("Flask{}Height", flaskNumber), 120)
        
        if (flaskX == 0 || flaskY == 0) {
            ShowOverlay(Format("Flask{} の座標が未設定です`nF9で座標設定を行ってください", flaskNumber), 3000)
            LogWarn("VisualDetection", Format("Flask{} coordinates not set", flaskNumber))
            return false
        }
        
        ; FindTextのGUIを起動してキャプチャ準備
        LaunchFindTextCapture(flaskX, flaskY, flaskWidth, flaskHeight, flaskNumber)
        
        ; 操作ガイドを更新
        UpdateCaptureInstructions(flaskNumber)
        
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to start Flask{} capture: {}", flaskNumber, e.Message))
        ShowOverlay(Format("Flask{} キャプチャ開始に失敗", flaskNumber), 2000)
        return false
    }
}

; FindTextキャプチャの起動
LaunchFindTextCapture(centerX, centerY, width, height, flaskNumber) {
    try {
        LogDebug("VisualDetection", Format("Launching FindText capture for Flask{} at center {},{}, size {}x{}", 
            flaskNumber, centerX, centerY, width, height))
        
        ; FindTextインスタンスを取得
        ft := FindText()
        
        ; 既存のキャプチャGUIを閉じる
        if (g_pattern_capture_state["capture_gui"]) {
            try {
                g_pattern_capture_state["capture_gui"].Close()
            } catch {
                ; GUI が既に閉じられている場合は無視
            }
        }
        
        ; FindTextのGUIを表示
        captureGui := ft.Gui("Show")
        g_pattern_capture_state["capture_gui"] := captureGui
        
        ; チャージ検出エリアを計算（上部1/3）
        chargeArea := CalculateChargeDetectionArea(centerX, centerY, width, height)
        
        if (chargeArea.Count > 0) {
            ShowOverlay(Format("Flask{} パターンキャプチャ準備完了`n検出エリア: 上部1/3 ({},{} to {},{})`nFindTextでキャプチャしてください", 
                flaskNumber, chargeArea["left"], chargeArea["top"], chargeArea["right"], chargeArea["bottom"]), 4000)
            
            LogInfo("VisualDetection", Format("FindText GUI launched for Flask{} charge area: {},{} to {},{}", 
                flaskNumber, chargeArea["left"], chargeArea["top"], chargeArea["right"], chargeArea["bottom"]))
        } else {
            ShowOverlay(Format("Flask{} パターンキャプチャ準備完了`nFindTextでキャプチャしてください", flaskNumber), 3000)
        }
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to launch FindText capture: {}", e.Message))
        ShowOverlay("FindTextキャプチャ起動に失敗", 2000)
    }
}

; キャプチャ指示の更新
UpdateCaptureInstructions(flaskNumber) {
    try {
        if (!g_pattern_capture_state["instruction_gui"]) {
            return
        }
        
        ; 指示GUIのタイトルを更新
        g_pattern_capture_state["instruction_gui"].Title := 
            Format("フラスコパターンキャプチャ - Flask{}", flaskNumber)
        
        LogDebug("VisualDetection", Format("Updated capture instructions for Flask{}", flaskNumber))
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to update capture instructions: {}", e.Message))
    }
}

; フラスコパターンをConfig.iniに保存
SaveFlaskPattern(flaskNumber, patternText) {
    try {
        LogInfo("VisualDetection", Format("Saving pattern for Flask{}", flaskNumber))
        
        if (!patternText || patternText == "") {
            LogWarn("VisualDetection", Format("Empty pattern provided for Flask{}", flaskNumber))
            ShowOverlay(Format("Flask{} パターンが空です", flaskNumber), 2000)
            return false
        }
        
        ; Config.iniに保存
        configKey := Format("Flask{}ChargedPattern", flaskNumber)
        ConfigManager.Set("VisualDetection", configKey, patternText)
        
        ; フラスコ名も更新
        flaskName := ConfigManager.Get("VisualDetection", Format("Flask{}Name", flaskNumber), Format("Flask {}", flaskNumber))
        
        ShowOverlay(Format("{} パターン保存完了", flaskName), 2000)
        LogInfo("VisualDetection", Format("Pattern saved for Flask{}: {} characters", flaskNumber, StrLen(patternText)))
        
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to save Flask{} pattern: {}", flaskNumber, e.Message))
        ShowOverlay(Format("Flask{} パターン保存に失敗", flaskNumber), 2000)
        return false
    }
}

; 個別フラスコパターンキャプチャ（外部呼び出し用）
CaptureFlaskPattern(flaskNumber) {
    try {
        LogInfo("VisualDetection", Format("Manual capture request for Flask{}", flaskNumber))
        
        if (flaskNumber < 1 || flaskNumber > 5) {
            LogError("VisualDetection", Format("Invalid flask number: {}", flaskNumber))
            ShowOverlay("無効なフラスコ番号です (1-5)", 2000)
            return false
        }
        
        ; パターンキャプチャモードが無効な場合は開始
        if (!g_pattern_capture_state["active"]) {
            StartFlaskPatternCapture()
            Sleep(500)  ; GUI表示待ち
        }
        
        ; 指定フラスコのキャプチャ開始
        return StartSingleFlaskCapture(flaskNumber)
        
    } catch as e {
        LogError("VisualDetection", Format("CaptureFlaskPattern failed for Flask{}: {}", flaskNumber, e.Message))
        ShowOverlay(Format("Flask{} キャプチャに失敗", flaskNumber), 2000)
        return false
    }
}

; 全フラスコパターンの順次キャプチャ
CaptureAllFlaskPatterns() {
    try {
        LogInfo("VisualDetection", "Starting sequential capture of all flask patterns")
        
        ; パターンキャプチャモードを開始
        if (!g_pattern_capture_state["active"]) {
            StartFlaskPatternCapture()
            Sleep(500)  ; GUI表示待ち
        }
        
        ShowOverlay("全フラスコパターンキャプチャ開始`n各フラスコでEnterキーを押してください", 3000)
        
        ; Flask1から順次キャプチャ
        for flaskNum in [1, 2, 3, 4, 5] {
            if (!StartSingleFlaskCapture(flaskNum)) {
                LogWarn("VisualDetection", Format("Failed to start capture for Flask{}, continuing...", flaskNum))
                continue
            }
            
            ; 次のフラスコまで少し待機
            Sleep(1000)
        }
        
        LogInfo("VisualDetection", "All flask pattern capture sequence initiated")
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("CaptureAllFlaskPatterns failed: {}", e.Message))
        ShowOverlay("全フラスコキャプチャに失敗", 2000)
        return false
    }
}

; ===================================================================
; 視覚検出テストモード管理 (v2.9.4)
; ===================================================================

; テストモード状態管理
global g_visual_test_mode := Map(
    "enabled", false,
    "continuous_test", false,
    "test_interval", 2000,  ; 2秒間隔
    "last_test_time", 0,
    "test_timer", ""
)

; 視覚検出テストモードの切り替え
ToggleVisualDetectionTestMode() {
    try {
        LogInfo("VisualDetection", "Toggling visual detection test mode")
        
        currentMode := g_visual_test_mode["enabled"]
        
        if (currentMode) {
            ; テストモードを無効化
            StopVisualDetectionTestMode()
        } else {
            ; テストモードを有効化
            StartVisualDetectionTestMode()
        }
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to toggle test mode: {}", e.Message))
        ShowOverlay("テストモード切り替えに失敗", 2000)
    }
}

; 視覚検出テストモード開始
StartVisualDetectionTestMode() {
    try {
        LogInfo("VisualDetection", "Starting visual detection test mode")
        
        ; 既にアクティブな場合は停止
        if (g_visual_test_mode["enabled"]) {
            StopVisualDetectionTestMode()
        }
        
        ; テストモード有効化
        g_visual_test_mode["enabled"] := true
        g_visual_test_mode["continuous_test"] := true
        g_visual_test_mode["last_test_time"] := A_TickCount
        
        ; 連続テストタイマー開始
        testInterval := g_visual_test_mode["test_interval"]
        g_visual_test_mode["test_timer"] := SetTimer(PerformContinuousFlaskTest, testInterval)
        
        ShowOverlay("視覚検出テストモード開始`n" . 
                   Format("{}ms間隔で連続テスト実行中", testInterval), 3000)
        
        ; 初回テスト実行
        PerformContinuousFlaskTest()
        
        LogInfo("VisualDetection", Format("Test mode started with {}ms interval", testInterval))
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to start test mode: {}", e.Message))
        ShowOverlay("テストモード開始に失敗", 2000)
    }
}

; 視覚検出テストモード停止
StopVisualDetectionTestMode() {
    try {
        LogInfo("VisualDetection", "Stopping visual detection test mode")
        
        ; テストモード無効化
        g_visual_test_mode["enabled"] := false
        g_visual_test_mode["continuous_test"] := false
        
        ; タイマー停止
        if (g_visual_test_mode["test_timer"]) {
            SetTimer(g_visual_test_mode["test_timer"], 0)  ; タイマー停止
            g_visual_test_mode["test_timer"] := ""
        }
        
        ShowOverlay("視覚検出テストモード停止", 2000)
        LogInfo("VisualDetection", "Test mode stopped successfully")
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to stop test mode: {}", e.Message))
        ShowOverlay("テストモード停止に失敗", 2000)
    }
}

; 連続フラスコテスト実行
PerformContinuousFlaskTest() {
    try {
        ; テストモードが無効な場合は停止
        if (!g_visual_test_mode["enabled"] || !g_visual_test_mode["continuous_test"]) {
            return
        }
        
        LogDebug("VisualDetection", "Performing continuous flask test")
        
        ; 全フラスコの検出テスト
        results := []
        successCount := 0
        
        Loop 5 {
            flaskNumber := A_Index
            
            ; フラスコ位置確認
            flaskX := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
            flaskY := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
            pattern := ConfigManager.Get("VisualDetection", Format("Flask{}ChargedPattern", flaskNumber), "")
            
            if (flaskX == 0 || flaskY == 0 || pattern == "") {
                results.Push(Format("Flask{}: 未設定", flaskNumber))
                continue
            }
            
            ; 検出実行
            chargeStatus := DetectFlaskCharge(flaskNumber)
            switch chargeStatus {
                case 1:
                    results.Push(Format("Flask{}: ✓ チャージあり", flaskNumber))
                    successCount++
                case 0:
                    results.Push(Format("Flask{}: ○ 空", flaskNumber))
                    successCount++
                case -1:
                    results.Push(Format("Flask{}: ✗ 検出失敗", flaskNumber))
            }
        }
        
        ; 結果をオーバーレイで表示
        currentTime := FormatTime(A_Now, "HH:mm:ss")
        results.InsertAt(1, Format("=== 視覚検出テスト [{}] ===", currentTime))
        results.Push("")
        results.Push(Format("検出成功: {}/5 フラスコ", successCount))
        
        ShowMultiLineOverlay(results, 1500)
        
        ; 統計更新
        g_visual_test_mode["last_test_time"] := A_TickCount
        
        LogDebug("VisualDetection", Format("Continuous test completed: {}/5 successful", successCount))
        
    } catch as e {
        LogError("VisualDetection", Format("Continuous flask test failed: {}", e.Message))
        ; テストモード継続のためエラー時も停止しない
    }
}

; テストモード状態取得
IsVisualDetectionTestModeActive() {
    return g_visual_test_mode.Has("enabled") && g_visual_test_mode["enabled"]
}

; ===================================================================
; Wine of the Prophet 高精度チャージ検出 (v2.9.4)
; ===================================================================

; Wine of the Prophet用液体レベル検出
GetLiquidPercentage(flaskNumber) {
    try {
        LogDebug("VisualDetection", Format("Starting liquid percentage detection for Flask{}", flaskNumber))
        
        ; フラスコ位置と寸法を取得
        centerX := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
        centerY := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
        width := ConfigManager.Get("VisualDetection", Format("Flask{}Width", flaskNumber), 80)
        height := ConfigManager.Get("VisualDetection", Format("Flask{}Height", flaskNumber), 120)
        
        if (centerX == 0 || centerY == 0) {
            LogError("VisualDetection", Format("Flask{} position not configured", flaskNumber))
            return 0.0
        }
        
        ; 液体エリア計算（上部60%）
        liquidArea := CalculateLiquidDetectionArea(centerX, centerY, width, height)
        
        if (liquidArea.Count == 0) {
            LogError("VisualDetection", "Failed to calculate liquid detection area")
            return 0.0
        }
        
        ; ピクセルスキャンで液体レベルを検出
        liquidPercentage := ScanLiquidArea(liquidArea, flaskNumber)
        
        LogDebug("VisualDetection", Format("Flask{} liquid percentage: {}%", flaskNumber, Round(liquidPercentage * 100, 1)))
        return liquidPercentage
        
    } catch as e {
        LogError("VisualDetection", Format("GetLiquidPercentage failed for Flask{}: {}", flaskNumber, e.Message))
        return 0.0
    }
}

; 液体検出エリアの計算（上部60%、より精密）
CalculateLiquidDetectionArea(centerX, centerY, width, height) {
    try {
        halfWidth := width // 2
        halfHeight := height // 2
        
        ; Wine用液体検出エリア（上部60%、枠を除外してより精密に）
        liquidArea := Map(
            "left", centerX - halfWidth + 8,      ; 枠をより多く除外
            "top", centerY - halfHeight + 8,       ; 上端の枠除外
            "right", centerX + halfWidth - 8,     ; 右端の枠除外
            "bottom", centerY - height // 5       ; 上部60%まで（1/5点まで）
        )
        
        ; エリアサイズ計算
        liquidArea["width"] := liquidArea["right"] - liquidArea["left"]
        liquidArea["height"] := liquidArea["bottom"] - liquidArea["top"]
        
        LogDebug("VisualDetection", Format("Liquid area calculated: {},{} to {},{} ({}x{})", 
            liquidArea["left"], liquidArea["top"], liquidArea["right"], liquidArea["bottom"],
            liquidArea["width"], liquidArea["height"]))
        
        return liquidArea
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to calculate liquid detection area: {}", e.Message))
        return Map()
    }
}

; 液体エリアのピクセルスキャン
ScanLiquidArea(liquidArea, flaskNumber) {
    try {
        ; Wine of the Prophetの黄金色設定（設定可能）
        goldColorR := ConfigManager.Get("VisualDetection", "WineGoldR", 255)
        goldColorG := ConfigManager.Get("VisualDetection", "WineGoldG", 215)
        goldColorB := ConfigManager.Get("VisualDetection", "WineGoldB", 0)
        colorTolerance := ConfigManager.Get("VisualDetection", "WineColorTolerance", 30)
        
        totalPixels := 0
        liquidPixels := 0
        samplingRate := ConfigManager.Get("VisualDetection", "WineSamplingRate", 3)  ; 3ピクセルおきにサンプリング
        
        ; エリアをサンプリングしてスキャン
        loop liquidArea["height"] // samplingRate {
            y := liquidArea["top"] + (A_Index - 1) * samplingRate
            
            loop liquidArea["width"] // samplingRate {
                x := liquidArea["left"] + (A_Index - 1) * samplingRate
                totalPixels++
                
                ; ピクセル色を取得
                pixelColor := PixelGetColor(x, y, "RGB")
                
                ; RGBに分解
                r := (pixelColor >> 16) & 0xFF
                g := (pixelColor >> 8) & 0xFF  
                b := pixelColor & 0xFF
                
                ; 黄金色かどうか判定
                if (IsGoldColor(r, g, b, goldColorR, goldColorG, goldColorB, colorTolerance)) {
                    liquidPixels++
                }
            }
        }
        
        ; 液体割合を計算
        liquidPercentage := totalPixels > 0 ? (liquidPixels / totalPixels) : 0.0
        
        LogDebug("VisualDetection", Format("Flask{} liquid scan: {}/{} pixels gold ({}%)", 
            flaskNumber, liquidPixels, totalPixels, Round(liquidPercentage * 100, 1)))
        
        return liquidPercentage
        
    } catch as e {
        LogError("VisualDetection", Format("ScanLiquidArea failed: {}", e.Message))
        return 0.0
    }
}

; 黄金色判定ヘルパー
IsGoldColor(r, g, b, targetR, targetG, targetB, tolerance) {
    return (Abs(r - targetR) <= tolerance && 
            Abs(g - targetG) <= tolerance && 
            Abs(b - targetB) <= tolerance)
}

; Wine of the Prophet チャージレベル検出
DetectWineChargeLevel() {
    try {
        LogDebug("VisualDetection", "Starting Wine of the Prophet charge level detection")
        
        ; 液体エリアの黄金色ピクセル割合を取得
        liquidPercentage := GetLiquidPercentage(4)  ; Flask4 = Wine of the Prophet
        
        ; チャージ量を推定（最大140チャージ）
        maxCharge := ConfigManager.Get("VisualDetection", "WineMaxCharge", 140)
        chargePerUse := ConfigManager.Get("VisualDetection", "WineChargePerUse", 72)
        estimatedCharge := liquidPercentage * maxCharge
        
        ; 使用可能判定（チャージ72以上）
        canUse := (estimatedCharge >= chargePerUse)
        usesRemaining := Floor(estimatedCharge / chargePerUse)
        
        ; 結果をまとめて返す
        result := {
            charge: Round(estimatedCharge, 1),
            percentage: Round(liquidPercentage * 100, 1),
            canUse: canUse,
            usesRemaining: usesRemaining,
            maxCharge: maxCharge,
            chargePerUse: chargePerUse,
            detectionTime: A_TickCount
        }
        
        LogInfo("VisualDetection", Format("Wine charge detection: {:.1f}/{} charges ({}%), {} uses remaining, can use: {}", 
            result.charge, maxCharge, result.percentage, usesRemaining, canUse ? "Yes" : "No"))
        
        return result
        
    } catch as e {
        LogError("VisualDetection", Format("DetectWineChargeLevel failed: {}", e.Message))
        return {
            charge: 0,
            percentage: 0,
            canUse: false,
            usesRemaining: 0,
            maxCharge: 140,
            chargePerUse: 72,
            detectionTime: A_TickCount,
            error: e.Message
        }
    }
}

; Wineチャージ検出のテスト関数
TestWineChargeDetection() {
    try {
        LogInfo("VisualDetection", "Testing Wine of the Prophet charge detection")
        
        ; 検出実行
        result := DetectWineChargeLevel()
        
        ; 結果をオーバーレイで表示
        displayLines := [
            "=== Wine of the Prophet チャージ検出テスト ===",
            "",
            Format("推定チャージ: {:.1f}/{}", result.charge, result.maxCharge),
            Format("液体レベル: {}%", result.percentage),
            Format("使用可能回数: {}", result.usesRemaining),
            Format("使用可能: {}", result.canUse ? "はい" : "いいえ"),
            ""
        ]
        
        if (result.HasOwnProp("error")) {
            displayLines.Push("⚠ エラー: " . result.error)
        } else {
            displayLines.Push("✓ 検出成功")
        }
        
        ShowMultiLineOverlay(displayLines, 5000)
        
        return result.HasOwnProp("error") ? false : true
        
    } catch as e {
        LogError("VisualDetection", Format("TestWineChargeDetection failed: {}", e.Message))
        ShowOverlay("Wine検出テストに失敗", 2000)
        return false
    }
}

; ===================================================================
; フラスコパターン管理 (v2.9.4)
; ===================================================================

; 全フラスコパターンクリア
ClearAllFlaskPatterns() {
    try {
        LogInfo("VisualDetection", "Clearing all flask patterns")
        
        clearedCount := 0
        
        ; 各フラスコのパターンをクリア
        Loop 5 {
            flaskNumber := A_Index
            patternKey := Format("Flask{}ChargedPattern", flaskNumber)
            
            ; 現在のパターンを確認
            currentPattern := ConfigManager.Get("VisualDetection", patternKey, "")
            
            if (currentPattern != "") {
                ; パターンをクリア
                ConfigManager.Set("VisualDetection", patternKey, "")
                clearedCount++
                
                LogDebug("VisualDetection", Format("Cleared pattern for Flask{}", flaskNumber))
            }
        }
        
        ; 結果をログに記録
        LogInfo("VisualDetection", Format("Cleared {} flask patterns", clearedCount))
        
        ; 成功メッセージ
        if (clearedCount > 0) {
            ShowOverlay(Format("{}個のフラスコパターンをクリアしました", clearedCount), 2500)
        } else {
            ShowOverlay("クリアするパターンがありませんでした", 2000)
        }
        
        return clearedCount
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to clear flask patterns: {}", e.Message))
        ShowOverlay("パターンクリアに失敗", 2000)
        return 0
    }
}

; 特定フラスコのパターンクリア
ClearFlaskPattern(flaskNumber) {
    try {
        LogInfo("VisualDetection", Format("Clearing pattern for Flask{}", flaskNumber))
        
        if (flaskNumber < 1 || flaskNumber > 5) {
            LogError("VisualDetection", Format("Invalid flask number: {}", flaskNumber))
            return false
        }
        
        patternKey := Format("Flask{}ChargedPattern", flaskNumber)
        currentPattern := ConfigManager.Get("VisualDetection", patternKey, "")
        
        if (currentPattern == "") {
            ShowOverlay(Format("Flask{} のパターンは既に空です", flaskNumber), 2000)
            return true
        }
        
        ; パターンをクリア
        ConfigManager.Set("VisualDetection", patternKey, "")
        
        ; フラスコ名を取得して表示
        flaskName := ConfigManager.Get("VisualDetection", Format("Flask{}Name", flaskNumber), Format("Flask {}", flaskNumber))
        ShowOverlay(Format("{} のパターンをクリアしました", flaskName), 2000)
        
        LogInfo("VisualDetection", Format("Flask{} pattern cleared successfully", flaskNumber))
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to clear Flask{} pattern: {}", flaskNumber, e.Message))
        ShowOverlay(Format("Flask{} パターンクリアに失敗", flaskNumber), 2000)
        return false
    }
}

; パターン統計情報取得
GetFlaskPatternStats() {
    try {
        stats := Map(
            "total_patterns", 0,
            "configured_flasks", [],
            "empty_flasks", [],
            "pattern_lengths", Map()
        )
        
        Loop 5 {
            flaskNumber := A_Index
            pattern := ConfigManager.Get("VisualDetection", Format("Flask{}ChargedPattern", flaskNumber), "")
            
            if (pattern != "") {
                stats["total_patterns"]++
                stats["configured_flasks"].Push(flaskNumber)
                stats["pattern_lengths"][flaskNumber] := StrLen(pattern)
            } else {
                stats["empty_flasks"].Push(flaskNumber)
            }
        }
        
        return stats
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to get pattern stats: {}", e.Message))
        return Map()
    }
}