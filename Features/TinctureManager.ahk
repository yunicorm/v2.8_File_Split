; ===================================================================
; Tincture管理システム
; Tinctureの使用、クールダウン管理、再試行メカニズム
; ===================================================================

; --- Tincture状態のリセット ---
ResetTinctureState() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    
    g_tincture_active := false
    g_tincture_cooldown_end := 0
    g_tincture_retry_count := 0
    
    LogInfo("TinctureManager", "Tincture state reset")
}

; --- 初回Tincture使用 ---
InitialTinctureUse() {
    global g_tincture_active, KEY_TINCTURE
    
    Send(KEY_TINCTURE)
    g_tincture_active := true  ; 初回は成功と仮定
    
    LogInfo("TinctureManager", "Initial Tincture use")
}

; --- Tinctureクールダウンチェック開始 ---
StartTinctureCooldownCheck() {
    StartManagedTimer("TinctureCooldown", CheckTinctureCooldown, 100)
}

; --- Tinctureクールダウンチェック ---
CheckTinctureCooldown() {
    global g_tincture_cooldown_end, g_tincture_active, g_macro_active
    
    ; マクロが非アクティブなら何もしない
    if (!g_macro_active) {
        StopManagedTimer("TinctureCooldown")
        return
    }
    
    if (A_TickCount >= g_tincture_cooldown_end) {
        ; クールダウン終了 - Tincture再使用試行
        AttemptTinctureUse()
    }
}

; --- Tincture使用試行 ---
AttemptTinctureUse() {
    global g_tincture_active, g_tincture_retry_count, g_macro_active, g_tincture_retry_max
    
    ; マクロが非アクティブなら何もしない
    if (!g_macro_active) {
        g_tincture_retry_count := 0
        return
    }
    
    ; 最大試行回数チェック
    if (g_tincture_retry_count >= g_tincture_retry_max) {
        ShowOverlay("Tincture使用失敗 - 最大試行回数到達", 2000)
        StopManagedTimer("TinctureCooldown")
        g_tincture_retry_count := 0
        LogWarn("TinctureManager", "Max retry attempts reached")
        return
    }
    
    ; Tincture使用を試みる
    g_tincture_retry_count++
    Send(KEY_TINCTURE)
    
    LogInfo("TinctureManager", Format("Tincture use attempt {}/{}", 
        g_tincture_retry_count, g_tincture_retry_max))
    
    ; 使用確認のため少し待機
    Sleep(500)
    
    ; Tincture使用確認タイマーを開始
    SetTimer(() => VerifyTinctureUse(), -1000)
    
    ShowOverlay(Format("Tincture使用試行 ({}/{})", 
        g_tincture_retry_count, g_tincture_retry_max), 1000)
}

; --- Tincture使用確認 ---
VerifyTinctureUse() {
    global g_tincture_active, g_tincture_retry_count, g_macro_active
    global g_mana_fill_rate, g_last_mana_state
    
    ; マクロが非アクティブなら何もしない
    if (!g_macro_active) {
        g_tincture_retry_count := 0
        return
    }
    
    ; マナの状態をチェック（Tinctureが効いていればマナが維持/回復する）
    currentMana := CheckManaRadial()
    
    ; Tinctureが効いているかの判定基準：
    ; 1. マナがある程度（30%以上）維持されている
    ; 2. または前回より増加している
    if (g_mana_fill_rate >= 30 || (currentMana && !g_last_mana_state)) {
        ; Tincture使用成功と判断
        HandleTinctureSuccess()
    } else {
        ; Tincture使用失敗と判断 - 再試行
        ShowOverlay("Tincture効果未確認 - 再試行中...", 1000)
        SetTimer(() => AttemptTinctureUse(), -500)
    }
}

; --- Tincture使用成功処理 ---
HandleTinctureSuccess() {
    global g_tincture_active, g_tincture_retry_count, g_flask_timer_active
    global g_mana_flask_key, g_status_update_needed
    
    g_tincture_active := true
    g_tincture_retry_count := 0
    StopManagedTimer("TinctureCooldown")
    
    // マナフラスコループのタイミングをリセット
    ResetFlaskTiming()
    
    ShowOverlay("Tincture使用成功！", 2000)
    g_status_update_needed := true
    
    LogInfo("TinctureManager", "Tincture successfully activated")
}

; --- マナ枯渇時のTincture処理 ---
HandleTinctureOnManaDepletion() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global TIMING_MANA_DEPLETED_CD
    
    g_tincture_active := false
    g_tincture_cooldown_end := A_TickCount + TIMING_MANA_DEPLETED_CD
    g_tincture_retry_count := 0
    
    // クールダウンチェック開始
    StartTinctureCooldownCheck()
    
    LogInfo("TinctureManager", Format("Tincture deactivated due to mana depletion. CD: {}ms", 
        TIMING_MANA_DEPLETED_CD))
}

; --- Tincture状態の取得 ---
GetTinctureStatus() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    
    if (g_tincture_active) {
        return {
            status: "Active",
            cooldownRemaining: 0,
            retryCount: g_tincture_retry_count
        }
    } else if (g_tincture_cooldown_end > A_TickCount) {
        return {
            status: "Cooldown",
            cooldownRemaining: g_tincture_cooldown_end - A_TickCount,
            retryCount: g_tincture_retry_count
        }
    } else {
        return {
            status: "Ready",
            cooldownRemaining: 0,
            retryCount: g_tincture_retry_count
        }
    }
}