; Flask Pattern Capture Module
; Pattern capture functionality for visual detection
; v2.9.6 - New module for pattern capture features

; Start flask pattern capture mode
StartFlaskPatternCapture() {
    global g_pattern_capture_state
    
    try {
        LogInfo("PatternCapture", "Starting flask pattern capture mode")
        
        ; Check if visual detection is enabled
        if (!IsVisualDetectionEnabled()) {
            ShowOverlay("視覚検出が無効です。設定で有効にしてください", 3000)
            LogWarn("PatternCapture", "Visual detection is disabled, cannot start pattern capture")
            return false
        }
        
        ; Initialize capture state
        g_pattern_capture_state["active"] := true
        g_pattern_capture_state["current_flask"] := 0
        g_pattern_capture_state["capture_mode"] := "manual"
        
        ; Clear any existing overlay
        if (g_pattern_capture_state["overlay_gui"] != "") {
            try {
                g_pattern_capture_state["overlay_gui"].Destroy()
            } catch {
                ; Ignore destroy errors
            }
        }
        
        ; Create instruction overlay
        CreatePatternCaptureOverlay()
        
        LogInfo("PatternCapture", "Pattern capture mode activated")
        return true
        
    } catch as e {
        LogError("PatternCapture", "Failed to start pattern capture: " . e.Message)
        ShowOverlay("パターンキャプチャ開始エラー: " . e.Message, 3000)
        return false
    }
}

; Create the pattern capture instruction overlay
CreatePatternCaptureOverlay() {
    global g_pattern_capture_state
    
    try {
        ; Create overlay GUI
        overlay := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Resize", "フラスコパターンキャプチャ")
        overlay.BackColor := "0x000040"
        overlay.MarginX := 20
        overlay.MarginY := 15
        
        ; Add instruction text
        overlay.SetFont("s12 Bold", "MS Gothic")
        overlay.Add("Text", "cWhite", "=== フラスコパターンキャプチャモード ===")
        
        overlay.SetFont("s10", "MS Gothic")
        overlay.Add("Text", "cYellow y+10", "操作方法:")
        overlay.Add("Text", "cWhite y+5", "1-5: 各フラスコのパターンをキャプチャ")
        overlay.Add("Text", "cWhite y+2", "Space: すべてのフラスコを順番にキャプチャ")
        overlay.Add("Text", "cWhite y+2", "Escape: キャプチャモード終了")
        
        overlay.Add("Text", "cLime y+10", "注意事項:")
        overlay.Add("Text", "cWhite y+5", "フラスコが充填されている状態でキャプチャしてください")
        overlay.Add("Text", "cWhite y+2", "キャプチャ前にフラスコ座標が設定されている必要があります")
        
        ; Position the overlay
        overlay.Show("x50 y100 AutoSize")
        
        ; Store overlay reference
        g_pattern_capture_state["overlay_gui"] := overlay
        
        LogInfo("PatternCapture", "Pattern capture overlay created")
        
    } catch as e {
        LogError("PatternCapture", "Failed to create pattern capture overlay: " . e.Message)
    }
}

; Capture pattern for a specific flask
CaptureFlaskPattern(flaskNumber) {
    global g_pattern_capture_state
    
    try {
        if (!g_pattern_capture_state["active"]) {
            LogWarn("PatternCapture", "Pattern capture mode is not active")
            ShowOverlay("パターンキャプチャモードが有効ではありません", 2000)
            return false
        }
        
        if (flaskNumber < 1 || flaskNumber > 5) {
            LogWarn("PatternCapture", Format("Invalid flask number: {}", flaskNumber))
            ShowOverlay("無効なフラスコ番号です (1-5)", 2000)
            return false
        }
        
        LogInfo("PatternCapture", Format("Capturing pattern for Flask{}", flaskNumber))
        
        ; Get flask coordinates from config
        flaskX := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
        flaskY := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
        flaskWidth := ConfigManager.Get("VisualDetection", Format("Flask{}Width", flaskNumber), 60)
        flaskHeight := ConfigManager.Get("VisualDetection", Format("Flask{}Height", flaskNumber), 80)
        
        if (flaskX == 0 || flaskY == 0) {
            ShowOverlay(Format("Flask{} の座標が設定されていません", flaskNumber), 3000)
            LogWarn("PatternCapture", Format("Flask{} coordinates not set", flaskNumber))
            return false
        }
        
        ; Capture the pattern using FindText
        result := CaptureFlaskPatternImage(flaskX, flaskY, flaskWidth, flaskHeight, flaskNumber)
        
        if (result) {
            ; Store the pattern
            g_pattern_capture_state["patterns"][Format("Flask{}", flaskNumber)] := result
            
            ShowOverlay(Format("Flask{} パターンをキャプチャしました", flaskNumber), 2000)
            LogInfo("PatternCapture", Format("Flask{} pattern captured successfully", flaskNumber))
            
            ; Update overlay to show progress
            UpdatePatternCaptureProgress()
            
            return true
        } else {
            ShowOverlay(Format("Flask{} パターンキャプチャに失敗しました", flaskNumber), 3000)
            LogError("PatternCapture", Format("Failed to capture Flask{} pattern", flaskNumber))
            return false
        }
        
    } catch as e {
        LogError("PatternCapture", Format("Error capturing Flask{} pattern: {}", flaskNumber, e.Message))
        ShowOverlay(Format("Flask{} キャプチャエラー: {}", flaskNumber, e.Message), 3000)
        return false
    }
}

; Capture pattern image using screen capture
CaptureFlaskPatternImage(x, y, width, height, flaskNumber) {
    try {
        ; Calculate capture area with some padding
        padding := 5
        captureX := x - padding
        captureY := y - padding
        captureWidth := width + (padding * 2)
        captureHeight := height + (padding * 2)
        
        ; Use FindText to capture the pattern
        ; This creates a pattern string that can be used for detection
        patternString := FindText().GetTextFromScreen(captureX, captureY, captureX + captureWidth, captureY + captureHeight, 0, 0)
        
        if (patternString != "") {
            ; Save pattern to config for persistence
            ConfigManager.Set("FlaskPatterns", Format("Flask{}Pattern", flaskNumber), patternString)
            
            LogInfo("PatternCapture", Format("Flask{} pattern saved: {} chars", flaskNumber, StrLen(patternString)))
            return patternString
        } else {
            LogWarn("PatternCapture", Format("No pattern captured for Flask{}", flaskNumber))
            return ""
        }
        
    } catch as e {
        LogError("PatternCapture", Format("Error capturing Flask{} image: {}", flaskNumber, e.Message))
        return ""
    }
}

; Capture all flask patterns sequentially
CaptureAllFlaskPatterns() {
    global g_pattern_capture_state
    
    try {
        if (!g_pattern_capture_state["active"]) {
            LogWarn("PatternCapture", "Pattern capture mode is not active")
            return false
        }
        
        LogInfo("PatternCapture", "Starting sequential capture of all flask patterns")
        
        ; Set to auto mode
        g_pattern_capture_state["capture_mode"] := "auto"
        
        ShowOverlay("すべてのフラスコのパターンをキャプチャします...", 2000)
        
        successCount := 0
        failureCount := 0
        
        ; Capture each flask pattern
        Loop 5 {
            flaskNumber := A_Index
            
            ShowOverlay(Format("Flask{} をキャプチャ中...", flaskNumber), 1000)
            Sleep(1000)  ; Give user time to see the message
            
            if (CaptureFlaskPattern(flaskNumber)) {
                successCount++
            } else {
                failureCount++
            }
            
            Sleep(500)  ; Brief pause between captures
        }
        
        ; Show final result
        ShowMultiLineOverlay([
            "=== 一括キャプチャ完了 ===",
            "",
            Format("成功: {} / 5", successCount),
            Format("失敗: {} / 5", failureCount),
            "",
            successCount == 5 ? "すべてのパターンが正常にキャプチャされました" : "一部のパターンでエラーが発生しました"
        ], 4000)
        
        LogInfo("PatternCapture", Format("Sequential capture completed: {} success, {} failed", successCount, failureCount))
        
        ; Reset to manual mode
        g_pattern_capture_state["capture_mode"] := "manual"
        
        return successCount > 0
        
    } catch as e {
        LogError("PatternCapture", "Error in sequential pattern capture: " . e.Message)
        ShowOverlay("一括キャプチャエラー: " . e.Message, 3000)
        return false
    }
}

; Update pattern capture progress display
UpdatePatternCaptureProgress() {
    global g_pattern_capture_state
    
    try {
        if (!g_pattern_capture_state.Has("patterns")) {
            return
        }
        
        capturedCount := g_pattern_capture_state["patterns"].Count
        
        ; Show brief progress update
        ShowOverlay(Format("パターンキャプチャ進捗: {} / 5", capturedCount), 1500)
        
        LogInfo("PatternCapture", Format("Pattern capture progress: {} / 5", capturedCount))
        
    } catch as e {
        LogError("PatternCapture", "Error updating pattern capture progress: " . e.Message)
    }
}

; Stop flask pattern capture mode
StopFlaskPatternCapture() {
    global g_pattern_capture_state
    
    try {
        LogInfo("PatternCapture", "Stopping flask pattern capture mode")
        
        ; Deactivate capture mode
        g_pattern_capture_state["active"] := false
        g_pattern_capture_state["current_flask"] := 0
        g_pattern_capture_state["capture_mode"] := "manual"
        
        ; Destroy overlay if it exists
        if (g_pattern_capture_state["overlay_gui"] != "") {
            try {
                g_pattern_capture_state["overlay_gui"].Destroy()
                g_pattern_capture_state["overlay_gui"] := ""
            } catch {
                ; Ignore destroy errors
            }
        }
        
        ; Show final summary
        capturedCount := g_pattern_capture_state.Has("patterns") ? g_pattern_capture_state["patterns"].Count : 0
        
        ShowOverlay(Format("パターンキャプチャモード終了 ({} / 5 キャプチャ済み)", capturedCount), 2000)
        LogInfo("PatternCapture", Format("Pattern capture mode stopped, {} patterns captured", capturedCount))
        
        ; Save patterns to config file
        if (capturedCount > 0) {
            ConfigManager.Save()
            LogInfo("PatternCapture", "Pattern data saved to config")
        }
        
        return true
        
    } catch as e {
        LogError("PatternCapture", "Error stopping pattern capture: " . e.Message)
        ShowOverlay("パターンキャプチャ終了エラー: " . e.Message, 3000)
        return false
    }
}

; Clear all captured patterns
ClearAllFlaskPatterns() {
    global g_pattern_capture_state
    
    try {
        LogInfo("PatternCapture", "Clearing all flask patterns")
        
        ; Clear from memory
        if (g_pattern_capture_state.Has("patterns")) {
            g_pattern_capture_state["patterns"] := Map()
        }
        
        ; Clear from config
        Loop 5 {
            flaskNumber := A_Index
            ConfigManager.Set("FlaskPatterns", Format("Flask{}Pattern", flaskNumber), "")
        }
        
        ; Save changes
        ConfigManager.Save()
        
        ShowOverlay("すべてのフラスコパターンをクリアしました", 2000)
        LogInfo("PatternCapture", "All flask patterns cleared")
        
        return true
        
    } catch as e {
        LogError("PatternCapture", "Error clearing flask patterns: " . e.Message)
        ShowOverlay("パターンクリアエラー: " . e.Message, 3000)
        return false
    }
}