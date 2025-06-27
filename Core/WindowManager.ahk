; ===================================================================
; ウィンドウ管理システム
; Path of ExileとSteamリモートプレイのウィンドウ検出と管理
; ===================================================================

; --- ウィンドウ状態チェック ---
CheckWindowStatus() {
    global statusGui, g_macro_active, g_status_update_needed
    
    ; GUIが存在しない場合は何もしない
    if (!statusGui || !IsObject(statusGui)) {
        return
    }
    
    ; Path of ExileまたはStreaming Clientがアクティブか確認
    try {
        if (WinActive("ahk_group TargetWindows")) {
            ; アクティブな場合は表示
            ShowStatusWindow()
            
            ; Tinctureのクールダウン更新チェック
            CheckTinctureCooldownDisplay()
        } else {
            ; アクティブでない場合は非表示
            statusGui.Hide()
        }
    } catch {
        ; エラーが発生した場合は無視
        LogError("WindowManager", "Error in CheckWindowStatus")
    }
}

; --- ステータスウィンドウを表示 ---
ShowStatusWindow() {
    global statusGui
    
    statusWidth := 220
    statusHeight := 150
    statusX := 0 + (3440 / 2) - (statusWidth / 2)
    statusY := 1440 - 250  ; 画面下部から250px上
    
    statusGui.Show("x" . statusX . " y" . statusY . " w" . statusWidth . " h" . statusHeight . " NoActivate NA")
}

; --- Tinctureクールダウン表示の更新チェック ---
CheckTinctureCooldownDisplay() {
    global g_macro_active, g_tincture_active, g_tincture_cooldown_end, g_status_update_needed
    
    if (g_macro_active && !g_tincture_active && g_tincture_cooldown_end > A_TickCount) {
        ; 前回の残り時間と1秒以上差がある場合のみ更新
        static lastRemaining := 0
        currentRemaining := Round((g_tincture_cooldown_end - A_TickCount) / 1000, 1)
        
        if (Abs(currentRemaining - lastRemaining) >= 1) {
            lastRemaining := currentRemaining
            g_status_update_needed := true
        }
    }
}

; --- ターゲットウィンドウのチェック ---
IsTargetWindowActive() {
    return WinActive("ahk_group TargetWindows")
}

; --- ウィンドウ情報を取得 ---
GetTargetWindowInfo() {
    if (WinActive("ahk_exe streaming_client.exe")) {
        return {
            type: "Steam Remote Play",
            exe: "streaming_client.exe",
            hwnd: WinGetID("A")
        }
    } else if (WinActive("ahk_exe PathOfExileSteam.exe")) {
        return {
            type: "Path of Exile",
            exe: "PathOfExileSteam.exe",
            hwnd: WinGetID("A")
        }
    }
    
    return {
        type: "None",
        exe: "",
        hwnd: 0
    }
}

; --- ウィンドウの座標を取得 ---
GetWindowCoordinates() {
    if (!IsTargetWindowActive()) {
        return {x: 0, y: 0, width: 0, height: 0}
    }
    
    WinGetPos(&x, &y, &w, &h, "A")
    return {x: x, y: y, width: w, height: h}
}

; --- マルチモニター対応の座標計算 ---
GetMonitorInfo() {
    ; 現在のウィンドウがどのモニターにあるか判定
    MonitorCount := MonitorGetCount()
    
    if (MonitorCount == 1) {
        return {
            count: 1,
            primary: 1,
            current: 1,
            left: 0,
            top: 0,
            width: 3440,
            height: 1440
        }
    }
    
    ; マルチモニター環境での処理
    ; TODO: より詳細なモニター情報取得
    return {
        count: MonitorCount,
        primary: MonitorGetPrimary(),
        current: 1,  // 簡略化
        left: 0,
        top: 0,
        width: 3440,
        height: 1440
    }
}