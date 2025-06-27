; ===================================================================
; 色検出ユーティリティ（修正版）
; ピクセル色の取得と分析用関数（キャッシュ機能付き）
; ===================================================================

; --- グローバル変数 ---
global g_pixel_cache := Map()
global g_cache_hit_count := 0
global g_cache_miss_count := 0
global g_slow_detection_count := 0

; --- 色検出（タイムアウトとキャッシュ付き） ---
SafePixelGetColor(x, y, mode := "RGB") {
    global g_pixel_cache, g_cache_hit_count, g_cache_miss_count
    
    static cacheExpiry := 50  ; 50ms キャッシュ有効期限
    static coordModeSet := false
    
    ; CoordModeを一度だけ設定
    if (!coordModeSet) {
        CoordMode("Pixel", "Screen")
        coordModeSet := true
    }
    
    ; キャッシュキーを生成
    cacheKey := Format("{},{}", x, y)
    currentTime := A_TickCount
    
    ; キャッシュをチェック
    if (g_pixel_cache.Has(cacheKey)) {
        cached := g_pixel_cache[cacheKey]
        if (currentTime - cached.time < cacheExpiry) {
            g_cache_hit_count++
            return cached.color
        }
    }
    
    g_cache_miss_count++
    
    ; タイムアウト設定を取得
    timeout := ConfigManager.Get("Performance", "ColorDetectTimeout", 50)
    startTime := currentTime
    
    try {
        ; 座標が画面内かチェック
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight
        
        if (x < 0 || y < 0 || x >= screenWidth || y >= screenHeight) {
            throw Error(Format("Coordinates out of bounds: {},{} (Screen: {}x{})", 
                x, y, screenWidth, screenHeight))
        }
        
        ; 色を取得
        color := PixelGetColor(x, y, mode)
        
        ; キャッシュに保存
        g_pixel_cache[cacheKey] := {color: color, time: currentTime}
        
        ; キャッシュサイズ制限（メモリ使用量対策）
        if (g_pixel_cache.Count > 1000) {
            CleanupPixelCache()
        }
        
        ; タイムアウトチェック
        elapsed := A_TickCount - startTime
        if (elapsed > timeout) {
            global g_slow_detection_count
            g_slow_detection_count++
            LogWarn("ColorDetection", Format("Slow pixel detection at {},{}: {}ms (Total slow: {})", 
                x, y, elapsed, g_slow_detection_count))
        }
        
        return color
        
    } catch Error as e {
        LogError("ColorDetection", Format("Failed to get pixel at {},{}: {}", 
            x, y, e.Message))
        
        ; エラー時もキャッシュ（黒色として）
        g_pixel_cache[cacheKey] := {color: 0x000000, time: currentTime}
        return 0x000000
    }
}

; --- キャッシュのクリーンアップ ---
CleanupPixelCache() {
    global g_pixel_cache
    
    currentTime := A_TickCount
    expiredKeys := []
    
    ; 期限切れのエントリを収集
    for key, cached in g_pixel_cache {
        if (currentTime - cached.time > 100) {  ; 100ms以上古いエントリ
            expiredKeys.Push(key)
        }
    }
    
    ; 期限切れエントリを削除
    for key in expiredKeys {
        g_pixel_cache.Delete(key)
    }
    
    LogDebug("ColorDetection", Format("Pixel cache cleaned: {} entries removed", expiredKeys.Length))
}

; --- 色の明度を計算 ---
GetColorBrightness(color) {
    try {
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        
        ; 明度を計算（0-255の範囲）
        ; 人間の目の感度を考慮した重み付け
        return Round((r * 0.299 + g * 0.587 + b * 0.114))
    } catch Error as e {
        LogError("ColorDetection", "Brightness calculation failed: " . e.Message)
        return 0
    }
}

; --- RGB値を個別に取得 ---
GetRGB(color) {
    try {
        return {
            r: (color >> 16) & 0xFF,
            g: (color >> 8) & 0xFF,
            b: color & 0xFF
        }
    } catch Error as e {
        LogError("ColorDetection", "RGB extraction failed: " . e.Message)
        return {r: 0, g: 0, b: 0}
    }
}

; --- HSV色空間への変換 ---
RGBtoHSV(color) {
    rgb := GetRGB(color)
    
    ; 正規化（0-1の範囲）
    r := rgb.r / 255.0
    g := rgb.g / 255.0
    b := rgb.b / 255.0
    
    maxVal := Max(r, g, b)
    minVal := Min(r, g, b)
    delta := maxVal - minVal
    
    ; 明度（Value）
    v := maxVal
    
    ; 彩度（Saturation）
    s := (maxVal == 0) ? 0 : delta / maxVal
    
    ; 色相（Hue）
    h := 0
    if (delta != 0) {
        if (maxVal == r) {
            h := ((g - b) / delta) + (g < b ? 6 : 0)
        } else if (maxVal == g) {
            h := ((b - r) / delta) + 2
        } else {
            h := ((r - g) / delta) + 4
        }
        h /= 6
    }
    
    return {
        h: Round(h * 360),      ; 0-360度
        s: Round(s * 100),      ; 0-100%
        v: Round(v * 100)       ; 0-100%
    }
}

; --- 色の類似度を計算（改善版） ---
CalculateColorSimilarity(color1, color2, method := "euclidean") {
    try {
        switch method {
            case "euclidean":
                return CalculateEuclideanSimilarity(color1, color2)
            case "hsv":
                return CalculateHSVSimilarity(color1, color2)
            default:
                return CalculateEuclideanSimilarity(color1, color2)
        }
    } catch Error as e {
        LogError("ColorDetection", "Similarity calculation failed: " . e.Message)
        return 0
    }
}

; --- ユークリッド距離による類似度 ---
CalculateEuclideanSimilarity(color1, color2) {
    rgb1 := GetRGB(color1)
    rgb2 := GetRGB(color2)
    
    ; ユークリッド距離を計算
    distance := Sqrt(
        (rgb1.r - rgb2.r)**2 + 
        (rgb1.g - rgb2.g)**2 + 
        (rgb1.b - rgb2.b)**2
    )
    
    ; 最大距離（黒から白）は約441.67
    maxDistance := Sqrt(255**2 * 3)
    
    ; 類似度を計算（100%が完全一致）
    similarity := 100 - (distance / maxDistance * 100)
    return Round(similarity, 2)
}

; --- HSV色空間での類似度 ---
CalculateHSVSimilarity(color1, color2) {
    hsv1 := RGBtoHSV(color1)
    hsv2 := RGBtoHSV(color2)
    
    ; 色相の差（円環を考慮）
    hueDiff := Abs(hsv1.h - hsv2.h)
    if (hueDiff > 180) {
        hueDiff := 360 - hueDiff
    }
    
    ; 重み付けして差を計算
    totalDiff := (hueDiff / 180 * 0.5) +         ; 色相（50%）
                 (Abs(hsv1.s - hsv2.s) / 100 * 0.3) +  ; 彩度（30%）
                 (Abs(hsv1.v - hsv2.v) / 100 * 0.2)    ; 明度（20%）
    
    similarity := 100 - (totalDiff * 100)
    return Round(Max(0, similarity), 2)
}

; --- 色が特定の範囲内かチェック ---
IsColorInRange(color, targetColor, tolerance := 10) {
    try {
        rgb := GetRGB(color)
        target := GetRGB(targetColor)
        
        return (
            Abs(rgb.r - target.r) <= tolerance &&
            Abs(rgb.g - target.g) <= tolerance &&
            Abs(rgb.b - target.b) <= tolerance
        )
    } catch Error as e {
        LogError("ColorDetection", "Range check failed: " . e.Message)
        return false
    }
}

; --- 青色成分が優勢かチェック（マナ検出用） ---
IsBlueColor(color, threshold := 40, dominance := 20) {
    try {
        rgb := GetRGB(color)
        
        ; 青色が閾値以上で、かつ赤・緑より優勢
        return (
            rgb.b >= threshold && 
            rgb.b > rgb.r + dominance && 
            rgb.b > rgb.g + dominance
        )
    } catch Error as e {
        LogError("ColorDetection", "Blue color check failed: " . e.Message)
        return false
    }
}

; --- 金色/茶色系かチェック（GGGロゴ検出用） ---
IsGoldBrownColor(color) {
    try {
        rgb := GetRGB(color)
        hsv := RGBtoHSV(color)
        
        ; HSVでの判定（より正確）
        ; 金色/茶色は色相が30-50度、彩度が中程度以上
        isGoldHue := (hsv.h >= 25 && hsv.h <= 55)
        hasSaturation := (hsv.s >= 30)
        hasBrightness := (hsv.v >= 40)
        
        ; RGBでの追加チェック
        rgbCheck := (rgb.r > 100 && rgb.r > rgb.g && rgb.g > rgb.b && (rgb.r - rgb.b) > 50)
        
        return (isGoldHue && hasSaturation && hasBrightness) || rgbCheck
        
    } catch Error as e {
        LogError("ColorDetection", "Gold/brown color check failed: " . e.Message)
        return false
    }
}

; --- 暗い色かチェック ---
IsDarkColor(color, threshold := 50) {
    brightness := GetColorBrightness(color)
    return brightness < threshold
}

; --- 色を16進数文字列に変換 ---
ColorToHex(color) {
    try {
        return Format("0x{:06X}", color & 0xFFFFFF)
    } catch Error as e {
        LogError("ColorDetection", "Hex conversion failed: " . e.Message)
        return "0x000000"
    }
}

; --- 16進数文字列を色に変換 ---
HexToColor(hexStr) {
    try {
        ; "0x"や"#"プレフィックスを削除
        hexStr := RegExReplace(hexStr, "^(0x|#)", "")
        
        ; 3文字の短縮形をサポート（#FFF -> #FFFFFF）
        if (StrLen(hexStr) == 3) {
            r := SubStr(hexStr, 1, 1)
            g := SubStr(hexStr, 2, 1)
            b := SubStr(hexStr, 3, 1)
            hexStr := r . r . g . g . b . b
        }
        
        return Integer("0x" . hexStr)
    } catch Error as e {
        LogError("ColorDetection", "Hex parsing failed: " . e.Message)
        return 0x000000
    }
}

; --- 色の平均を計算（重み付き対応） ---
AverageColors(colors, weights := "") {
    if (!IsObject(colors) || colors.Length == 0) {
        return 0
    }
    
    try {
        totalR := 0.0
        totalG := 0.0
        totalB := 0.0
        totalWeight := 0.0
        
        ; 重みが指定されていない場合は均等
        if (!IsObject(weights) || weights.Length != colors.Length) {
            weights := []
            Loop colors.Length {
                weights.Push(1.0)
            }
        }
        
        ; 加重平均を計算
        for i, color in colors {
            try {
                rgb := GetRGB(color)
                weight := weights[i]
                
                totalR += rgb.r * weight
                totalG += rgb.g * weight
                totalB += rgb.b * weight
                totalWeight += weight
            } catch {
                ; 無効な色はスキップ
                continue
            }
        }
        
        if (totalWeight == 0) {
            return 0
        }
        
        avgR := Round(totalR / totalWeight)
        avgG := Round(totalG / totalWeight)
        avgB := Round(totalB / totalWeight)
        
        return (avgR << 16) | (avgG << 8) | avgB
        
    } catch Error as e {
        LogError("ColorDetection", "Color averaging failed: " . e.Message)
        return 0
    }
}

; --- エリア内の主要色を取得（最適化版） ---
GetDominantColor(x, y, width, height, sampleRate := 5) {
    colors := Map()
    
    try {
        ; サンプリングレートを調整
        actualSampleRate := Max(sampleRate, 
            ConfigManager.Get("Performance", "ManaSampleRate", 5))
        
        ; 総サンプル数を制限（パフォーマンス対策）
        maxSamples := 100
        totalSamples := 0
        
        yStep := Max(actualSampleRate, Ceil(height / Sqrt(maxSamples)))
        xStep := Max(actualSampleRate, Ceil(width / Sqrt(maxSamples)))
        
        Loop {
            if (A_Index > height / yStep) {
                break
            }
            
            scanY := y + (A_Index - 1) * yStep
            
            Loop {
                if (A_Index > width / xStep) {
                    break
                }
                
                scanX := x + (A_Index - 1) * xStep
                totalSamples++
                
                if (totalSamples > maxSamples) {
                    break 2
                }
                
                try {
                    color := SafePixelGetColor(scanX, scanY)
                    
                    ; 色をグループ化（精度を下げて類似色をまとめる）
                    groupedColor := (color >> 4) << 4
                    
                    if (colors.Has(groupedColor)) {
                        colors[groupedColor]++
                    } else {
                        colors[groupedColor] := 1
                    }
                } catch {
                    ; エラーは無視して次のピクセルへ
                    continue
                }
            }
        }
        
        ; 最も頻度の高い色を返す
        maxCount := 0
        dominantColor := 0
        
        for color, count in colors {
            if (count > maxCount) {
                maxCount := count
                dominantColor := color
            }
        }
        
        LogDebug("ColorDetection", Format("Dominant color found: {} (samples: {})", 
            ColorToHex(dominantColor), totalSamples))
        
        return dominantColor
        
    } catch Error as e {
        LogError("ColorDetection", "Dominant color detection failed: " . e.Message)
        return 0x000000
    }
}

; --- デバッグ用：色情報を文字列化 ---
FormatColorInfo(color) {
    try {
        rgb := GetRGB(color)
        hsv := RGBtoHSV(color)
        brightness := GetColorBrightness(color)
        hex := ColorToHex(color)
        
        return Format("RGB({},{},{}) HSV({},{},{}) Brightness:{} Hex:{}", 
            rgb.r, rgb.g, rgb.b,
            hsv.h, hsv.s, hsv.v,
            brightness, hex)
    } catch Error as e {
        return "Color info unavailable: " . e.Message
    }
}

; --- キャッシュ統計を取得 ---
GetColorDetectionStats() {
    global g_cache_hit_count, g_cache_miss_count, g_slow_detection_count
    global g_pixel_cache
    
    hitRate := 0
    if (g_cache_hit_count + g_cache_miss_count > 0) {
        hitRate := Round(g_cache_hit_count / (g_cache_hit_count + g_cache_miss_count) * 100, 2)
    }
    
    return {
        cacheSize: g_pixel_cache.Count,
        hitCount: g_cache_hit_count,
        missCount: g_cache_miss_count,
        hitRate: hitRate,
        slowDetections: g_slow_detection_count
    }
}

; --- キャッシュをリセット ---
ResetColorDetectionCache() {
    global g_pixel_cache, g_cache_hit_count, g_cache_miss_count, g_slow_detection_count
    
    g_pixel_cache.Clear()
    g_cache_hit_count := 0
    g_cache_miss_count := 0
    g_slow_detection_count := 0
    
    LogInfo("ColorDetection", "Color detection cache reset")
}