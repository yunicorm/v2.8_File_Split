; Visual detection system for Flask charge monitoring using FindText
; v2.9.6 - Overlay functions moved to Features/Flask/FlaskOverlay.ahk; VisualDetection.ahk
; Visual detection system for Flask charge monitoring using FindText
; Provides wrapper functions for FindText integration with error handling

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
            "WineGoldR", "230",
            "WineGoldG", "170",
            "WineGoldB", "70",
            "WineColorTolerance", "50",
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

; 楕円形フラスコ座標取得開始（順次設定方式）
StartFlaskPositionCapture() {
    global g_current_flask_index, g_setup_notification_gui
    
    ; モニター情報取得
    monitors := GetFlaskMonitorInfo()
    centralMonitor := monitors["central"]
    
    ; フラスコスロット推定位置計算
    flaskPositions := CalculateFlaskSlotPositions(centralMonitor)
    
    ; フラスコ設定開始
    g_current_flask_index := 1
    LogInfo("VisualDetection", "Starting sequential flask position capture with estimated positions")
    
    ; Flask1の推定位置にオーバーレイ作成
    if (flaskPositions.Has(1)) {
        flask1Pos := flaskPositions[1]
        CreateSingleFlaskOverlay(flask1Pos["x"], flask1Pos["y"], g_current_flask_index)
        LogInfo("VisualDetection", Format("Flask1 overlay created at estimated position: {},{}", 
            flask1Pos["x"], flask1Pos["y"]))
    } else {
        ; フォールバック位置
        flaskInitialX := centralMonitor["left"] + 100
        flaskInitialY := centralMonitor["bottom"] - 200
        CreateSingleFlaskOverlay(flaskInitialX, flaskInitialY, g_current_flask_index)
        LogWarn("VisualDetection", "Using fallback position for Flask1")
    }
    
    ; 通知オーバーレイ作成（中央モニター上部中央）
    notificationX := centralMonitor["centerX"]
    notificationY := centralMonitor["top"] + 100
    CreateSetupNotificationOverlay(notificationX, notificationY, g_current_flask_index)
    
    ShowOverlay("楕円調整: ]/[ 幅 '/; 高さ =/- 全体 Shift:微調整 Enter:確定", 5000)
    
    ; ホットキー設定
    LogDebug("VisualDetection", "Setting up hotkeys for elliptical flask position capture")
    
    ; 位置調整（現在のフラスコのみ）
    Hotkey("Up", (*) => MoveSingleOverlay(0, -10), "On")
    Hotkey("Down", (*) => MoveSingleOverlay(0, 10), "On")
    Hotkey("Left", (*) => MoveSingleOverlay(-10, 0), "On")
    Hotkey("Right", (*) => MoveSingleOverlay(10, 0), "On")
    LogDebug("VisualDetection", "Movement hotkeys set")
    
    ; 楕円サイズ調整（現在のフラスコのみ）
    Hotkey("=", (*) => ResizeSingleOverlayWithFeedback(5, 5, "全体拡大"), "On")
    Hotkey("-", (*) => ResizeSingleOverlayWithFeedback(-5, -5, "全体縮小"), "On")
    Hotkey("]", (*) => ResizeSingleOverlayWithFeedback(10, 0, "幅拡大"), "On")
    Hotkey("[", (*) => ResizeSingleOverlayWithFeedback(-10, 0, "幅縮小"), "On")
    Hotkey("'", (*) => ResizeSingleOverlayWithFeedback(0, 10, "高さ拡大"), "On")
    Hotkey(";", (*) => ResizeSingleOverlayWithFeedback(0, -10, "高さ縮小"), "On")
    LogDebug("VisualDetection", "Ellipse resize hotkeys set")
    
    ; 微調整（Shift+キー）
    Hotkey("+]", (*) => ResizeSingleOverlayWithFeedback(2, 0, "幅微調整+"), "On")
    Hotkey("+[", (*) => ResizeSingleOverlayWithFeedback(-2, 0, "幅微調整-"), "On")
    Hotkey("+'", (*) => ResizeSingleOverlayWithFeedback(0, 2, "高さ微調整+"), "On")
    Hotkey("+;", (*) => ResizeSingleOverlayWithFeedback(0, -2, "高さ微調整-"), "On")
    LogDebug("VisualDetection", "Fine adjustment hotkeys set")
    
    ; 間隔調整
    Hotkey("+", (*) => AdjustFlaskSpacing(2), "On")    ; 5→2に変更
    Hotkey("_", (*) => AdjustFlaskSpacing(-2), "On")   ; -5→-2に変更
    LogDebug("VisualDetection", "Flask spacing hotkeys set")
    
    ; 保存・制御
    Hotkey("Enter", (*) => ConfirmCurrentFlaskAndNext(), "On")  ; 個別確定&次へ
    Hotkey("Tab", (*) => NextFlask(), "On")
    Hotkey("Escape", (*) => EndOverlayCapture(), "On")
    LogDebug("VisualDetection", "Control hotkeys set")
    
    ; 操作性向上機能のホットキー
    Hotkey("P", (*) => ShowPresetMenu(), "On")              ; プリセットメニュー
    Hotkey("G", (*) => ToggleGridSnap(), "On")             ; グリッドスナップ切り替え
    Hotkey("H", (*) => ShowHelpOverlay(), "On")            ; ヘルプ表示
    Hotkey("I", (*) => ImportFlaskSettings(), "On")        ; 設定インポート
    Hotkey("E", (*) => ExportFlaskSettings(), "On")        ; 設定エクスポート
    
    ; 一括調整機能
    Hotkey("+Up", (*) => BatchMoveAllFlasks(0, -10), "On")     ; 全体上移動
    Hotkey("+Down", (*) => BatchMoveAllFlasks(0, 10), "On")    ; 全体下移動
    Hotkey("+Left", (*) => BatchMoveAllFlasks(-10, 0), "On")   ; 全体左移動
    Hotkey("+Right", (*) => BatchMoveAllFlasks(10, 0), "On")   ; 全体右移動
    Hotkey("^]", (*) => BatchAdjustSpacing(5), "On")           ; 間隔拡大
    Hotkey("^[", (*) => BatchAdjustSpacing(-5), "On")          ; 間隔縮小
    Hotkey("^=", (*) => BatchResizeAllFlasks(5, 5), "On")      ; 全体サイズ拡大
    Hotkey("^-", (*) => BatchResizeAllFlasks(-5, -5), "On")    ; 全体サイズ縮小
    
    LogDebug("VisualDetection", "Enhanced operation hotkeys set")
}

; プリセットメニュー表示
ShowPresetMenu() {
    global g_preset_menu_gui
    
    try {
        ; 既存のメニューがあれば削除
        if (g_preset_menu_gui && g_preset_menu_gui != "") {
            try {
                g_preset_menu_gui.Destroy()
                g_preset_menu_gui := ""
                return  ; トグル動作
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; プリセットメニューGUI作成
        g_preset_menu_gui := Gui("+AlwaysOnTop -MaximizeBox", "フラスコ位置プリセット")
        g_preset_menu_gui.BackColor := "0x2D2D30"
        
        ; フォント設定
        g_preset_menu_gui.SetFont("s10", "Segoe UI")
        
        ; メニュー項目追加
        g_preset_menu_gui.Add("Text", "cWhite w200 Center", "プリセット選択")
        g_preset_menu_gui.Add("Text", "cGray w200 x10 y+5", "──────────────")
        
        ; デフォルトプリセット
        btn1 := g_preset_menu_gui.Add("Button", "w180 x10 y+10", "1. 標準左下配置")
        btn1.OnEvent("Click", (*) => ApplyPreset("standard"))
        
        btn2 := g_preset_menu_gui.Add("Button", "w180 x10 y+5", "2. 中央下配置")
        btn2.OnEvent("Click", (*) => ApplyPreset("center"))
        
        btn3 := g_preset_menu_gui.Add("Button", "w180 x10 y+5", "3. 右下配置")
        btn3.OnEvent("Click", (*) => ApplyPreset("right"))
        
        ; カスタムプリセット
        g_preset_menu_gui.Add("Text", "cGray w200 x10 y+15", "──────────────")
        
        btn4 := g_preset_menu_gui.Add("Button", "w180 x10 y+10", "4. 現在の設定を読み込み")
        btn4.OnEvent("Click", (*) => ApplyPreset("current"))
        
        btn5 := g_preset_menu_gui.Add("Button", "w180 x10 y+5", "5. カスタム保存")
        btn5.OnEvent("Click", (*) => SaveCustomPreset())
        
        ; 閉じるボタン
        btnClose := g_preset_menu_gui.Add("Button", "w180 x10 y+15", "閉じる")
        btnClose.OnEvent("Click", (*) => ClosePresetMenu())
        
        ; ESCキーで閉じる
        g_preset_menu_gui.OnEvent("Escape", (*) => ClosePresetMenu())
        
        ; 画面中央に表示
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        menuX := centralMonitor["centerX"] - 100
        menuY := centralMonitor["centerY"] - 150
        
        g_preset_menu_gui.Show(Format("x{} y{} w220 h300", menuX, menuY))
        
        LogInfo("VisualDetection", "Preset menu displayed")
        
    } catch as e {
        LogError("VisualDetection", "Failed to show preset menu: " . e.Message)
    }
}

; プリセットメニューを閉じる
ClosePresetMenu() {
    global g_preset_menu_gui
    
    try {
        if (g_preset_menu_gui && g_preset_menu_gui != "") {
            g_preset_menu_gui.Destroy()
            g_preset_menu_gui := ""
        }
    } catch as e {
        LogError("VisualDetection", "Failed to close preset menu: " . e.Message)
    }
}

; プリセット適用
ApplyPreset(presetType) {
    try {
        LogInfo("VisualDetection", Format("Applying preset: {}", presetType))
        
        ; モニター情報取得
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        
        ; プリセット別座標計算
        presetPositions := Map()
        
        switch presetType {
            case "standard":  ; 標準左下配置
                baseX := 100
                baseY := 1350
                spacing := 80
                
                Loop 5 {
                    relativeX := baseX + (A_Index - 1) * spacing
                    absoluteX := centralMonitor["left"] + relativeX
                    
                    presetPositions[A_Index] := Map(
                        "x", absoluteX,
                        "y", baseY,
                        "width", 60,
                        "height", 80
                    )
                }
                
            case "center":  ; 中央下配置
                centerX := centralMonitor["centerX"]
                totalWidth := 4 * 80 + 60  ; 5フラスコ分の幅
                startX := centerX - totalWidth // 2
                baseY := 1350
                spacing := 80
                
                Loop 5 {
                    absoluteX := startX + (A_Index - 1) * spacing
                    
                    presetPositions[A_Index] := Map(
                        "x", absoluteX,
                        "y", baseY,
                        "width", 60,
                        "height", 80
                    )
                }
                
            case "right":  ; 右下配置
                baseX := centralMonitor["width"] - 500  ; 右端から500px
                baseY := 1350
                spacing := 80
                
                Loop 5 {
                    relativeX := baseX + (A_Index - 1) * spacing
                    absoluteX := centralMonitor["left"] + relativeX
                    
                    presetPositions[A_Index] := Map(
                        "x", absoluteX,
                        "y", baseY,
                        "width", 60,
                        "height", 80
                    )
                }
                
            case "current":  ; 現在の設定を読み込み
                Loop 5 {
                    flaskPos := LoadFlaskPosition(A_Index)
                    if (flaskPos["configured"]) {
                        presetPositions[A_Index] := Map(
                            "x", flaskPos["x"],
                            "y", flaskPos["y"],
                            "width", flaskPos["width"],
                            "height", flaskPos["height"]
                        )
                    }
                }
        }
        
        ; 設定完了フラスコを全て表示
        ClearCompletedFlaskOverlays()
        for flaskNum, pos in presetPositions {
            CreateCompletedFlaskOverlay(pos["x"], pos["y"], flaskNum, pos["width"], pos["height"])
        }
        
        ; メニューを閉じる
        ClosePresetMenu()
        
        ShowOverlay(Format("プリセット「{}」を適用しました", presetType), 2000)
        LogInfo("VisualDetection", Format("Preset '{}' applied successfully", presetType))
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to apply preset '{}': {}", presetType, e.Message))
        ShowOverlay("プリセットの適用に失敗しました", 2000)
    }
}

; カスタムプリセット保存
SaveCustomPreset() {
    try {
        ; 現在の設定をカスタムプリセットとして保存
        customPreset := Map()
        
        Loop 5 {
            flaskPos := LoadFlaskPosition(A_Index)
            if (flaskPos["configured"]) {
                customPreset[A_Index] := Map(
                    "relativeX", flaskPos["relativeX"],
                    "relativeY", flaskPos["relativeY"],
                    "width", flaskPos["width"],
                    "height", flaskPos["height"]
                )
            }
        }
        
        ; カスタムプリセットをConfigに保存
        for flaskNum, pos in customPreset {
            ConfigManager.Set("VisualDetection", Format("CustomFlask{}X", flaskNum), pos["relativeX"])
            ConfigManager.Set("VisualDetection", Format("CustomFlask{}Y", flaskNum), pos["relativeY"])
            ConfigManager.Set("VisualDetection", Format("CustomFlask{}Width", flaskNum), pos["width"])
            ConfigManager.Set("VisualDetection", Format("CustomFlask{}Height", flaskNum), pos["height"])
        }
        
        ClosePresetMenu()
        ShowOverlay("カスタムプリセットを保存しました", 2000)
        LogInfo("VisualDetection", "Custom preset saved successfully")
        
    } catch as e {
        LogError("VisualDetection", "Failed to save custom preset: " . e.Message)
        ShowOverlay("カスタムプリセットの保存に失敗しました", 2000)
    }
}

; 一括移動（全フラスコを同時移動）
BatchMoveAllFlasks(dx, dy) {
    global g_completed_flask_overlays
    
    try {
        LogInfo("VisualDetection", Format("Batch moving all flasks by dx={}, dy={}", dx, dy))
        
        ; 既存の完了フラスコオーバーレイをクリア
        ClearCompletedFlaskOverlays()
        
        ; 全フラスコの位置を一括更新
        Loop 5 {
            flaskPos := LoadFlaskPosition(A_Index)
            if (flaskPos["configured"]) {
                newX := flaskPos["x"] + dx
                newY := flaskPos["y"] + dy
                
                ; 新しい位置を保存
                SaveSingleFlaskPosition(A_Index, newX, newY, flaskPos["width"], flaskPos["height"])
                
                ; 視覚的フィードバック
                CreateCompletedFlaskOverlay(newX, newY, A_Index, flaskPos["width"], flaskPos["height"])
            }
        }
        
        ShowOverlay(Format("全フラスコを移動: {},{}", dx, dy), 1500)
        
        ; 3秒後にオーバーレイを削除
        SetTimer(() => ClearCompletedFlaskOverlays(), -3000)
        
    } catch as e {
        LogError("VisualDetection", "Failed to batch move flasks: " . e.Message)
    }
}

; 一括間隔調整
BatchAdjustSpacing(spacingChange) {
    global g_completed_flask_overlays
    
    try {
        LogInfo("VisualDetection", Format("Batch adjusting flask spacing by {}", spacingChange))
        
        ; モニター情報取得
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        
        ; 既存の完了フラスコオーバーレイをクリア
        ClearCompletedFlaskOverlays()
        
        ; Flask1の位置を基準とする
        flask1Pos := LoadFlaskPosition(1)
        if (!flask1Pos["configured"]) {
            ShowOverlay("Flask1が設定されていません", 2000)
            return
        }
        
        baseX := flask1Pos["x"]
        baseY := flask1Pos["y"]
        
        ; 現在の間隔を計算
        currentSpacing := 80  ; デフォルト
        flask2Pos := LoadFlaskPosition(2)
        if (flask2Pos["configured"]) {
            currentSpacing := flask2Pos["x"] - flask1Pos["x"]
        }
        
        ; 新しい間隔
        newSpacing := Max(50, currentSpacing + spacingChange)  ; 最小50px
        
        ; 全フラスコの位置を再計算
        Loop 5 {
            flaskPos := LoadFlaskPosition(A_Index)
            if (flaskPos["configured"]) {
                newX := baseX + (A_Index - 1) * newSpacing
                
                ; 新しい位置を保存
                SaveSingleFlaskPosition(A_Index, newX, baseY, flaskPos["width"], flaskPos["height"])
                
                ; 視覚的フィードバック
                CreateCompletedFlaskOverlay(newX, baseY, A_Index, flaskPos["width"], flaskPos["height"])
            }
        }
        
        ShowOverlay(Format("フラスコ間隔: {}px", newSpacing), 2000)
        
        ; 3秒後にオーバーレイを削除
        SetTimer(() => ClearCompletedFlaskOverlays(), -3000)
        
    } catch as e {
        LogError("VisualDetection", "Failed to batch adjust spacing: " . e.Message)
    }
}

; 一括サイズ変更
BatchResizeAllFlasks(dw, dh) {
    global g_completed_flask_overlays
    
    try {
        LogInfo("VisualDetection", Format("Batch resizing all flasks by dw={}, dh={}", dw, dh))
        
        ; 既存の完了フラスコオーバーレイをクリア
        ClearCompletedFlaskOverlays()
        
        ; 全フラスコのサイズを一括更新
        Loop 5 {
            flaskPos := LoadFlaskPosition(A_Index)
            if (flaskPos["configured"]) {
                newWidth := Max(40, flaskPos["width"] + dw)  ; 最小40px
                newHeight := Max(40, flaskPos["height"] + dh)  ; 最小40px
                
                ; 新しいサイズを保存
                SaveSingleFlaskPosition(A_Index, flaskPos["x"], flaskPos["y"], newWidth, newHeight)
                
                ; 視覚的フィードバック
                CreateCompletedFlaskOverlay(flaskPos["x"], flaskPos["y"], A_Index, newWidth, newHeight)
            }
        }
        
        ShowOverlay(Format("全フラスコサイズ変更: {},{}", dw, dh), 1500)
        
        ; 3秒後にオーバーレイを削除
        SetTimer(() => ClearCompletedFlaskOverlays(), -3000)
        
    } catch as e {
        LogError("VisualDetection", "Failed to batch resize flasks: " . e.Message)
    }
}

; 設定インポート
ImportFlaskSettings() {
    try {
        LogInfo("VisualDetection", "Importing flask settings from Config.ini")
        
        ; 既存の完了フラスコオーバーレイをクリア
        ClearCompletedFlaskOverlays()
        
        importedCount := 0
        
        ; Config.iniから設定を読み込み
        Loop 5 {
            flaskPos := LoadFlaskPosition(A_Index)
            if (flaskPos["configured"]) {
                ; 視覚的フィードバック
                CreateCompletedFlaskOverlay(flaskPos["x"], flaskPos["y"], A_Index, 
                    flaskPos["width"], flaskPos["height"])
                importedCount++
            }
        }
        
        if (importedCount > 0) {
            ShowOverlay(Format("{}個のフラスコ設定をインポートしました", importedCount), 3000)
            
            ; 5秒後にオーバーレイを削除
            SetTimer(() => ClearCompletedFlaskOverlays(), -5000)
        } else {
            ShowOverlay("インポートできる設定が見つかりません", 2000)
        }
        
        LogInfo("VisualDetection", Format("Imported {} flask settings", importedCount))
        
    } catch as e {
        LogError("VisualDetection", "Failed to import flask settings: " . e.Message)
        ShowOverlay("設定のインポートに失敗しました", 2000)
    }
}

; 設定エクスポート
ExportFlaskSettings() {
    try {
        LogInfo("VisualDetection", "Exporting flask settings to clipboard")
        
        ; 現在の設定を文字列として構築
        exportText := "# Path of Exile フラスコ位置設定" . "`n"
        exportText .= "# Generated by VisualDetection.ahk" . "`n`n"
        
        exportText .= "[VisualDetection]" . "`n"
        
        exportedCount := 0
        Loop 5 {
            flaskPos := LoadFlaskPosition(A_Index)
            if (flaskPos["configured"]) {
                exportText .= Format("Flask{}X={}`n", A_Index, flaskPos["relativeX"])
                exportText .= Format("Flask{}Y={}`n", A_Index, flaskPos["relativeY"])
                exportText .= Format("Flask{}Width={}`n", A_Index, flaskPos["width"])
                exportText .= Format("Flask{}Height={}`n", A_Index, flaskPos["height"])
                exportedCount++
            }
        }
        
        ; モニター情報も追加
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        exportText .= Format("CentralMonitorWidth={}`n", centralMonitor["width"])
        exportText .= Format("CentralMonitorHeight={}`n", centralMonitor["height"])
        
        exportText .= "`n# 座標は中央モニター相対座標です" . "`n"
        exportText .= Format("# エクスポート日時: {}`n", FormatTime(A_Now, "yyyy/MM/dd HH:mm:ss"))
        
        ; クリップボードにコピー
        A_Clipboard := exportText
        
        if (exportedCount > 0) {
            ShowOverlay(Format("{}個のフラスコ設定をクリップボードにコピーしました", exportedCount), 3000)
        } else {
            ShowOverlay("エクスポートできる設定がありません", 2000)
        }
        
        LogInfo("VisualDetection", Format("Exported {} flask settings to clipboard", exportedCount))
        
    } catch as e {
        LogError("VisualDetection", "Failed to export flask settings: " . e.Message)
        ShowOverlay("設定のエクスポートに失敗しました", 2000)
    }
}

; Include split modules
#Include "Flask/FlaskDetection.ahk"
#Include "Flask/FlaskOverlay.ahk"
#Include "Wine/WineDetection.ahk"
#Include "VisualDetection/UIHelpers.ahk"
#Include "VisualDetection/CoordinateManager.ahk"

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
    
    ; 楕円関連ホットキーを無効化
    for key in ["Up","Down","Left","Right","Space","Enter","Tab","Escape",
               "=","-","]","[","'",";","+","_",
               "+]","+[","+'","+;"] {
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

; 楕円形液体検出エリアの計算（F9設定範囲をそのまま使用）
CalculateLiquidDetectionArea(centerX, centerY, width, height) {
    try {
        halfWidth := width // 2
        halfHeight := height // 2
        
        ; F9で設定した楕円全体を検出エリアとする（簡素化）
        liquidArea := Map(
            "left", centerX - halfWidth,
            "top", centerY - halfHeight,
            "right", centerX + halfWidth,
            "bottom", centerY + halfHeight,
            "width", width,
            "height", height
        )
        
        LogDebug("VisualDetection", Format("Ellipse detection area: {}×{} at center ({},{})", 
            width, height, centerX, centerY))
        
        return liquidArea
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to calculate ellipse detection area: {}", e.Message))
        return Map()
    }
}

; 楕円形液体エリアのピクセルスキャン
ScanLiquidArea(liquidArea, flaskNumber) {
    try {
        ; フラスコの中心座標と寸法を取得
        centerX := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
        centerY := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
        width := ConfigManager.Get("VisualDetection", Format("Flask{}Width", flaskNumber), 80)
        height := ConfigManager.Get("VisualDetection", Format("Flask{}Height", flaskNumber), 120)
        
        if (centerX == 0 || centerY == 0) {
            LogError("VisualDetection", Format("Flask{} position not configured for ellipse scanning", flaskNumber))
            return 0.0
        }
        
        ; Wine of the Prophetの液体色設定（設定可能）
        ; 注意: 新しいIsWineLiquidColor関数では個別のRGB設定は使用されず、
        ; 複数の色範囲を自動判定するため、これらの設定値は互換性のために保持
        goldColorR := ConfigManager.Get("VisualDetection", "WineGoldR", 230)
        goldColorG := ConfigManager.Get("VisualDetection", "WineGoldG", 170)
        goldColorB := ConfigManager.Get("VisualDetection", "WineGoldB", 70)
        colorTolerance := ConfigManager.Get("VisualDetection", "WineColorTolerance", 50)
        
        totalPixels := 0
        liquidPixels := 0
        samplingRate := ConfigManager.Get("VisualDetection", "WineSamplingRate", 3)  ; 3ピクセルおきにサンプリング
        
        ; 楕円形エリア内のピクセルのみをスキャン
        loop liquidArea["height"] // samplingRate {
            y := liquidArea["top"] + (A_Index - 1) * samplingRate
            
            loop liquidArea["width"] // samplingRate {
                x := liquidArea["left"] + (A_Index - 1) * samplingRate
                
                ; 楕円形内のピクセルのみをチェック
                if (IsPointInEllipse(x, y, centerX, centerY, width, height)) {
                    totalPixels++
                    
                    ; ピクセル色を取得
                    pixelColor := PixelGetColor(x, y, "RGB")
                    
                    ; RGBに分解
                    r := (pixelColor >> 16) & 0xFF
                    g := (pixelColor >> 8) & 0xFF  
                    b := pixelColor & 0xFF
                    
                    ; Wine液体色かどうか判定
                    if (IsWineLiquidColor(r, g, b)) {
                        liquidPixels++
                    }
                }
            }
        }
        
        ; 液体割合を計算
        liquidPercentage := totalPixels > 0 ? (liquidPixels / totalPixels) : 0.0
        
        LogDebug("VisualDetection", Format("Flask{} elliptical liquid scan: {}/{} pixels detected as wine liquid ({}%)", 
            flaskNumber, liquidPixels, totalPixels, Round(liquidPercentage * 100, 1)))
        
        return liquidPercentage
        
    } catch as e {
        LogError("VisualDetection", Format("ScanLiquidArea failed: {}", e.Message))
        return 0.0
    }
}

; 楕円内座標判定ヘルパー
IsPointInEllipse(px, py, centerX, centerY, width, height) {
    ; 楕円の方程式: ((x-h)²/a²) + ((y-k)²/b²) <= 1
    a := width / 2.0
    b := height / 2.0
    dx := px - centerX
    dy := py - centerY
    
    return ((dx * dx) / (a * a) + (dy * dy) / (b * b)) <= 1
}

; Wine液体色判定ヘルパー（複数色範囲対応）
IsWineLiquidColor(r, g, b) {
    ; 明るいオレンジ色範囲
    if (r >= 200 && r <= 255 && g >= 150 && g <= 200 && b >= 50 && b <= 100) {
        return true
    }
    
    ; 中間のオレンジ色範囲
    if (r >= 180 && r <= 240 && g >= 120 && g <= 190 && b >= 40 && b <= 90) {
        return true
    }
    
    ; 暗い茶色範囲（エッジ部分）
    if (r >= 30 && r <= 70 && g >= 20 && g <= 50 && b >= 15 && b <= 35) {
        return true
    }
    
    return false
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

; ===================================================================
; Wine of the Prophet 診断機能 (v2.9.4)
; ===================================================================

; マウス位置の色情報取得（Ctrl+F11）

; Wine診断モード（F11拡張）

; Wine診断オーバーレイ削除タイマー関数
DestroyWineDiagnosisOverlay() {
    global g_wine_diagnosis_overlay
    if (IsSet(g_wine_diagnosis_overlay) && g_wine_diagnosis_overlay) {
        try {
            g_wine_diagnosis_overlay.Destroy()
        } catch {
            ; 既に削除されている場合は無視
        }
        g_wine_diagnosis_overlay := ""
    }
}

; 検出エリアを視覚的に表示
ShowDetectionAreaOverlay(centerX, centerY, width, height) {
    try {
        ; 既存のオーバーレイを削除
        global g_wine_diagnosis_overlay
        if (IsSet(g_wine_diagnosis_overlay) && g_wine_diagnosis_overlay) {
            try {
                g_wine_diagnosis_overlay.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 液体検出エリアを計算
        liquidArea := CalculateLiquidDetectionArea(centerX, centerY, width, height)
        
        ; オーバーレイGUIを作成
        g_wine_diagnosis_overlay := Gui()
        g_wine_diagnosis_overlay.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g_wine_diagnosis_overlay.BackColor := "Red"
        g_wine_diagnosis_overlay.Show(Format("x{} y{} w{} h{} NA", 
            liquidArea["left"], liquidArea["top"], 
            liquidArea["width"], liquidArea["height"]))
        WinSetTransparent(100, g_wine_diagnosis_overlay)
        
        ; 5秒後に自動削除
        SetTimer(DestroyWineDiagnosisOverlay, -5000)
        
        LogDebug("VisualDetection", "Detection area overlay displayed")
        
    } catch as e {
        LogError("VisualDetection", "Failed to show detection area overlay: " . e.Message)
    }
}

; 色分布を分析
AnalyzeColorDistribution(centerX, centerY, width, height) {
    try {
        liquidArea := CalculateLiquidDetectionArea(centerX, centerY, width, height)
        colorMap := Map()
        totalPixels := 0
        
        ; サンプリングレートを使用してピクセルをスキャン
        samplingRate := ConfigManager.Get("VisualDetection", "WineSamplingRate", 3)
        
        Loop liquidArea["height"] // samplingRate {
            y := liquidArea["top"] + (A_Index - 1) * samplingRate
            
            Loop liquidArea["width"] // samplingRate {
                x := liquidArea["left"] + (A_Index - 1) * samplingRate
                totalPixels++
                
                ; ピクセル色を取得
                pixelColor := PixelGetColor(x, y, "RGB")
                
                ; RGBに分解
                r := (pixelColor >> 16) & 0xFF
                g := (pixelColor >> 8) & 0xFF  
                b := pixelColor & 0xFF
                
                ; 色を文字列キーとして記録
                colorKey := Format("{},{},{}", r, g, b)
                if (!colorMap.Has(colorKey)) {
                    colorMap[colorKey] := {count: 0, r: r, g: g, b: b}
                }
                colorMap[colorKey].count++
            }
        }
        
        ; 色を出現頻度でソート
        sortedColors := []
        for colorKey, colorData in colorMap {
            percentage := (colorData.count / totalPixels) * 100
            sortedColors.Push({
                r: colorData.r,
                g: colorData.g,
                b: colorData.b,
                count: colorData.count,
                percentage: percentage
            })
        }
        
        ; 出現頻度で降順ソート
        sortedColors := SortColorsByFrequency(sortedColors)
        
        return {
            totalPixels: totalPixels,
            uniqueColors: colorMap.Count,
            topColors: sortedColors,
            colorMap: colorMap
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to analyze color distribution: " . e.Message)
        return Map()
    }
}

; 色を頻度でソート（簡易バブルソート）
SortColorsByFrequency(colors) {
    n := colors.Length
    Loop n - 1 {
        Loop n - A_Index {
            if (colors[A_Index].count < colors[A_Index + 1].count) {
                temp := colors[A_Index]
                colors[A_Index] := colors[A_Index + 1]
                colors[A_Index + 1] := temp
            }
        }
    }
    return colors
}

; 最適設定を提案
SuggestOptimalSettings(colorDistribution, currentR, currentG, currentB) {
    try {
        if (!colorDistribution.Has("topColors") || colorDistribution["topColors"].Length == 0) {
            return Map()
        }
        
        ; 黄金色に近い色を探す
        goldenColors := []
        for colorData in colorDistribution["topColors"] {
            ; 黄色系の色（R高、G中〜高、B低）を探す
            if (colorData.r > 200 && colorData.g > 150 && colorData.b < 100) {
                goldenColors.Push(colorData)
            }
        }
        
        ; 最も出現頻度の高い黄金色を選択
        if (goldenColors.Length > 0) {
            optimalColor := goldenColors[1]
            return {
                r: optimalColor.r,
                g: optimalColor.g,
                b: optimalColor.b,
                percentage: optimalColor.percentage,
                tolerance: 25,  ; 推奨許容値
                found: true
            }
        } else {
            ; 黄金色が見つからない場合は最頻出色を返す
            topColor := colorDistribution["topColors"][1]
            return {
                r: topColor.r,
                g: topColor.g,
                b: topColor.b,
                percentage: topColor.percentage,
                tolerance: 30,
                found: false,
                warning: "黄金色が検出されませんでした"
            }
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to suggest optimal settings: " . e.Message)
        return Map()
    }
}

; 診断結果を表示
DisplayDiagnosisResults(colorDist, optimal, x, y, w, h, curR, curG, curB, curTol) {
    try {
        lines := ["=== Wine of the Prophet 診断結果 ===", ""]
        
        ; 現在の設定
        lines.Push("【現在の設定】")
        lines.Push(Format("座標: ({}, {})  サイズ: {}x{}", x, y, w, h))
        lines.Push(Format("色設定: RGB({}, {}, {})  許容値: {}", curR, curG, curB, curTol))
        lines.Push("")
        
        ; 色分析結果
        lines.Push("【色分布分析】")
        lines.Push(Format("総ピクセル数: {}  ユニーク色数: {}", 
            colorDist["totalPixels"], colorDist["uniqueColors"]))
        lines.Push("")
        
        ; TOP5の色
        lines.Push("【最頻出色TOP5】")
        topCount := Min(5, colorDist["topColors"].Length)
        Loop topCount {
            color := colorDist["topColors"][A_Index]
            lines.Push(Format("{}. RGB({}, {}, {}) - {:.1f}%", 
                A_Index, color.r, color.g, color.b, color.percentage))
        }
        lines.Push("")
        
        ; 推奨設定
        if (optimal.Count > 0) {
            lines.Push("【推奨設定】")
            if (optimal.Has("found") && optimal["found"]) {
                lines.Push(Format("✓ 黄金色検出: RGB({}, {}, {})", optimal["r"], optimal["g"], optimal["b"]))
                lines.Push(Format("  出現率: {:.1f}%", optimal["percentage"]))
                lines.Push(Format("  推奨許容値: {}", optimal["tolerance"]))
            } else if (optimal.Has("warning")) {
                lines.Push("⚠ " . optimal["warning"])
                lines.Push(Format("  最頻出色: RGB({}, {}, {})", optimal["r"], optimal["g"], optimal["b"]))
            }
            
            ; 現在設定との差分
            if (optimal.Has("r")) {
                diffR := Abs(optimal["r"] - curR)
                diffG := Abs(optimal["g"] - curG)
                diffB := Abs(optimal["b"] - curB)
                lines.Push("")
                lines.Push(Format("現在設定との差分: R:{}, G:{}, B:{}", diffR, diffG, diffB))
            }
        }
        
        ; マルチラインオーバーレイで表示
        ShowMultiLineOverlay(lines, 10000)
        
        ; ログファイルにも記録
        logPath := A_ScriptDir . "\logs\wine_diagnosis_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".txt"
        try {
            logContent := ""
            for line in lines {
                logContent .= line . "`n"
            }
            FileAppend(logContent, logPath)
            LogInfo("VisualDetection", "Diagnosis results saved to: " . logPath)
        } catch {
            LogWarn("VisualDetection", "Failed to save diagnosis results to file")
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to display diagnosis results: " . e.Message)
        ShowOverlay("診断結果表示に失敗", 2000)
    }
}