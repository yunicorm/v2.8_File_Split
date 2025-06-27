; ===================================================================
; ステータス表示UI（エラーハンドリング強化版）
; ===================================================================

; --- ステータスオーバーレイ作成 ---
CreateStatusOverlay() {
    global statusGui
    
    try {
        statusGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        statusGui.BackColor := "000000"
        RecreateStatusGui()
        
        ; 定期的にウィンドウ状態をチェック
        SetTimer(CheckWindowStatus, 100)
        
        ; ステータス更新チェック
        SetTimer(CheckStatusUpdate, 100)
        
        LogInfo("StatusDisplay", "Status overlay created successfully")
        
    } catch Error as e {
        LogError("StatusDisplay", "Failed to create status overlay: " . e.Message)
        ShowOverlay("ステータス表示の作成に失敗しました", 3000)
    }
}

; --- ステータス更新チェック ---
CheckStatusUpdate() {
    global g_status_update_needed
    
    try {
        if (g_status_update_needed) {
            g_status_update_needed := false
            RecreateStatusGui()
        }
    } catch Error as e {
        LogError("StatusDisplay", "Status update check failed: " . e.Message)
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
    
    try {
        ; 新しいGUIを作成
        if (statusGui && IsObject(statusGui)) {
            try {
                ; 既存のコントロールを削除
                for hwnd in WinGetControlsHwnd(statusGui) {
                    ControlSetText("", hwnd)
                }
            } catch {
                ; コントロール削除のエラーは無視
            }
        }
        
        ; ステータステキストを追加
        BuildStatusText()
        
        WinSetTransparent(180, statusGui)
        
        ; 表示位置を設定
        if (WinActive("ahk_group TargetWindows") && g_macro_active) {
            ShowStatusWindow()
        }
        
    } catch Error as e {
        LogError("StatusDisplay", "Failed to recreate status GUI: " . e.Message)
    }
}

; --- ステータステキスト構築 ---
BuildStatusText() {
    global statusGui, g_macro_active, g_mana_fill_rate
    global g_tincture_active, g_tincture_cooldown_end
    global g_flask_timer_active, g_loading_check_enabled
    
    try {
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
        
    } catch Error as e {
        LogError("StatusDisplay", "Failed to build status text: " . e.Message)
        
        ; エラー時の簡易表示
        try {
            statusGui.SetFont("s14 cRed", "Arial")
            statusGui.Add("Text", "x10 y10 w200 h130", "Status Error")
        } catch {
            ; 再度のエラーは無視
        }
    }
}

; --- ステータスオーバーレイ表示（関数名を統一） ---
ShowStatusOverlay() {
    ShowStatusWindow()
}

; --- UI要素のクリーンアップ ---
CleanupUI() {
    global statusGui, overlayGui, debugGuis
    
    try {
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
        
        LogInfo("StatusDisplay", "UI cleanup completed")
        
    } catch Error as e {
        LogError("StatusDisplay", "UI cleanup failed: " . e.Message)
    }
}

; --- ステータス表示のリフレッシュ ---
RefreshStatusDisplay() {
    global statusGui, g_macro_active
    
    try {
        if (statusGui && IsObject(statusGui) && g_macro_active) {
            RecreateStatusGui()
            LogDebug("StatusDisplay", "Status display refreshed")
        }
    } catch Error as e {
        LogError("StatusDisplay", "Failed to refresh status display: " . e.Message)
    }
}

; --- ステータス表示の一時的な非表示 ---
TemporaryHideStatus(duration := 2000) {
    global statusGui
    
    try {
        if (statusGui && IsObject(statusGui)) {
            statusGui.Hide()
            SetTimer(() => ShowStatusWindow(), -duration)
        }
    } catch Error as e {
        LogError("StatusDisplay", "Failed to temporarily hide status: " . e.Message)
    }