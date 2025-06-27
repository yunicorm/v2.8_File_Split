; ===================================================================
; Tincture管理システム（修正版）
; Tinctureの使用、クールダウン管理、再試行メカニズム
; ===================================================================

; --- グローバル変数の追加 ---
global g_tincture_verification_pending := false
global g_tincture_last_use_time := 0
global g_tincture_retry_timer_active := false

; --- Tincture状態のリセット ---
ResetTinctureState() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global g_tincture_verification_pending, g_tincture_retry_timer_active
    
    g_tincture_active := false
    g_tincture_cooldown_end := 0
    g_tincture_retry_count := 0
    g_tincture_verification_pending := false
    g_tincture_retry_timer_active := false
    
    ; 関連するタイマーを停止
    StopManagedTimer("TinctureCooldown")
    StopManagedTimer("TinctureRetry")
    StopManagedTimer("TinctureVerification")
    
    LogInfo("TinctureManager", "Tincture state reset")
}

; --- 初回Tincture使用 ---
InitialTinctureUse() {
    global g_tincture_active, g_tincture_last_use_time, KEY_TINCTURE
    global g_tincture_verification_pending
    
    Send(KEY_TINCTURE)
    g_tincture_active := true  ; 初回は成功と仮定
    g_tincture_last_use_time := A_TickCount
    g_tincture_verification_pending := false
    
    LogInfo("TinctureManager", "Initial Tincture use")
}

; --- Tinctureクールダウンチェック開始 ---
StartTinctureCooldownCheck() {
    global g_macro_active
    
    ; マクロが非アクティブなら開始しない
    if (!g_macro_active) {
        return
    }
    
    StartManagedTimer("TinctureCooldown", CheckTinctureCooldown, 100)
    LogDebug("TinctureManager", "Tincture cooldown check started")
}

; --- Tinctureクールダウンチェック ---
CheckTinctureCooldown() {
    global g_tincture_cooldown_end, g_tincture_active, g_macro_active
    global g_tincture_retry_timer_active
    
    ; マクロが非アクティブなら停止
    if (!g_macro_active) {
        StopManagedTimer("TinctureCooldown")
        return
    }
    
    ; クールダウン中かチェック
    if (A_TickCount < g_tincture_cooldown_end) {
        return
    }
    
    ; 既に再試行中の場合はスキップ
    if (g_tincture_retry_timer_active) {
        return
    }
    
    ; クールダウン終了 - Tincture再使用試行
    StopManagedTimer("TinctureCooldown")
    AttemptTinctureUse()
}

; --- Tincture使用試行（改善版） ---
AttemptTinctureUse() {
    global g_tincture_active, g_tincture_retry_count, g_macro_active, g_tincture_retry_max
    global KEY_TINCTURE, g_tincture_verification_pending, g_tincture_last_use_time
    global g_tincture_retry_timer_active, g_tincture_cooldown_end, TIMING_MANA_DEPLETED_CD
    
    ; 多重実行防止
    if (g_tincture_retry_timer_active) {
        LogDebug("TinctureManager", "Tincture retry already in progress")
        return
    }
    
    ; マクロが非アクティブなら何もしない
    if (!g_macro_active) {
        g_tincture_retry_count := 0
        g_tincture_retry_timer_active := false
        StopManagedTimer("TinctureCooldown")
        StopManagedTimer("TinctureRetry")
        StopManagedTimer("TinctureVerification")
        LogDebug("TinctureManager", "Tincture attempt cancelled - macro inactive")
        return
    }
    
    ; 最大試行回数チェック
    if (g_tincture_retry_count >= g_tincture_retry_max) {
        HandleMaxRetryReached()
        return
    }
    
    try {
        ; 再試行フラグを設定
        g_tincture_retry_timer_active := true
        
        ; Tincture使用を試みる
        g_tincture_retry_count++
        g_tincture_last_use_time := A_TickCount
        g_tincture_verification_pending := true
        
        Send(KEY_TINCTURE)
        
        LogInfo("TinctureManager", Format("Tincture use attempt {}/{}", 
            g_tincture_retry_count, g_tincture_retry_max))
        
        ShowOverlay(Format("Tincture使用試行 ({}/{})", 
            g_tincture_retry_count, g_tincture_retry_max), 1000)
        
        ; 使用確認のため少し待機
        Sleep(500)
        
        ; マクロがまだアクティブかチェック
        if (!g_macro_active) {
            g_tincture_retry_timer_active := false
            return
        }
        
        ; 使用確認タイマーを開始
        StartManagedTimer("TinctureVerification", VerifyTinctureUse, -1000)
        
    } catch Error as e {
        g_tincture_retry_timer_active := false
        LogError("TinctureManager", "Error in AttemptTinctureUse: " . e.Message)
        
        ; エラーの場合は再試行
        if (g_macro_active && g_tincture_retry_count < g_tincture_retry_max) {
            StartManagedTimer("TinctureRetry", () => AttemptTinctureUse(), -2000)
        }
    }
}

; --- 最大再試行回数到達時の処理 ---
HandleMaxRetryReached() {
    global g_tincture_retry_count, g_tincture_cooldown_end, TIMING_MANA_DEPLETED_CD
    global g_tincture_retry_timer_active
    
    ShowOverlay("Tincture使用失敗 - 最大試行回数到達", 2000)
    
    ; タイマーを停止
    StopManagedTimer("TinctureCooldown")
    StopManagedTimer("TinctureRetry")
    StopManagedTimer("TinctureVerification")
    
    g_tincture_retry_count := 0
    g_tincture_retry_timer_active := false
    
    ; 次回のクールダウンを設定（通常の2倍）
    g_tincture_cooldown_end := A_TickCount + (TIMING_MANA_DEPLETED_CD * 2)
    
    ; クールダウンチェックを再開
    StartTinctureCooldownCheck()
    
    LogWarn("TinctureManager", "Max retry attempts reached - extended cooldown applied")
}

; --- Tincture使用確認（改善版） ---
VerifyTinctureUse() {
    global g_tincture_active, g_tincture_retry_count, g_macro_active
    global g_mana_fill_rate, g_last_mana_state, g_tincture_verification_pending
    global g_tincture_retry_timer_active
    
    ; 検証フラグをリセット
    g_tincture_verification_pending := false
    g_tincture_retry_timer_active := false
    
    ; マクロが非アクティブなら何もしない
    if (!g_macro_active) {
        g_tincture_retry_count := 0
        StopManagedTimer("TinctureVerification")
        LogDebug("TinctureManager", "Tincture verification cancelled - macro inactive")
        return
    }
    
    try {
        ; マナの状態をチェック（Tinctureが効いていればマナが維持/回復する）
        currentMana := CheckManaRadial()
        
        ; Tinctureが効いているかの判定基準：
        ; 1. マナがある程度（30%以上）維持されている
        ; 2. または前回より増加している
        ; 3. または現在マナがある
        isTinctureActive := (g_mana_fill_rate >= 30 || 
                            (currentMana && !g_last_mana_state) || 
                            currentMana)
        
        if (isTinctureActive) {
            ; Tincture使用成功と判断
            HandleTinctureSuccess()
        } else {
            ; Tincture使用失敗と判断
            HandleTinctureFailure()
        }
        
    } catch Error as e {
        LogError("TinctureManager", "Error in VerifyTinctureUse: " . e.Message)
        
        ; エラーの場合は失敗として扱う
        HandleTinctureFailure()
    }
}

; --- Tincture使用失敗時の処理 ---
HandleTinctureFailure() {
    global g_tincture_retry_count, g_tincture_retry_max, g_macro_active
    global g_tincture_retry_timer_active
    
    ShowOverlay("Tincture効果未確認 - 再試行中...", 1000)
    LogDebug("TinctureManager", "Tincture effect not confirmed")
    
    g_tincture_retry_timer_active := false
    
    ; まだ試行回数が残っていて、マクロがアクティブなら再試行
    if (g_macro_active && g_tincture_retry_count < g_tincture_retry_max) {
        StartManagedTimer("TinctureRetry", () => AttemptTinctureUse(), -500)
    } else if (g_tincture_retry_count >= g_tincture_retry_max) {
        HandleMaxRetryReached()
    }
}

; --- Tincture使用成功処理 ---
HandleTinctureSuccess() {
    global g_tincture_active, g_tincture_retry_count, g_flask_timer_active
    global g_mana_flask_key, g_status_update_needed, g_tincture_retry_timer_active
    
    g_tincture_active := true
    g_tincture_retry_count := 0
    g_tincture_retry_timer_active := false
    
    ; 関連タイマーを停止
    StopManagedTimer("TinctureCooldown")
    StopManagedTimer("TinctureRetry")
    
    ; マナフラスコループのタイミングをリセット
    ResetFlaskTiming()
    
    ShowOverlay("Tincture使用成功！", 2000)
    g_status_update_needed := true
    
    LogInfo("TinctureManager", "Tincture successfully activated")
}

; --- マナ枯渇時のTincture処理 ---
HandleTinctureOnManaDepletion() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global TIMING_MANA_DEPLETED_CD, g_tincture_verification_pending
    global g_tincture_retry_timer_active
    
    g_tincture_active := false
    g_tincture_cooldown_end := A_TickCount + TIMING_MANA_DEPLETED_CD
    g_tincture_retry_count := 0
    g_tincture_verification_pending := false
    g_tincture_retry_timer_active := false
    
    ; 関連タイマーを停止
    StopManagedTimer("TinctureRetry")
    StopManagedTimer("TinctureVerification")
    
    ; クールダウンチェック開始
    StartTinctureCooldownCheck()
    
    LogInfo("TinctureManager", Format("Tincture deactivated due to mana depletion. CD: {}ms", 
        TIMING_MANA_DEPLETED_CD))
}

; --- Tincture状態の取得 ---
GetTinctureStatus() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global g_tincture_verification_pending, g_tincture_retry_timer_active
    
    status := ""
    
    if (g_tincture_active) {
        status := "Active"
    } else if (g_tincture_verification_pending) {
        status := "Verifying"
    } else if (g_tincture_retry_timer_active) {
        status := "Retrying"
    } else if (g_tincture_cooldown_end > A_TickCount) {
        status := "Cooldown"
    } else {
        status := "Ready"
    }
    
    return {
        status: status,
        cooldownRemaining: Max(0, g_tincture_cooldown_end - A_TickCount),
        retryCount: g_tincture_retry_count,
        isActive: g_tincture_active,
        isPending: g_tincture_verification_pending || g_tincture_retry_timer_active
    }
}

; --- 強制的なTincture停止（緊急停止用） ---
ForceTinctureStop() {
    global g_tincture_active, g_tincture_retry_count, g_tincture_verification_pending
    global g_tincture_retry_timer_active
    
    g_tincture_active := false
    g_tincture_retry_count := 0
    g_tincture_verification_pending := false
    g_tincture_retry_timer_active := false
    
    ; 全ての関連タイマーを停止
    StopManagedTimer("TinctureCooldown")
    StopManagedTimer("TinctureRetry")
    StopManagedTimer("TinctureVerification")
    
    LogInfo("TinctureManager", "Tincture forcefully stopped")
}

; --- デバッグ情報の取得 ---
GetTinctureDebugInfo() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global g_tincture_verification_pending, g_tincture_retry_timer_active
    global g_tincture_last_use_time, g_tincture_retry_max
    
    debugInfo := []
    debugInfo.Push("=== Tincture Debug Info ===")
    debugInfo.Push(Format("Active: {}", g_tincture_active))
    debugInfo.Push(Format("Retry Count: {}/{}", g_tincture_retry_count, g_tincture_retry_max))
    debugInfo.Push(Format("Verification Pending: {}", g_tincture_verification_pending))
    debugInfo.Push(Format("Retry Timer Active: {}", g_tincture_retry_timer_active))
    
    if (g_tincture_cooldown_end > A_TickCount) {
        debugInfo.Push(Format("Cooldown Remaining: {}s", 
            Round((g_tincture_cooldown_end - A_TickCount) / 1000, 1)))
    } else {
        debugInfo.Push("Cooldown: None")
    }
    
    if (g_tincture_last_use_time > 0) {
        debugInfo.Push(Format("Last Use: {}s ago", 
            Round((A_TickCount - g_tincture_last_use_time) / 1000, 1)))
    }
    
    return debugInfo
}