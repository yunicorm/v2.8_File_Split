; ===================================================================
; メインホットキー定義
; マクロの主要な操作用ホットキー
; ===================================================================

; --- F12キー連打防止用グローバル変数 ---
global g_f12_processing := false
global g_f12_last_toggle := 0
global g_f12_cooldown := 1000  ; 1秒のクールダウン

; --- ホットキーコンテキスト設定 ---
#HotIf WinActive("ahk_group TargetWindows")

; ===================================================================
; F12: マクロのオン/オフ切り替え
; ===================================================================
F12:: {
    global g_f12_processing, g_f12_last_toggle, g_f12_cooldown
    
    ; 現在時刻を取得
    currentTime := A_TickCount
    
    ; 処理中またはクールダウン中の場合は無視
    if (g_f12_processing || (currentTime - g_f12_last_toggle < g_f12_cooldown)) {
        ; デバッグ用：ブロックされたことを表示
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
    
    ; マクロのトグル処理を実行
    try {
        ToggleMacro()
        LogInfo("MainHotkeys", "F12 pressed - Macro toggled")
    } catch as e {
        ShowOverlay("エラー: " . e.Message, 2000)
        LogError("MainHotkeys", "Error in F12 handler: " . e.Message)
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
; Ctrl+F12: 緊急停止（全機能を即座に停止）
; ===================================================================
^F12:: {
    ShowOverlay("緊急停止！", 3000)
    
    ; 全てのタイマーを停止
    StopAllTimers()
    
    ; マクロ状態をリセット
    global g_macro_active
    g_macro_active := false
    
    ; UIを更新
    UpdateStatusOverlay()
    
    LogWarn("MainHotkeys", "Emergency stop activated (Ctrl+F12)")
}

; ===================================================================
; Shift+F12: マクロ再起動
; ===================================================================
+F12:: {
    ShowOverlay("マクロ再起動中...", 1500)
    
    ; 一旦停止
    if (g_macro_active) {
        ToggleMacro()
        Sleep(500)
    }
    
    ; 再度開始
    ToggleMacro()
    
    LogInfo("MainHotkeys", "Macro restarted (Shift+F12)")
}

; ===================================================================
; Alt+F12: 設定リロード（将来の拡張用）
; ===================================================================
!F12:: {
    ShowOverlay("設定リロード機能は未実装です", 2000)
    ; TODO: Config.ahkの再読み込み機能を実装
}

; ===================================================================
; Pause: マクロの一時停止/再開
; ===================================================================
Pause:: {
    global g_macro_active
    
    if (g_macro_active) {
        ShowOverlay("マクロ一時停止", 1500)
        ToggleMacro()
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
    } catch {
        ShowOverlay("ステータス表示エラー", 1500)
    }
}

#HotIf  ; コンテキストをリセット