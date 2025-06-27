; ===================================================================
; マナ監視システム
; ===================================================================

; --- マナ円形検出（完全枯渇検出式） ---
CheckManaRadial() {
    global g_mana_center_x, g_mana_center_y, g_mana_radius, g_mana_fill_rate
    
    ; 検出設定
    blueThreshold := 40
    checkRatios := [0.85, 0.90, 0.95]  ; マナオーブ下部の3つの高さ
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
                if (IsBlueColor(color, blueThreshold, 20)) {
                    totalBlueFound++
                }
            } catch {
                ; エラーは無視
            }
        }
    }
    
    ; 充填率を更新（0または100で簡略化）
    g_mana_fill_rate := totalBlueFound > 0 ? 100 : 0
    
    ; 完全枯渇は全ポイント（15箇所）で青が検出されない場合
    return totalBlueFound > 0
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
    SetTimer(MonitorMana, 100)
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
    
    currentMana := CheckManaRadial()
    
    ; マナ状態の変化を検出
    if (!currentMana && g_last_mana_state && g_tincture_active) {
        HandleManaDepletion()
    } else if (currentMana && !g_last_mana_state) {
        HandleManaRecovery()
    }
    
    g_last_mana_state := currentMana
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
}