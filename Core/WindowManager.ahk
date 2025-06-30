; ===================================================================
; ウィンドウ管理システム（エラーハンドリング強化版）
; Path of ExileとSteamリモートプレイのウィンドウ検出と管理
; ===================================================================

; --- ウィンドウ状態チェック（WindowManager版） ---
CheckWindowStatusLegacy() {
    global statusGui, g_macro_active, g_status_update_needed
    
    ; GUIが存在しない場合は何もしない
    if (!statusGui || !IsObject(statusGui)) {
        return
    }
    
    try {
        ; Path of ExileまたはStreaming Clientがアクティブか確認
        if (WinActive("ahk_group TargetWindows")) {
            ; アクティブな場合は表示
            ShowStatusWindow()
            
            ; Tinctureのクールダウン更新チェック
            CheckTinctureCooldownDisplay()
        } else {
            ; アクティブでない場合は非表示
            try {
                statusGui.Hide()
            } catch {
                ; Hide失敗は無視
            }
        }
    } catch as e {
        LogError("WindowManager", "Error in CheckWindowStatus: " . e.Message)
    }
}

; --- ステータスウィンドウを表示 ---
ShowStatusWindow() {
    global statusGui
    
    try {
        statusWidth := ConfigManager.Get("UI", "StatusWidth", 220)
        statusHeight := ConfigManager.Get("UI", "StatusHeight", 150)
        statusOffsetY := ConfigManager.Get("UI", "StatusOffsetY", 250)
        
        screenWidth := ConfigManager.Get("Resolution", "ScreenWidth", 3440)
        screenHeight := ConfigManager.Get("Resolution", "ScreenHeight", 1440)
        
        statusX := (screenWidth / 2) - (statusWidth / 2)
        statusY := screenHeight - statusOffsetY
        
        statusGui.Show("x" . statusX . " y" . statusY . " w" . statusWidth . " h" . statusHeight . " NoActivate NA")
        
    } catch as e {
        LogError("WindowManager", "Failed to show status window: " . e.Message)
    }
}

; --- Tinctureクールダウン表示の更新チェック ---
CheckTinctureCooldownDisplay() {
    global g_macro_active, g_tincture_active, g_tincture_cooldown_end, g_status_update_needed
    
    try {
        if (g_macro_active && !g_tincture_active && g_tincture_cooldown_end > A_TickCount) {
            ; 前回の残り時間と1秒以上差がある場合のみ更新
            static lastRemaining := 0
            currentRemaining := Round((g_tincture_cooldown_end - A_TickCount) / 1000, 1)
            
            if (Abs(currentRemaining - lastRemaining) >= 1) {
                lastRemaining := currentRemaining
                g_status_update_needed := true
            }
        }
    } catch as e {
        LogError("WindowManager", "Tincture cooldown display error: " . e.Message)
    }
}

; --- ターゲットウィンドウのチェック ---
IsTargetWindowActive() {
    try {
        return WinActive("ahk_group TargetWindows")
    } catch as e {
        LogError("WindowManager", "Window check failed: " . e.Message)
        return false
    }
}

; --- ウィンドウ情報を取得 ---
GetTargetWindowInfo() {
    try {
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
    } catch as e {
        LogError("WindowManager", "Failed to get window info: " . e.Message)
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
    
    try {
        WinGetPos(&x, &y, &w, &h, "A")
        return {x: x, y: y, width: w, height: h}
    } catch as e {
        LogError("WindowManager", "Failed to get window coordinates: " . e.Message)
        return {x: 0, y: 0, width: 0, height: 0}
    }
}

; --- マルチモニター対応の座標計算 ---
GetMonitorInfo() {
    try {
        ; 現在のウィンドウがどのモニターにあるか判定
        MonitorCount := MonitorGetCount()
        
        if (MonitorCount == 1) {
            return {
                count: 1,
                primary: 1,
                current: 1,
                left: 0,
                top: 0,
                width: ConfigManager.Get("Resolution", "ScreenWidth", 3440),
                height: ConfigManager.Get("Resolution", "ScreenHeight", 1440)
            }
        }
        
        ; マルチモニター環境での処理
        currentMonitor := 1
        
        ; アクティブウィンドウがある場合、そのモニターを特定
        if (IsTargetWindowActive()) {
            WinGetPos(&winX, &winY, , , "A")
            
            Loop MonitorCount {
                MonitorGet(A_Index, &left, &top, &right, &bottom)
                if (winX >= left && winX < right && winY >= top && winY < bottom) {
                    currentMonitor := A_Index
                    break
                }
            }
        }
        
        ; 現在のモニター情報を取得
        MonitorGet(currentMonitor, &left, &top, &right, &bottom)
        
        return {
            count: MonitorCount,
            primary: MonitorGetPrimary(),
            current: currentMonitor,
            left: left,
            top: top,
            width: right - left,
            height: bottom - top
        }
        
    } catch as e {
        LogError("WindowManager", "Failed to get monitor info: " . e.Message)
        
        ; エラー時のデフォルト値
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
}

; --- ウィンドウの中心座標を取得 ---
GetWindowCenter() {
    coords := GetWindowCoordinates()
    return {
        x: coords.x + (coords.width / 2),
        y: coords.y + (coords.height / 2)
    }
}

; --- ウィンドウのアスペクト比を取得 ---
GetWindowAspectRatio() {
    coords := GetWindowCoordinates()
    if (coords.height > 0) {
        return coords.width / coords.height
    }
    return 16/9  ; デフォルト
}