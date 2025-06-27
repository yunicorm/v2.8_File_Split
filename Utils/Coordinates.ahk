; ===================================================================
; 座標計算ユーティリティ
; 画面解像度やUI要素の位置計算用関数
; ===================================================================

; --- 画面解像度の取得 ---
GetScreenResolution() {
    return {
        width: A_ScreenWidth,
        height: A_ScreenHeight
    }
}

; --- モニター情報の詳細取得 ---
GetDetailedMonitorInfo() {
    monitors := []
    
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        MonitorGetWorkArea(A_Index, &workLeft, &workTop, &workRight, &workBottom)
        
        monitors.Push({
            index: A_Index,
            bounds: {
                left: left,
                top: top,
                right: right,
                bottom: bottom,
                width: right - left,
                height: bottom - top
            },
            workArea: {
                left: workLeft,
                top: workTop,
                right: workRight,
                bottom: workBottom,
                width: workRight - workLeft,
                height: workBottom - workTop
            },
            isPrimary: (A_Index == MonitorGetPrimary())
        })
    }
    
    return monitors
}

; --- 特定の解像度用の座標をスケーリング ---
ScaleCoordinates(x, y, sourceWidth := 3440, sourceHeight := 1440) {
    currentRes := GetScreenResolution()
    
    return {
        x: Round(x * currentRes.width / sourceWidth),
        y: Round(y * currentRes.height / sourceHeight)
    }
}

; --- UI要素の推定位置を計算 ---
CalculateUIPositions(screenWidth := 3440, screenHeight := 1440) {
    return {
        ; マナオーブ（右下）
        manaOrb: {
            centerX: screenWidth - 146,  ; 右端から146px
            centerY: screenHeight - 140,  ; 下端から140px
            radius: 139
        },
        
        ; ヘルスオーブ（左下）
        healthOrb: {
            centerX: 146,  ; 左端から146px
            centerY: screenHeight - 140,  ; 下端から140px
            radius: 139
        },
        
        ; スキルバー（下部中央）
        skillBar: {
            centerX: screenWidth / 2,
            centerY: screenHeight - 50,
            width: 800,
            height: 80
        },
        
        ; ミニマップ（右上）
        minimap: {
            centerX: screenWidth - 150,
            centerY: 150,
            radius: 140
        },
        
        ; インベントリボタン（右下）
        inventory: {
            x: screenWidth - 50,
            y: screenHeight - 300,
            width: 40,
            height: 40
        }
    }
}

; --- 円形領域内のランダムポイント生成 ---
GetRandomPointInCircle(centerX, centerY, radius) {
    ; 極座標を使用してランダムな点を生成
    angle := Random(0, 360) * (3.14159 / 180)  ; ラジアンに変換
    distance := Sqrt(Random(0, 1000) / 1000) * radius  ; 均等分布
    
    return {
        x: Round(centerX + distance * Cos(angle)),
        y: Round(centerY + distance * Sin(angle))
    }
}

; --- 矩形領域内のランダムポイント生成 ---
GetRandomPointInRect(x, y, width, height) {
    return {
        x: x + Random(0, width),
        y: y + Random(0, height)
    }
}

; --- 2点間の距離を計算 ---
CalculateDistance(x1, y1, x2, y2) {
    return Sqrt((x2 - x1)**2 + (y2 - y1)**2)
}

; --- 点が円内にあるかチェック ---
IsPointInCircle(pointX, pointY, centerX, centerY, radius) {
    distance := CalculateDistance(pointX, pointY, centerX, centerY)
    return distance <= radius
}

; --- 点が矩形内にあるかチェック ---
IsPointInRect(pointX, pointY, rectX, rectY, rectWidth, rectHeight) {
    return (
        pointX >= rectX && 
        pointX <= rectX + rectWidth &&
        pointY >= rectY &&
        pointY <= rectY + rectHeight
    )
}

; --- 画面上の相対位置を計算（0-1の範囲） ---
GetRelativePosition(x, y, screenWidth := 0, screenHeight := 0) {
    if (screenWidth == 0 || screenHeight == 0) {
        res := GetScreenResolution()
        screenWidth := res.width
        screenHeight := res.height
    }
    
    return {
        x: x / screenWidth,
        y: y / screenHeight
    }
}

; --- 相対位置から絶対座標を計算 ---
GetAbsolutePosition(relX, relY, screenWidth := 0, screenHeight := 0) {
    if (screenWidth == 0 || screenHeight == 0) {
        res := GetScreenResolution()
        screenWidth := res.width
        screenHeight := res.height
    }
    
    return {
        x: Round(relX * screenWidth),
        y: Round(relY * screenHeight)
    }
}

; --- グリッド座標を計算（デバッグ用） ---
CreateGrid(x, y, width, height, rows, cols) {
    grid := []
    cellWidth := width / cols
    cellHeight := height / rows
    
    Loop rows {
        row := A_Index - 1
        Loop cols {
            col := A_Index - 1
            grid.Push({
                row: row,
                col: col,
                x: x + col * cellWidth,
                y: y + row * cellHeight,
                width: cellWidth,
                height: cellHeight,
                centerX: x + col * cellWidth + cellWidth / 2,
                centerY: y + row * cellHeight + cellHeight / 2
            })
        }
    }
    
    return grid
}