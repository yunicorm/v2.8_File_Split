; ===================================================================
; ステータス表示UI（修正版）
; 効率的な更新とエラーハンドリングの強化
; ===================================================================

; --- グローバル変数の追加 ---
global g_last_status_hash := ""
global g_status_update_timer := ""
global g_status_gui_creating := false

; --- ステータスオーバーレイ作成 ---
CreateStatusOverlay() {
    global statusGui, g_status_gui_creating
    
    ; 作成中フラグをチェック
    if (g_status_gui_creating) {
        LogDebug("StatusDisplay", "Status GUI creation already in progress")
        return
    }
    
    try {
        g_status_gui_creating := true
        
        ; 既存のGUIがあれば破棄
        if (IsSet(statusGui) && IsObject(statusGui)) {
            try {
                statusGui.Destroy()
            } catch {
                ; エラーは無視
            }
        }
        
        ; 新しいGUIを作成
        statusGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        statusGui.BackColor := "000000"
        
        ; 初期状態を作成
        RecreateStatusGui()
        
        ; ウィンドウ状態チェックタイマーを開始
        SetTimer(CheckWindowStatus, 250)  ; 250msに変更（パフォーマンス向上）
        
        ; ステータス更新チェックタイマーを開始
        g_status_update_timer := SetTimer(CheckStatusUpdate, 100)
        
        LogInfo("StatusDisplay", "Status overlay created successfully")
        
    } catch as e {
        LogError("StatusDisplay", "Failed to create status overlay: " . e.Message)
        ShowOverlay("ステータス表示の作成に失敗しました", 3000)
    } finally {
        g_status_gui_creating := false
    }
}

; --- ステータス更新チェック（効率化版） ---
CheckStatusUpdate() {
    global g_status_update_needed, g_last_status_hash, g_macro_active
    
    try {
        ; 現在の状態のハッシュを計算
        currentHash := ComputeStatusHash()
        
        ; ハッシュが変更されたか、強制更新フラグが立っている場合のみ更新
        if (currentHash != g_last_status_hash || g_status_update_needed) {
            g_status_update_needed := false
            g_last_status_hash := currentHash
            RecreateStatusGui()
        }
    } catch as e {
        LogError("StatusDisplay", "Status update check failed: " . e.Message)
    }
}

; --- 状態ハッシュの計算 ---
ComputeStatusHash() {
    global g_macro_active, g_mana_fill_rate, g_tincture_active
    global g_tincture_cooldown_end, g_flask_timer_active
    global g_loading_check_enabled, g_tincture_retry_count
    
    try {
        ; Tincture状態を取得
        tinctureStatus := GetTinctureStatus()
        
        ; クールダウン残り時間（秒単位に丸める）
        cooldownSec := 0
        if (g_tincture_cooldown_end > A_TickCount) {
            cooldownSec := Round((g_tincture_cooldown_end - A_TickCount) / 1000)
        }
        
        ; 状態を文字列化してハッシュ値を生成
        stateString := Format("{}-{}-{}-{}-{}-{}-{}", 
            g_macro_active ? "ON" : "OFF",
            g_mana_fill_rate,
            tinctureStatus.status,
            cooldownSec,
            g_flask_timer_active ? "ON" : "OFF",
            g_loading_check_enabled ? "ON" : "OFF",
            g_tincture_retry_count)
        
        return stateString
    } catch as e {
        LogError("StatusDisplay", "Failed to compute status hash: " . e.Message)
        return "error"
    }
}

; --- ステータス更新（強制） ---
UpdateStatusOverlay() {
    global g_status_update_needed
    g_status_update_needed := true
}

; --- GUI再作成（メモリリーク対策版） ---
RecreateStatusGui() {
    global statusGui, g_macro_active, g_status_gui_creating
    
    if (g_status_gui_creating) {
        return
    }
    
    try {
        g_status_gui_creating := true
        
        ; GUIが存在しない場合は何もしない
        if (!IsSet(statusGui) || !IsObject(statusGui)) {
            LogError("StatusDisplay", "StatusGui not initialized")
            return
        }
        
        ; 既存のコントロールを全て削除
        CleanupStatusControls()
        
        ; ステータステキストを構築して追加
        BuildStatusText()
        
        ; 透明度を設定
        WinSetTransparent(180, statusGui)
        
        ; 表示位置を設定（アクティブウィンドウとマクロ状態をチェック）
        if (WinActive("ahk_group TargetWindows") && g_macro_active) {
            ShowStatusWindowSafe()
        }
        
    } catch as e {
        LogError("StatusDisplay", "Failed to recreate status GUI: " . e.Message)
    } finally {
        g_status_gui_creating := false
    }
}

; --- 既存コントロールのクリーンアップ ---
CleanupStatusControls() {
    global statusGui
    
    try {
        ; 全てのコントロールを取得して削除
        for hwnd in WinGetControlsHwnd(statusGui) {
            try {
                ; コントロールを削除
                DllCall("DestroyWindow", "Ptr", hwnd)
            } catch {
                ; 個別のエラーは無視
            }
        }
    } catch as e {
        LogDebug("StatusDisplay", "Control cleanup error: " . e.Message)
    }
}

; --- ステータステキスト構築（改善版） ---
BuildStatusText() {
    global statusGui, g_macro_active, g_mana_fill_rate
    global g_tincture_active, g_tincture_cooldown_end
    global g_flask_timer_active, g_loading_check_enabled
    
    try {
        ; ステータス情報を構築
        statusLines := []
        
        ; マクロ状態
        statusLines.Push(Format("マクロ: {}", g_macro_active ? "ON" : "OFF"))
        
        if (g_macro_active) {
            ; マナ状態
            manaColor := GetManaStatusColor(g_mana_fill_rate)
            statusLines.Push(Format("マナ: {}%", g_mana_fill_rate))
            
            ; Tincture状態
            tinctureStatus := GetTinctureStatus()
            tinctureText := FormatTinctureStatus(tinctureStatus)
            statusLines.Push(tinctureText)
            
            ; フラスコ状態
            statusLines.Push(Format("Flask: {}", g_flask_timer_active ? "Auto" : "OFF"))
            
            ; エリア検出状態
            detectionType := ""
            if (ConfigManager.Get("ClientLog", "Enabled", true)) {
                detectionType := "ログ監視"
            } else if (g_loading_check_enabled) {
                detectionType := "画面検出"
            } else {
                detectionType := "無効"
            }
            statusLines.Push(Format("エリア検出: {}", detectionType))
        }
        
        ; テキストを結合
        statusText := ""
        for line in statusLines {
            statusText .= line . "`n"
        }
        statusText := RTrim(statusText, "`n")
        
        ; フォント設定
        statusGui.SetFont("s14 cWhite", "Arial")
        
        ; テキストコントロールを追加
        textControl := statusGui.Add("Text", "x10 y10 w200 h130", statusText)
        
        ; コントロールへの参照を保存（将来の更新用）
        statusGui.statusTextControl := textControl
        
    } catch as e {
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

; --- Tincture状態のフォーマット ---
FormatTinctureStatus(status) {
    text := "Tincture: "
    
    switch status.status {
        case "Active":
            text .= "Active"
        case "Cooldown":
            remaining := Round(status.cooldownRemaining / 1000, 1)
            text .= Format("CD: {}s", remaining)
        case "Verifying":
            text .= "確認中..."
        case "Retrying":
            text .= Format("再試行 {}/{}", status.retryCount, g_tincture_retry_max)
        case "Ready":
            text .= "Ready"
        default:
            text .= status.status
    }
    
    return text
}

; --- マナ状態に応じた色を取得 ---
GetManaStatusColor(manaPercent) {
    if (manaPercent >= 50) {
        return "00FF00"  ; 緑
    } else if (manaPercent >= 30) {
        return "FFFF00"  ; 黄
    } else if (manaPercent > 0) {
        return "FF8800"  ; オレンジ
    } else {
        return "FF0000"  ; 赤
    }
}

; --- ウィンドウ状態チェック（最適化版） ---
CheckWindowStatus() {
    global statusGui, g_macro_active
    
    ; GUIが存在しない場合は何もしない
    if (!IsSet(statusGui) || !IsObject(statusGui)) {
        return
    }
    
    try {
        ; Path of ExileまたはStreaming Clientがアクティブか確認
        isActive := WinActive("ahk_group TargetWindows")
        
        if (isActive && g_macro_active) {
            ; アクティブかつマクロONの場合は表示
            if (!WinExist(statusGui)) {
                ShowStatusWindowSafe()
            }
        } else {
            ; それ以外の場合は非表示
            try {
                statusGui.Hide()
            } catch {
                ; Hide失敗は無視
            }
        }
    } catch as e {
        LogError("StatusDisplay", "Error in CheckWindowStatus: " . e.Message)
    }
}

; --- ステータスウィンドウを表示（StatusDisplay版） ---
ShowStatusWindowSafe() {
    global statusGui
    
    try {
        if (!IsSet(statusGui) || !IsObject(statusGui)) {
            return
        }
        
        ; 設定から位置とサイズを取得
        statusWidth := ConfigManager.Get("UI", "StatusWidth", 220)
        statusHeight := ConfigManager.Get("UI", "StatusHeight", 150)
        statusOffsetY := ConfigManager.Get("UI", "StatusOffsetY", 250)
        
        screenWidth := ConfigManager.Get("Resolution", "ScreenWidth", 3440)
        screenHeight := ConfigManager.Get("Resolution", "ScreenHeight", 1440)
        
        ; 中央下部に配置
        statusX := (screenWidth / 2) - (statusWidth / 2)
        statusY := screenHeight - statusOffsetY
        
        ; ウィンドウを表示
        statusGui.Show(Format("x{} y{} w{} h{} NoActivate NA", 
            statusX, statusY, statusWidth, statusHeight))
        
    } catch as e {
        LogError("StatusDisplay", "Failed to show status window: " . e.Message)
    }
}

; --- UI要素のクリーンアップ ---
CleanupUI() {
    global statusGui, overlayGui, debugGuis, g_status_update_timer
    
    try {
        ; ステータス更新タイマーを停止
        if (g_status_update_timer) {
            SetTimer(g_status_update_timer, 0)
            g_status_update_timer := ""
        }
        
        ; ウィンドウチェックタイマーを停止
        SetTimer(CheckWindowStatus, 0)
        
        ; ステータスGUIをクリーンアップ
        if (IsSet(statusGui) && IsObject(statusGui)) {
            try {
                statusGui.Destroy()
                statusGui := ""
            } catch {
                ; エラーは無視
            }
        }
        
        ; オーバーレイGUIをクリーンアップ
        if (IsSet(overlayGui) && IsObject(overlayGui)) {
            try {
                overlayGui.Destroy()
                overlayGui := ""
            } catch {
                ; エラーは無視
            }
        }
        
        ; デバッグGUIをクリーンアップ
        if (IsSet(CleanupDebugGuis)) {
            CleanupDebugGuis()
        }
        
        ; ハッシュをリセット
        global g_last_status_hash
        g_last_status_hash := ""
        
        LogInfo("StatusDisplay", "UI cleanup completed")
        
    } catch as e {
        LogError("StatusDisplay", "UI cleanup failed: " . e.Message)
    }
}

; --- ステータス表示のリフレッシュ ---
RefreshStatusDisplay() {
    global statusGui, g_macro_active, g_last_status_hash
    
    try {
        if (IsSet(statusGui) && IsObject(statusGui) && g_macro_active) {
            ; ハッシュをリセットして強制更新
            g_last_status_hash := ""
            RecreateStatusGui()
            LogDebug("StatusDisplay", "Status display refreshed")
        }
    } catch as e {
        LogError("StatusDisplay", "Failed to refresh status display: " . e.Message)
    }
}

; --- ステータス表示の一時的な非表示 ---
TemporaryHideStatus(duration := 2000) {
    global statusGui
    
    try {
        if (IsSet(statusGui) && IsObject(statusGui)) {
            statusGui.Hide()
            SetTimer(() => ShowStatusIfActive(), -duration)
        }
    } catch as e {
        LogError("StatusDisplay", "Failed to temporarily hide status: " . e.Message)
    }
}

; --- アクティブな場合のみ表示 ---
ShowStatusIfActive() {
    global g_macro_active
    
    if (g_macro_active && WinActive("ahk_group TargetWindows")) {
        ShowStatusWindowSafe()
    }
}