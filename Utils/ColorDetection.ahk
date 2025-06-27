; ===================================================================
; 色検出ユーティリティ（エラーハンドリング強化版）
; ピクセル色の取得と分析用関数
; ===================================================================

; --- 色の明度を計算 ---
GetColorBrightness(color) {
    try {
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        
        ; 明度を計算（0-255の範囲）
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

; --- 色検出（タイムアウト付き） ---
SafePixelGetColor(x, y, mode := "RGB") {
    timeout := ConfigManager.Get("Performance", "ColorDetectTimeout", 50)
    startTime := A_TickCount
    
    try {
        ; 座標が画面内かチェック
        if (x < 0 || y < 0 || x > A_ScreenWidth || y > A_ScreenHeight) {
            throw Error("Coordinates out of screen bounds")
        }
        
        color := PixelGetColor(x, y, mode)
        
        ; タイムアウトチェック
        if (A_TickCount - startTime > timeout) {
            LogWarn("ColorDetection", Format("Slow pixel detection at {},{}: {}ms", 
                x, y, A_TickCount - startTime))
        }
        
        return color
        
    } catch Error as e {
        LogError("ColorDetection", Format("Failed to get pixel at {},{}: {}", 
            x, y, e.Message))
        return 0x000000  ; デフォルト黒色
    }
}

; --- 色の類似度を計算（0-100%） ---
CalculateColorSimilarity(color1, color2) {
    try {
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
        
    } catch Error as e {
        LogError("ColorDetection", "Similarity calculation failed: " . e.Message)
        return 0
    }
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
        
        ; 金色/茶色系の判定（R > G > B で、Rが高め）
        return (
            rgb.r > 100 && 
            rgb.r > rgb.g && 
            rgb.g > rgb.b && 
            (rgb.r - rgb.b) > 50
        )
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
        return Format("0x{:06X}", color)
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
        return Integer("0x" . hexStr)
    } catch Error as e {
        LogError("ColorDetection", "Hex parsing failed: " . e.Message)
        return 0x000000
    }
}

; --- 色の平均を計算（エラーハンドリング付き） ---
AverageColors(colors) {
    if (!IsObject(colors) || colors.Length == 0) {
        return 0
    }
    
    try {
        totalR := 0
        totalG := 0
        totalB := 0
        validCount := 0
        
        for color in colors {
            try {
                rgb := GetRGB(color)
                totalR += rgb.r
                totalG += rgb.g
                totalB += rgb.b
                validCount++
            } catch {
                ; 無効な色はスキップ
                continue
            }
        }
        
        if (validCount == 0) {
            return 0
        }
        
        avgR := Round(totalR / validCount)
        avgG := Round(totalG / validCount)
        avgB := Round(totalB / validCount)
        
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
        
        Loop height // actualSampleRate {
            scanY := y + (A_Index - 1) * actualSampleRate
            Loop width // actualSampleRate {
                scanX := x + (A_Index - 1) * actualSampleRate
                
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
        brightness := GetColorBrightness(color)
        hex := ColorToHex(color)
        
        return Format("RGB({}, {}, {}) Brightness: {} Hex: {}", 
            rgb.r, rgb.g, rgb.b, brightness, hex)
    } catch Error as e {
        return "Color info unavailable: " . e.Message
    }
}