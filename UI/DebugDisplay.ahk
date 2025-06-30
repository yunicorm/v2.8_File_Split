; ===================================================================
; デバッグ表示システム（修正版）
; マナ状態、タイマー、その他デバッグ情報の表示
; ===================================================================

; --- グローバル変数 ---
global debugGuis := []
global g_debug_cleanup_timer := ""
global g_debug_gui_creating := false

; --- マナデバッグ表示（F11） ---
ShowManaDebug(*) {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate
    global debugGuis, g_debug_gui_creating
    
    ; 作成中なら何もしない
    if (g_debug_gui_creating) {
        return
    }
    
    try {
        g_debug_gui_creating := true
        
        ; 既存のデバッグGUIをクリア
        CleanupDebugGuis()
        
        ; デバッグオーバーレイ
        debugGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        debugGui.BackColor := "000000"
        debugGui.SetFont("s12 cWhite", "Arial")
        
        ; マナ状態を取得
        hasMana := CheckManaRadial()
        
        ; 完全枯渇検出の詳細情報
        detailInfo := GetManaDetectionDetails()
        
        ; デバッグテキスト作成
        debugText := FormatManaDebugText(detailInfo, hasMana)
        
        ; テキストコントロールを追加
        debugGui.Add("Text", "w450 h350", debugText)
        
        ; 表示位置を計算（マナオーブの近く）
        displayX := g_mana_center_x - 225
        displayY := g_mana_center_y - 350
        
        ; 画面境界チェック
        screenWidth := ConfigManager.Get("Resolution", "ScreenWidth", 3440)
        if (displayX + 450 > screenWidth) {
            displayX := screenWidth - 450
        }
        if (displayX < 0) {
            displayX := 0
        }
        
        debugGui.Show(Format("x{} y{} w450 h350 NoActivate", displayX, displayY))
        WinSetTransparent(200, debugGui)
        
        ; デバッグGUIリストに追加
        debugGuis.Push({gui: debugGui, type: "mana_debug"})
        
        ; 検出ポイントを視覚化
        ShowImprovedDetectionPoints()
        
        ; 自動クリーンアップタイマーを設定
        SetDebugCleanupTimer(5000)
        
        LogInfo("DebugDisplay", "Mana debug info displayed")
        
    } catch as e {
        LogError("DebugDisplay", "Failed to show mana debug: " . e.Message)
        ShowOverlay("マナデバッグ表示エラー", 2000)
    } finally {
        g_debug_gui_creating := false
    }
}

; --- マナ検出の詳細情報を取得 ---
GetManaDetectionDetails() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius
    
    checkRatios := [0.85, 0.90, 0.95]
    blueThreshold := ConfigManager.Get("Mana", "BlueThreshold", 40)
    blueDominance := ConfigManager.Get("Mana", "BlueDominance", 20)
    
    totalBlueFound := 0
    detailResults := []
    colorDetails := []
    
    for ratio in checkRatios {
        bottomY := g_mana_center_y + (g_mana_radius * ratio)
        lineBlueCount := 0
        lineColors := []
        
        Loop 5 {
    xOffset := (A_Index - 3) * g_mana_radius * 0.2
            checkX := g_mana_center_x + xOffset
            checkY := bottomY
            
            try {
                color := SafePixelGetColor(checkX, checkY, "RGB")
                rgb := GetRGB(color)
                
                isBlue := (rgb.b >= blueThreshold && 
                          rgb.b > rgb.r + blueDominance && 
                          rgb.b > rgb.g + blueDominance)
                
                if (isBlue) {
                    lineBlueCount++
                    totalBlueFound++
                }
                
                lineColors.Push({
                    x: checkX,
                    y: checkY,
                    color: color,
                    rgb: rgb,
                    isBlue: isBlue
                })
                
            } catch as e {
                LogDebug("DebugDisplay", Format("Failed to check point at {},{}: {}", 
                    checkX, checkY, e.Message))
                lineColors.Push({
                    x: checkX,
                    y: checkY,
                    error: true
                })
            }
        }
        
        detailResults.Push({
            ratio: ratio,
            blueCount: lineBlueCount,
            colors: lineColors
        })
    }
    
    return {
        totalBlueFound: totalBlueFound,
        details: detailResults,
        fillRate: g_mana_fill_rate,
        threshold: blueThreshold,
        dominance: blueDominance
    }
}

; --- マナデバッグテキストのフォーマット ---
FormatManaDebugText(detailInfo, hasMana) {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate
    
    text := "=== マナオーブ情報（完全枯渇検出式） ===`n"
    text .= Format("位置: {}, {} (半径: {}px)`n", 
        Round(g_mana_center_x), Round(g_mana_center_y), Round(g_mana_radius))
    text .= Format("充填率: {}%`n", g_mana_fill_rate)
    text .= Format("マナあり: {} (検出: {}/15)`n", 
        hasMana ? "はい" : "いいえ", detailInfo.totalBlueFound)
    text .= Format("青色閾値: {} (優勢度: {})`n`n", 
        detailInfo.threshold, detailInfo.dominance)
    
    text .= "検出詳細:`n"
    for result in detailInfo.details {
        text .= Format("  {}%ライン: {}/5 青検出`n", 
            Round(result.ratio * 100), result.blueCount)
    }
    
    text .= Format("`n判定: {}`n", 
        detailInfo.totalBlueFound == 0 ? "完全枯渇 (0/26)" : 
        detailInfo.totalBlueFound < 3 ? "ほぼ枯渇" : "マナあり")
    
    ; 最適化モードの状態
    if (ConfigManager.Get("Mana", "OptimizedDetection", true)) {
        text .= "`n最適化モード: 有効"
    }
    
    return text
}

; --- 完全枯渇検出ポイント表示（改善版） ---
ShowImprovedDetectionPoints() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, debugGuis
    
    try {
        ; 設定値
        blueThreshold := ConfigManager.Get("Mana", "BlueThreshold", 40)
        blueDominance := ConfigManager.Get("Mana", "BlueDominance", 20)
        checkRatios := [0.85, 0.90, 0.95]
        lineColors := ["FFFF00", "FF8800", "FF0000"]  ; 黄、オレンジ、赤
        
        ; 各高さで検出ラインと結果を表示
        for i, ratio in checkRatios {
            lineY := g_mana_center_y + (g_mana_radius * ratio)
            
            ; 検出ライン表示
            lineGui := CreateDebugLine(
                g_mana_center_x - g_mana_radius * 0.8,
                lineY,
                g_mana_radius * 1.6,
                2,
                lineColors[i]
            )
            debugGuis.Push({gui: lineGui, type: "detection_line"})
            
            ; 各ラインの5つの検出ポイント
            Loop 5 {
    xOffset := (A_Index - 3) * g_mana_radius * 0.2
                checkX := g_mana_center_x + xOffset
                checkY := lineY
                
                pointGui := CreateDetectionPoint(checkX, checkY, blueThreshold, blueDominance)
                if (pointGui) {
                    debugGuis.Push({gui: pointGui, type: "detection_point"})
                }
            }
            
            ; 高さラベル
            labelGui := CreateDebugLabel(
                g_mana_center_x + g_mana_radius + 10,
                lineY - 8,
                Format("{}%", Round(ratio * 100)),
                lineColors[i]
            )
            debugGuis.Push({gui: labelGui, type: "detection_label"})
        }
        
        ; 説明テキスト
        infoGui := CreateDebugInfo(
            g_mana_center_x - g_mana_radius - 150,
            g_mana_center_y
        )
        debugGuis.Push({gui: infoGui, type: "info"})
        
    } catch as e {
        LogError("DebugDisplay", "Failed to show detection points: " . e.Message)
    }
}

; --- デバッグライン作成 ---
CreateDebugLine(x, y, width, height, color) {
    try {
        lineGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        lineGui.BackColor := color
        lineGui.Show(Format("x{} y{} w{} h{} NoActivate", x, y, width, height))
        return lineGui
    } catch {
        return ""
    }
}

; --- 検出ポイント作成 ---
CreateDetectionPoint(x, y, threshold, dominance) {
    try {
        pointGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        
        ; ピクセル色を取得
        pixelColor := SafePixelGetColor(x, y, "RGB")
        rgb := GetRGB(pixelColor)
        
        ; 青色判定
        isBlue := (rgb.b >= threshold && 
                  rgb.b > rgb.r + dominance && 
                  rgb.b > rgb.g + dominance)
        
        pointGui.BackColor := isBlue ? "00FF00" : "FF0000"  ; 緑（マナあり）または赤（マナなし）
        pointGui.Show(Format("x{} y{} w6 h6 NoActivate", x-3, y-3))
        
        return pointGui
    } catch {
        return ""
    }
}

; --- デバッグラベル作成 ---
CreateDebugLabel(x, y, text, color) {
    try {
        labelGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        labelGui.BackColor := "000000"
        labelGui.SetFont("s10 c" . color, "Arial")
        labelGui.Add("Text", , text)
        labelGui.Show(Format("x{} y{} NoActivate", x, y))
        return labelGui
    } catch {
        return ""
    }
}

; --- デバッグ情報作成 ---
CreateDebugInfo(x, y) {
    try {
        infoGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        infoGui.BackColor := "000000"
        infoGui.SetFont("s10 cWhite", "Arial")
        infoText := "完全枯渇検出:`n3つの高さすべてで`n青が検出されない時"
        infoGui.Add("Text", , infoText)
        infoGui.Show(Format("x{} y{} NoActivate", x, y))
        return infoGui
    } catch {
        return ""
    }
}

; --- デバッグGUIクリーンアップ（改善版） ---
CleanupDebugGuis() {
    global debugGuis, g_debug_cleanup_timer
    
    ; クリーンアップタイマーを停止
    if (g_debug_cleanup_timer) {
        SetTimer(g_debug_cleanup_timer, 0)
        g_debug_cleanup_timer := ""
    }
    
    ; 各GUIを破棄
    for item in debugGuis {
        try {
            if (IsObject(item) && item.HasOwnProp("gui") && IsObject(item.gui)) {
                item.gui.Destroy()
            }
        } catch {
            ; エラーは無視
        }
    }
    
    ; 配列をクリア
    debugGuis := []
    
    ; ガベージコレクションを促す
    CollectGarbage()
    
    LogDebug("DebugDisplay", "Debug GUIs cleaned up")
}

; --- 自動クリーンアップタイマー設定 ---
SetDebugCleanupTimer(delay) {
    global g_debug_cleanup_timer
    
    ; 既存のタイマーがあれば停止
    if (g_debug_cleanup_timer) {
        SetTimer(g_debug_cleanup_timer, 0)
    }
    
    ; 新しいタイマーを設定
    g_debug_cleanup_timer := SetTimer(CleanupDebugGuis, -delay)
}

; --- タイマーデバッグ表示 ---
ShowTimerDebugInfo() {
    global g_debug_mode
    
    if (!g_debug_mode && !GetKeyState("Shift", "P")) {
        ShowOverlay("デバッグモードが無効です (Ctrl+D で有効化)", 2000)
        return
    }
    
    ShowActiveTimerDetails()
    LogInfo("DebugDisplay", "Timer debug info displayed")
}

; --- アクティブタイマーの詳細表示 ---
ShowActiveTimerDetails() {
    activeTimers := GetActiveTimers()
    
    timerInfo := []
    timerInfo.Push("=== アクティブタイマー ===")
    timerInfo.Push(Format("合計: {} タイマー", activeTimers.Length))
    timerInfo.Push("")
    
    if (activeTimers.Length == 0) {
        timerInfo.Push("アクティブなタイマーなし")
    } else {
        for timer in activeTimers {
            elapsed := Round(timer.runTime / 1000, 1)
            timerInfo.Push(Format("{}: {}秒経過 ({}ms間隔)", 
                timer.name, elapsed, timer.period))
        }
    }
    
    ShowMultiLineOverlay(timerInfo, 5000)
}

; --- 全体デバッグ情報表示（拡張版） ---
ShowFullDebugInfo() {
    global g_macro_active, g_mana_fill_rate
    global g_loading_screen_active, g_auto_start_enabled
    
    debugInfo := []
    debugInfo.Push("=== Path of Exile マクロ デバッグ情報 ===")
    debugInfo.Push(Format("バージョン: v2.9.2 | AHK: {}", A_AhkVersion))
    debugInfo.Push("")
    
    ; マクロ状態
    debugInfo.Push(Format("マクロ: {} | 自動開始: {}", 
        g_macro_active ? "ON" : "OFF",
        g_auto_start_enabled ? "有効" : "無効"))
    
    ; マナ状態
    debugInfo.Push(Format("マナ: {}%", g_mana_fill_rate))
    
    ; Tincture詳細状態
    tinctureDebug := GetTinctureDebugInfo()
    for line in tinctureDebug {
        if (A_Index > 1) {  ; ヘッダーをスキップ
            debugInfo.Push(line)
        }
    }
    
    debugInfo.Push("")
    
    ; フラスコ状態
    global g_flask_timer_active
    debugInfo.Push(Format("フラスコループ: {}", 
        g_flask_timer_active ? "ON" : "OFF"))
    
    ; エリア検出状態
    if (ConfigManager.Get("ClientLog", "Enabled", true)) {
        global g_last_area_name
        debugInfo.Push(Format("エリア検出: ログ監視 (最終: {})", 
            g_last_area_name ? g_last_area_name : "なし"))
    } else {
        debugInfo.Push(Format("ロード画面: {}", 
            g_loading_screen_active ? "検出中" : "ゲーム画面"))
    }
    
    ; タイマー情報
    activeTimers := GetActiveTimers()
    debugInfo.Push("")
    debugInfo.Push(Format("アクティブタイマー: {}", activeTimers.Length))
    
    ; 解像度情報
    debugInfo.Push("")
    debugInfo.Push(Format("解像度: {}x{}", 
        ConfigManager.Get("Resolution", "ScreenWidth", 3440),
        ConfigManager.Get("Resolution", "ScreenHeight", 1440)))
    
    ShowMultiLineOverlay(debugInfo, 5000)
}

; --- パフォーマンスデバッグ ---
ShowPerformanceDebug() {
    perfInfo := []
    perfInfo.Push("=== パフォーマンス情報 ===")
    perfInfo.Push("")
    
    ; メモリ使用量（推定）
    try {
        ; AutoHotkeyのプロセスIDを取得
        pid := DllCall("GetCurrentProcessId")
        
        ; メモリ情報構造体
        memInfo := Buffer(40)
        
        ; プロセスハンドルを取得
        hProcess := DllCall("OpenProcess", "UInt", 0x0410, "Int", false, "UInt", pid)
        
        if (hProcess) {
            ; メモリ情報を取得
            if (DllCall("K32.dll\GetProcessMemoryInfo", "Ptr", hProcess, "Ptr", memInfo, "UInt", 40)) {
                workingSet := NumGet(memInfo, 8, "UInt64") / 1024 / 1024
                peakWorkingSet := NumGet(memInfo, 16, "UInt64") / 1024 / 1024
                
                perfInfo.Push(Format("メモリ使用量: {:.1f} MB", workingSet))
                perfInfo.Push(Format("ピークメモリ: {:.1f} MB", peakWorkingSet))
            }
            
            DllCall("CloseHandle", "Ptr", hProcess)
        }
    } catch {
        perfInfo.Push("メモリ情報: 取得失敗")
    }
    
    perfInfo.Push("")
    
    ; タイマー統計
    activeTimers := GetActiveTimers()
    perfInfo.Push(Format("アクティブタイマー: {}", activeTimers.Length))
    
    ; デバッグGUI数
    global debugGuis
    perfInfo.Push(Format("デバッグGUI: {}", debugGuis.Length))
    
    ShowMultiLineOverlay(perfInfo, 3000)
}

; --- ガベージコレクション（メモリ最適化） ---
CollectGarbage() {
    try {
        ; AutoHotkeyのガベージコレクション相当の処理
        ; 未使用の変数やオブジェクトの解放を促す
        DllCall("SetProcessWorkingSetSize", "Ptr", -1, "Ptr", -1, "Ptr", -1)
    } catch {
        ; エラーは無視
    }
}