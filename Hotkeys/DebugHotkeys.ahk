; ===================================================================
; デバッグ用ホットキー定義
; 開発・デバッグ用の各種ホットキー
; ===================================================================

#HotIf WinActive("ahk_group TargetWindows")

; ===================================================================
; F11: Wine検出テスト / マナデバッグ (v2.9.4)
; ===================================================================
F11:: {
    ; Wine Charge Detection Test (v2.9.4)
    wineDetectionEnabled := ConfigManager.Get("VisualDetection", "WineChargeDetectionEnabled", false)
    
    if (wineDetectionEnabled) {
        TestWineChargeDetection()
        LogInfo("DebugHotkeys", "F11 pressed - Wine charge detection test")
    } else if (IsVisualDetectionEnabled()) {
        TestAllFlaskDetection()
        LogInfo("DebugHotkeys", "F11 pressed - Visual detection test")
    } else {
        ShowManaDebug()  ; 従来の機能を維持
        LogInfo("DebugHotkeys", "F11 pressed - Mana debug displayed")
    }
}

; ===================================================================
; F10: フラスコパターンキャプチャモード (v2.9.4)
; ===================================================================
F10:: {
    ; Visual Detection Pattern Capture Mode (v2.9.4)
    if (IsVisualDetectionEnabled()) {
        StartFlaskPatternCapture()
        LogInfo("DebugHotkeys", "F10 pressed - Pattern capture mode started")
    } else {
        ; エリア検出方式の切り替え（従来機能の代替）
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
}

; ===================================================================
; Shift+F10: 視覚検出テストモード切り替え
; ===================================================================
+F10:: {
    if (!IsVisualDetectionEnabled()) {
        ShowOverlay("視覚検出が無効です。設定で有効にしてください", 3000)
        LogWarn("DebugHotkeys", "Visual detection test mode requested but visual detection is disabled")
        return
    }

    ; テストモード切り替え
    ToggleVisualDetectionTestMode()
    LogInfo("DebugHotkeys", "Shift+F10 pressed - Visual detection test mode toggled")
}

; ===================================================================
; Ctrl+F10: 全フラスコパターンクリア
; ===================================================================
^F10:: {
    result := MsgBox("全てのフラスコパターンをクリアしますか？`n`nこの操作は取り消せません。", 
                     "パターンクリア確認", "YesNo Icon!")

    if (result == "Yes") {
        ClearAllFlaskPatterns()
        ShowOverlay("全フラスコパターンをクリアしました", 2000)
        LogInfo("DebugHotkeys", "Ctrl+F10 pressed - All flask patterns cleared")
    } else {
        LogInfo("DebugHotkeys", "Ctrl+F10 pressed - Pattern clear cancelled")
    }
}

; ===================================================================
; F9: フラスコ座標設定モード
; ===================================================================
F9:: {
    StartFlaskPositionCapture()
    LogInfo("DebugHotkeys", "F9 pressed - Flask position capture mode")
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

; ===================================================================
; Alt+F10: 視覚検出を強制的に有効化して保存
; ===================================================================
!F10:: {
    try {
        ; Config.iniに保存
        ConfigManager.Set("VisualDetection", "Enabled", true)
        
        ; ファイルに強制的に書き込み
        ConfigManager.Save()
        
        ; 再初期化
        InitializeVisualDetection()
        
        Sleep(500)
        
        ; 診断情報表示
        if (IsVisualDetectionEnabled()) {
            ShowOverlay("視覚検出を有効化しました（保存済み）", 2000)
            LogInfo("DebugHotkeys", "Visual detection enabled and saved")
        } else {
            ShowOverlay("有効化に失敗しました", 2000)
            LogError("DebugHotkeys", "Failed to enable visual detection")
        }
        
    } catch as e {
        LogError("DebugHotkeys", "Alt+F10 error: " . e.Message)
    }
}

; ===================================================================
; Alt+Shift+F10: 視覚検出の診断情報表示
; ===================================================================
+!F10:: {
    try {
        ; Config.iniの状態
        configEnabled := ConfigManager.Get("VisualDetection", "Enabled", false)
        
        ; グローバル変数の状態
        stateEnabled := g_visual_detection_state.Has("enabled") ? g_visual_detection_state["enabled"] : "Not Set"
        findtextInstance := g_visual_detection_state.Has("findtext_instance") ? 
            (g_visual_detection_state["findtext_instance"] != "" ? "Initialized" : "Empty") : "Not Set"
        
        ; FindText.ahkの存在確認
        findTextPath := A_ScriptDir . "\Utils\FindText.ahk"
        findTextExists := FileExist(findTextPath) ? "Found" : "Not Found"
        
        ; 診断情報を表示
        diagnostics := [
            "=== Visual Detection Diagnostics ===",
            "",
            "Config.ini Enabled: " . (configEnabled ? "True" : "False"),
            "State Enabled: " . stateEnabled,
            "FindText Instance: " . findtextInstance,
            "FindText.ahk: " . findTextExists,
            "Path: " . findTextPath,
            "",
            "IsVisualDetectionEnabled(): " . (IsVisualDetectionEnabled() ? "True" : "False")
        ]
        
        ShowMultiLineOverlay(diagnostics, 5000)
        
        ; ログにも出力
        for line in diagnostics {
            LogInfo("DebugHotkeys", line)
        }
        
        ; FindText.ahkが見つからない場合は再初期化を試みる
        if (findTextExists == "Found" && !IsVisualDetectionEnabled()) {
            ShowOverlay("視覚検出を再初期化します...", 2000)
            Sleep(2000)
            InitializeVisualDetection()
            ShowOverlay("再初期化完了", 2000)
        }
        
    } catch as e {
        LogError("DebugHotkeys", "Diagnostics failed: " . e.Message)
        ShowOverlay("診断に失敗: " . e.Message, 3000)
    }
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

; ===================================================================
; パターンキャプチャモード専用ホットキー (v2.9.4)
; ===================================================================

#HotIf (g_pattern_capture_state.Has("active") && g_pattern_capture_state["active"])

; 数字キー 1-5: フラスコ選択
1:: {
    CaptureFlaskPattern(1)
    LogInfo("DebugHotkeys", "Pattern capture: Flask 1 selected")
}

2:: {
    CaptureFlaskPattern(2)
    LogInfo("DebugHotkeys", "Pattern capture: Flask 2 selected")
}

3:: {
    CaptureFlaskPattern(3)
    LogInfo("DebugHotkeys", "Pattern capture: Flask 3 selected")
}

4:: {
    CaptureFlaskPattern(4)
    LogInfo("DebugHotkeys", "Pattern capture: Flask 4 selected")
}

5:: {
    CaptureFlaskPattern(5)
    LogInfo("DebugHotkeys", "Pattern capture: Flask 5 selected")
}

; Space: 全フラスコ順次キャプチャ
Space:: {
    CaptureAllFlaskPatterns()
    LogInfo("DebugHotkeys", "Pattern capture: All flasks sequential capture started")
}

; Escape: キャプチャモード終了
Escape:: {
    StopFlaskPatternCapture()
    LogInfo("DebugHotkeys", "Pattern capture: Mode stopped via Escape")
}

#HotIf  ; パターンキャプチャモードコンテキスト終了