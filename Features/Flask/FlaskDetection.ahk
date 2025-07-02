; Flask Detection Module
; Handles visual detection of flask charge status
; v2.9.6 - Extracted from VisualDetection.ahk for better modularity

; Global variables used by flask detection - initialized in VisualDetection/Core.ahk
global g_visual_detection_state

; Detection status constants
global FLASK_CHARGED := 1
global FLASK_EMPTY := 0
global FLASK_DETECTION_FAILED := -1
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

; Note: GetDetectionMode() and SetDetectionMode() are now handled by VisualDetection/Core.ahk
; to avoid duplication and maintain centralized state management

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

; GetDetectionResults function removed - using VisualDetection/Core.ahk version instead

; ClearDetectionResults function removed - using VisualDetection/Core.ahk version instead

; CleanupVisualDetection function removed - using VisualDetection/Core.ahk version instead

; サイズ変更用ヘルパー関数（グローバル）
ResizeWithLog(dw, dh, key) {
    LogDebug("VisualDetection", key . " key pressed")
    ResizeOverlay(dw, dh)
}

; 楕円形フラスコ座標取得開始（順次設定方式）
StartFlaskPositionCapture() {
    try {
        LogInfo("VisualDetection", "Starting flask position capture sequence")
        
        ; グローバル変数の初期化
        global g_current_flask_index := 1
        global g_flask_setup_active := true
        global g_flask_rect_width := 60
        global g_flask_rect_height := 80
        
        ; Visual Detection システムが有効か確認
        if (!IsVisualDetectionEnabled()) {
            LogWarn("VisualDetection", "Visual detection is disabled - starting position capture in coordinates-only mode")
        }
        
        ; 第1フラスコから開始
        StartSingleFlaskCapture(1)
        
        ; 操作説明を表示
        instructions := [
            "フラスコ位置設定モード開始",
            "",
            "操作方法:",
            "矢印キー: 位置調整 (10px)",
            "]/[: 幅調整 (10px)",
            "'/;: 高さ調整 (10px)", 
            "=/−: 全体サイズ調整 (5px)",
            "Shift+キー: 微調整 (2px)",
            "",
            "Enter: 位置確定・次へ",
            "Escape: 設定終了",
            "G: グリッドスナップ切替",
            "H: ヘルプ表示"
        ]
        
        ShowMultiLineOverlayWithTitle(instructions, 8000, Format("フラスコ{}/5 設定中", g_current_flask_index))
        
        LogInfo("VisualDetection", "Flask position capture started successfully")
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to start flask position capture: {}", e.Message))
        return false
    }
}

; 単一フラスコの座標設定開始
StartSingleFlaskCapture(flaskNumber) {
    try {
        global g_current_flask_index := flaskNumber
        
        LogInfo("VisualDetection", Format("Starting capture for Flask {}", flaskNumber))
        
        ; 既存の設定を読み込むか、推定位置を使用
        flaskConfig := LoadFlaskPosition(flaskNumber)
        if (flaskConfig["configured"]) {
            centerX := flaskConfig["x"]
            centerY := flaskConfig["y"]
            LogInfo("VisualDetection", Format("Using existing position for Flask {}: {},{}", flaskNumber, centerX, centerY))
        } else {
            ; 推定位置を計算
            estimatedPos := EstimateFlaskPosition(flaskNumber)
            centerX := estimatedPos["x"]
            centerY := estimatedPos["y"]
            LogInfo("VisualDetection", Format("Using estimated position for Flask {}: {},{}", flaskNumber, centerX, centerY))
        }
        
        ; オーバーレイを作成・表示
        CreateSingleFlaskOverlay(centerX, centerY, flaskNumber)
        
        ; ホットキーを有効化（FlaskOverlay.ahkの機能を呼び出し）
        ; Note: ホットキー管理はFlaskOverlay.ahkで実装済み
        
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to start single flask capture: {}", e.Message))
        return false
    }
}

; フラスコ位置推定
EstimateFlaskPosition(flaskNumber) {
    try {
        ; モニター情報を取得
        monitors := GetMonitorInfo()
        if (!monitors.Has("primary")) {
            throw Error("Primary monitor not found")
        }
        
        primary := monitors["primary"]
        
        ; フラスコ間隔とベース位置を計算
        flaskSpacing := 80
        baseX := primary["centerX"] - (2 * flaskSpacing)  ; 5つのフラスコの中央
        baseY := primary["bottom"] - 100  ; 画面下から100px上
        
        ; フラスコ番号に基づく位置
        estimatedX := baseX + ((flaskNumber - 1) * flaskSpacing)
        estimatedY := baseY
        
        LogDebug("VisualDetection", Format("Estimated Flask {} position: {},{}", flaskNumber, estimatedX, estimatedY))
        
        return Map("x", estimatedX, "y", estimatedY)
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to estimate flask position: {}", e.Message))
        ; フォールバック位置
        return Map("x", 500, "y", 800)
    }
}
