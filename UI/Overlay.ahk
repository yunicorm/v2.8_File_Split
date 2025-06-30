; ===================================================================
; オーバーレイ表示システム
; 一時的なメッセージやステータスの表示
; ===================================================================

; --- オーバーレイ表示 ---
ShowOverlay(message, duration := 2000) {
    global overlayGui
    
    ; 既存のオーバーレイがある場合は削除
    try {
        if (overlayGui && IsObject(overlayGui)) {
            overlayGui.Destroy()
        }
    } catch {
        ; エラーは無視
    }
    
    ; 中央モニターの座標
    centerMonitorLeft := 0
    centerMonitorWidth := 3440
    centerMonitorHeight := 1440
    
    ; オーバーレイGUIの作成
    overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
    overlayGui.BackColor := "000000"
    overlayGui.SetFont("s28 bold cAAFF00", "Arial")
    overlayText := overlayGui.Add("Text", "Center", message)
    
    ; テキストサイズを推定
    textWidth := StrLen(message) * 22 + 80
    textHeight := 80
    
    ; 中央モニターの中心座標を計算
    overlayX := centerMonitorLeft + (centerMonitorWidth / 2) - (textWidth / 2)
    overlayY := (centerMonitorHeight / 2) - (textHeight / 2) - 200
    
    ; オーバーレイを表示
    overlayGui.Show("x" . overlayX . " y" . overlayY . " w" . textWidth . " h" . textHeight . " NoActivate NA")
    WinSetTransparent(220, overlayGui)
    
    ; 指定時間後に削除
    SetTimer(() => RemoveOverlay(), -duration)
    
    LogDebug("Overlay", Format("Showing message: {} ({}ms)", message, duration))
}

; --- オーバーレイ削除 ---
RemoveOverlay() {
    global overlayGui
    
    try {
        if (overlayGui && IsObject(overlayGui)) {
            overlayGui.Destroy()
            overlayGui := ""
        }
    } catch {
        ; エラーは無視
    }
}

; --- カスタムオーバーレイ（色やフォント指定） ---
ShowCustomOverlay(message, options := {}) {
    ; デフォルトオプション
    defaults := {
        duration: 2000,
        fontSize: 28,
        fontColor: "AAFF00",
        fontStyle: "bold",
        bgColor: "000000",
        transparency: 220,
        offsetY: -200
    }
    
    ; オプションをマージ
    for key, value in defaults {
        if (!options.HasProp(key)) {
            options[key] := value
        }
    }
    
    ; カスタムオーバーレイGUIを作成
    customGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
    customGui.BackColor := options.bgColor
    customGui.SetFont("s" . options.fontSize . " " . options.fontStyle . " c" . options.fontColor, "Arial")
    customGui.Add("Text", "Center", message)
    
    ; 表示位置を計算
    textWidth := StrLen(message) * (options.fontSize * 0.8) + 80
    textHeight := options.fontSize * 3
    
    overlayX := (3440 / 2) - (textWidth / 2)
    overlayY := (1440 / 2) - (textHeight / 2) + options.offsetY
    
    customGui.Show("x" . overlayX . " y" . overlayY . " w" . textWidth . " h" . textHeight . " NoActivate NA")
    WinSetTransparent(options.transparency, customGui)
    
    ; 自動削除
    SetTimer(() => DestroyGui(customGui), -options.duration)
}

; --- GUI破棄用ヘルパー ---
DestroyGui(guiObj) {
    try {
        if (guiObj && IsObject(guiObj)) {
            guiObj.Destroy()
        }
    } catch {
        ; エラーは無視
    }
}

; --- 複数行オーバーレイ ---
ShowMultiLineOverlay(lines, duration := 3000) {
    try {
        if (!IsObject(lines) || lines.Length == 0) {
            LogWarn("Overlay", "ShowMultiLineOverlay called with empty or invalid lines")
            return false
        }
        
        ; 複数行のテキストを結合
        message := ""
        for line in lines {
            message .= line . "`n"
        }
        message := RTrim(message, "`n")
        
        ; オーバーレイGUIの作成
        multiGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        multiGui.BackColor := "0x1E1E1E"  ; 暗いグレー背景
        multiGui.SetFont("s18 cWhite", "Consolas")  ; 等幅フォント使用
        
        ; テキストエリアを作成（左寄せで等幅表示）
        textControl := multiGui.Add("Text", "Left x10 y10", message)
        
        ; サイズと位置を計算
        maxLineLength := 0
        for line in lines {
            if (StrLen(line) > maxLineLength) {
                maxLineLength := StrLen(line)
            }
        }
        
        ; 等幅フォントのサイズ調整
        textWidth := maxLineLength * 11 + 40  ; Consolasフォント用調整
        textHeight := lines.Length * 22 + 30  ; 行間調整
        
        ; 画面右側に固定表示（右端から50px内側）
        overlayX := 3440 - textWidth - 50
        overlayY := 100  ; 上端から100px下
        
        multiGui.Show("x" . overlayX . " y" . overlayY . " w" . textWidth . " h" . textHeight . " NoActivate NA")
        WinSetTransparent(230, multiGui)  ; 少し濃い目の透明度
        
        SetTimer(() => DestroyGui(multiGui), -duration)
        
        LogDebug("Overlay", Format("Multi-line overlay displayed: {} lines, {}ms duration", lines.Length, duration))
        return true
        
    } catch as e {
        LogError("Overlay", Format("Failed to show multi-line overlay: {}", e.Message))
        return false
    }
}

; --- プログレスバーオーバーレイ（将来の拡張用） ---
ShowProgressOverlay(title, current, max, duration := 0) {
    ; TODO: 実装予定
    ; プログレスバー付きのオーバーレイ表示
    percentage := Round((current / max) * 100)
    ShowOverlay(Format("{}: {}%", title, percentage), duration > 0 ? duration : 2000)
}