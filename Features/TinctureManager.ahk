; ===================================================================
; Tincture管理システム（完全修正版）
; Tinctureの使用、クールダウン管理、再試行メカニズム（強化版）
; ===================================================================

; --- グローバル変数の追加 ---
global g_tincture_verification_pending := false
global g_tincture_last_use_time := 0
global g_tincture_retry_timer_active := false
global g_tincture_history := []  ; 使用履歴
global g_tincture_success_count := 0
global g_tincture_failure_count := 0
global g_tincture_total_attempts := 0
global g_tincture_verification_method := "mana"  ; "mana" or "buff"

; --- Tincture状態のリセット（拡張版） ---
ResetTinctureState() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global g_tincture_verification_pending, g_tincture_retry_timer_active
    global g_tincture_history, g_tincture_last_use_time
    
    g_tincture_active := false
    g_tincture_cooldown_end := 0
    g_tincture_retry_count := 0
    g_tincture_verification_pending := false
    g_tincture_retry_timer_active := false
    g_tincture_last_use_time := 0
    
    ; 履歴をクリア（最新10件のみ保持）
    if (g_tincture_history.Length > 10) {
        g_tincture_history := g_tincture_history.Slice(-10)
    }
    
    ; 関連するタイマーを停止
    StopManagedTimer("TinctureCooldown")
    StopManagedTimer("TinctureRetry")
    StopManagedTimer("TinctureVerification")
    StopManagedTimer("TinctureTimeout")
    
    LogInfo("TinctureManager", "Tincture state reset completed")
}

; --- 初回Tincture使用（改善版） ---
InitialTinctureUse() {
    global g_tincture_active, g_tincture_last_use_time, KEY_TINCTURE
    global g_tincture_verification_pending, g_tincture_total_attempts
    
    try {
        ; パフォーマンス計測
        StartPerfTimer("InitialTincture")
        
        Send(KEY_TINCTURE)
        g_tincture_active := true  ; 初回は成功と仮定
        g_tincture_last_use_time := A_TickCount
        g_tincture_verification_pending := false
        g_tincture_total_attempts++
        
        ; 使用履歴に記録
        RecordTinctureUse("initial", true)
        
        duration := EndPerfTimer("InitialTincture", "TinctureManager")
        
        LogInfo("TinctureManager", Format("Initial Tincture use completed ({}ms)", duration))
        
    } catch as e {
        LogError("TinctureManager", "Initial Tincture use failed: " . e.Message)
        g_tincture_active := false
    }
}

; --- Tinctureクールダウンチェック開始（改善版） ---
StartTinctureCooldownCheck() {
    global g_macro_active, g_tincture_cooldown_end
    
    ; マクロが非アクティブなら開始しない
    if (!g_macro_active) {
        return
    }
    
    ; 既にチェック中の場合はスキップ
    if (IsTimerActive("TinctureCooldown")) {
        LogDebug("TinctureManager", "Cooldown check already active")
        return
    }
    
    ; 残り時間を計算
    remaining := g_tincture_cooldown_end - A_TickCount
    if (remaining > 0) {
        ShowOverlay(Format("Tincture CD: {}s", Round(remaining / 1000, 1)), 1500)
    }
    
    StartManagedTimer("TinctureCooldown", CheckTinctureCooldown, 100)
    LogDebug("TinctureManager", "Tincture cooldown check started")
}

; --- Tinctureクールダウンチェック（改善版） ---
CheckTinctureCooldown() {
    global g_tincture_cooldown_end, g_tincture_active, g_macro_active
    global g_tincture_retry_timer_active, g_mana_fill_rate
    
    ; マクロが非アクティブなら停止
    if (!g_macro_active) {
        StopManagedTimer("TinctureCooldown")
        return
    }
    
    ; まだクールダウン中
    if (A_TickCount < g_tincture_cooldown_end) {
        ; 残り時間を更新（ステータス表示用）
        UpdateStatusOverlay()
        return
    }
    
    ; 既に再試行中の場合はスキップ
    if (g_tincture_retry_timer_active) {
        return
    }
    
    ; マナが十分にある場合のみ再使用を試みる
    if (g_mana_fill_rate < 20) {
        LogDebug("TinctureManager", Format("Mana too low for Tincture ({}%), waiting", g_mana_fill_rate))
        return
    }
    
    ; クールダウン終了 - Tincture再使用試行
    StopManagedTimer("TinctureCooldown")
    AttemptTinctureUse()
}

; --- Tincture使用試行（完全改善版） ---
AttemptTinctureUse() {
    global g_tincture_active, g_tincture_retry_count, g_macro_active, g_tincture_retry_max
    global KEY_TINCTURE, g_tincture_verification_pending, g_tincture_last_use_time
    global g_tincture_retry_timer_active, g_tincture_cooldown_end, TIMING_MANA_DEPLETED_CD
    global g_tincture_total_attempts, g_mana_fill_rate
    
    ; 多重実行防止
    if (g_tincture_retry_timer_active) {
        LogDebug("TinctureManager", "Tincture retry already in progress")
        return
    }
    
    ; マクロが非アクティブなら何もしない
    if (!g_macro_active) {
        CleanupTinctureTimers()
        return
    }
    
    ; マナチェック
    if (g_mana_fill_rate < 20) {
        LogDebug("TinctureManager", "Insufficient mana for Tincture attempt")
        ; 1秒後に再チェック
        SetTimer(() => AttemptTinctureUse(), -1000)
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
        
        ; パフォーマンス計測
        StartPerfTimer("TinctureAttempt")
        
        ; Tincture使用を試みる
        g_tincture_retry_count++
        g_tincture_last_use_time := A_TickCount
        g_tincture_verification_pending := true
        g_tincture_total_attempts++
        
        ; 使用前の状態を記録
        preManaState := g_mana_fill_rate
        
        Send(KEY_TINCTURE)
        
        LogInfo("TinctureManager", Format("Tincture use attempt {}/{} (Mana: {}%)", 
            g_tincture_retry_count, g_tincture_retry_max, preManaState))
        
        ShowOverlay(Format("Tincture使用試行 ({}/{})", 
            g_tincture_retry_count, g_tincture_retry_max), 1000)
        
        ; 使用確認のため少し待機
        verifyDelay := ConfigManager.Get("Tincture", "VerifyDelay", 1000)
        Sleep(Min(verifyDelay, 500))  ; 最大500msに制限
        
        ; マクロがまだアクティブかチェック
        if (!g_macro_active) {
            g_tincture_retry_timer_active := false
            return
        }
        
        duration := EndPerfTimer("TinctureAttempt", "TinctureManager")
        
        ; 使用確認タイマーを開始
        StartManagedTimer("TinctureVerification", VerifyTinctureUse, -(verifyDelay - 500))
        
        ; タイムアウトタイマーも設定（フェイルセーフ）
        StartManagedTimer("TinctureTimeout", () => HandleTinctureTimeout(), -3000)
        
    } catch as e {
        g_tincture_retry_timer_active := false
        LogError("TinctureManager", "Error in AttemptTinctureUse: " . e.Message)
        
        ; エラーの場合は再試行
        if (g_macro_active && g_tincture_retry_count < g_tincture_retry_max) {
            retryInterval := ConfigManager.Get("Tincture", "RetryInterval", 500)
            StartManagedTimer("TinctureRetry", () => AttemptTinctureUse(), -retryInterval)
        }
    }
}

; --- Tinctureタイムアウト処理 ---
HandleTinctureTimeout() {
    global g_tincture_verification_pending, g_tincture_retry_timer_active
    
    if (g_tincture_verification_pending) {
        LogWarn("TinctureManager", "Tincture verification timeout")
        g_tincture_verification_pending := false
        g_tincture_retry_timer_active := false
        
        ; タイムアウトは失敗として扱う
        HandleTinctureFailure()
    }
}

; --- 最大再試行回数到達時の処理（改善版） ---
HandleMaxRetryReached() {
    global g_tincture_retry_count, g_tincture_cooldown_end, TIMING_MANA_DEPLETED_CD
    global g_tincture_retry_timer_active, g_tincture_failure_count
    
    g_tincture_failure_count++
    
    ShowOverlay("Tincture使用失敗 - 最大試行回数到達", 2000)
    
    ; タイマーを停止
    CleanupTinctureTimers()
    
    g_tincture_retry_count := 0
    g_tincture_retry_timer_active := false
    
    ; 次回のクールダウンを設定（通常の2倍）
    g_tincture_cooldown_end := A_TickCount + (TIMING_MANA_DEPLETED_CD * 2)
    
    ; 使用履歴に記録
    RecordTinctureUse("max_retry", false)
    
    ; クールダウンチェックを再開
    StartTinctureCooldownCheck()
    
    LogWarn("TinctureManager", Format("Max retry attempts reached - extended cooldown applied ({}ms)", 
        TIMING_MANA_DEPLETED_CD * 2))
}

; --- Tincture使用確認（完全改善版） ---
VerifyTinctureUse() {
    global g_tincture_active, g_tincture_retry_count, g_macro_active
    global g_mana_fill_rate, g_last_mana_state, g_tincture_verification_pending
    global g_tincture_retry_timer_active, g_tincture_verification_method
    
    ; タイムアウトタイマーを停止
    StopManagedTimer("TinctureTimeout")
    
    ; 検証フラグをリセット
    g_tincture_verification_pending := false
    g_tincture_retry_timer_active := false
    
    ; マクロが非アクティブなら何もしない
    if (!g_macro_active) {
        CleanupRetryState()
        return
    }
    
    try {
        ; 検証方法に応じて確認
        isTinctureActive := false
        
        switch g_tincture_verification_method {
            case "mana":
                isTinctureActive := VerifyByManaState()
            case "buff":
                isTinctureActive := VerifyByBuffIcon()
            default:
                isTinctureActive := VerifyByManaState()
        }
        
        if (isTinctureActive) {
            HandleTinctureSuccess()
        } else {
            HandleTinctureFailure()
        }
        
    } catch as e {
        LogError("TinctureManager", "Error in VerifyTinctureUse: " . e.Message)
        HandleTinctureFailure()
    }
}

; --- マナ状態による検証 ---
VerifyByManaState() {
    global g_mana_fill_rate, g_last_mana_state
    
    ; マナの状態をチェック（Tinctureが効いていればマナが維持/回復する）
    currentMana := CheckManaRadial()
    
    ; Tinctureが効いているかの判定基準：
    ; 1. マナがある程度（30%以上）維持されている
    ; 2. または前回より増加している
    ; 3. または現在マナがある
    isTinctureActive := (g_mana_fill_rate >= 30 || 
                        (currentMana && !g_last_mana_state) || 
                        currentMana)
    
    LogDebug("TinctureManager", Format("Mana verification: {}% (Active: {})", 
        g_mana_fill_rate, isTinctureActive))
    
    return isTinctureActive
}

; --- バフアイコンによる検証（将来の実装用） ---
VerifyByBuffIcon() {
    ; TODO: バフバーのTinctureアイコンを検出する実装
    LogDebug("TinctureManager", "Buff icon verification not implemented, falling back to mana")
    return VerifyByManaState()
}

; --- Tincture使用失敗時の処理（改善版） ---
HandleTinctureFailure() {
    global g_tincture_retry_count, g_tincture_retry_max, g_macro_active
    global g_tincture_retry_timer_active, g_tincture_failure_count
    
    ShowOverlay("Tincture効果未確認 - 再試行中...", 1000)
    LogDebug("TinctureManager", Format("Tincture effect not confirmed (attempt {}/{})", 
        g_tincture_retry_count, g_tincture_retry_max))
    
    g_tincture_retry_timer_active := false
    
    ; 使用履歴に記録
    RecordTinctureUse("retry", false)
    
    ; まだ試行回数が残っていて、マクロがアクティブなら再試行
    if (g_macro_active && g_tincture_retry_count < g_tincture_retry_max) {
        retryInterval := ConfigManager.Get("Tincture", "RetryInterval", 500)
        StartManagedTimer("TinctureRetry", () => AttemptTinctureUse(), -retryInterval)
    } else if (g_tincture_retry_count >= g_tincture_retry_max) {
        HandleMaxRetryReached()
    }
}

; --- Tincture使用成功処理（改善版） ---
HandleTinctureSuccess() {
    global g_tincture_active, g_tincture_retry_count, g_flask_timer_active
    global g_mana_flask_key, g_status_update_needed, g_tincture_retry_timer_active
    global g_tincture_success_count
    
    g_tincture_active := true
    g_tincture_retry_count := 0
    g_tincture_retry_timer_active := false
    g_tincture_success_count++
    
    ; 関連タイマーを停止
    StopManagedTimer("TinctureCooldown")
    StopManagedTimer("TinctureRetry")
    StopManagedTimer("TinctureTimeout")
    
    ; マナフラスコループのタイミングをリセット
    ResetFlaskTiming()
    
    ShowOverlay("Tincture使用成功！", 2000)
    g_status_update_needed := true
    
    ; 使用履歴に記録
    RecordTinctureUse("success", true)
    
    ; 成功率を計算
    successRate := Round(g_tincture_success_count / g_tincture_total_attempts * 100, 1)
    
    LogInfo("TinctureManager", Format("Tincture successfully activated (Success rate: {}%)", 
        successRate))
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
    CleanupTinctureTimers()
    
    ; 使用履歴に記録
    RecordTinctureUse("depletion", false)
    
    ; クールダウンチェック開始
    StartTinctureCooldownCheck()
    
    LogInfo("TinctureManager", Format("Tincture deactivated due to mana depletion. CD: {}ms", 
        TIMING_MANA_DEPLETED_CD))
}

; --- Tincture関連タイマーのクリーンアップ ---
CleanupTinctureTimers() {
    StopManagedTimer("TinctureRetry")
    StopManagedTimer("TinctureVerification")
    StopManagedTimer("TinctureTimeout")
}

; --- 再試行状態のクリーンアップ ---
CleanupRetryState() {
    global g_tincture_retry_count, g_tincture_verification_pending
    global g_tincture_retry_timer_active
    
    g_tincture_retry_count := 0
    g_tincture_verification_pending := false
    g_tincture_retry_timer_active := false
    
    CleanupTinctureTimers()
    
    LogDebug("TinctureManager", "Retry state cleaned up")
}

; --- Tincture使用履歴の記録 ---
RecordTinctureUse(type, success) {
    global g_tincture_history
    
    record := {
        timestamp: A_TickCount,
        type: type,
        success: success,
        manaFillRate: g_mana_fill_rate,
        retryCount: g_tincture_retry_count
    }
    
    g_tincture_history.Push(record)
    
    ; 履歴サイズを制限
    if (g_tincture_history.Length > 50) {
        g_tincture_history.RemoveAt(1)
    }
}

; --- Tincture状態の取得（拡張版） ---
GetTinctureStatus() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global g_tincture_verification_pending, g_tincture_retry_timer_active
    global g_tincture_success_count, g_tincture_total_attempts
    
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
    
    successRate := g_tincture_total_attempts > 0 ? 
        Round(g_tincture_success_count / g_tincture_total_attempts * 100, 1) : 100
    
    return {
        status: status,
        cooldownRemaining: Max(0, g_tincture_cooldown_end - A_TickCount),
        retryCount: g_tincture_retry_count,
        isActive: g_tincture_active,
        isPending: g_tincture_verification_pending || g_tincture_retry_timer_active,
        successRate: successRate,
        totalAttempts: g_tincture_total_attempts
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
    CleanupTinctureTimers()
    
    LogInfo("TinctureManager", "Tincture forcefully stopped")
}

; --- デバッグ情報の取得（拡張版） ---
GetTinctureDebugInfo() {
    global g_tincture_active, g_tincture_cooldown_end, g_tincture_retry_count
    global g_tincture_verification_pending, g_tincture_retry_timer_active
    global g_tincture_last_use_time, g_tincture_retry_max
    global g_tincture_success_count, g_tincture_failure_count, g_tincture_total_attempts
    global g_tincture_history
    
    debugInfo := []
    debugInfo.Push("=== Tincture Debug Info ===")
    debugInfo.Push(Format("Active: {}", g_tincture_active))
    debugInfo.Push(Format("Retry Count: {}/{}", g_tincture_retry_count, g_tincture_retry_max))
    debugInfo.Push(Format("Verification Pending: {}", g_tincture_verification_pending))
    debugInfo.Push(Format("Retry Timer Active: {}", g_tincture_retry_timer_active))
    
    ; 統計情報
    successRate := g_tincture_total_attempts > 0 ? 
        Round(g_tincture_success_count / g_tincture_total_attempts * 100, 1) : 0
    debugInfo.Push(Format("Success/Total: {}/{} ({}%)", 
        g_tincture_success_count, g_tincture_total_attempts, successRate))
    
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
    
    ; 最近の履歴
    if (g_tincture_history.Length > 0) {
        debugInfo.Push("")
        debugInfo.Push("Recent History:")
        for i, record in g_tincture_history {
            if (i > g_tincture_history.Length - 3) {  ; 最新3件
                debugInfo.Push(Format("  {} - {} (Mana: {}%)", 
                    record.type, 
                    record.success ? "Success" : "Failed",
                    record.manaFillRate))
            }
        }
    }
    
    return debugInfo
}

; --- Tincture統計のリセット ---
ResetTinctureStats() {
    global g_tincture_success_count, g_tincture_failure_count
    global g_tincture_total_attempts, g_tincture_history
    
    g_tincture_success_count := 0
    g_tincture_failure_count := 0
    g_tincture_total_attempts := 0
    g_tincture_history := []
    
    LogInfo("TinctureManager", "Tincture statistics reset")
}

; --- 検証方法の切り替え ---
SetTinctureVerificationMethod(method) {
    global g_tincture_verification_method
    
    if (method == "mana" || method == "buff") {
        g_tincture_verification_method := method
        LogInfo("TinctureManager", Format("Verification method set to: {}", method))
        return true
    }
    
    return false
}