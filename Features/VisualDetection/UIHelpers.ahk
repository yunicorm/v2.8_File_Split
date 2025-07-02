; UI Helpers Module
; Extended overlay and notification functions for visual detection
; v2.9.6 - Extracted from VisualDetection.ahk for better modularity

; UI Helper globals
global g_multi_line_overlay_gui := ""
global g_notification_overlay_gui := ""
global g_progress_overlay_gui := ""

; Overlay display constants
global OVERLAY_DEFAULT_DURATION := 2000
global OVERLAY_LONG_DURATION := 5000
global OVERLAY_SHORT_DURATION := 1000

; Enhanced multi-line overlay display
ShowMultiLineOverlay(lines, duration := 5000) {
    global g_multi_line_overlay_gui
    
    try {
        LogDebug("VisualDetection", Format("ShowMultiLineOverlay called with {} lines, duration {}", lines.Length, duration))
        
        ; 既存のオーバーレイを削除
        if (g_multi_line_overlay_gui && g_multi_line_overlay_gui != "") {
            try {
                g_multi_line_overlay_gui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; マルチラインGUI作成
        g_multi_line_overlay_gui := Gui("+AlwaysOnTop -MaximizeBox", "情報表示")
        g_multi_line_overlay_gui.BackColor := "0x2D2D30"  ; ダークグレー
        
        ; フォント設定
        g_multi_line_overlay_gui.SetFont("s10", "Consolas")
        
        ; テキスト内容を構築
        content := ""
        for line in lines {
            content .= line . "`n"
        }
        
        ; テキストコントロール追加
        g_multi_line_overlay_gui.SetFont("s10 cLime", "Consolas")
        textControl := g_multi_line_overlay_gui.Add("Text", "w500 h300", content)
        
        ; 閉じるボタン
        g_multi_line_overlay_gui.SetFont("s10", "Segoe UI")
        btnClose := g_multi_line_overlay_gui.Add("Button", "w100 x200 y+10", "閉じる")
        btnClose.OnEvent("Click", (*) => CloseMultiLineOverlay())
        
        ; ESCキーで閉じる
        g_multi_line_overlay_gui.OnEvent("Escape", (*) => CloseMultiLineOverlay())
        
        ; 画面中央に表示
        monitors := GetMonitorInfo()
        if (monitors.Has("primary")) {
            centerX := monitors["primary"]["centerX"] - 250
            centerY := monitors["primary"]["centerY"] - 200
        } else {
            centerX := A_ScreenWidth // 2 - 250
            centerY := A_ScreenHeight // 2 - 200
        }
        
        g_multi_line_overlay_gui.Show(Format("x{} y{} w520 h350", centerX, centerY))
        
        ; 自動閉じるタイマー設定
        if (duration > 0) {
            SetTimer(() => CloseMultiLineOverlay(), -duration)
        }
        
        LogDebug("VisualDetection", "Multi-line overlay displayed successfully")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to show multi-line overlay: " . e.Message)
        ; フォールバック: 単純なオーバーレイ
        fallbackText := ""
        for line in lines {
            fallbackText .= line . " | "
        }
        ShowOverlay(fallbackText, duration)
        return false
    }
}

; マルチラインオーバーレイを閉じる
CloseMultiLineOverlay() {
    global g_multi_line_overlay_gui
    
    try {
        if (g_multi_line_overlay_gui && g_multi_line_overlay_gui != "") {
            g_multi_line_overlay_gui.Destroy()
            g_multi_line_overlay_gui := ""
        }
    } catch as e {
        LogError("VisualDetection", "Failed to close multi-line overlay: " . e.Message)
    }
}

; 進捗表示オーバーレイ
ShowProgressOverlay(title, currentStep, totalSteps, stepDescription := "") {
    global g_progress_overlay_gui
    
    try {
        ; 既存の進捗オーバーレイを削除
        if (g_progress_overlay_gui && g_progress_overlay_gui != "") {
            try {
                g_progress_overlay_gui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 進捗GUI作成
        g_progress_overlay_gui := Gui("+AlwaysOnTop -MaximizeBox", title)
        g_progress_overlay_gui.BackColor := "0x2D2D30"
        
        ; タイトル
        g_progress_overlay_gui.SetFont("s12 Bold cWhite", "Segoe UI")
        g_progress_overlay_gui.Add("Text", "Center w300 h30", title)
        
        ; 進捗バー
        progressPercent := Round((currentStep / totalSteps) * 100)
        g_progress_overlay_gui.SetFont("s10 cLime", "Segoe UI")
        g_progress_overlay_gui.Add("Progress", "w280 h20 Range0-100", progressPercent)
        
        ; 進捗テキスト
        progressText := Format("{} / {} ({:.0f}%)", currentStep, totalSteps, progressPercent)
        g_progress_overlay_gui.Add("Text", "Center w300 h25 cWhite", progressText)
        
        ; ステップ説明
        if (stepDescription != "") {
            g_progress_overlay_gui.SetFont("s9 cSilver", "Segoe UI")
            g_progress_overlay_gui.Add("Text", "Center w300 h30", stepDescription)
        }
        
        ; 画面中央に表示
        monitors := GetMonitorInfo()
        if (monitors.Has("primary")) {
            centerX := monitors["primary"]["centerX"] - 160
            centerY := monitors["primary"]["centerY"] - 75
        } else {
            centerX := A_ScreenWidth // 2 - 160
            centerY := A_ScreenHeight // 2 - 75
        }
        
        g_progress_overlay_gui.Show(Format("x{} y{} w320 h150", centerX, centerY))
        
        LogDebug("VisualDetection", Format("Progress overlay shown: {}/{} - {}", currentStep, totalSteps, stepDescription))
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to show progress overlay: " . e.Message)
        return false
    }
}

; 進捗オーバーレイを閉じる
CloseProgressOverlay() {
    global g_progress_overlay_gui
    
    try {
        if (g_progress_overlay_gui && g_progress_overlay_gui != "") {
            g_progress_overlay_gui.Destroy()
            g_progress_overlay_gui := ""
        }
    } catch as e {
        LogError("VisualDetection", "Failed to close progress overlay: " . e.Message)
    }
}

; 通知スタイルのオーバーレイ
ShowNotificationOverlay(title, message, type := "info", duration := 3000) {
    global g_notification_overlay_gui
    
    try {
        ; 既存の通知を削除
        if (g_notification_overlay_gui && g_notification_overlay_gui != "") {
            try {
                g_notification_overlay_gui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 通知GUI作成
        g_notification_overlay_gui := Gui("+AlwaysOnTop -Caption +ToolWindow", "通知")
        
        ; タイプに応じた色設定
        switch type {
            case "success":
                g_notification_overlay_gui.BackColor := "0x2D5016"  ; 暗い緑
                iconColor := "Lime"
                icon := "✓"
            case "warning":
                g_notification_overlay_gui.BackColor := "0x4A3C00"  ; 暗い黄
                iconColor := "Yellow"
                icon := "⚠"
            case "error":
                g_notification_overlay_gui.BackColor := "0x4A1515"  ; 暗い赤
                iconColor := "Red"
                icon := "✗"
            default:  ; info
                g_notification_overlay_gui.BackColor := "0x1E2951"  ; 暗い青
                iconColor := "Aqua"
                icon := "ℹ"
        }
        
        ; アイコン
        g_notification_overlay_gui.SetFont("s16 Bold c" . iconColor, "Segoe UI")
        g_notification_overlay_gui.Add("Text", "x10 y10 w30 h30 Center", icon)
        
        ; タイトル
        g_notification_overlay_gui.SetFont("s11 Bold cWhite", "Segoe UI")
        g_notification_overlay_gui.Add("Text", "x50 y10 w250 h25", title)
        
        ; メッセージ
        g_notification_overlay_gui.SetFont("s9 cSilver", "Segoe UI")
        g_notification_overlay_gui.Add("Text", "x50 y35 w250 h40", message)
        
        ; 右下に表示
        monitors := GetMonitorInfo()
        if (monitors.Has("primary")) {
            x := monitors["primary"]["right"] - 320
            y := monitors["primary"]["bottom"] - 100
        } else {
            x := A_ScreenWidth - 320
            y := A_ScreenHeight - 100
        }
        
        g_notification_overlay_gui.Show(Format("x{} y{} w310 h80", x, y))
        WinSetTransparent(240, g_notification_overlay_gui)
        
        ; 自動閉じるタイマー
        if (duration > 0) {
            SetTimer(() => CloseNotificationOverlay(), -duration)
        }
        
        LogDebug("VisualDetection", Format("Notification overlay shown: {} - {}", title, message))
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to show notification overlay: " . e.Message)
        return false
    }
}

; 通知オーバーレイを閉じる
CloseNotificationOverlay() {
    global g_notification_overlay_gui
    
    try {
        if (g_notification_overlay_gui && g_notification_overlay_gui != "") {
            g_notification_overlay_gui.Destroy()
            g_notification_overlay_gui := ""
        }
    } catch as e {
        LogError("VisualDetection", "Failed to close notification overlay: " . e.Message)
    }
}

; 設定確認ダイアログ
ShowConfirmationDialog(title, message, yesCallback, noCallback := "") {
    try {
        result := MsgBox(message, title, "YesNo Icon?")
        
        if (result == "Yes" && yesCallback != "") {
            yesCallback.Call()
        } else if (result == "No" && noCallback != "") {
            noCallback.Call()
        }
        
        return result == "Yes"
        
    } catch as e {
        LogError("VisualDetection", "Failed to show confirmation dialog: " . e.Message)
        return false
    }
}

; カウントダウンオーバーレイ
ShowCountdownOverlay(seconds, message := "開始まで") {
    try {
        Loop seconds {
            remaining := seconds - A_Index + 1
            ShowOverlay(Format("{} {} 秒", message, remaining), 950)
            Sleep(1000)
        }
        ShowOverlay("開始！", 1000)
        
    } catch as e {
        LogError("VisualDetection", "Failed to show countdown overlay: " . e.Message)
    }
}

; 基本的なモニター情報取得
GetMonitorInfo() {
    try {
        monitors := Map()
        monitors["primary"] := Map(
            "left", 0,
            "top", 0,
            "right", A_ScreenWidth,
            "bottom", A_ScreenHeight,
            "width", A_ScreenWidth,
            "height", A_ScreenHeight,
            "centerX", A_ScreenWidth // 2,
            "centerY", A_ScreenHeight // 2
        )
        return monitors
        
    } catch as e {
        LogError("VisualDetection", "Failed to get monitor info: " . e.Message)
        return Map()
    }
}