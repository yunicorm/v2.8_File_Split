; ===================================================================
; マナ監視システム（修正版）
; パフォーマンス最適化とエラーハンドリング強化
; ===================================================================

; --- グローバル変数の追加 ---
global g_mana_check_count := 0
global g_mana_check_errors := 0
global g_last_full_check_time := 0
global g_mana_state_stable_count := 0
global g_performance_mode := true

; --- マナ円形検出（最適化版） ---
CheckManaRadialOptimized() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate
    global g_last_full_check_time, g_mana_state_stable_count, g_performance_mode
    
    try {
        currentTime := A_TickCount
        
        ; パフォーマンスモード：安定した状態では簡易チェック
        if (g_performance_mode && g_mana_state_stable_count > 5) {
            ; 最後の完全チェックから1秒以上経過していなければ簡易チェック
            if (currentTime - g_last_full_check_time < 1000) {
                return CheckManaQuick()
            }
        }
        
        ; 完全チェックを実行
        g_last_full_check_time := currentTime
        return CheckManaRadialDetailed()
        
    } catch Error as e {
        global g_mana_check_errors
        g_mana_check_errors++
        LogError("ManaMonitor", Format("Optimized mana check failed (errors: {}): {}", 
            g_mana_check_errors, e.Message))
        return g_last_mana_state  ; エラー時は前回の状態を返す
    }
}

; --- 簡易マナチェック（高速） ---
CheckManaQuick() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius
    
    try {
        ; 3点のみチェック（下部中央、左右）
        checkPoints := [
            {x: g_mana_center_x, y: g_mana_center_y + (g_mana_radius * 0.9)},
            {x: g_mana_center_x - (g_mana_radius * 0.3), y: g_mana_center_y + (g_mana_radius * 0.85)},
            {x: g_mana_center_x + (g_mana_radius * 0.3), y: g_mana_center_y + (g_mana_radius * 0.85)}
        ]
        
        blueThreshold := ConfigManager.Get("Mana", "BlueThreshold", 40)
        blueDominance := ConfigManager.Get("Mana", "BlueDominance", 20)
        blueFound := 0
        
        for point in checkPoints {
            color := SafePixelGetColor(point.x, point.y, "RGB")
            if (IsBlueColor(color, blueThreshold, blueDominance)) {
                blueFound++
            }
        }
        
        ; 3点中2点以上で青が検出されればマナありと判定
        return blueFound >= 2
        
    } catch Error as e {
        LogDebug("ManaMonitor", "Quick check failed: " . e.Message)
        return g_last_mana_state
    }
}

; --- マナ円形検出（詳細版） ---
CheckManaRadialDetailed() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate
    global g_mana_check_count
    
    g_mana_check_count++
    
    ; 検出設定
    blueThreshold := ConfigManager.Get("Mana", "BlueThreshold", 40)
    blueDominance := ConfigManager.Get("Mana", "BlueDominance", 20)
    
    ; 動的なチェック密度（パフォーマンスと精度のバランス）
    checkRatios := g_mana_fill_rate < 30 ? [0.85, 0.90, 0.95] : [0.88, 0.93]
    pointsPerLine := g_mana_fill_rate < 30 ? 5 : 3
    
    totalBlueFound := 0
    totalPoints := 0
    
    ; バッチ処理で色検出（パフォーマンス向上）
    checkBatch := []
    
    ; チェックポイントを事前に計算
    for ratio in checkRatios {
        bottomY := g_mana_center_y + (g_mana_radius * ratio)
        
        Loop pointsPerLine {
            xOffset := ((A_Index - 1) - (pointsPerLine - 1) / 2) * g_mana_radius * 0.4 / (pointsPerLine - 1)
            checkBatch.Push({
                x: g_mana_center_x + xOffset,
                y: bottomY,
                ratio: ratio
            })
        }
    }
    
    ; バッチで色をチェック
    for point in checkBatch {
        try {
            color := SafePixelGetColor(point.x, point.y, "RGB")
            if (IsBlueColor(color, blueThreshold, blueDominance)) {
                totalBlueFound++
            }
            totalPoints++
        } catch Error as e {
            LogDebug("ManaMonitor", Format("Pixel check failed at {},{}: {}", 
                point.x, point.y, e.Message))
        }
        
        ; パフォーマンスのため、一定間隔でSleepを入れる
        if (Mod(A_Index, 5) == 0) {
            Sleep(1)
        }
    }
    
    ; 充填率を更新
    if (totalPoints > 0) {
        g_mana_fill_rate := Round((totalBlueFound / totalPoints) * 100)
    } else {
        g_mana_fill_rate := 0
    }
    
    ; デバッグ情報
    if (g_debug_mode && Mod(g_mana_check_count, 10) == 0) {
        LogDebug("ManaMonitor", Format("Mana check #{}: {}/{} blue ({}%)", 
            g_mana_check_count, totalBlueFound, totalPoints, g_mana_fill_rate))
    }
    
    ; 完全枯渇は全ポイントで青が検出されない場合
    return totalBlueFound > 0
}

; --- マナ円形検出（メイン関数） ---
CheckManaRadial() {
    global g_mana_optimized, g_performance_mode
    
    ; 設定を確認
    g_performance_mode := ConfigManager.Get("Mana", "OptimizedDetection", true)
    
    if (g_mana_optimized && g_performance_mode) {
        return CheckManaRadialOptimized()
    } else {
        return CheckManaRadialDetailed()
    }
}

; --- マナ状態の初期化 ---
InitializeManaState() {
    global g_last_mana_state, g_mana_depleted, g_mana_state_stable_count
    global g_mana_check_count, g_mana_check_errors
    
    ; カウンターをリセット
    g_mana_check_count := 0
    g_mana_check_errors := 0
    g_mana_state_stable_count := 0
    
    ; 初期状態を取得
    currentManaState := CheckManaRadialDetailed()  // 初回は詳細チェック
    g_last_mana_state := currentManaState
    g_mana_depleted := !currentManaState
    
    LogInfo("ManaMonitor", Format("Mana state initialized: {} ({}%)", 
        currentManaState ? "Has mana" : "Depleted", g_mana_fill_rate))
}

; --- マナ監視開始 ---
StartManaMonitoring() {
    global g_mana_monitoring_enabled
    
    g_mana_monitoring_enabled := true
    interval := ConfigManager.Get("Mana", "MonitorInterval", 100)
    
    // 動的インターバル調整
    if (g_performance_mode) {
        interval := Max(interval, 150)  // パフォーマンスモードでは最小150ms
    }
    
    StartManagedTimer("ManaMonitor", MonitorMana, interval)
    
    LogInfo("ManaMonitor", Format("Mana monitoring started (interval: {}ms)", interval))
}

; --- マナ監視メイン関数（改善版） ---
MonitorMana() {
    global g_mana_depleted, g_tincture_active, g_last_mana_state
    global g_macro_start_time, g_macro_active, g_mana_monitoring_enabled
    global g_mana_state_stable_count, g_mana_fill_rate
    
    ; 監視が無効またはマクロが非アクティブなら停止
    if (!g_mana_monitoring_enabled || !g_macro_active) {
        StopManagedTimer("ManaMonitor")
        return
    }
    
    ; マクロ開始から2秒間は枯渇判定を行わない（初期化期間）
    if (A_TickCount - g_macro_start_time < 2000) {
        currentMana := CheckManaQuick()
        g_last_mana_state := currentMana
        return
    }
    
    try {
        ; 現在のマナ状態を取得
        currentMana := CheckManaRadial()
        
        ; 状態が安定しているかチェック
        if (currentMana == g_last_mana_state) {
            g_mana_state_stable_count++
        } else {
            g_mana_state_stable_count := 0
        }
        
        ; マナ状態の変化を検出
        if (!currentMana && g_last_mana_state && g_tincture_active) {
            ; マナ枯渇を検出
            HandleManaDepletion()
        } else if (currentMana && !g_last_mana_state) {
            ; マナ回復を検出
            HandleManaRecovery()
        } else if (g_mana_fill_rate < 20 && g_tincture_active) {
            ; 低マナ警告（20%未満）
            HandleLowManaWarning()
        }
        
        g_last_mana_state := currentMana
        
    } catch Error as e {
        LogError("ManaMonitor", "Monitor cycle failed: " . e.Message)
        
        ; エラーが続く場合は監視間隔を延長
        if (g_mana_check_errors > 10) {
            AdjustMonitoringInterval(200)
        }
    }
}

; --- 監視間隔の動的調整 ---
AdjustMonitoringInterval(newInterval) {
    StopManagedTimer("ManaMonitor")
    StartManagedTimer("ManaMonitor", MonitorMana, newInterval)
    LogInfo("ManaMonitor", Format("Monitoring interval adjusted to {}ms", newInterval))
}

; --- マナ枯渇処理（改善版） ---
HandleManaDepletion() {
    global g_mana_depleted, g_tincture_active, g_tincture_cooldown_end
    global g_tincture_retry_count, TIMING_MANA_DEPLETED_CD, g_mana_fill_rate
    
    ; 二重処理を防ぐ
    if (g_mana_depleted) {
        return
    }
    
    g_mana_depleted := true
    g_tincture_active := false
    g_tincture_cooldown_end := A_TickCount + TIMING_MANA_DEPLETED_CD
    g_tincture_retry_count := 0
    
    StartTinctureCooldownCheck()
    ShowOverlay(Format("マナ完全枯渇 ({}%) - Tincture CD開始", g_mana_fill_rate), 2000)
    UpdateStatusOverlay()
    
    LogInfo("ManaMonitor", Format("Mana depletion detected (fill rate: {}%)", g_mana_fill_rate))
    
    ; パフォーマンスモードを一時的に解除（精度優先）
    global g_performance_mode
    g_performance_mode := false
    SetTimer(() => RestorePerformanceMode(), -5000)
}

; --- マナ回復処理 ---
HandleManaRecovery() {
    global g_mana_depleted, g_mana_fill_rate, g_tincture_active
    global g_tincture_cooldown_end, g_mana_state_stable_count
    
    g_mana_depleted := false
    g_mana_state_stable_count := 0  // 状態変化でリセット
    
    ShowOverlay(Format("マナ回復 ({}%)", g_mana_fill_rate), 1000)
    
    ; Tincture状態の確認
    if (!g_tincture_active && A_TickCount >= g_tincture_cooldown_end) {
        ShowOverlay("Tincture状態異常 - 再確認中...", 1500)
        SetTimer(() => AttemptTinctureUse(), -1000)
    }
    
    LogInfo("ManaMonitor", Format("Mana recovery detected ({}%)", g_mana_fill_rate))
}

; --- 低マナ警告 ---
HandleLowManaWarning() {
    static lastWarningTime := 0
    
    currentTime := A_TickCount
    if (currentTime - lastWarningTime > 5000) {  ; 5秒に1回まで
        ShowOverlay(Format("警告: 低マナ ({}%)", g_mana_fill_rate), 1500)
        lastWarningTime := currentTime
        LogWarn("ManaMonitor", Format("Low mana warning: {}%", g_mana_fill_rate))
    }
}

; --- パフォーマンスモードの復元 ---
RestorePerformanceMode() {
    global g_performance_mode
    g_performance_mode := ConfigManager.Get("Mana", "OptimizedDetection", true)
    LogDebug("ManaMonitor", "Performance mode restored")
}

; --- マナ監視の停止 ---
StopManaMonitoring() {
    global g_mana_monitoring_enabled
    
    g_mana_monitoring_enabled := false
    StopManagedTimer("ManaMonitor")
    
    LogInfo("ManaMonitor", "Mana monitoring stopped")
}

; --- マナ監視統計の取得 ---
GetManaMonitorStats() {
    global g_mana_check_count, g_mana_check_errors, g_mana_fill_rate
    global g_mana_state_stable_count, g_performance_mode
    
    return {
        checkCount: g_mana_check_count,
        errorCount: g_mana_check_errors,
        errorRate: g_mana_check_count > 0 ? Round(g_mana_check_errors / g_mana_check_count * 100, 2) : 0,
        fillRate: g_mana_fill_rate,
        stableCount: g_mana_state_stable_count,
        performanceMode: g_performance_mode
    }
}

; --- デバッグ情報の取得 ---
GetManaDebugInfo() {
    stats := GetManaMonitorStats()
    colorStats := GetColorDetectionStats()
    
    debugInfo := []
    debugInfo.Push("=== Mana Monitor Debug ===")
    debugInfo.Push(Format("Checks: {} (Errors: {} = {}%)", 
        stats.checkCount, stats.errorCount, stats.errorRate))
    debugInfo.Push(Format("Fill Rate: {}%", stats.fillRate))
    debugInfo.Push(Format("Stable Count: {}", stats.stableCount))
    debugInfo.Push(Format("Performance Mode: {}", stats.performanceMode))
    debugInfo.Push("")
    debugInfo.Push(Format("Color Cache: {} entries ({}% hit rate)", 
        colorStats.cacheSize, colorStats.hitRate))
    debugInfo.Push(Format("Slow Detections: {}", colorStats.slowDetections))
    
    return debugInfo
}