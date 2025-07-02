; Flask Overlay Management System
; This file contains all overlay-related functions for flask position setup
; Extracted from VisualDetection.ahk for better maintainability

; Global overlay variables
global g_current_single_overlay := ""
global g_flask_number_overlay := ""
global g_flask_overlay_gui := ""
global g_help_overlay_gui := ""
global g_boundary_warning_overlay := ""
global g_setup_notification_gui := ""
global g_guideline_overlays := Map()
global g_completed_flask_overlays := Map()

; Grid and sizing globals
global g_grid_snap_enabled := false
global g_flask_rect_width := 80
global g_flask_rect_height := 120

; ヘルプオーバーレイ表示
ShowHelpOverlay() {
    global g_help_overlay_gui
    
    try {
        ; 既存のヘルプがあれば削除（トグル動作）
        if (g_help_overlay_gui && g_help_overlay_gui != "") {
            try {
                g_help_overlay_gui.Destroy()
                g_help_overlay_gui := ""
                return
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; ヘルプオーバーレイGUI作成
        g_help_overlay_gui := Gui("+AlwaysOnTop -MaximizeBox", "フラスコ位置設定 - 操作ヘルプ")
        g_help_overlay_gui.BackColor := "0x1E1E1E"
        
        ; フォント設定
        g_help_overlay_gui.SetFont("s9", "Consolas")
        
        ; ヘルプ内容構築
        helpText := ""
        helpText .= "■ 基本操作`n"
        helpText .= "  矢印キー     : 位置調整 (10px)`n"
        helpText .= "  ]/[          : 幅調整 (10px)`n"
        helpText .= "  '/;          : 高さ調整 (10px)`n"
        helpText .= "  =/−          : 全体サイズ調整 (5px)`n"
        helpText .= "  Shift+キー   : 微調整 (2px)`n"
        helpText .= "  Enter        : 位置確定・次へ`n"
        helpText .= "  Escape       : 設定終了`n`n"
        
        helpText .= "■ 一括操作`n"
        helpText .= "  Shift+矢印   : 全フラスコ移動`n"
        helpText .= "  Ctrl+]/[     : 全フラスコ間隔調整`n"
        helpText .= "  Ctrl+=/−     : 全フラスコサイズ調整`n`n"
        
        helpText .= "■ 便利機能`n"
        helpText .= "  G            : グリッドスナップ ON/OFF`n"
        helpText .= "  P            : プリセットメニュー`n"
        helpText .= "  I            : 設定インポート`n"
        helpText .= "  E            : 設定エクスポート`n"
        helpText .= "  H            : このヘルプ表示`n`n"
        
        helpText .= "■ 視覚ガイド`n"
        helpText .= "  緑楕円       : 設定完了フラスコ`n"
        helpText .= "  黄点線       : 隣接フラスコとの距離`n"
        helpText .= "  赤枠         : 境界警告 (画面端近接)`n"
        helpText .= "  大きい数字   : 現在設定中のフラスコ番号`n`n"
        
        helpText .= "■ プリセット`n"
        helpText .= "  標準左下     : PoE標準的な左下配置`n"
        helpText .= "  中央下       : 画面中央下部配置`n"
        helpText .= "  右下         : 画面右下配置`n"
        helpText .= "  現在設定     : Config.iniから読み込み`n"
        
        ; テキストコントロール追加
        g_help_overlay_gui.SetFont("s9 cLime", "Consolas")
        g_help_overlay_gui.Add("Text", "w500 h400", helpText)
        
        ; 閉じるボタン
        g_help_overlay_gui.SetFont("s10", "Segoe UI")
        btnClose := g_help_overlay_gui.Add("Button", "w100 x200 y+10", "閉じる")
        btnClose.OnEvent("Click", (*) => CloseHelpOverlay())
        
        ; ESCキーで閉じる
        g_help_overlay_gui.OnEvent("Escape", (*) => CloseHelpOverlay())
        
        ; 画面中央に表示
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        helpX := centralMonitor["centerX"] - 250
        helpY := centralMonitor["centerY"] - 250
        
        g_help_overlay_gui.Show(Format("x{} y{} w520 h480", helpX, helpY))
        
        LogInfo("VisualDetection", "Help overlay displayed")
        
    } catch as e {
        LogError("VisualDetection", "Failed to show help overlay: " . e.Message)
    }
}

; ヘルプオーバーレイを閉じる
CloseHelpOverlay() {
    global g_help_overlay_gui
    
    try {
        if (g_help_overlay_gui && g_help_overlay_gui != "") {
            g_help_overlay_gui.Destroy()
            g_help_overlay_gui := ""
        }
    } catch as e {
        LogError("VisualDetection", "Failed to close help overlay: " . e.Message)
    }
}

; モニター情報取得関数（Utils/Coordinates.ahkのGetDetailedMonitorInfo()を使用）
GetFlaskMonitorInfo() {
    try {
        ; Utils/Coordinates.ahkの詳細モニター情報を取得
        detailedMonitors := GetDetailedMonitorInfo()
        
        ; 3440x1440のモニターを中央モニターとして特定
        centralMonitor := ""
        for monitor in detailedMonitors {
            if (monitor.bounds.width == 3440 && monitor.bounds.height == 1440) {
                centralMonitor := monitor
                break
            }
        }
        
        ; 3440x1440モニターが見つからない場合、最大のモニターを選択
        if (!centralMonitor) {
            largestArea := 0
            for monitor in detailedMonitors {
                area := monitor.bounds.width * monitor.bounds.height
                if (area > largestArea) {
                    largestArea := area
                    centralMonitor := monitor
                }
            }
        }
        
        if (centralMonitor) {
            ; 中央モニター情報をMapで返す
            monitors := Map()
            monitors["central"] := Map(
                "left", centralMonitor.bounds.left,
                "top", centralMonitor.bounds.top,
                "right", centralMonitor.bounds.right,
                "bottom", centralMonitor.bounds.bottom,
                "width", centralMonitor.bounds.width,
                "height", centralMonitor.bounds.height,
                "centerX", centralMonitor.bounds.left + (centralMonitor.bounds.width // 2),
                "centerY", centralMonitor.bounds.top + (centralMonitor.bounds.height // 2)
            )
            
            LogInfo("VisualDetection", Format("Central monitor detected: {}x{} at {},{}", 
                centralMonitor.bounds.width, centralMonitor.bounds.height, 
                centralMonitor.bounds.left, centralMonitor.bounds.top))
            return monitors
        } else {
            throw Error("No suitable monitor found")
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to get monitor info: " . e.Message)
        ; フォールバック（プライマリモニターを使用）
        monitors := Map()
        monitors["central"] := Map(
            "left", 0, "top", 0, "right", A_ScreenWidth, "bottom", A_ScreenHeight,
            "width", A_ScreenWidth, "height", A_ScreenHeight, 
            "centerX", A_ScreenWidth // 2, "centerY", A_ScreenHeight // 2
        )
        LogWarn("VisualDetection", "Using fallback monitor info")
        return monitors
    }
}

; フラスコスロット推定位置計算
CalculateFlaskSlotPositions(centralMonitor) {
    try {
        ; フラスコスロット設定（PoEの実際の配置に基づく）
        flaskSettings := Map(
            "baseX", 100,           ; 中央モニター左端からのオフセット
            "baseY", 1350,          ; フラスコ中心Y座標（3440x1440での推定値）
            "spacing", 80,          ; フラスコ間隔（70-80ピクセル）
            "count", 5              ; フラスコ数
        )
        
        ; 解像度スケーリング（3440x1440以外の場合）
        scaleX := centralMonitor["width"] / 3440.0
        scaleY := centralMonitor["height"] / 1440.0
        
        ; スケーリング適用
        scaledBaseX := Round(flaskSettings["baseX"] * scaleX)
        scaledBaseY := Round(flaskSettings["baseY"] * scaleY)
        scaledSpacing := Round(flaskSettings["spacing"] * scaleX)
        
        ; 各フラスコの推定位置を計算
        flaskPositions := Map()
        Loop 5 {
            flaskNum := A_Index
            relativeX := scaledBaseX + (flaskNum - 1) * scaledSpacing
            absoluteX := centralMonitor["left"] + relativeX
            absoluteY := scaledBaseY  ; Y座標は固定
            
            flaskPositions[flaskNum] := Map(
                "x", absoluteX,
                "y", absoluteY,
                "relativeX", relativeX,  ; 中央モニター相対座標
                "relativeY", scaledBaseY
            )
            
            LogDebug("VisualDetection", Format("Flask{} estimated position: absolute({},{}) relative({},{})", 
                flaskNum, absoluteX, absoluteY, relativeX, scaledBaseY))
        }
        
        return flaskPositions
        
    } catch as e {
        LogError("VisualDetection", "Failed to calculate flask positions: " . e.Message)
        return Map()
    }
}

; 単一フラスコオーバーレイ作成（番号表示付き）
CreateSingleFlaskOverlay(x, y, flaskNumber) {
    global g_current_single_overlay, g_flask_number_overlay, g_flask_rect_width, g_flask_rect_height
    
    try {
        LogDebug("VisualDetection", Format("Creating Flask{} overlay at {},{}", flaskNumber, x, y))
        
        ; 既存のオーバーレイがあれば削除
        if (g_current_single_overlay && g_current_single_overlay != "") {
            try {
                g_current_single_overlay.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        if (g_flask_number_overlay && g_flask_number_overlay != "") {
            try {
                g_flask_number_overlay.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 楕円形オーバーレイ作成
        g_current_single_overlay := Gui()
        g_current_single_overlay.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g_current_single_overlay.BackColor := "Lime"  ; 緑色で区別
        
        ; 楕円形のリージョンを作成
        hRgn := DllCall("CreateEllipticRgn", "int", 0, "int", 0, 
                        "int", g_flask_rect_width, "int", g_flask_rect_height)
        
        ; GUIを表示（左上座標で表示）
        g_current_single_overlay.Show(Format("x{} y{} w{} h{} NA", 
            x - g_flask_rect_width // 2, 
            y - g_flask_rect_height // 2, 
            g_flask_rect_width, 
            g_flask_rect_height))
        
        ; 楕円リージョンを適用
        if (hRgn) {
            DllCall("SetWindowRgn", "ptr", g_current_single_overlay.Hwnd, "ptr", hRgn, "int", true)
        }
        
        WinSetTransparent(120, g_current_single_overlay)
        
        ; フラスコ番号表示オーバーレイ作成
        CreateFlaskNumberOverlay(x, y, flaskNumber)
        
        ; ガイドライン表示
        CreateGuidelineOverlays(x, y, flaskNumber)
        
        ; 境界警告チェック
        CheckBoundaryWarning(x, y)
        
        LogDebug("VisualDetection", Format("Flask{} overlay with number created successfully", flaskNumber))
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to create Flask{} overlay: {}", flaskNumber, e.Message))
        return false
    }
}

; フラスコ番号表示オーバーレイ作成
CreateFlaskNumberOverlay(x, y, flaskNumber) {
    global g_flask_number_overlay
    
    try {
        ; 番号表示用GUI作成
        g_flask_number_overlay := Gui()
        g_flask_number_overlay.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g_flask_number_overlay.BackColor := "Black"
        
        ; フォント設定（24pt、白色、太字）
        g_flask_number_overlay.SetFont("s24 Bold cWhite", "Segoe UI")
        
        ; 番号テキスト追加
        textControl := g_flask_number_overlay.Add("Text", "Center w60 h40", Format("{}", flaskNumber))
        
        ; 中央に配置（楕円の中心）
        g_flask_number_overlay.Show(Format("x{} y{} w60 h40 NA", x - 30, y - 20))
        
        ; 半透明設定
        WinSetTransparent(180, g_flask_number_overlay)
        
        LogDebug("VisualDetection", Format("Flask{} number overlay created", flaskNumber))
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to create Flask{} number overlay: {}", flaskNumber, e.Message))
    }
}

; 設定完了フラスコの視覚化（緑色楕円）
CreateCompletedFlaskOverlay(x, y, flaskNumber, width, height) {
    global g_completed_flask_overlays
    
    try {
        ; 完了フラスコ用GUI作成
        completedGui := Gui()
        completedGui.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        completedGui.BackColor := "Green"  ; 緑色
        
        ; 楕円形のリージョンを作成
        hRgn := DllCall("CreateEllipticRgn", "int", 0, "int", 0, 
                        "int", width, "int", height)
        
        ; GUIを表示
        completedGui.Show(Format("x{} y{} w{} h{} NA", 
            x - width // 2, 
            y - height // 2, 
            width, 
            height))
        
        ; 楕円リージョンを適用
        if (hRgn) {
            DllCall("SetWindowRgn", "ptr", completedGui.Hwnd, "ptr", hRgn, "int", true)
        }
        
        ; 薄い透明度設定（30%程度）
        WinSetTransparent(80, completedGui)
        
        ; 配列に追加
        g_completed_flask_overlays.Push(completedGui)
        
        LogDebug("VisualDetection", Format("Completed Flask{} overlay created", flaskNumber))
        return completedGui
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to create completed Flask{} overlay: {}", flaskNumber, e.Message))
        return ""
    }
}

; ガイドライン表示
CreateGuidelineOverlays(currentX, currentY, flaskNumber) {
    global g_guideline_overlays
    
    try {
        ; 既存のガイドラインを削除
        ClearGuidelineOverlays()
        
        ; モニター情報とフラスコ位置計算
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        flaskPositions := CalculateFlaskSlotPositions(centralMonitor)
        
        ; 隣接するフラスコとの間隔ガイドライン作成
        adjacentFlasks := []
        if (flaskNumber > 1) {
            adjacentFlasks.Push(flaskNumber - 1)  ; 左隣
        }
        if (flaskNumber < 5) {
            adjacentFlasks.Push(flaskNumber + 1)  ; 右隣
        }
        
        for adjFlask in adjacentFlasks {
            if (flaskPositions.Has(adjFlask)) {
                adjPos := flaskPositions[adjFlask]
                CreateDottedLine(currentX, currentY, adjPos["x"], adjPos["y"])
            }
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to create guideline overlays: " . e.Message)
    }
}

; 点線作成
CreateDottedLine(x1, y1, x2, y2) {
    global g_guideline_overlays
    
    try {
        ; 線の長さと角度計算
        distance := Sqrt((x2 - x1)**2 + (y2 - y1)**2)
        angle := ATan2Custom(y2 - y1, x2 - x1)
        
        ; 点線のドット数（10px間隔）
        dotCount := Floor(distance / 10)
        
        Loop dotCount {
            progress := A_Index / dotCount
            dotX := x1 + (x2 - x1) * progress
            dotY := y1 + (y2 - y1) * progress
            
            ; ドット作成（小さな円）
            dotGui := Gui()
            dotGui.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
            dotGui.BackColor := "Yellow"
            
            ; 円形リージョン作成（3px円）
            hRgn := DllCall("CreateEllipticRgn", "int", 0, "int", 0, "int", 3, "int", 3)
            
            dotGui.Show(Format("x{} y{} w3 h3 NA", dotX - 1, dotY - 1))
            
            if (hRgn) {
                DllCall("SetWindowRgn", "ptr", dotGui.Hwnd, "ptr", hRgn, "int", true)
            }
            
            WinSetTransparent(150, dotGui)
            g_guideline_overlays.Push(dotGui)
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to create dotted line: " . e.Message)
    }
}

; ガイドライン削除
ClearGuidelineOverlays() {
    global g_guideline_overlays
    
    try {
        for guideGui in g_guideline_overlays {
            if (guideGui) {
                try {
                    guideGui.Destroy()
                } catch {
                    ; 既に削除されている場合は無視
                }
            }
        }
        g_guideline_overlays := []
        
    } catch as e {
        LogError("VisualDetection", "Failed to clear guideline overlays: " . e.Message)
    }
}

; 境界警告チェック
CheckBoundaryWarning(x, y) {
    global g_boundary_warning_overlay, g_flask_rect_width, g_flask_rect_height
    
    try {
        ; 既存の警告を削除
        if (g_boundary_warning_overlay && g_boundary_warning_overlay != "") {
            try {
                g_boundary_warning_overlay.Destroy()
                g_boundary_warning_overlay := ""
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; モニター境界チェック
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        
        margin := 50  ; 境界からの警告マージン
        warningNeeded := false
        
        ; 境界近接チェック
        if (x - g_flask_rect_width // 2 < centralMonitor["left"] + margin ||
            x + g_flask_rect_width // 2 > centralMonitor["right"] - margin ||
            y - g_flask_rect_height // 2 < centralMonitor["top"] + margin ||
            y + g_flask_rect_height // 2 > centralMonitor["bottom"] - margin) {
            warningNeeded := true
        }
        
        if (warningNeeded) {
            ; 警告枠作成
            g_boundary_warning_overlay := Gui()
            g_boundary_warning_overlay.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
            g_boundary_warning_overlay.BackColor := "Red"
            
            ; 警告枠サイズ（オーバーレイより少し大きく）
            warningWidth := g_flask_rect_width + 20
            warningHeight := g_flask_rect_height + 20
            
            ; 楕円形警告枠
            hRgn := DllCall("CreateEllipticRgn", "int", 0, "int", 0, 
                            "int", warningWidth, "int", warningHeight)
            
            g_boundary_warning_overlay.Show(Format("x{} y{} w{} h{} NA", 
                x - warningWidth // 2, 
                y - warningHeight // 2, 
                warningWidth, 
                warningHeight))
            
            if (hRgn) {
                DllCall("SetWindowRgn", "ptr", g_boundary_warning_overlay.Hwnd, "ptr", hRgn, "int", true)
            }
            
            WinSetTransparent(100, g_boundary_warning_overlay)
            
            LogDebug("VisualDetection", "Boundary warning displayed")
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to check boundary warning: " . e.Message)
    }
}

; 設定通知オーバーレイ作成
CreateSetupNotificationOverlay(x, y, flaskNumber) {
    global g_setup_notification_gui
    
    try {
        LogDebug("VisualDetection", Format("Creating setup notification for Flask{}", flaskNumber))
        
        ; 既存の通知があれば削除
        if (g_setup_notification_gui && g_setup_notification_gui != "") {
            try {
                g_setup_notification_gui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 通知GUI作成
        g_setup_notification_gui := Gui()
        g_setup_notification_gui.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g_setup_notification_gui.BackColor := "0x2D2D30"  ; ダークグレー
        
        ; テキスト追加
        g_setup_notification_gui.SetFont("s14 Bold", "Segoe UI")
        textControl := g_setup_notification_gui.Add("Text", "cWhite Center w300 h50", 
            Format("Flask{} 設定中", flaskNumber))
        
        ; 枠線追加
        g_setup_notification_gui.MarginX := 20
        g_setup_notification_gui.MarginY := 15
        
        ; 中央に表示
        g_setup_notification_gui.Show(Format("x{} y{} w340 h80 NA", x - 170, y - 40))
        
        ; 半透明設定
        WinSetTransparent(200, g_setup_notification_gui)
        
        LogDebug("VisualDetection", Format("Setup notification created for Flask{}", flaskNumber))
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to create notification for Flask{}: {}", flaskNumber, e.Message))
        return false
    }
}

; 楕円形オーバーレイ作成
CreateFlaskOverlay(x, y) {
    global g_flask_overlay_gui, g_flask_rect_width, g_flask_rect_height
    
    LogDebug("VisualDetection", Format("CreateFlaskOverlay called: x={}, y={}, size={}x{}", x, y, g_flask_rect_width, g_flask_rect_height))
    
    if (g_flask_overlay_gui && g_flask_overlay_gui != "") {
        LogDebug("VisualDetection", "Destroying existing overlay GUI")
        try {
            g_flask_overlay_gui.Destroy()
        } catch {
            ; 既に削除されている場合は無視
        }
    }
    
    g_flask_overlay_gui := Gui()
    g_flask_overlay_gui.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    g_flask_overlay_gui.BackColor := "Red"
    
    ; 楕円形のリージョンを作成
    hRgn := DllCall("CreateEllipticRgn", "int", 0, "int", 0, 
                    "int", g_flask_rect_width, "int", g_flask_rect_height)
    
    ; GUIを表示してからリージョンを設定
    g_flask_overlay_gui.Show(Format("x{} y{} w{} h{} NA", 
        x - g_flask_rect_width // 2, 
        y - g_flask_rect_height // 2, 
        g_flask_rect_width, 
        g_flask_rect_height))
    
    ; 楕円リージョンを適用
    if (hRgn) {
        DllCall("SetWindowRgn", "ptr", g_flask_overlay_gui.Hwnd, "ptr", hRgn, "int", true)
    }
    
    WinSetTransparent(100, g_flask_overlay_gui)
    
    LogDebug("VisualDetection", Format("Elliptical flask overlay created at center {},{} with size {}x{}", x, y, g_flask_rect_width, g_flask_rect_height))
}

; 複数楕円形フラスコオーバーレイ一括作成
CreateAllFlaskOverlays(startX, startY) {
    global g_flask_overlay_guis, g_flask_rect_width, g_flask_rect_height, g_flask_spacing
    
    LogDebug("VisualDetection", Format("Creating all elliptical flask overlays starting at {},{}", startX, startY))
    
    ; 既存のオーバーレイをクリア
    for existingGui in g_flask_overlay_guis {
        if (existingGui) {
            try {
                existingGui.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
    }
    g_flask_overlay_guis := []
    
    Loop 5 {
        ; 中心座標で計算
        centerX := startX + (A_Index - 1) * (g_flask_rect_width + g_flask_spacing)
        centerY := startY
        
        newGui := Gui()
        newGui.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        newGui.BackColor := "Red"
        
        ; 楕円形のリージョンを作成
        hRgn := DllCall("CreateEllipticRgn", "int", 0, "int", 0, 
                        "int", g_flask_rect_width, "int", g_flask_rect_height)
        
        ; GUIを表示（左上座標で表示）
        newGui.Show(Format("x{} y{} w{} h{} NA", 
            centerX - g_flask_rect_width // 2, 
            centerY - g_flask_rect_height // 2, 
            g_flask_rect_width, 
            g_flask_rect_height))
        
        ; 楕円リージョンを適用
        if (hRgn) {
            DllCall("SetWindowRgn", "ptr", newGui.Hwnd, "ptr", hRgn, "int", true)
        }
        
        WinSetTransparent(100, newGui)
        g_flask_overlay_guis.Push(newGui)
        
        LogDebug("VisualDetection", Format("Flask{} elliptical overlay created at center {},{}", A_Index, centerX, centerY))
    }
    
    LogDebug("VisualDetection", "All elliptical flask overlays created successfully")
}

; 単一オーバーレイ移動（ガイド更新付き、グリッドスナップ対応）
MoveSingleOverlay(dx, dy) {
    global g_current_single_overlay, g_flask_number_overlay, g_current_flask_index
    global g_flask_rect_width, g_flask_rect_height, g_grid_snap_enabled
    
    if (!g_current_single_overlay || g_current_single_overlay == "") {
        LogDebug("VisualDetection", "No single overlay to move")
        return
    }
    
    try {
        ; 現在位置取得
        g_current_single_overlay.GetPos(&x, &y)
        newX := x + dx
        newY := y + dy
        
        ; 中心座標計算
        centerX := newX + g_flask_rect_width // 2
        centerY := newY + g_flask_rect_height // 2
        
        ; グリッドスナップ適用
        if (g_grid_snap_enabled) {
            centerX := Round(centerX / 10) * 10
            centerY := Round(centerY / 10) * 10
            newX := centerX - g_flask_rect_width // 2
            newY := centerY - g_flask_rect_height // 2
        }
        
        ; オーバーレイ移動
        g_current_single_overlay.Move(newX, newY)
        
        ; 番号オーバーレイも一緒に移動
        if (g_flask_number_overlay && g_flask_number_overlay != "") {
            g_flask_number_overlay.Move(centerX - 30, centerY - 20)
        }
        
        ; ガイドライン更新
        CreateGuidelineOverlays(centerX, centerY, g_current_flask_index)
        
        ; 境界警告チェック
        CheckBoundaryWarning(centerX, centerY)
        
        LogDebug("VisualDetection", Format("Single overlay moved to center {},{} (grid snap: {})", 
            centerX, centerY, g_grid_snap_enabled))
        
    } catch as e {
        LogError("VisualDetection", "Failed to move single overlay: " . e.Message)
    }
}

; グリッドスナップ切り替え
ToggleGridSnap() {
    global g_grid_snap_enabled
    
    g_grid_snap_enabled := !g_grid_snap_enabled
    
    snapStatus := g_grid_snap_enabled ? "有効" : "無効"
    ShowOverlay(Format("グリッドスナップ: {}", snapStatus), 2000)
    
    LogInfo("VisualDetection", Format("Grid snap toggled: {}", g_grid_snap_enabled))
}

; 単一オーバーレイサイズ変更（フィードバック付き）
ResizeSingleOverlayWithFeedback(dw, dh, action) {
    global g_current_single_overlay, g_flask_rect_width, g_flask_rect_height, g_current_flask_index
    
    if (!g_current_single_overlay || g_current_single_overlay == "") {
        LogDebug("VisualDetection", "No single overlay to resize")
        return
    }
    
    try {
        LogDebug("VisualDetection", Format("ResizeSingleOverlay: dw={}, dh={}, action={}", dw, dh, action))
        
        ; サイズ更新（最小40ピクセル）
        oldWidth := g_flask_rect_width
        oldHeight := g_flask_rect_height
        g_flask_rect_width := Max(40, g_flask_rect_width + dw)
        g_flask_rect_height := Max(40, g_flask_rect_height + dh)
        
        ; 楕円比率を計算
        aspectRatio := Round(g_flask_rect_width / g_flask_rect_height, 2)
        
        ; 現在位置を取得（中央座標で計算）
        g_current_single_overlay.GetPos(&guiX, &guiY, &guiW, &guiH)
        centerX := guiX + (guiW // 2)
        centerY := guiY + (guiH // 2)
        
        ; オーバーレイを再作成
        CreateSingleFlaskOverlay(centerX, centerY, g_current_flask_index)
        
        ; フィードバック表示
        ToolTip(Format("Flask{}: {}`n楕円: {}×{} (比率 {})", 
                      g_current_flask_index, action, g_flask_rect_width, g_flask_rect_height, aspectRatio))
        SetTimer(() => ToolTip(), -2000)
        
        LogDebug("VisualDetection", Format("Flask{} overlay resized to {}x{}", g_current_flask_index, g_flask_rect_width, g_flask_rect_height))
        
    } catch as e {
        LogError("VisualDetection", "Failed to resize single overlay: " . e.Message)
    }
}

; Enterキーでの順次確定処理（アニメーション付き）
ConfirmCurrentFlaskAndNext() {
    global g_current_flask_index, g_current_single_overlay, g_setup_notification_gui
    global g_flask_rect_width, g_flask_rect_height
    
    try {
        LogInfo("VisualDetection", Format("Confirming Flask{} position", g_current_flask_index))
        
        if (!g_current_single_overlay || g_current_single_overlay == "") {
            ShowOverlay("設定するオーバーレイがありません", 2000)
            return
        }
        
        ; 現在のオーバーレイの中央座標を取得
        g_current_single_overlay.GetPos(&guiX, &guiY, &guiW, &guiH)
        centerX := guiX + (guiW // 2)
        centerY := guiY + (guiH // 2)
        
        ; 設定を保存
        SaveSingleFlaskPosition(g_current_flask_index, centerX, centerY, g_flask_rect_width, g_flask_rect_height)
        
        ; 設定完了フラスコの視覚化作成
        CreateCompletedFlaskOverlay(centerX, centerY, g_current_flask_index, g_flask_rect_width, g_flask_rect_height)
        
        ; 完了メッセージ
        ShowOverlay(Format("Flask{} 設定完了", g_current_flask_index), 1500)
        
        ; 次のフラスコへ
        g_current_flask_index++
        
        if (g_current_flask_index <= 5) {
            ; 次のフラスコ位置計算
            monitors := GetFlaskMonitorInfo()
            centralMonitor := monitors["central"]
            flaskPositions := CalculateFlaskSlotPositions(centralMonitor)
            
            ; 次のフラスコの推定位置
            if (flaskPositions.Has(g_current_flask_index)) {
                nextFlaskPos := flaskPositions[g_current_flask_index]
                targetX := nextFlaskPos["x"]
                targetY := nextFlaskPos["y"]
            } else {
                ; フォールバック位置
                baseX := centralMonitor["left"] + 100
                flaskSpacing := 80
                targetX := baseX + (g_current_flask_index - 1) * flaskSpacing
                targetY := centralMonitor["bottom"] - 200
            }
            
            ; スムーズ移行アニメーション開始
            StartTransitionAnimation(centerX, centerY, targetX, targetY, g_current_flask_index)
            
        } else {
            ; 全て完了
            EndSequentialSetup()
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to confirm flask position: " . e.Message)
        ShowOverlay("フラスコ設定の確定に失敗しました", 3000)
    }
}

; スムーズ移行アニメーション
StartTransitionAnimation(startX, startY, endX, endY, flaskNumber) {
    try {
        LogDebug("VisualDetection", Format("Starting transition animation from {},{} to {},{} for Flask{}", 
            startX, startY, endX, endY, flaskNumber))
        
        ; アニメーション用グローバル変数を設定
        global animStartX := startX
        global animStartY := startY
        global animEndX := endX
        global animEndY := endY
        global animCurrentFrame := 0
        global animTotalFrames := 18  ; 300ms / 16ms = ~18 frames
        global animTargetFlask := flaskNumber
        
        ; 現在のオーバーレイとガイドを削除
        ClearCurrentOverlays()
        
        ; タイマー開始
        SetTimer(PerformFlaskAnimation, 16)
        
    } catch as e {
        LogError("VisualDetection", "Failed to start transition animation: " . e.Message)
        ; フォールバック：直接次のフラスコを作成
        CreateSingleFlaskOverlay(endX, endY, flaskNumber)
    }
}

; アニメーション実行関数（グローバルスコープ）
PerformFlaskAnimation() {
    global animStartX, animStartY, animEndX, animEndY
    global animCurrentFrame, animTotalFrames, animTargetFlask
    
    animCurrentFrame++
    progress := animCurrentFrame / animTotalFrames
    
    ; イージング関数（ease-out）
    easedProgress := 1 - (1 - progress)**3
    
    ; 現在位置計算
    currentX := animStartX + (animEndX - animStartX) * easedProgress
    currentY := animStartY + (animEndY - animStartY) * easedProgress
    
    ; オーバーレイを新しい位置に作成
    CreateSingleFlaskOverlay(currentX, currentY, animTargetFlask)
    
    if (animCurrentFrame >= animTotalFrames) {
        ; アニメーション完了
        SetTimer(PerformFlaskAnimation, 0)  ; タイマー停止
        
        ; 通知更新
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        notificationX := centralMonitor["centerX"]
        notificationY := centralMonitor["top"] + 100
        CreateSetupNotificationOverlay(notificationX, notificationY, animTargetFlask)
        
        LogInfo("VisualDetection", Format("Transition animation completed for Flask{}", animTargetFlask))
    }
}

; 現在のオーバーレイとガイドをクリア
ClearCurrentOverlays() {
    global g_current_single_overlay, g_flask_number_overlay, g_boundary_warning_overlay
    
    try {
        ; メインオーバーレイ削除
        if (g_current_single_overlay && g_current_single_overlay != "") {
            try {
                g_current_single_overlay.Destroy()
                g_current_single_overlay := ""
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 番号オーバーレイ削除
        if (g_flask_number_overlay && g_flask_number_overlay != "") {
            try {
                g_flask_number_overlay.Destroy()
                g_flask_number_overlay := ""
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 境界警告削除
        if (g_boundary_warning_overlay && g_boundary_warning_overlay != "") {
            try {
                g_boundary_warning_overlay.Destroy()
                g_boundary_warning_overlay := ""
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; ガイドライン削除
        ClearGuidelineOverlays()
        
    } catch as e {
        LogError("VisualDetection", "Failed to clear current overlays: " . e.Message)
    }
}

; 単一フラスコ位置保存（中央モニター相対座標）
SaveSingleFlaskPosition(flaskNumber, absoluteX, absoluteY, width, height) {
    try {
        ; モニター情報取得
        monitors := GetFlaskMonitorInfo()
        centralMonitor := monitors["central"]
        
        ; 絶対座標を中央モニター相対座標に変換
        relativeX := absoluteX - centralMonitor["left"]
        relativeY := absoluteY - centralMonitor["top"]
        
        ; 相対座標で設定保存
        ConfigManager.Set("VisualDetection", Format("Flask{}X", flaskNumber), relativeX)
        ConfigManager.Set("VisualDetection", Format("Flask{}Y", flaskNumber), relativeY)
        ConfigManager.Set("VisualDetection", Format("Flask{}Width", flaskNumber), width)
        ConfigManager.Set("VisualDetection", Format("Flask{}Height", flaskNumber), height)
        
        ; 中央モニター情報も保存（将来の座標計算用）
        ConfigManager.Set("VisualDetection", "CentralMonitorWidth", centralMonitor["width"])
        ConfigManager.Set("VisualDetection", "CentralMonitorHeight", centralMonitor["height"])
        
        LogInfo("VisualDetection", Format("Flask{} position saved: absolute({},{}) relative({},{}) size {}x{}", 
            flaskNumber, absoluteX, absoluteY, relativeX, relativeY, width, height))
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to save Flask{} position: {}", flaskNumber, e.Message))
        return false
    }
}

; ConvertRelativeToAbsolute function removed - using VisualDetection/CoordinateManager.ahk version instead

; フラスコ位置読み込み（相対座標から絶対座標に変換）
LoadFlaskPosition(flaskNumber) {
    try {
        ; 相対座標を読み込み
        relativeX := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
        relativeY := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
        width := ConfigManager.Get("VisualDetection", Format("Flask{}Width", flaskNumber), 60)
        height := ConfigManager.Get("VisualDetection", Format("Flask{}Height", flaskNumber), 80)
        
        if (relativeX == 0 && relativeY == 0) {
            LogDebug("VisualDetection", Format("Flask{} position not configured", flaskNumber))
            return Map("x", 0, "y", 0, "width", width, "height", height, "configured", false)
        }
        
        ; 絶対座標に変換
        absolutePos := ConvertRelativeToAbsolute(relativeX, relativeY)
        
        return Map(
            "x", absolutePos["x"],
            "y", absolutePos["y"],
            "width", width,
            "height", height,
            "relativeX", relativeX,
            "relativeY", relativeY,
            "configured", true
        )
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to load Flask{} position: {}", flaskNumber, e.Message))
        return Map("x", 0, "y", 0, "width", 60, "height", 80, "configured", false)
    }
}

; 順次設定終了処理
EndSequentialSetup() {
    global g_current_single_overlay, g_setup_notification_gui, g_flask_number_overlay
    global g_completed_flask_overlays, g_boundary_warning_overlay
    
    try {
        LogInfo("VisualDetection", "Ending sequential flask setup")
        
        ; 現在のオーバーレイを削除
        ClearCurrentOverlays()
        
        ; 通知削除
        if (g_setup_notification_gui && g_setup_notification_gui != "") {
            g_setup_notification_gui.Destroy()
            g_setup_notification_gui := ""
        }
        
        ; ホットキー無効化
        EndOverlayCapture()
        
        ; 完了メッセージ
        ShowOverlay("全フラスコの設定が完了しました！", 3000)
        
        ; 少し待ってから設定完了フラスコ表示も削除
        SetTimer(() => ClearCompletedFlaskOverlays(), -5000)
        
        LogInfo("VisualDetection", "Sequential flask setup completed successfully")
        
    } catch as e {
        LogError("VisualDetection", "Failed to end sequential setup: " . e.Message)
    }
}

; 設定完了フラスコオーバーレイをクリア
ClearCompletedFlaskOverlays() {
    global g_completed_flask_overlays
    
    try {
        for completedGui in g_completed_flask_overlays {
            if (completedGui) {
                try {
                    completedGui.Destroy()
                } catch {
                    ; 既に削除されている場合は無視
                }
            }
        }
        g_completed_flask_overlays := []
        
        LogDebug("VisualDetection", "Completed flask overlays cleared")
        
    } catch as e {
        LogError("VisualDetection", "Failed to clear completed flask overlays: " . e.Message)
    }
}

; 移動
MoveOverlay(dx, dy) {
    global g_flask_overlay_gui
    if (!g_flask_overlay_gui || g_flask_overlay_gui == "") {
        return
    }
    
    g_flask_overlay_gui.GetPos(&x, &y)
    g_flask_overlay_gui.Move(x + dx, y + dy)
}

; 全オーバーレイ一括移動
MoveAllOverlays(dx, dy) {
    global g_flask_overlay_guis
    
    LogDebug("VisualDetection", Format("Moving all overlays by dx={}, dy={}", dx, dy))
    
    for gui in g_flask_overlay_guis {
        if (gui) {
            gui.GetPos(&x, &y)
            gui.Move(x + dx, y + dy)
            LogDebug("VisualDetection", Format("Moved overlay to {},{}", x + dx, y + dy))
        }
    }
}

; サイズ変更
ResizeOverlay(dw, dh) {
    global g_flask_overlay_gui, g_flask_rect_width, g_flask_rect_height
    LogDebug("VisualDetection", Format("ResizeOverlay called: dw={}, dh={}", dw, dh))
    
    if (!g_flask_overlay_gui) {
        LogDebug("VisualDetection", "ResizeOverlay: No overlay GUI exists")
        return
    }
    
    ; 最小20ピクセル
    old_width := g_flask_rect_width
    old_height := g_flask_rect_height
    g_flask_rect_width := Max(20, g_flask_rect_width + dw)
    g_flask_rect_height := Max(20, g_flask_rect_height + dh)
    
    LogDebug("VisualDetection", Format("Size changed: {}x{} -> {}x{}", old_width, old_height, g_flask_rect_width, g_flask_rect_height))
    
    ; 再作成
    g_flask_overlay_gui.GetPos(&x, &y)
    LogDebug("VisualDetection", Format("Recreating overlay at: {}, {}", x, y))
    CreateFlaskOverlay(x, y)
    
    ; サイズ表示
    ToolTip(Format("Size: {}x{}", g_flask_rect_width, g_flask_rect_height))
    SetTimer(() => ToolTip(), -1000)
}

; 視覚フィードバック付き楕円リサイズ関数
ResizeAllOverlaysWithFeedback(dw, dh, action) {
    global g_flask_overlay_guis, g_flask_rect_width, g_flask_rect_height
    
    LogDebug("VisualDetection", Format("ResizeAllOverlaysWithFeedback: dw={}, dh={}, action={}", dw, dh, action))
    
    ; サイズ更新（最小40ピクセル）
    oldWidth := g_flask_rect_width
    oldHeight := g_flask_rect_height
    g_flask_rect_width := Max(40, g_flask_rect_width + dw)
    g_flask_rect_height := Max(40, g_flask_rect_height + dh)
    
    ; 楕円比率を計算
    aspectRatio := Round(g_flask_rect_width / g_flask_rect_height, 2)
    
    ; 楕円情報を表示
    ToolTip(Format("{}`n楕円: {}×{} (比率 {})", 
                  action, g_flask_rect_width, g_flask_rect_height, aspectRatio))
    SetTimer(() => ToolTip(), -2000)
    
    ; 全オーバーレイを再作成（中心座標基準）
    if (g_flask_overlay_guis.Length > 0 && g_flask_overlay_guis[1]) {
        ; 最初のオーバーレイの現在の中心座標を取得
        g_flask_overlay_guis[1].GetPos(&currentX, &currentY, &currentW, &currentH)
        centerX := currentX + currentW // 2
        centerY := currentY + currentH // 2
        
        LogDebug("VisualDetection", Format("Recreating elliptical overlays from center {},{}", centerX, centerY))
        CreateAllFlaskOverlays(centerX, centerY)
    }
    
    LogDebug("VisualDetection", Format("Ellipse resized: {}×{} -> {}×{} (ratio: {})", 
             oldWidth, oldHeight, g_flask_rect_width, g_flask_rect_height, aspectRatio))
}

; 全オーバーレイ一括サイズ変更（互換性維持用）
ResizeAllOverlays(dw, dh) {
    ResizeAllOverlaysWithFeedback(dw, dh, "サイズ変更")
}

; フラスコ間隔調整
AdjustFlaskSpacing(delta) {
    global g_flask_spacing, g_flask_overlay_guis
    
    LogDebug("VisualDetection", Format("Adjusting flask spacing by delta={}", delta))
    
    ; 間隔更新（最小5ピクセル）
    old_spacing := g_flask_spacing
    g_flask_spacing := Max(5, g_flask_spacing + delta)
    
    LogDebug("VisualDetection", Format("Spacing changed: {} -> {}", old_spacing, g_flask_spacing))
    
    ; 最初のオーバーレイの位置を基準に再配置
    if (g_flask_overlay_guis.Length > 0 && g_flask_overlay_guis[1]) {
        g_flask_overlay_guis[1].GetPos(&startX, &startY)
        LogDebug("VisualDetection", Format("Recreating all overlays with new spacing from {},{}", startX, startY))
        CreateAllFlaskOverlays(startX, startY)
        
        ; 間隔表示
        ToolTip(Format("Flask Spacing: {} pixels", g_flask_spacing))
        SetTimer(() => ToolTip(), -1000)
    }
}

; 位置保存
SaveFlaskPosition() {
    global g_flask_overlay_gui, g_current_flask_index
    if (!g_flask_overlay_gui || g_flask_overlay_gui == "") {
        return
    }
    
    g_flask_overlay_gui.GetPos(&x, &y, &w, &h)
    centerX := x + w // 2
    centerY := y + h // 2
    
    ; 中心座標を保存
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "X", centerX)
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "Y", centerY)
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "Width", g_flask_rect_width)
    ConfigManager.Set("VisualDetection", 
        "Flask" . g_current_flask_index . "Height", g_flask_rect_height)
    
    LogInfo("VisualDetection", Format("Saved Flask {} position: ({}, {}) size: {}x{}", 
        g_current_flask_index, centerX, centerY, g_flask_rect_width, g_flask_rect_height))
}
