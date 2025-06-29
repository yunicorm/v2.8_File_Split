; ===================================================================
; デバッグ用ホットキー定義
; 開発・デバッグ用の各種ホットキー
; ===================================================================

#HotIf WinActive("ahk_group TargetWindows")

; ===================================================================
; F11: 視覚的検出テスト (v2.9.4)
; ===================================================================
F11:: {
    ; Visual Detection Test (v2.9.4)
    if (IsVisualDetectionEnabled()) {
        TestAllFlaskDetection()
        LogInfo("DebugHotkeys", "F11 pressed - Visual detection test")
    } else {
        ShowManaDebug()  ; 従来の機能を維持
        LogInfo("DebugHotkeys", "F11 pressed - Mana debug displayed")
    }
}

; ===================================================================
; F10: エリア検出方式の切り替え
; ===================================================================
F10:: {
    global g_loading_check_enabled, g_macro_active
    
    ; 現在の設定を取得
    clientLogEnabled := ConfigManager.Get("ClientLog", "Enabled", true)
    
    if (clientLogEnabled) {
        ; Client.txt監視を無効化して、旧方式に切り替え
        ConfigManager.Set("ClientLog", "Enabled", false)
        ConfigManager.Set("LoadingScreen", "Enabled", true)
        g_loading_check_enabled := true
        
        if (g_macro_active) {
            StopClientLogMonitoring()
            StartLoadingScreenDetection()
        }
        
        ShowOverlay("エリア検出: ピクセル検出方式", 2000)
        LogInfo("DebugHotkeys", "Switched to pixel-based loading detection")
    } else {
        ; 旧方式を無効化して、Client.txt監視に切り替え
        ConfigManager.Set("ClientLog", "Enabled", true)
        ConfigManager.Set("LoadingScreen", "Enabled", false)
        g_loading_check_enabled := false
        
        if (g_macro_active) {
            StopLoadingScreenDetection()
            StartClientLogMonitoring()
        }
        
        ShowOverlay("エリア検出: Client.txtログ監視", 2000)
        LogInfo("DebugHotkeys", "Switched to log-based area detection")
    }
}

; ===================================================================
; F9: エリア検出デバッグ
; ===================================================================
F9:: {
    global g_client_log_path, g_last_area_name
    
    ; Client.txt監視が有効な場合
    if (ConfigManager.Get("ClientLog", "Enabled", true)) {
        ; 最後のエリアエントリーを表示
        ShowLastAreaEntry()
        
        debugInfo := []
        debugInfo.Push("=== エリア検出デバッグ ===")
        debugInfo.Push("ログパス: " . g_client_log_path)
        debugInfo.Push("最後のエリア: " . g_last_area_name)
        debugInfo.Push("ファイルサイズ: " . g_last_file_size)
        
        ShowMultiLineOverlay(debugInfo, 5000)
    } else {
        ShowOverlay("Client.txt監視が無効です", 2000)
    }
    
    LogInfo("DebugHotkeys", "F9 pressed - Area detection debug")
}

; ===================================================================
; F8: タイマーデバッグ表示
; ===================================================================
F8:: {
    ShowTimerDebugInfo()
    LogInfo("DebugHotkeys", "F8 pressed - Timer debug displayed")
}

; ===================================================================
; F7: 全体デバッグ情報表示
; ===================================================================
F7:: {
    ShowFullDebugInfo()
    LogInfo("DebugHotkeys", "F7 pressed - Full debug info displayed")
}

; ===================================================================
; F6: ログビューアを開く
; ===================================================================
F6:: {
    ShowLogViewer()
    LogInfo("DebugHotkeys", "F6 pressed - Log viewer opened")
}

; ===================================================================
; Ctrl+D: デバッグモードの切り替え
; ===================================================================
^d:: {
    global g_debug_mode
    g_debug_mode := !g_debug_mode
    
    ShowOverlay(Format("デバッグモード: {}", g_debug_mode ? "ON" : "OFF"), 1500)
    LogInfo("DebugHotkeys", Format("Debug mode toggled: {}", g_debug_mode))
}

; ===================================================================
; Ctrl+L: ログ記録の切り替え
; ===================================================================
^l:: {
    global g_log_enabled
    g_log_enabled := !g_log_enabled
    
    ShowOverlay(Format("ログ記録: {}", g_log_enabled ? "ON" : "OFF"), 1500)
    LogInfo("DebugHotkeys", Format("Logging toggled: {}", g_log_enabled))
}

; ===================================================================
; Ctrl+T: テストオーバーレイ表示
; ===================================================================
^t:: {
    ; カスタムオーバーレイのテスト
    ShowCustomOverlay("カスタムオーバーレイテスト", {
        duration: 3000,
        fontSize: 24,
        fontColor: "00FFFF",
        bgColor: "000080",
        transparency: 180
    })
    
    LogInfo("DebugHotkeys", "Test overlay displayed")
}

; ===================================================================
; Ctrl+M: マナ状態の手動チェック
; ===================================================================
^m:: {
    hasMana := CheckManaRadial()
    ShowOverlay(Format("マナ状態: {} ({}%)", 
        hasMana ? "あり" : "なし", g_mana_fill_rate), 2000)
    
    LogInfo("DebugHotkeys", Format("Manual mana check: {} ({}%)", 
        hasMana, g_mana_fill_rate))
}

; ===================================================================
; Ctrl+S: 現在の座標を表示（開発用）
; ===================================================================
^s:: {
    MouseGetPos(&mouseX, &mouseY)
    
    ; ピクセル色も取得
    try {
        pixelColor := PixelGetColor(mouseX, mouseY, "RGB")
        colorInfo := FormatColorInfo(pixelColor)
        
        ShowMultiLineOverlay([
            Format("座標: {}, {}", mouseX, mouseY),
            colorInfo,
            "",
            "Ctrl+C でクリップボードにコピー"
        ], 5000)
        
        ; クリップボードにコピー
        A_Clipboard := Format("x: {}, y: {}, color: {}", 
            mouseX, mouseY, ColorToHex(pixelColor))
            
    } catch {
        ShowOverlay(Format("座標: {}, {}", mouseX, mouseY), 3000)
    }
    
    LogDebug("DebugHotkeys", Format("Mouse position: {}, {}", mouseX, mouseY))
}

; ===================================================================
; Ctrl+R: マクロ状態のリセット（デバッグ用）
; ===================================================================
^r:: {
    ResetMacroState()
    ShowOverlay("マクロ状態をリセットしました", 2000)
    LogWarn("DebugHotkeys", "Macro state reset manually")
}

; --- マクロ状態リセット関数 ---
ResetMacroState() {
    global g_macro_active, g_tincture_active, g_flask_timer_active
    global g_loading_screen_active, g_waiting_for_user_input
    global g_mana_depleted, g_tincture_retry_count
    
    ; 全タイマー停止
    StopAllTimers()
    
    ; 状態をリセット
    g_macro_active := false
    g_tincture_active := false
    g_flask_timer_active := false
    g_loading_screen_active := false
    g_waiting_for_user_input := false
    g_mana_depleted := false
    g_tincture_retry_count := 0
    
    ; UI更新
    UpdateStatusOverlay()
}

; ===================================================================
; Ctrl+P: パフォーマンステスト（開発用）
; ===================================================================
^p:: {
    RunPerformanceTest()
}

; --- パフォーマンステスト関数 ---
RunPerformanceTest() {
    ShowOverlay("パフォーマンステスト開始...", 1000)
    
    ; マナチェック速度テスト
    StartPerfTimer("ManaCheck100")
    Loop 100 {
        CheckManaRadial()
    }
    manaCheckTime := EndPerfTimer("ManaCheck100")
    
    ; 色検出速度テスト
    StartPerfTimer("ColorDetect100")
    Loop 100 {
        PixelGetColor(100, 100, "RGB")
    }
    colorDetectTime := EndPerfTimer("ColorDetect100")
    
    ShowMultiLineOverlay([
        "=== パフォーマンステスト結果 ===",
        Format("マナチェック100回: {}ms", manaCheckTime),
        Format("色検出100回: {}ms", colorDetectTime),
        Format("平均マナチェック: {}ms", Round(manaCheckTime / 100, 2)),
        Format("平均色検出: {}ms", Round(colorDetectTime / 100, 2))
    ], 5000)
}

#HotIf  ; コンテキストをリセット

; ===================================================================
; グローバルホットキー（ウィンドウに関係なく動作）
; ===================================================================

; Ctrl+Shift+F12: 緊急スクリプト再起動（確認なし）
^+F12:: {
    ShowOverlay("スクリプト再起動中...", 1000)
    Sleep(1000)
    Reload()
}

; 注意: Ctrl+Alt+Shift+F12 はMainHotkeys.ahkで定義されています