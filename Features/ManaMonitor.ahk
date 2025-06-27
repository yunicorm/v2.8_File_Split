; ===================================================================
; マナ監視システム（最適化版）
; ===================================================================

; --- マナ円形検出（最適化版） ---
CheckManaRadialOptimized() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate
    
    try {
        ; まず中央付近の1点を高速チェック
        quickCheckY := g_mana_center_y + (g_mana_radius * 0.9)
        quickColor := PixelGetColor(g_mana_center_x, quickCheckY, "RGB")
        
        blueThreshold := ConfigManager.Get("Mana", "BlueThreshold", 40)
        blueDominance := ConfigManager.Get("Mana", "BlueDominance", 20)
        
        ; 青色が検出されたら詳細チェックをスキップ
        if (IsBlueColor(quickColor, blueThreshold, blueDominance)) {
            g_mana_fill_rate := 100
            return true
        }
        
        ; 詳細チェックが必要な場合のみ実行
        return CheckManaRadialDetailed()
        
    } catch Error as e {
        LogError("ManaMonitor", "Optimized mana check failed: " . e.Message)
        return g_last_mana_state  ; エラー時は前回の状態を返す
    }
}

; --- マナ円形検出（詳細版） ---
CheckManaRadialDetailed() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate
    
    ; 検出設定
    blueThreshold := ConfigManager.Get("Mana", "BlueThreshold", 40)
    blueDominance := ConfigManager.Get("Mana", "BlueDominance", 20)
    checkRatios := [0.85, 0.90, 0.95]
    totalBlueFound := 0
    
    ; 各高さで青色を検出
    for ratio in checkRatios {
        bottomY := g_mana_center_y + (g_mana_radius * ratio)
        
        ; 各高さで5ポイントをチェック
        Loop 5 {
            xOffset := (A_Index - 3) * g_mana_radius * 0.2
            checkX := g_mana_center_x + xOffset
            checkY := bottomY
            
            try {
                color := PixelGetColor(checkX, checkY, "RGB")
                if (IsBlueColor(color, blueThreshold, blueDominance)) {
                    totalBlueFound++
                }
            } catch Error as e {
                LogDebug("ManaMonitor", Format("Pixel check failed at {},{}: {}", 
                    checkX, checkY, e.Message))
            }
        }
    }
    
    ; 充填率を更新
    g_mana_fill_rate := Round((totalBlueFound / 15) * 100)
    
    ; 完全枯渇は全ポイント（15箇所）で青が検出されない場合
    return totalBlueFound > 0
}

; --- マナ円形検出（メイン関数） ---
CheckManaRadial() {
    global g_mana_optimized
    
    if (g_mana_optimized) {
        return CheckManaRadialOptimized()
    } else {
        return CheckManaRadialDetailed()
    }
}

; --- マナ状態の初期化 ---
InitializeManaState() {
    global g_last_mana_state, g_mana_depleted
    
    currentManaState := CheckManaRadial()
    g_last_mana_state := currentManaState
    g_mana_depleted := !currentManaState
}

; --- マナ監視開始 ---
StartManaMonitoring() {
    interval := ConfigManager.Get("Mana", "MonitorInterval", 100)
    SetTimer(MonitorMana, interval)
}

; --- マナ監視メイン関数 ---
MonitorMana() {
    global g_mana_depleted, g_tincture_active, g_last_mana_state
    global g_macro_start_time, g_macro_active
    
    if (!g_macro_active) {
        SetTimer(MonitorMana, 0)
        return
    }
    
    ; マクロ開始から2秒間は枯渇判定を行わない
    if (A_TickCount - g_macro_start_time < 2000) {
        currentMana := CheckManaRadial()
        g_last_mana_state := currentMana
        return
    }
    
    try {
        currentMana := CheckManaRadial()
        
        ; マナ状態の変化を検出
        if (!currentMana && g_last_mana_state && g_tincture_active) {
            HandleManaDepletion()
        } else if (currentMana && !g_last_mana_state) {
            HandleManaRecovery()
        }
        
        g_last_mana_state := currentMana
        
    } catch Error as e {
        LogError("ManaMonitor", "Monitor cycle failed: " . e.Message)
    }
}

; --- マナ枯渇処理 ---
HandleManaDepletion() {
    global g_mana_depleted, g_tincture_active, g_tincture_cooldown_end
    global g_tincture_retry_count, TIMING_MANA_DEPLETED_CD
    
    g_mana_depleted := true
    g_tincture_active := false
    g_tincture_cooldown_end := A_TickCount + TIMING_MANA_DEPLETED_CD
    g_tincture_retry_count := 0
    
    StartTinctureCooldownCheck()
    ShowOverlay("マナ完全枯渇 (0%) - Tincture CD開始", 2000)
    UpdateStatusOverlay()
    
    LogInfo("ManaMonitor", "Mana depletion detected")
}

; --- マナ回復処理 ---
HandleManaRecovery() {
    global g_mana_depleted, g_mana_fill_rate, g_tincture_active
    global g_tincture_cooldown_end
    
    g_mana_depleted := false
    ShowOverlay(Format("マナ回復 ({}%)", g_mana_fill_rate), 1000)
    
    ; Tincture状態の確認
    if (!g_tincture_active && A_TickCount >= g_tincture_cooldown_end) {
        ShowOverlay("Tincture状態異常 - 再確認中...", 1500)
        SetTimer(() => AttemptTinctureUse(), -1000)
    }
    
    LogInfo("ManaMonitor", Format("Mana recovery detected ({}%)", g_mana_fill_rate))
}