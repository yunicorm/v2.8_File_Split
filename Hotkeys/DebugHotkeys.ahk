; ===================================================================
; デバッグ用ホットキー定義
; 開発・デバッグ用の各種ホットキー
; ===================================================================

#HotIf WinActive("ahk_group TargetWindows")

; ===================================================================
; F11: マナ状態デバッグ表示
; ===================================================================
F11:: {
    ShowManaDebug()
    LogInfo("DebugHotkeys", "F11 pressed - Mana debug displayed")
}

; ===================================================================
; F10: ロード画面検出のオン/オフ
; ===================================================================
F10:: {
    global g_loading_check_enabled, g_macro_active
    g_loading_check_enabled := !g_loading_check_enabled
    
    if (g_loading_check_enabled) {
        ShowOverlay("ロード画面検出: ON（入力待機モード）", 1500)
        if (g_macro_active) {
            StartLoadingScreenDetection()
        }
    } else {
        ShowOverlay("ロード画面検出: OFF", 1500)
        StopLoadingScreenDetection()
    }
    
    LogInfo("DebugHotkeys", Format("F10 pressed - Loading detection: {}", 
        g_loading_check_enabled ? "ON" : "OFF"))
}

; ===================================================================
; F9: 待機モードの詳細切り替え
; ===================================================================
F9:: {
    static mode := 1
    mode := (mode == 1) ? 2 : 1
    
    if (mode == 1) {
        ShowOverlay("簡易入力待機モード", 1500)
    } else {
        ShowOverlay("詳細アクション待機モード", 1500)
    }
    
    LogInfo("DebugHotkeys", Format("F9 pressed - Wait mode: {}", mode))
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

; Ctrl+Alt+F12: スクリプト再起動
^!F12:: {
    ShowOverlay("スクリプト再起動中...", 1000)
    Sleep(1000)
    Reload()
}

; Ctrl+Alt+Shift+F12: スクリプト終了
^!+F12:: {
    result := MsgBox("スクリプトを終了しますか？", "確認", "YesNo")
    if (result == "Yes") {
        ExitApp()
    }
}