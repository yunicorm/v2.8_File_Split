; ===================================================================
; デバッグ表示システム
; マナ状態、タイマー、その他デバッグ情報の表示
; ===================================================================

; --- マナデバッグ表示（F11） ---
ShowManaDebug(*) {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate, debugGuis
    
    ; 既存のデバッグGUIをクリア
    CleanupDebugGuis()
    
    ; デバッグオーバーレイ
    debugGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    debugGui.BackColor := "000000"
    debugGui.SetFont("s12 cWhite", "Arial")
    
    ; マナ状態を取得
    hasMana := CheckManaRadial()
    
    ; 完全枯渇検出の詳細情報
    checkRatios := [0.85, 0.90, 0.95]
    blueThreshold := 40
    totalBlueFound := 0
    detailResults := []
    
    ; 各高さでの検出結果
    for ratio in checkRatios {
        bottomY := g_mana_center_y + (g_mana_radius * ratio)
        lineBlueCount := 0
        
        Loop 5 {
            xOffset := (A_Index - 3) * g_mana_radius * 0.2
            checkX := g_mana_center_x + xOffset
            checkY := bottomY
            
            try {
                color := PixelGetColor(checkX, checkY, "RGB")
                b := color & 0xFF
                g := (color >> 8) & 0xFF
                r := (color >> 16) & 0xFF
                
                if (b >= blueThreshold && b > r + 20 && b > g + 20) {
                    lineBlueCount++
                    totalBlueFound++
                }
            } catch {
                ; エラーは無視
            }
        }
        
        detailResults.Push(Format("{}%ライン: {}/5 青検出", 
            Round(ratio * 100), lineBlueCount))
    }
    
    ; デバッグテキスト作成
    debugText := Format("マナオーブ情報（完全枯渇検出式）`n")
    debugText .= Format("位置: {}, {}`n", Round(g_mana_center_x), Round(g_mana_center_y))
    debugText .= Format("半径: {}px`n", Round(g_mana_radius))
    debugText .= Format("充填率: {}%`n", g_mana_fill_rate)
    debugText .= Format("マナあり: {}`n", hasMana ? "はい" : "いいえ")
    debugText .= Format("総青検出: {}/15 ポイント`n`n", totalBlueFound)
    
    debugText .= "検出詳細:`n"
    for result in detailResults {
        debugText .= result . "`n"
    }
    
    debugText .= Format("`n判定: {}", 
        totalBlueFound == 0 ? "完全枯渇(0/26)" : "マナあり")
    
    debugGui.Add("Text", "w450", debugText)
    debugGui.Show("x" . (g_mana_center_x - 225) . " y" . (g_mana_center_y - 300) . " w450 h280 NoActivate")
    WinSetTransparent(200, debugGui)
    
    ; デバッグGUIリストに追加
    debugGuis.Push(debugGui)
    
    ; 検出ポイントを視覚化
    ShowImprovedDetectionPoints()
    
    ; 5秒後に削除
    SetTimer(() => CleanupDebugGuis(), -5000)
    
    LogInfo("DebugDisplay", "Mana debug info displayed")
}

; --- 完全枯渇検出ポイント表示 ---
ShowImprovedDetectionPoints() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, debugGuis
    
    ; 設定値
    blueThreshold := 40
    checkRatios := [0.85, 0.90, 0.95]  ; 3つの検出高さ
    lineColors := ["FFFF00", "FF8800", "FF0000"]  ; 黄、オレンジ、赤
    
    ; 各高さで検出ラインと結果を表示
    for i, ratio in checkRatios {
        lineY := g_mana_center_y + (g_mana_radius * ratio)
        
        ; 検出ライン表示
        lineGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        lineGui.BackColor := lineColors[i]
        lineGui.Show(Format("x{} y{} w{} h2 NoActivate", 
            g_mana_center_x - g_mana_radius * 0.8, 
            lineY,
            g_mana_radius * 1.6))
        debugGuis.Push(lineGui)
        
        ; 各ラインの5つの検出ポイント
        Loop 5 {
            xOffset := (A_Index - 3) * g_mana_radius * 0.2
            checkX := g_mana_center_x + xOffset
            checkY := lineY
            
            pointGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
            
            try {
                pixelColor := PixelGetColor(checkX, checkY, "RGB")
                blue := pixelColor & 0xFF
                green := (pixelColor >> 8) & 0xFF
                red := (pixelColor >> 16) & 0xFF
                
                if (blue >= blueThreshold && blue > red + 20 && blue > green + 20) {
                    pointGui.BackColor := "00FF00"  ; 緑（マナあり）
                } else {
                    pointGui.BackColor := "FF0000"  ; 赤（マナなし）
                }
                
                pointGui.Show("x" . (checkX-3) . " y" . (checkY-3) . " w6 h6 NoActivate")
                debugGuis.Push(pointGui)
            } catch {
                ; エラーは無視
            }
        }
        
        ; 高さラベル
        labelGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        labelGui.BackColor := "000000"
        labelGui.SetFont("s10 c" . lineColors[i], "Arial")
        labelGui.Add("Text", , Format("{}%", Round(ratio * 100)))
        labelGui.Show(Format("x{} y{} NoActivate",
            g_mana_center_x + g_mana_radius + 10, lineY - 8))
        debugGuis.Push(labelGui)
    }
    
    ; 説明テキスト
    infoGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    infoGui.BackColor := "000000"
    infoGui.SetFont("s10 cWhite", "Arial")
    infoGui.Add("Text", , "完全枯渇検出:`n3つの高さすべてで`n青が検出されない時")
    infoGui.Show(Format("x{} y{} NoActivate",
        g_mana_center_x - g_mana_radius - 150, g_mana_center_y))
    debugGuis.Push(infoGui)
}

; --- デバッグGUIクリーンアップ ---
CleanupDebugGuis() {
    global debugGuis
    
    for gui in debugGuis {
        try {
            if (IsObject(gui)) {
                gui.Destroy()
            }
        } catch {
            ; エラーは無視
        }
    }
    debugGuis := []
}

; --- タイマーデバッグ表示 ---
ShowTimerDebug() {
    global g_active_timers
    
    if (!g_debug_mode) {
        return
    }
    
    timerInfo := []
    timerInfo.Push("=== アクティブタイマー ===")
    timerInfo.Push(Format("合計: {} タイマー", g_active_timers.Count))
    timerInfo.Push("")
    
    for name, info in g_active_timers {
        elapsed := Round((A_TickCount - info.startTime) / 1000, 1)
        timerInfo.Push(Format("{}: {}秒経過 ({}ms間隔)", name, elapsed, info.period))
    }
    
    if (g_active_timers.Count == 0) {
        timerInfo.Push("アクティブなタイマーなし")
    }
    
    ShowMultiLineOverlay(timerInfo, 5000)
}

; --- 全体デバッグ情報表示 ---
ShowFullDebugInfo() {
    global g_macro_active, g_mana_fill_rate, g_tincture_active
    global g_flask_timer_active, g_loading_screen_active
    
    debugInfo := []
    debugInfo.Push("=== Path of Exile マクロ デバッグ情報 ===")
    debugInfo.Push("")
    
    ; マクロ状態
    debugInfo.Push(Format("マクロ: {}", g_macro_active ? "ON" : "OFF"))
    
    ; マナ状態
    debugInfo.Push(Format("マナ: {}%", g_mana_fill_rate))
    
    ; Tincture状態
    tinctureStatus := GetTinctureStatus()
    debugInfo.Push(Format("Tincture: {} (再試行: {})", 
        tinctureStatus.status, tinctureStatus.retryCount))
    
    ; フラスコ状態
    debugInfo.Push(Format("フラスコループ: {}", 
        g_flask_timer_active ? "ON" : "OFF"))
    
    ; ロード画面
    debugInfo.Push(Format("ロード画面: {}", 
        g_loading_screen_active ? "検出中" : "ゲーム画面"))
    
    ; タイマー情報
    activeTimers := GetActiveTimers()
    debugInfo.Push("")
    debugInfo.Push(Format("アクティブタイマー: {}", activeTimers.Length))
    
    ShowMultiLineOverlay(debugInfo, 5000)
}

; --- パフォーマンスデバッグ ---
ShowPerformanceDebug() {
    ; CPU使用率やメモリ使用量などの表示（将来の拡張用）
    ShowOverlay("パフォーマンスデバッグは未実装です", 2000)
}