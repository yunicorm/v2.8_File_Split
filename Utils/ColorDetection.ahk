; ===================================================================
; 色検出ユーティリティ
; ピクセル色の取得と分析用関数
; ===================================================================

; --- 色の明度を計算 ---
GetColorBrightness(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    
    ; 明度を計算（0-255の範囲）
    return Round((r * 0.299 + g * 0.587 + b * 0.114))
}

; --- RGB値を個別に取得 ---
GetRGB(color) {
    return {
        r: (color >> 16) & 0xFF,
        g: (color >> 8) & 0xFF,
        b: color & 0xFF
    }
}

; --- 色の類似度を計算（0-100%） ---
CalculateColorSimilarity(color1, color2) {
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

; --- 色が特定の範囲内かチェック ---
IsColorInRange(color, targetColor, tolerance := 10) {
    rgb := GetRGB(color)
    target := GetRGB(targetColor)
    
    return (
        Abs(rgb.r - target.r) <= tolerance &&
        Abs(rgb.g - target.g) <= tolerance &&
        Abs(rgb.b - target.b) <= tolerance
    )
}

; --- 青色成分が優勢かチェック（マナ検出用） ---
IsBlueColor(color, threshold := 40, dominance := 20) {
    rgb := GetRGB(color)
    
    return (
        rgb.b >= threshold && 
        rgb.b > rgb.r + dominance && 
        rgb.b > rgb.g + dominance
    )
}

; --- 金色/茶色系かチェック（GGGロゴ検出用） ---
IsGoldBrownColor(color) {
    rgb := GetRGB(color)
    
    ; 金色/茶色系の判定（R > G > B で、Rが高め）
    return (
        rgb.r > 100 && 
        rgb.r > rgb.g && 
        rgb.g > rgb.b && 
        (rgb.r - rgb.b) > 50
    )
}

; --- 暗い色かチェック ---
IsDarkColor(color, threshold := 50) {
    brightness := GetColorBrightness(color)
    return brightness < threshold
}

; --- 色を16進数文字列に変換 ---
ColorToHex(color) {
    return Format("0x{:06X}", color)
}

; --- 16進数文字列を色に変換 ---
HexToColor(hexStr) {
    ; "0x"や"#"プレフィックスを削除
    hexStr := RegExReplace(hexStr, "^(0x|#)", "")
    return Integer("0x" . hexStr)
}

; --- 色の平均を計算 ---
AverageColors(colors) {
    if (!IsObject(colors) || colors.Length == 0) {
        return 0
    }
    
    totalR := 0
    totalG := 0
    totalB := 0
    
    for color in colors {
        rgb := GetRGB(color)
        totalR += rgb.r
        totalG += rgb.g
        totalB += rgb.b
    }
    
    count := colors.Length
    avgR := Round(totalR / count)
    avgG := Round(totalG / count)
    avgB := Round(totalB / count)
    
    return (avgR << 16) | (avgG << 8) | avgB
}

; --- エリア内の主要色を取得 ---
GetDominantColor(x, y, width, height, sampleRate := 5) {
    colors := Map()
    
    Loop height // sampleRate {
        scanY := y + (A_Index - 1) * sampleRate
        Loop width // sampleRate {
            scanX := x + (A_Index - 1) * sampleRate
            
            try {
                color := PixelGetColor(scanX, scanY, "RGB")
                
                ; 色をグループ化（精度を下げて類似色をまとめる）
                groupedColor := (color >> 4) << 4
                
                if (colors.Has(groupedColor)) {
                    colors[groupedColor]++
                } else {
                    colors[groupedColor] := 1
                }
            } catch {
                ; エラーは無視
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
}

; --- デバッグ用：色情報を文字列化 ---
FormatColorInfo(color) {
    rgb := GetRGB(color)
    brightness := GetColorBrightness(color)
    hex := ColorToHex(color)
    
    return Format("RGB({}, {}, {}) Brightness: {} Hex: {}", 
        rgb.r, rgb.g, rgb.b, brightness, hex)
}