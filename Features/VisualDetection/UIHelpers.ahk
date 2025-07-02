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

; ShowMultiLineOverlay function removed - using UI/Overlay.ahk version instead
; If you need VisualDetection-specific overlay with title, use ShowMultiLineOverlayWithTitle

; Enhanced multi-line overlay display with title bar
ShowMultiLineOverlayWithTitle(lines, duration := 5000, title := "情報表示") {
    global g_multi_line_overlay_gui
    
    try {
        LogDebug("VisualDetection", Format("ShowMultiLineOverlayWithTitle called with {} lines, duration {}", lines.Length, duration))
        
        ; 既存のオーバーレイを削除
        if (g_multi_line_overlay_gui && g_multi_line_overlay_gui != "") {
            try {
                g_multi_line_overlay_gui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; マルチラインGUI作成（タイトルバー付き）
        g_multi_line_overlay_gui := Gui("+AlwaysOnTop -MaximizeBox", title)
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
        
        LogDebug("VisualDetection", "Multi-line overlay with title displayed successfully")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to show multi-line overlay with title: " . e.Message)
        ; フォールバック: 標準のShowMultiLineOverlay
        ShowMultiLineOverlay(lines, duration)
        return false
    }
}

; マルチラインオーバーレイを閉じる
CloseMultiLineOverlay() {
    global g_multi_line_overlay_gui
    
    if (g_multi_line_overlay_gui && g_multi_line_overlay_gui != "") {
        try {
            g_multi_line_overlay_gui.Destroy()
        } catch {
            ; 既に削除されている場合は無視
        }
        g_multi_line_overlay_gui := ""
    }
}

; Visual Detection specific progress overlay
ShowVisualDetectionProgress(title, currentStep, totalSteps, stepDescription := "") {
    global g_progress_overlay_gui
    
    try {
        ; 既存のオーバーレイを削除
        if (g_progress_overlay_gui && g_progress_overlay_gui != "") {
            try {
                g_progress_overlay_gui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 進捗GUI作成
        g_progress_overlay_gui := Gui("+AlwaysOnTop +ToolWindow -Caption", "進捗表示")
        g_progress_overlay_gui.BackColor := "0x2D2D30"
        g_progress_overlay_gui.MarginX := 20
        g_progress_overlay_gui.MarginY := 15
        
        ; タイトル
        g_progress_overlay_gui.SetFont("s12 Bold", "Yu Gothic UI")
        g_progress_overlay_gui.Add("Text", "cWhite w300 Center", title)
        
        ; 進捗テキスト
        g_progress_overlay_gui.SetFont("s10 Norm")
        progressText := Format("{} / {} 完了", currentStep, totalSteps)
        g_progress_overlay_gui.Add("Text", "cWhite w300 Center y+10", progressText)
        
        ; 進捗バー
        percentage := Round(currentStep / totalSteps * 100)
        progressBar := g_progress_overlay_gui.Add("Progress", "w300 h25 y+10 BackgroundGray", percentage)
        
        ; パーセンテージ表示
        g_progress_overlay_gui.SetFont("s14 Bold")
        g_progress_overlay_gui.Add("Text", "cLime w300 Center y+10", percentage . "%")
        
        ; ステップ説明
        if (stepDescription != "") {
            g_progress_overlay_gui.SetFont("s9 Norm")
            g_progress_overlay_gui.Add("Text", "c0xAAAAAA w300 Center y+10", stepDescription)
        }
        
        ; 画面中央に表示
        monitors := GetMonitorInfo()
        if (monitors.Has("primary")) {
            centerX := monitors["primary"]["centerX"] - 170
            centerY := monitors["primary"]["centerY"] - 100
        } else {
            centerX := A_ScreenWidth // 2 - 170
            centerY := A_ScreenHeight // 2 - 100
        }
        
        g_progress_overlay_gui.Show(Format("x{} y{} NoActivate", centerX, centerY))
        
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to show progress overlay: " . e.Message)
        return false
    }
}

; Close visual detection progress overlay
CloseVisualDetectionProgress() {
    global g_progress_overlay_gui
    
    if (g_progress_overlay_gui && g_progress_overlay_gui != "") {
        try {
            g_progress_overlay_gui.Destroy()
        } catch {
            ; 既に削除されている場合は無視
        }
        g_progress_overlay_gui := ""
    }
}

; Visual Detection notification overlay with icon
ShowVisualNotification(title, message, type := "info", duration := 3000) {
    global g_notification_overlay_gui
    
    try {
        ; 既存のオーバーレイを削除
        if (g_notification_overlay_gui && g_notification_overlay_gui != "") {
            try {
                g_notification_overlay_gui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 通知GUI作成
        g_notification_overlay_gui := Gui("+AlwaysOnTop +ToolWindow -Caption", "通知")
        g_notification_overlay_gui.BackColor := "0x2D2D30"
        g_notification_overlay_gui.MarginX := 20
        g_notification_overlay_gui.MarginY := 15
        
        ; アイコンと色を設定
        if (type == "success") {
            iconText := "✓"
            iconColor := "c0x00FF00"
            borderColor := "0x00FF00"
        } else if (type == "error") {
            iconText := "✗"
            iconColor := "cRed"
            borderColor := "0xFF0000"
        } else if (type == "warning") {
            iconText := "！"
            iconColor := "cYellow"
            borderColor := "0xFFFF00"
        } else {
            iconText := "ℹ"
            iconColor := "c0x00BFFF"
            borderColor := "0x00BFFF"
        }
        
        ; 左側のアイコン
        g_notification_overlay_gui.SetFont("s24 Bold", "Segoe UI Symbol")
        g_notification_overlay_gui.Add("Text", iconColor . " x0 y+5 w50 Center", iconText)
        
        ; タイトルとメッセージ
        g_notification_overlay_gui.SetFont("s11 Bold", "Yu Gothic UI")
        g_notification_overlay_gui.Add("Text", "cWhite x60 y15 w280", title)
        
        g_notification_overlay_gui.SetFont("s9 Norm")
        g_notification_overlay_gui.Add("Text", "c0xDDDDDD x60 y+5 w280", message)
        
        ; 右上に表示
        monitors := GetMonitorInfo()
        if (monitors.Has("primary")) {
            posX := monitors["primary"]["right"] - 380
            posY := monitors["primary"]["top"] + 50
        } else {
            posX := A_ScreenWidth - 380
            posY := 50
        }
        
        g_notification_overlay_gui.Show(Format("x{} y{} w360 NoActivate", posX, posY))
        
        ; 自動的に閉じる
        if (duration > 0) {
            SetTimer(() => CloseVisualNotification(), -duration)
        }
        
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to show notification overlay: " . e.Message)
        return false
    }
}

; Close visual detection notification overlay
CloseVisualNotification() {
    global g_notification_overlay_gui
    
    if (g_notification_overlay_gui && g_notification_overlay_gui != "") {
        try {
            g_notification_overlay_gui.Destroy()
        } catch {
            ; 既に削除されている場合は無視
        }
        g_notification_overlay_gui := ""
    }
}

; Helper functions for confirmation dialog
HandleConfirmYes(confirmGui, yesCallback) {
    confirmGui.Destroy()
    if (yesCallback) {
        yesCallback.Call()
    }
}

HandleConfirmNo(confirmGui, noCallback) {
    confirmGui.Destroy()
    if (noCallback) {
        noCallback.Call()
    }
}

; Visual Detection confirmation dialog
ShowVisualConfirmation(title, message, yesCallback, noCallback := "") {
    confirmGui := Gui("+AlwaysOnTop", title)
    confirmGui.SetFont("s10", "Yu Gothic UI")
    
    confirmGui.Add("Text", "w300", message)
    
    btnYes := confirmGui.Add("Button", "w80 x50 y+20", "はい(&Y)")
    btnNo := confirmGui.Add("Button", "w80 x+20", "いいえ(&N)")
    
    btnYes.OnEvent("Click", (*) => HandleConfirmYes(confirmGui, yesCallback))
    
    btnNo.OnEvent("Click", (*) => HandleConfirmNo(confirmGui, noCallback))
    
    confirmGui.Show("Center")
}

; Visual Detection countdown overlay
ShowVisualCountdown(seconds, message := "開始まで") {
    countdownGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "カウントダウン")
    countdownGui.BackColor := "0x1E1E1E"
    countdownGui.SetFont("s24 cWhite Bold", "Arial")
    
    textControl := countdownGui.Add("Text", "Center w200 h80", Format("{}`n{}", message, seconds))
    
    countdownGui.Show("Center NoActivate")
    
    ; カウントダウン処理
    Loop seconds {
        remaining := seconds - A_Index + 1
        textControl.Text := Format("{}`n{}", message, remaining)
        
        if (remaining > 1) {
            Sleep(1000)
        }
    }
    
    countdownGui.Destroy()
}

; GetMonitorInfo function removed - using Core/WindowManager.ahk version instead