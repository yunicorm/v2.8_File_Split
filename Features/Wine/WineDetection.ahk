; Wine of the Prophet Detection Module
; Specialized visual detection for Wine of the Prophet flask
; v2.9.6 - Extracted from VisualDetection.ahk for better modularity

; Wine of the Prophet configuration constants
global WINE_FLASK_NUMBER := 4
global WINE_MAX_CHARGE := 140
global WINE_CHARGE_PER_USE := 72
global WINE_GOLD_COLOR := Map(
    "r", 230,
    "g", 170, 
    "b", 70,
    "tolerance", 50
)

; Wine detection globals
global g_wine_detection_state := Map(
    "enabled", false,
    "sampling_rate", 3,
    "color_tolerance", 50,
    "last_diagnosis_time", 0,
    "diagnosis_results", Map()
)
; Wineチャージ検出のテスト関数
TestWineChargeDetection() {
    try {
        LogInfo("VisualDetection", "Testing Wine of the Prophet charge detection")
        
        ; 検出実行
        result := DetectWineChargeLevel()
        
        ; 結果をオーバーレイで表示
        displayLines := [
            "=== Wine of the Prophet チャージ検出テスト ===",
            "",
            Format("推定チャージ: {:.1f}/{}", result.charge, result.maxCharge),
            Format("液体レベル: {}%", result.percentage),
            Format("使用可能回数: {}", result.usesRemaining),
            Format("使用可能: {}", result.canUse ? "はい" : "いいえ"),
            ""
        ]
        
        if (result.HasOwnProp("error")) {
            displayLines.Push("⚠ エラー: " . result.error)
        } else {
            displayLines.Push("✓ 検出成功")
        }
        
        ShowMultiLineOverlay(displayLines, 5000)
        
        return result.HasOwnProp("error") ? false : true
        
    } catch as e {
        LogError("VisualDetection", Format("TestWineChargeDetection failed: {}", e.Message))
        ShowOverlay("Wine検出テストに失敗", 2000)
        return false
    }
}

; ===================================================================
; フラスコパターン管理 (v2.9.4)
; ===================================================================

; 全フラスコパターンクリア
ClearAllFlaskPatterns() {
    try {
        LogInfo("VisualDetection", "Clearing all flask patterns")
        
        clearedCount := 0
        
        ; 各フラスコのパターンをクリア
        Loop 5 {
            flaskNumber := A_Index
            patternKey := Format("Flask{}ChargedPattern", flaskNumber)
            
            ; 現在のパターンを確認
            currentPattern := ConfigManager.Get("VisualDetection", patternKey, "")
            
            if (currentPattern != "") {
                ; パターンをクリア
                ConfigManager.Set("VisualDetection", patternKey, "")
                clearedCount++
                
                LogDebug("VisualDetection", Format("Cleared pattern for Flask{}", flaskNumber))
            }
        }
        
        ; 結果をログに記録
        LogInfo("VisualDetection", Format("Cleared {} flask patterns", clearedCount))
        
        ; 成功メッセージ
        if (clearedCount > 0) {
            ShowOverlay(Format("{}個のフラスコパターンをクリアしました", clearedCount), 2500)
        } else {
            ShowOverlay("クリアするパターンがありませんでした", 2000)
        }
        
        return clearedCount
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to clear flask patterns: {}", e.Message))
        ShowOverlay("パターンクリアに失敗", 2000)
        return 0
    }
}

; 特定フラスコのパターンクリア
ClearFlaskPattern(flaskNumber) {
    try {
        LogInfo("VisualDetection", Format("Clearing pattern for Flask{}", flaskNumber))
        
        if (flaskNumber < 1 || flaskNumber > 5) {
            LogError("VisualDetection", Format("Invalid flask number: {}", flaskNumber))
            return false
        }
        
        patternKey := Format("Flask{}ChargedPattern", flaskNumber)
        currentPattern := ConfigManager.Get("VisualDetection", patternKey, "")
        
        if (currentPattern == "") {
            ShowOverlay(Format("Flask{} のパターンは既に空です", flaskNumber), 2000)
            return true
        }
        
        ; パターンをクリア
        ConfigManager.Set("VisualDetection", patternKey, "")
        
        ; フラスコ名を取得して表示
        flaskName := ConfigManager.Get("VisualDetection", Format("Flask{}Name", flaskNumber), Format("Flask {}", flaskNumber))
        ShowOverlay(Format("{} のパターンをクリアしました", flaskName), 2000)
        
        LogInfo("VisualDetection", Format("Flask{} pattern cleared successfully", flaskNumber))
        return true
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to clear Flask{} pattern: {}", flaskNumber, e.Message))
        ShowOverlay(Format("Flask{} パターンクリアに失敗", flaskNumber), 2000)
        return false
    }
}

; パターン統計情報取得
GetFlaskPatternStats() {
    try {
        stats := Map(
            "total_patterns", 0,
            "configured_flasks", [],
            "empty_flasks", [],
            "pattern_lengths", Map()
        )
        
        Loop 5 {
            flaskNumber := A_Index
            pattern := ConfigManager.Get("VisualDetection", Format("Flask{}ChargedPattern", flaskNumber), "")
            
            if (pattern != "") {
                stats["total_patterns"]++
                stats["configured_flasks"].Push(flaskNumber)
                stats["pattern_lengths"][flaskNumber] := StrLen(pattern)
            } else {
                stats["empty_flasks"].Push(flaskNumber)
            }
        }
        
        return stats
        
    } catch as e {
        LogError("VisualDetection", Format("Failed to get pattern stats: {}", e.Message))
        return Map()
    }
}

; ===================================================================
; Wine of the Prophet 診断機能 (v2.9.4)
; ===================================================================

; マウス位置の色情報取得（Ctrl+F11）
GetMousePositionColor() {
    try {
        LogDebug("VisualDetection", "GetMousePositionColor() called")
        MouseGetPos(&x, &y)
        
        ; ピクセル色を取得
        pixelColor := PixelGetColor(x, y, "RGB")
        
        ; RGBに分解
        r := (pixelColor >> 16) & 0xFF
        g := (pixelColor >> 8) & 0xFF  
        b := pixelColor & 0xFF
        
        LogDebug("VisualDetection", Format("Color detected: X:{}, Y:{}, R:{}, G:{}, B:{}", x, y, r, g, b))
        
        ; 情報を配列として準備
        displayInfo := [
            "=== マウス位置の色情報 ===",
            "",
            Format("座標: {}, {}", x, y),
            Format("RGB: R={}, G={}, B={}", r, g, b),
            Format("Hex: #{:06X}", pixelColor),
            "",
            "wine_color_log.txt に記録されました"
        ]
        
        ; デバッグログを追加
        LogDebug("VisualDetection", "Preparing to show multi-line overlay")
        LogDebug("VisualDetection", Format("Display info lines: {}", displayInfo.Length))
        
        ; マルチラインオーバーレイで表示（フォールバック付き）
        try {
            ShowMultiLineOverlay(displayInfo, 4000)
            LogDebug("VisualDetection", "ShowMultiLineOverlay called successfully")
        } catch as overlayError {
            LogWarn("VisualDetection", "ShowMultiLineOverlay failed: " . overlayError.Message)
            ; フォールバック
            info := Format("X:{} Y:{} RGB({},{},{}) #{:06X}", x, y, r, g, b, pixelColor)
            ShowOverlay(info, 3000)
            LogDebug("VisualDetection", "Fallback ShowOverlay used")
        }
        
        ; ログファイルに記録
        logText := Format("[{}] Mouse Position Color - X:{}, Y:{}, R:{}, G:{}, B:{}, Hex:#{:06X}",
            FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"), x, y, r, g, b, pixelColor)
        
        try {
            FileAppend(logText . "`n", A_ScriptDir . "\logs\wine_color_log.txt")
            LogInfo("VisualDetection", "Mouse color info saved to wine_color_log.txt")
        } catch {
            LogWarn("VisualDetection", "Failed to save color info to log file")
        }
        
        return {x: x, y: y, r: r, g: g, b: b, hex: pixelColor}
        
    } catch as e {
        LogError("VisualDetection", "Failed to get mouse position color: " . e.Message)
        try {
            ShowMultiLineOverlay(["色情報取得に失敗", "", e.Message], 3000)
        } catch {
            ShowOverlay("色情報取得に失敗: " . e.Message, 3000)
        }
        return Map()
    }
}

; Wine診断モード（F11拡張）
DiagnoseWineDetection() {
    try {
        LogInfo("VisualDetection", "DiagnoseWineDetection() called - Starting Wine of the Prophet detection diagnosis")
        
        ; Flask4（Wine）の設定を取得
        centerX := ConfigManager.Get("VisualDetection", "Flask4X", 626)
        centerY := ConfigManager.Get("VisualDetection", "Flask4Y", 1402)
        width := ConfigManager.Get("VisualDetection", "Flask4Width", 80)
        height := ConfigManager.Get("VisualDetection", "Flask4Height", 120)
        
        LogDebug("VisualDetection", Format("Wine Flask settings: X:{}, Y:{}, W:{}, H:{}", centerX, centerY, width, height))
        
        ; 現在の色設定
        goldR := ConfigManager.Get("VisualDetection", "WineGoldR", 255)
        goldG := ConfigManager.Get("VisualDetection", "WineGoldG", 215)
        goldB := ConfigManager.Get("VisualDetection", "WineGoldB", 0)
        tolerance := ConfigManager.Get("VisualDetection", "WineColorTolerance", 30)
        
        LogDebug("VisualDetection", Format("Wine color settings: RGB({},{},{}), Tolerance:{}", goldR, goldG, goldB, tolerance))
        
        ; 検出エリアを表示
        LogDebug("VisualDetection", "Showing detection area overlay")
        ShowDetectionAreaOverlay(centerX, centerY, width, height)
        
        ; 色分布を分析
        LogDebug("VisualDetection", "Analyzing color distribution")
        colorDistribution := AnalyzeColorDistribution(centerX, centerY, width, height)
        
        ; 最適設定を提案
        LogDebug("VisualDetection", "Suggesting optimal settings")
        optimalSettings := SuggestOptimalSettings(colorDistribution, goldR, goldG, goldB)
        
        ; 診断結果を表示
        LogDebug("VisualDetection", "Displaying diagnosis results")
        DisplayDiagnosisResults(colorDistribution, optimalSettings, centerX, centerY, width, height, goldR, goldG, goldB, tolerance)
        
        LogInfo("VisualDetection", "Wine detection diagnosis completed successfully")
        
    } catch as e {
        LogError("VisualDetection", "Wine diagnosis failed: " . e.Message)
        try {
            ShowMultiLineOverlay(["Wine診断に失敗", "", e.Message], 3000)
        } catch {
            ShowOverlay("Wine診断に失敗: " . e.Message, 2000)
        }
    }
}

; Wine診断オーバーレイ削除タイマー関数
DestroyWineDiagnosisOverlay() {
    global g_wine_diagnosis_overlay
    if (IsSet(g_wine_diagnosis_overlay) && g_wine_diagnosis_overlay) {
        try {
            g_wine_diagnosis_overlay.Destroy()
        } catch {
            ; 既に削除されている場合は無視
        }
        g_wine_diagnosis_overlay := ""
    }
}

; 検出エリアを視覚的に表示
ShowDetectionAreaOverlay(centerX, centerY, width, height) {
    try {
        ; 既存のオーバーレイを削除
        global g_wine_diagnosis_overlay
        if (IsSet(g_wine_diagnosis_overlay) && g_wine_diagnosis_overlay) {
            try {
                g_wine_diagnosis_overlay.Destroy()
            } catch {
                ; 既に削除されている場合は無視
            }
        }
        
        ; 液体検出エリアを計算
        liquidArea := CalculateLiquidDetectionArea(centerX, centerY, width, height)
        
        ; オーバーレイGUIを作成
        g_wine_diagnosis_overlay := Gui()
        g_wine_diagnosis_overlay.Opt("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g_wine_diagnosis_overlay.BackColor := "Red"
        g_wine_diagnosis_overlay.Show(Format("x{} y{} w{} h{} NA", 
            liquidArea["left"], liquidArea["top"], 
            liquidArea["width"], liquidArea["height"]))
        WinSetTransparent(100, g_wine_diagnosis_overlay)
        
        ; 5秒後に自動削除
        SetTimer(DestroyWineDiagnosisOverlay, -5000)
        
        LogDebug("VisualDetection", "Detection area overlay displayed")
        
    } catch as e {
        LogError("VisualDetection", "Failed to show detection area overlay: " . e.Message)
    }
}

; Original AnalyzeColorDistribution function removed - using updated version at end of file

; 最適設定を提案
SuggestOptimalSettings(colorDistribution, currentR, currentG, currentB) {
    try {
        if (!colorDistribution.Has("topColors") || colorDistribution["topColors"].Length == 0) {
            return Map()
        }
        
        ; 黄金色に近い色を探す
        goldenColors := []
        for colorData in colorDistribution["topColors"] {
            ; 黄色系の色（R高、G中〜高、B低）を探す
            if (colorData.r > 200 && colorData.g > 150 && colorData.b < 100) {
                goldenColors.Push(colorData)
            }
        }
        
        ; 最も出現頻度の高い黄金色を選択
        if (goldenColors.Length > 0) {
            optimalColor := goldenColors[1]
            return {
                r: optimalColor.r,
                g: optimalColor.g,
                b: optimalColor.b,
                percentage: optimalColor.percentage,
                tolerance: 25,  ; 推奨許容値
                found: true
            }
        } else {
            ; 黄金色が見つからない場合は最頻出色を返す
            topColor := colorDistribution["topColors"][1]
            return {
                r: topColor.r,
                g: topColor.g,
                b: topColor.b,
                percentage: topColor.percentage,
                tolerance: 30,
                found: false,
                warning: "黄金色が検出されませんでした"
            }
        }
        
    } catch as e {
        LogError("VisualDetection", "Failed to suggest optimal settings: " . e.Message)
        return Map()
    }
}

; 診断結果を表示
DisplayDiagnosisResults(colorDist, optimal, x, y, w, h, curR, curG, curB, curTol) {
    try {
        lines := ["=== Wine of the Prophet 診断結果 ===", ""]
        
        ; 現在の設定
        lines.Push("【現在の設定】")
        lines.Push(Format("座標: ({}, {})  サイズ: {}x{}", x, y, w, h))
        lines.Push(Format("色設定: RGB({}, {}, {})  許容値: {}", curR, curG, curB, curTol))
        lines.Push("")
        
        ; 色分析結果
        lines.Push("【色分布分析】")
        lines.Push(Format("総ピクセル数: {}  ユニーク色数: {}", 
            colorDist["totalPixels"], colorDist["uniqueColors"]))
        lines.Push("")
        
        ; TOP5の色
        lines.Push("【最頻出色TOP5】")
        topCount := Min(5, colorDist["topColors"].Length)
        Loop topCount {
            color := colorDist["topColors"][A_Index]
            lines.Push(Format("{}. RGB({}, {}, {}) - {:.1f}%", 
                A_Index, color.r, color.g, color.b, color.percentage))
        }
        lines.Push("")
        
        ; 推奨設定
        if (optimal.Count > 0) {
            lines.Push("【推奨設定】")
            if (optimal.Has("found") && optimal["found"]) {
                lines.Push(Format("✓ 黄金色検出: RGB({}, {}, {})", optimal["r"], optimal["g"], optimal["b"]))
                lines.Push(Format("  出現率: {:.1f}%", optimal["percentage"]))
                lines.Push(Format("  推奨許容値: {}", optimal["tolerance"]))
            } else if (optimal.Has("warning")) {
                lines.Push("⚠ " . optimal["warning"])
                lines.Push(Format("  最頻出色: RGB({}, {}, {})", optimal["r"], optimal["g"], optimal["b"]))
            }
            
            ; 現在設定との差分
            if (optimal.Has("r")) {
                diffR := Abs(optimal["r"] - curR)
                diffG := Abs(optimal["g"] - curG)
                diffB := Abs(optimal["b"] - curB)
                lines.Push("")
                lines.Push(Format("現在設定との差分: R:{}, G:{}, B:{}", diffR, diffG, diffB))
            }
        }
        
        ; マルチラインオーバーレイで表示
        ShowMultiLineOverlay(lines, 10000)
        
        ; ログファイルにも記録
        logPath := A_ScriptDir . "\logs\wine_diagnosis_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".txt"
        try {
            logContent := ""
            for line in lines {
                logContent .= line . "`n"
            }
            
            ; ログディレクトリを作成
            logDir := A_ScriptDir . "\logs"
            if (!DirExist(logDir)) {
                DirCreate(logDir)
            }
            
            ; ファイルに書き込み
            FileAppend(logContent, logPath, "UTF-8")
            LogInfo("WineDetection", Format("Diagnosis results saved to: {}", logPath))
            
        } catch as e {
            LogError("WineDetection", Format("Failed to save diagnosis log: {}", e.Message))
        }
        
        return true
        
    } catch as e {
        LogError("WineDetection", Format("Failed to display diagnosis results: {}", e.Message))
        return false
    }
}

; Wine of the Prophetのチャージレベルを検出
DetectWineChargeLevel() {
    try {
        LogDebug("WineDetection", "Detecting Wine of the Prophet charge level")
        
        ; Flask4（Wine）の設定を取得
        centerX := ConfigManager.Get("VisualDetection", "Flask4X", 626)
        centerY := ConfigManager.Get("VisualDetection", "Flask4Y", 1402)
        width := ConfigManager.Get("VisualDetection", "Flask4Width", 80)
        height := ConfigManager.Get("VisualDetection", "Flask4Height", 120)
        
        ; サンプリングレートを取得
        samplingRate := g_wine_detection_state["sampling_rate"]
        
        ; 色検出エリアの計算（フラスコの液体部分）
        liquidArea := Map(
            "left", centerX - width // 2 + 5,
            "top", centerY - height // 2 + 10,
            "right", centerX + width // 2 - 5,
            "bottom", centerY + 10  ; 液体部分のみ
        )
        
        ; 黄金色のピクセル数をカウント
        totalPixels := 0
        goldPixels := 0
        
        yStep := Max(samplingRate, 2)
        xStep := Max(samplingRate, 2)
        
        y := liquidArea["top"]
        while (y <= liquidArea["bottom"]) {
            x := liquidArea["left"]
            while (x <= liquidArea["right"]) {
                ; 楕円内判定
                if (IsPointInEllipse(x, y, centerX, centerY, width, height)) {
                    totalPixels++
                    
                    ; ピクセル色を取得
                    pixelColor := PixelGetColor(x, y, "RGB")
                    r := (pixelColor >> 16) & 0xFF
                    g := (pixelColor >> 8) & 0xFF
                    b := pixelColor & 0xFF
                    
                    ; 黄金色判定
                    tolerance := g_wine_detection_state["color_tolerance"]
                    if (IsGoldColor(r, g, b, tolerance)) {
                        goldPixels++
                    }
                }
                x += xStep
            }
            y += yStep
        }
        
        ; チャージ率を計算
        percentage := totalPixels > 0 ? Round((goldPixels / totalPixels) * 100, 1) : 0
        
        ; チャージ量を推定
        currentCharge := Round((percentage / 100) * WINE_MAX_CHARGE, 1)
        usesRemaining := Floor(currentCharge / WINE_CHARGE_PER_USE)
        canUse := currentCharge >= WINE_CHARGE_PER_USE
        
        result := Map(
            "charge", currentCharge,
            "maxCharge", WINE_MAX_CHARGE,
            "percentage", percentage,
            "usesRemaining", usesRemaining,
            "canUse", canUse,
            "chargePerUse", WINE_CHARGE_PER_USE,
            "goldPixels", goldPixels,
            "totalPixels", totalPixels,
            "detectionTime", A_TickCount
        )
        
        LogInfo("WineDetection", Format("Wine charge detected: {:.1f}/{} ({}%), {} uses remaining", 
            currentCharge, WINE_MAX_CHARGE, percentage, usesRemaining))
        
        return result
        
    } catch as e {
        LogError("WineDetection", "Wine charge detection failed: " . e.Message)
        
        ; エラー時のフォールバック
        return Map(
            "charge", 0,
            "maxCharge", WINE_MAX_CHARGE,
            "percentage", 0,
            "usesRemaining", 0,
            "canUse", false,
            "chargePerUse", WINE_CHARGE_PER_USE,
            "error", e.Message,
            "detectionTime", A_TickCount
        )
    }
}

; 黄金色判定ヘルパー関数
IsGoldColor(r, g, b, tolerance) {
    goldR := WINE_GOLD_COLOR["r"]
    goldG := WINE_GOLD_COLOR["g"]
    goldB := WINE_GOLD_COLOR["b"]
    
    return (Abs(r - goldR) <= tolerance && 
            Abs(g - goldG) <= tolerance && 
            Abs(b - goldB) <= tolerance)
}

; 点が楕円内にあるか判定
IsPointInEllipse(x, y, centerX, centerY, width, height) {
    ; 楕円の方程式: ((x-cx)/a)^2 + ((y-cy)/b)^2 <= 1
    a := width / 2
    b := height / 2
    dx := x - centerX
    dy := y - centerY
    
    return ((dx/a)**2 + (dy/b)**2) <= 1
}

; 色分布を分析
AnalyzeColorDistribution(centerX, centerY, width, height) {
    try {
        colorMap := Map()
        totalSamples := 0
        
        ; サンプリング
        samplingRate := 3
        yStart := centerY - height//2
        yEnd := centerY + height//2
        xStart := centerX - width//2
        xEnd := centerX + width//2
        
        y := yStart
        while (y <= yEnd) {
            x := xStart
            while (x <= xEnd) {
                if (IsPointInEllipse(x, y, centerX, centerY, width, height)) {
                    color := PixelGetColor(x, y, "RGB")
                    colorKey := Format("{:06X}", color)
                    
                    if (colorMap.Has(colorKey)) {
                        colorMap[colorKey]++
                    } else {
                        colorMap[colorKey] := 1
                    }
                    totalSamples++
                }
                x += samplingRate
            }
            y += samplingRate
        }
        
        ; 上位の色を抽出
        topColors := []
        for color, count in colorMap {
            percentage := (count / totalSamples) * 100
            if (percentage > 1) {  ; 1%以上の色のみ
                topColors.Push({
                    color: color,
                    count: count,
                    percentage: percentage,
                    r: (Integer("0x" . color) >> 16) & 0xFF,
                    g: (Integer("0x" . color) >> 8) & 0xFF,
                    b: Integer("0x" . color) & 0xFF
                })
            }
        }
        
        ; パーセンテージでソート（手動ソート）
        n := topColors.Length
        i := 1
        while (i < n) {
            j := i + 1
            while (j <= n) {
                if (topColors[i].percentage < topColors[j].percentage) {
                    temp := topColors[i]
                    topColors[i] := topColors[j]
                    topColors[j] := temp
                }
                j++
            }
            i++
        }
        
        return Map(
            "totalSamples", totalSamples,
            "uniqueColors", colorMap.Count,
            "topColors", topColors
        )
        
    } catch as e {
        LogError("WineDetection", "Color distribution analysis failed: " . e.Message)
        return Map()
    }
}

; 液体検出エリアを計算
CalculateLiquidDetectionArea(centerX, centerY, width, height) {
    try {
        ; フラスコの液体部分のみを対象とする
        ; 上部10px、左右5pxマージンを取り、下部は中央より下10pxまで
        margin := 5
        topMargin := 10
        
        liquidArea := Map(
            "left", centerX - width // 2 + margin,
            "top", centerY - height // 2 + topMargin,
            "right", centerX + width // 2 - margin,
            "bottom", centerY + 10,  ; 液体部分のみ
            "width", width - (margin * 2),
            "height", (height // 2) + 10 - topMargin
        )
        
        LogDebug("WineDetection", Format("Liquid area calculated: ({},{}) to ({},{}) size: {}x{}", 
            liquidArea["left"], liquidArea["top"], liquidArea["right"], liquidArea["bottom"],
            liquidArea["width"], liquidArea["height"]))
        
        return liquidArea
        
    } catch as e {
        LogError("WineDetection", "Failed to calculate liquid detection area: " . e.Message)
        
        ; フォールバック
        return Map(
            "left", centerX - 30,
            "top", centerY - 50,
            "right", centerX + 30,
            "bottom", centerY + 10,
            "width", 60,
            "height", 60
        )
    }
}
