; ===================================================================
; メインホットキー定義（修正版）
; マクロの主要な操作用ホットキー
; ===================================================================

; --- ホットキー制御用グローバル変数 ---
global g_hotkey_processing := Map()
global g_hotkey_cooldowns := Map()
global g_hotkey_last_press := Map()
global g_hotkey_press_count := Map()

; --- ホットキー設定 ---
global HOTKEY_COOLDOWNS := Map(
    "F12", 1000,          ; 1秒
    "ShiftF12", 500,      ; 0.5秒
    "CtrlF12", 2000,      ; 2秒（緊急停止は長めに）
    "AltF12", 1000,       ; 1秒
    "Pause", 500          ; 0.5秒
)

; --- ホットキーコンテキスト設定 ---
#HotIf WinActive("ahk_group TargetWindows")

; ===================================================================
; F12: マクロのリセット・再始動（改善版）
; ===================================================================
F12:: {
    if (!CheckHotkeyCooldown("F12")) {
        return
    }
    
    if (!BeginHotkeyProcessing("F12")) {
        ShowOverlay("処理中... 少し待ってください", 500)
        return
    }
    
    try {
        ; キーがまだ押されている場合は離されるまで待つ
        startTime := A_TickCount
        while (GetKeyState("F12", "P") && A_TickCount - startTime < 2000) {
            Sleep(10)
        }
        
        ; まだ押されている場合は無視
        if (GetKeyState("F12", "P")) {
            LogWarn("MainHotkeys", "F12 key stuck, ignoring")
            return
        }
        
        ; マクロのリセット・再始動処理
        LogInfo("MainHotkeys", "F12 pressed - Resetting macro")
        ResetMacro()
        
    } catch as e {
        ShowOverlay("エラー: " . e.Message, 2000)
        LogErrorWithStack("MainHotkeys", "Error in F12 handler", e)
    } finally {
        EndHotkeyProcessing("F12")
    }
}

; ===================================================================
; Shift+F12: マクロの手動停止/開始（改善版）
; ===================================================================
+F12:: {
    if (!CheckHotkeyCooldown("ShiftF12")) {
        return
    }
    
    if (!BeginHotkeyProcessing("ShiftF12")) {
        return
    }
    
    try {
        global g_macro_active
        
        if (g_macro_active) {
            ShowOverlay("マクロを停止します", 1500)
            ManualStopMacro()
            LogInfo("MainHotkeys", "Shift+F12 pressed - Macro manually stopped")
        } else {
            ShowOverlay("マクロを開始します", 1500)
            ToggleMacro()
            LogInfo("MainHotkeys", "Shift+F12 pressed - Macro started")
        }
        
    } catch as e {
        ShowOverlay("エラー: " . e.Message, 2000)
        LogError("MainHotkeys", "Error in Shift+F12 handler: " . e.Message)
    } finally {
        EndHotkeyProcessing("ShiftF12")
    }
}

; ===================================================================
; Ctrl+F12: 緊急停止（改善版）
; ===================================================================
^F12:: {
    if (!CheckHotkeyCooldown("CtrlF12", false)) {  ; 緊急停止は警告なし
        return
    }
    
    if (!BeginHotkeyProcessing("CtrlF12")) {
        return
    }
    
    try {
        LogWarn("MainHotkeys", "Emergency stop activated (Ctrl+F12)")
        EmergencyStopMacro()
        
        ; 確認メッセージ
        ShowOverlay("緊急停止完了 - 全機能無効", 3000)
        
    } catch as e {
        ; 緊急停止のエラーは最小限のログ
        OutputDebug("Emergency stop error: " . e.Message)
    } finally {
        EndHotkeyProcessing("CtrlF12")
    }
}

; ===================================================================
; Alt+F12: 設定リロード（改善版）
; ===================================================================
!F12:: {
    if (!CheckHotkeyCooldown("AltF12")) {
        return
    }
    
    if (!BeginHotkeyProcessing("AltF12")) {
        return
    }
    
    try {
        ShowOverlay("設定をリロード中...", 1500)
        
        ; 現在の設定をバックアップ
        ConfigManager.CreateBackup()
        
        if (ReloadConfiguration()) {
            ShowOverlay("設定のリロードが完了しました", 2000)
            LogInfo("MainHotkeys", "Configuration reloaded successfully")
            
            ; 変更された設定を適用
            ApplyConfigChanges()
        } else {
            ShowOverlay("設定のリロードに失敗しました", 2000)
            LogError("MainHotkeys", "Failed to reload configuration")
        }
        
    } catch as e {
        ShowOverlay("設定リロードエラー: " . e.Message, 3000)
        LogError("MainHotkeys", "Configuration reload error: " . e.Message)
    } finally {
        EndHotkeyProcessing("AltF12")
    }
}

; ===================================================================
; Pause: マクロの一時停止/再開（改善版）
; ===================================================================
Pause:: {
    if (!CheckHotkeyCooldown("Pause")) {
        return
    }
    
    if (!BeginHotkeyProcessing("Pause")) {
        return
    }
    
    try {
        global g_macro_active
        
        if (g_macro_active) {
            ShowOverlay("マクロ一時停止", 1500)
            
            ; フラスコのみ一時停止するオプション
            if (GetKeyState("Shift", "P")) {
                PauseFlaskAutomation()
                LogInfo("MainHotkeys", "Flask automation paused")
            } else {
                ManualStopMacro()
                LogInfo("MainHotkeys", "Macro paused")
            }
        } else {
            ShowOverlay("マクロ再開", 1500)
            ToggleMacro()
            LogInfo("MainHotkeys", "Macro resumed")
        }
        
    } catch as e {
        ShowOverlay("一時停止エラー: " . e.Message, 2000)
        LogError("MainHotkeys", "Pause key error: " . e.Message)
    } finally {
        EndHotkeyProcessing("Pause")
    }
}

; ===================================================================
; ScrollLock: ステータス表示の切り替え（改善版）
; ===================================================================
ScrollLock:: {
    try {
        global statusGui
        static isHidden := false
        
        if (!IsSet(statusGui) || !IsObject(statusGui)) {
            ShowOverlay("ステータス表示が初期化されていません", 1500)
            return
        }
        
        if (!isHidden) {
            statusGui.Hide()
            isHidden := true
            ShowOverlay("ステータス非表示", 1000)
        } else {
            ShowStatusWindow()
            isHidden := false
            ShowOverlay("ステータス表示", 1000)
        }
        
        LogDebug("MainHotkeys", Format("Status display toggled: {}", !isHidden))
        
    } catch as e {
        ShowOverlay("ステータス表示エラー", 1500)
        LogError("MainHotkeys", "Status display error: " . e.Message)
    }
}

; ===================================================================
; Ctrl+H: ホットキー一覧表示（改善版）
; ===================================================================
^h:: {
    try {
        hotkeyList := GetHotkeyList()
        ShowMultiLineOverlay(hotkeyList, 7000)
        LogDebug("MainHotkeys", "Hotkey list displayed")
    } catch as e {
        ShowOverlay("ホットキー一覧表示エラー", 1500)
        LogError("MainHotkeys", "Hotkey list error: " . e.Message)
    }
}

; ===================================================================
; F1: クイックヘルプ（新規追加）
; ===================================================================
F1:: {
    if (!CheckHotkeyCooldown("F1", false)) {
        return
    }
    
    try {
        helpText := []
        helpText.Push("=== クイックヘルプ ===")
        helpText.Push("F12: マクロ リセット")
        helpText.Push("Shift+F12: 手動停止/開始")
        helpText.Push("Ctrl+F12: 緊急停止")
        helpText.Push("現在の状態: " . (g_macro_active ? "動作中" : "停止中"))
        
        ShowMultiLineOverlay(helpText, 3000)
    } catch {
        ; エラーは無視
    }
}

#HotIf  ; コンテキストをリセット

; ===================================================================
; グローバルホットキー（ウィンドウに関係なく動作）
; ===================================================================

; Ctrl+Shift+S: 設定ウィンドウを開く
^+s:: {
    try {
        ShowSettingsWindow()
        LogInfo("MainHotkeys", "Settings window opened via hotkey")
    } catch as e {
        LogError("MainHotkeys", "Failed to open settings window: " . e.Message)
        ShowOverlay("設定ウィンドウを開けませんでした", 3000)
    }
}

; Ctrl+Alt+F12: スクリプト再起動（改善版）
^!F12:: {
    result := MsgBox("スクリプトを再起動しますか？`n未保存の設定は失われます。", "確認", "YesNo Icon?")
    if (result == "Yes") {
        try {
            ; ログをフラッシュ
            FlushLogBuffer()
            
            ; 設定を保存
            if (ConfigManager.isDirty) {
                ConfigManager.Save()
            }
            
            ShowOverlay("スクリプト再起動中...", 1000)
            Sleep(1000)
            Reload()
        } catch {
            Reload()  ; エラーでも再起動
        }
    }
}

; Ctrl+Alt+Shift+F12: スクリプト終了（改善版）
^!+F12:: {
    result := MsgBox("スクリプトを終了しますか？", "確認", "YesNo Icon?")
    if (result == "Yes") {
        try {
            ; クリーンアップ
            LogInfo("MainHotkeys", "Script exit requested by user")
            FlushLogBuffer()
            
            if (ConfigManager.isDirty) {
                ConfigManager.Save()
            }
            
            ExitApp()
        } catch {
            ExitApp()  ; エラーでも終了
        }
    }
}

; ===================================================================
; ヘルパー関数
; ===================================================================

; --- ホットキー処理開始 ---
BeginHotkeyProcessing(hotkeyName) {
    global g_hotkey_processing
    
    if (g_hotkey_processing.Has(hotkeyName) && g_hotkey_processing[hotkeyName]) {
        return false
    }
    
    g_hotkey_processing[hotkeyName] := true
    return true
}

; --- ホットキー処理終了 ---
EndHotkeyProcessing(hotkeyName) {
    global g_hotkey_processing
    
    if (g_hotkey_processing.Has(hotkeyName)) {
        g_hotkey_processing[hotkeyName] := false
    }
}

; --- クールダウンチェック ---
CheckHotkeyCooldown(hotkeyName, showWarning := true) {
    global g_hotkey_last_press, HOTKEY_COOLDOWNS, g_hotkey_press_count
    
    currentTime := A_TickCount
    cooldown := HOTKEY_COOLDOWNS.Has(hotkeyName) ? HOTKEY_COOLDOWNS[hotkeyName] : 500
    
    if (g_hotkey_last_press.Has(hotkeyName)) {
        timeSinceLastPress := currentTime - g_hotkey_last_press[hotkeyName]
        
        if (timeSinceLastPress < cooldown) {
            ; 連打カウント
            if (!g_hotkey_press_count.Has(hotkeyName)) {
                g_hotkey_press_count[hotkeyName] := 0
            }
            g_hotkey_press_count[hotkeyName]++
            
            if (showWarning && g_hotkey_press_count[hotkeyName] > 2) {
                remainingTime := Round((cooldown - timeSinceLastPress) / 1000, 1)
                ShowOverlay(Format("{}秒後に使用可能", remainingTime), 1000)
            }
            
            LogDebug("MainHotkeys", Format("{} on cooldown ({}ms remaining)", 
                hotkeyName, cooldown - timeSinceLastPress))
            return false
        }
    }
    
    g_hotkey_last_press[hotkeyName] := currentTime
    g_hotkey_press_count[hotkeyName] := 0
    return true
}

; --- ホットキーリスト取得 ---
GetHotkeyList() {
    hotkeyList := []
    hotkeyList.Push("=== メインホットキー ===")
    hotkeyList.Push("F12: マクロのリセット・再始動")
    hotkeyList.Push("Shift+F12: マクロの手動停止/開始")
    hotkeyList.Push("Ctrl+F12: 緊急停止（自動開始も無効）")
    hotkeyList.Push("Alt+F12: 設定リロード")
    hotkeyList.Push("Pause: 一時停止/再開")
    hotkeyList.Push("  +Shift: フラスコのみ一時停止")
    hotkeyList.Push("ScrollLock: ステータス表示切り替え")
    hotkeyList.Push("F1: クイックヘルプ")
    hotkeyList.Push("")
    hotkeyList.Push("=== デバッグホットキー ===")
    hotkeyList.Push("F11: マナデバッグ表示")
    hotkeyList.Push("F10: エリア検出方式切り替え")
    hotkeyList.Push("F9: エリア検出デバッグ")
    hotkeyList.Push("F8: タイマーデバッグ")
    hotkeyList.Push("F7: 全体デバッグ情報")
    hotkeyList.Push("F6: ログビューア")
    hotkeyList.Push("")
    hotkeyList.Push("=== グローバル ===")
    hotkeyList.Push("Ctrl+Alt+F12: スクリプト再起動")
    hotkeyList.Push("Ctrl+Alt+Shift+F12: スクリプト終了")
    
    return hotkeyList
}

; --- 設定変更の適用 ---
ApplyConfigChanges() {
    global g_macro_active
    
    ; マクロが動作中の場合は再起動を提案
    if (g_macro_active) {
        result := MsgBox("設定を完全に適用するにはマクロの再起動が必要です。`n今すぐ再起動しますか？", 
            "設定変更", "YesNo Icon?")
        
        if (result == "Yes") {
            ResetMacro()
        }
    }
}

; --- ホットキー統計の取得 ---
GetHotkeyStats() {
    global g_hotkey_press_count, g_hotkey_last_press
    
    stats := Map()
    
    for key, count in g_hotkey_press_count {
        lastPress := g_hotkey_last_press.Has(key) ? 
            Round((A_TickCount - g_hotkey_last_press[key]) / 1000, 1) : 0
            
        stats[key] := Map(
            "pressCount", count,
            "lastPressAgo", lastPress
        )
    }
    
    return stats
}