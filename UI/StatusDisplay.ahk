; ===================================================================
; ステータス表示UI
; ===================================================================

; --- ステータスオーバーレイ作成 ---
CreateStatusOverlay() {
    global statusGui
    
    statusGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
    statusGui.BackColor := "000000"
    RecreateStatusGui()
    
    ; 定期的にウィンドウ状態をチェック
    SetTimer(CheckWindowStatus, 100)
    
    ; ステータス更新チェック
    SetTimer(CheckStatusUpdate, 100)
}

; --- ステータス更新チェック ---
CheckStatusUpdate() {
    global g_status_update_needed
    
    if (g_status_update_needed) {
        g_status_update_needed := false
        RecreateStatusGui()
    }
}

; --- ステータス更新 ---
UpdateStatusOverlay() {
    global g_status_update_needed
    g_status_update_needed := true
}

; --- GUI再作成 ---
RecreateStatusGui() {
    global statusGui, g_macro_active
    
    ; 新しいGUIを作成
    if (statusGui && IsObject(statusGui)) {
        try {
            ; 既存のコントロールを削除
            for hwnd in WinGetControlsHwnd(statusGui) {
                ControlSetText("", hwnd)
            }
        } catch {
            ; エラーは無視
        }
    }
    
    ; ステータステキストを追加
    BuildStatusText()
    
    WinSetTransparent(180, statusGui)
    
    ; 表示位置を設定
    if (WinActive("ahk_group TargetWindows") && g_macro_active) {
        ShowStatusWindow()
    }
}

; --- ステータステキスト構築 ---
BuildStatusText() {
    global statusGui, g_macro_active, g_mana_fill_rate
    global g_tincture_active, g_tincture_cooldown_end
    global g_flask_timer_active, g_loading_check_enabled
    
    ; 既存のテキストコントロールをクリア
    try {
        for hwnd in WinGetControlsHwnd(statusGui) {
            ControlSetText("", hwnd)
        }
    } catch {
        ; エラーは無視
    }
    
    ; ステータス情報を構築
    statusText := ""
    
    ; マクロ状態
    statusText .= "マクロ: " . (g_macro_active ? "ON" : "OFF") . "`n"
    
    if (g_macro_active) {
        ; マナ状態
        statusText .= "マナ: " . g_mana_fill_rate . "%`n"
        
        ; Tincture状態
        if (g_tincture_active) {
            statusText .= "Tincture: Active`n"
        } else if (g_tincture_cooldown_end > A_TickCount) {
            remaining := Round((g_tincture_cooldown_end - A_TickCount) / 1000, 1)
            statusText .= "Tincture CD: " . remaining . "s`n"
        } else {
            statusText .= "Tincture: Ready`n"
        }
        
        ; フラスコ状態
        statusText .= "Flask: " . (g_flask_timer_active ? "Auto" : "OFF") . "`n"
        
        ; ロード画面検出
        if (g_loading_check_enabled) {
            statusText .= "ロード検出: ON"
        }
    }
    
    ; テキストコントロールを追加
    statusGui.SetFont("s14 cWhite", "Arial")
    statusGui.Add("Text", "x10 y10 w200 h130", statusText)
}

; --- ステータスオーバーレイ表示（関数名を統一） ---
ShowStatusOverlay() {
    ShowStatusWindow()
}

; --- UI要素のクリーンアップ ---
CleanupUI() {
    global statusGui, overlayGui, debugGuis
    
    ; ステータスGUIをクリーンアップ
    if (statusGui && IsObject(statusGui)) {
        try {
            statusGui.Destroy()
        } catch {
            ; エラーは無視
        }
    }
    
    ; オーバーレイGUIをクリーンアップ
    if (overlayGui && IsObject(overlayGui)) {
        try {
            overlayGui.Destroy()
        } catch {
            ; エラーは無視
        }
    }
    
    ; デバッグGUIをクリーンアップ
    CleanupDebugGuis()
}