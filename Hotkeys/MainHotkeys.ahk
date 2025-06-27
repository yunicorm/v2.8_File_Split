; ===================================================================
; メインホットキー定義
; マクロの主要な操作用ホットキー
; ===================================================================

; --- ShowOverlay関数が見つからない場合の一時的な定義 ---
if (!IsSet(ShowOverlay)) {
    ShowOverlay(message, duration := 2000) {
        ToolTip(message)
        SetTimer(() => ToolTip(), -duration)
    }
}

; --- F12キー連打防止用グローバル変数 ---
global g_f12_processing := false
global g_f12_last_toggle := 0
global g_f12_cooldown := 1000  ; 1秒のクールダウン

; --- ホットキーコンテキスト設定 ---
#HotIf WinActive("ahk_group TargetWindows")

; ===================================================================
; F12: マクロのリセット・再始動
; ===================================================================
F12:: {
    global g_f12_processing, g_f12_last_toggle, g_f12_cooldown, g_macro_active
    
    ; 現在時刻を取得
    currentTime := A_TickCount
    
    ; 処理中またはクールダウン中の場合は無視
    if (g_f12_processing || (currentTime - g_f12_last_toggle < g_f12_cooldown)) {
        ShowOverlay("処理中... 少し待ってください", 500)
        return
    }
    
    ; 処理開始をマーク
    g_f12_processing := true
    g_f12_last_toggle := currentTime
    
    ; キーがまだ押されている場合は離されるまで待つ
    if (GetKeyState("F12", "P")) {
        KeyWait("F12", "T2")  ; 最大2秒待機
    }
    
    ; マクロのリセット・再始動処理
    try {
        ResetMacro()
    } catch Error as e {
        ShowOverlay("エラー: " . e.Message, 2000)
        LogErrorWithStack("MainHotkeys", "Error in F12 handler", e)
    }
    
    ; 処理完了後、少し待ってからフラグをリセット
    SetTimer(() => ResetF12Flag(), -100)
}

; --- F12フラグリセット関数 ---
ResetF12Flag() {
    global g_f12_processing
    g_f12_processing := false
}

; ===================================================================
; Shift+F12: マクロの完全停止（手動停止）
; ===================================================================
+F12:: {
    global g_macro_active
    
    if (g_macro_active) {
        ShowOverlay("マクロを停止します", 1500)
        ManualStopMacro()  ; 手動停止関数を呼び出し
        LogInfo("MainHotkeys", "Shift+F12 pressed - Macro manually stopped")
    } else {
        ShowOverlay("マクロを開始します", 1500)
        ToggleMacro()  ; 停止中の場合は通常の開始
        LogInfo("MainHotkeys", "Shift+F12 pressed - Macro started")
    }
}

; ===================================================================
; Ctrl+F12: 緊急停止（全機能を即座に停止）
; ===================================================================
^F12:: {
    EmergencyStopMacro()  ; 緊急停止関数を呼び出し
    LogWarn("MainHotkeys", "Emergency stop activated (Ctrl+F12)")
}

; ===================================================================
; Alt+F12: 設定リロード
; ===================================================================
!F12:: {
    ShowOverlay("設定をリロード中...", 1500)
    
    if (ReloadConfiguration()) {
        ShowOverlay("設定のリロードが完了しました", 2000)
        LogInfo("MainHotkeys", "Configuration reloaded successfully")
    } else {
        ShowOverlay("設定のリロードに失敗しました", 2000)
        LogError("MainHotkeys", "Failed to reload configuration")
    }
}

; ===================================================================
; Pause: マクロの一時停止/再開
; ===================================================================
Pause:: {
    global g_macro_active
    
    if (g_macro_active) {
        ShowOverlay("マクロ一時停止", 1500)
        ManualStopMacro()  ; 手動停止として処理
    } else {
        ShowOverlay("マクロ再開", 1500)
        ToggleMacro()
    }
    
    LogInfo("MainHotkeys", "Pause key pressed")
}

; ===================================================================
; ScrollLock: ステータス表示の切り替え
; ===================================================================
ScrollLock:: {
    global statusGui
    
    try {
        if (statusGui && IsObject(statusGui)) {
            if (WinExist(statusGui)) {
                statusGui.Hide()
                ShowOverlay("ステータス非表示", 1000)
            } else {
                ShowStatusWindow()
                ShowOverlay("ステータス表示", 1000)
            }
        }
    } catch Error as e {
        ShowOverlay("ステータス表示エラー", 1500)
        LogError("MainHotkeys", "Status display error: " . e.Message)
    }
}

; ===================================================================
; Ctrl+H: ホットキー一覧表示
; ===================================================================
^h:: {
    ; 更新されたホットキー一覧
    hotkeyList := [
        "=== メインホットキー ===",
        "F12: マクロのリセット・再始動",
        "Shift+F12: マクロの手動停止/開始",
        "Ctrl+F12: 緊急停止（自動開始も無効）",
        "Alt+F12: 設定リロード",
        "Pause: 一時停止/再開",
        "ScrollLock: ステータス表示切り替え",
        "",
        "=== デバッグホットキー ===",
        "F11: マナデバッグ表示",
        "F10: エリア検出方式切り替え",
        "F9: エリア検出デバッグ",
        "F8: タイマーデバッグ",
        "F7: 全体デバッグ情報",
        "F6: ログビューア"
    ]
    
    ShowMultiLineOverlay(hotkeyList, 5000)
}

#HotIf  ; コンテキストをリセット