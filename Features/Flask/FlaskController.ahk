; ===================================================================
; フラスココントローラー - メイン制御・タイマー管理
; フラスコ自動化の中央制御とタイマー管理を担当
; ===================================================================

; --- グローバル変数 ---
global g_flask_timer_handles := Map()
global g_flask_automation_paused := false
global g_flask_active_flasks := Map()

; --- フラスコ自動化の開始（改善版） ---
StartFlaskAutomation() {
    global g_flask_timer_active, g_flask_automation_paused
    global g_flask_stats, g_flask_active_flasks
    
    ; 設定を初期化
    InitializeFlaskConfigs()
    
    ; 一時停止を解除
    g_flask_automation_paused := false
    
    ; 統計をリセット
    g_flask_stats.lastResetTime := A_TickCount
    g_flask_stats.totalUses := 0
    g_flask_stats.errors := 0
    
    ; アクティブなフラスコをクリア
    g_flask_active_flasks.Clear()
    
    ; 各フラスコの自動化を開始
    for flaskName, config in g_flask_configs {
        if (config.enabled) {
            if (StartFlaskTimer(flaskName, config)) {
                g_flask_active_flasks[flaskName] := true
            }
        }
    }
    
    g_flask_timer_active := true
    
    ; チャージ回復タイマーを開始
    StartManagedTimer("FlaskChargeRecovery", UpdateFlaskCharges, 100)
    
    LogInfo("FlaskManager", Format("Flask automation started with {} active flasks", 
        g_flask_active_flasks.Count))
}

; --- 個別フラスコタイマーの開始（改善版） ---
StartFlaskTimer(flaskName, config) {
    global g_flask_timer_handles, g_flask_use_count, g_flask_last_use_time
    
    try {
        ; 統計を初期化
        if (!g_flask_use_count.Has(flaskName)) {
            g_flask_use_count[flaskName] := 0
        }
        if (!g_flask_last_use_time.Has(flaskName)) {
            g_flask_last_use_time[flaskName] := 0
        }
        
        ; 使用条件をチェック
        if (config.HasOwnProp("useCondition") && !config.useCondition()) {
            LogDebug("FlaskManager", Format("Flask '{}' condition not met, delaying start", flaskName))
            ; 条件が満たされない場合は1秒後に再チェック
            SetTimer(() => RetryFlaskStart(flaskName, config), -1000)
            return false
        }
        
        ; 即座に使用
        if (UseFlask(flaskName, config)) {
            ; 次の使用をスケジュール
            delay := Random(config.minInterval, config.maxInterval)
            timerName := "Flask_" . flaskName
            
            StartManagedTimer(timerName, () => FlaskTimerCallback(flaskName), -delay)
            g_flask_timer_handles[flaskName] := timerName
            
            LogDebug("FlaskManager", Format("Flask '{}' timer started ({}ms)", flaskName, delay))
            return true
        }
        
        return false
        
    } catch as e {
        LogError("FlaskManager", Format("Failed to start flask '{}': {}", flaskName, e.Message))
        return false
    }
}

; --- フラスコ開始の再試行 ---
RetryFlaskStart(flaskName, config) {
    global g_macro_active, g_flask_active_flasks
    
    if (!g_macro_active || g_flask_automation_paused) {
        return
    }
    
    if (StartFlaskTimer(flaskName, config)) {
        g_flask_active_flasks[flaskName] := true
    } else {
        ; さらに再試行
        SetTimer(() => RetryFlaskStart(flaskName, config), -1000)
    }
}

; --- フラスコタイマーコールバック（改善版） ---
FlaskTimerCallback(flaskName) {
    global g_macro_active, g_flask_timer_active, g_flask_automation_paused
    global g_flask_configs, g_flask_timer_handles
    
    ; マクロが非アクティブまたは一時停止中の場合
    if (!g_macro_active || !g_flask_timer_active || g_flask_automation_paused) {
        StopFlaskTimer(flaskName)
        return
    }
    
    config := g_flask_configs[flaskName]
    if (!config || !config.enabled) {
        StopFlaskTimer(flaskName)
        return
    }
    
    ; 使用条件をチェック
    if (config.HasOwnProp("useCondition") && !config.useCondition()) {
        LogDebug("FlaskManager", Format("Flask '{}' condition not met, skipping", flaskName))
        ; 短い間隔で再チェック
        delay := 500
    } else {
        ; フラスコを使用
        if (UseFlask(flaskName, config)) {
            delay := Random(config.minInterval, config.maxInterval)
        } else {
            ; 使用失敗時は長めの間隔
            delay := config.maxInterval * 1.5
        }
    }
    
    ; 次の使用をスケジュール
    timerName := g_flask_timer_handles[flaskName]
    StartManagedTimer(timerName, () => FlaskTimerCallback(flaskName), -delay)
    
    LogDebug("FlaskManager", Format("Flask '{}' scheduled next use in {}ms", flaskName, delay))
}

; --- フラスコ使用（完全改善版） ---
UseFlask(flaskName, config) {
    global g_flask_use_count, g_flask_last_use_time, g_flask_stats
    global g_flask_charge_tracker
    
    try {
        ; 最小間隔のチェック（誤動作防止）
        if (g_flask_last_use_time.Has(flaskName)) {
            timeSinceLastUse := A_TickCount - g_flask_last_use_time[flaskName]
            if (timeSinceLastUse < config.minInterval * 0.8) {
                LogWarn("FlaskManager", Format("Flask '{}' use too soon ({}ms), skipping", 
                    flaskName, timeSinceLastUse))
                return false
            }
        }
        
        ; 視覚的検出の実行（Visual/Hybridモード）
        detectionMode := GetDetectionMode()
        if (detectionMode != "Timer") {
            ; フラスコ番号を取得（flask1, flask2等からの数字部分）
            flaskNumber := RegExReplace(flaskName, "^flask", "")
            if (IsNumber(flaskNumber) && flaskNumber >= 1 && flaskNumber <= 5) {
                chargeStatus := DetectFlaskCharge(flaskNumber)
                if (chargeStatus == 0) {
                    LogDebug("FlaskManager", Format("Flask '{}' visual detection: NO CHARGES", flaskName))
                    return false
                } else if (chargeStatus == -1) {
                    LogDebug("FlaskManager", Format("Flask '{}' visual detection failed, falling back to timer mode", flaskName))
                } else if (chargeStatus == 1) {
                    LogDebug("FlaskManager", Format("Flask '{}' visual detection: HAS CHARGES", flaskName))
                }
            }
        }
        
        ; チャージチェック（実装されている場合）
        if (config.maxCharges > 0 && config.chargePerUse > 0) {
            chargeInfo := g_flask_charge_tracker[flaskName]
            if (chargeInfo.currentCharges < config.chargePerUse) {
                LogDebug("FlaskManager", Format("Flask '{}' insufficient charges ({}/{})", 
                    flaskName, chargeInfo.currentCharges, config.chargePerUse))
                return false
            }
        }
        
        ; パフォーマンス計測開始
        StartPerfTimer("Flask_" . flaskName)
        
        ; キー送信前の短い待機（安定性向上）
        Sleep(10)
        
        ; キー送信
        Send(config.key)
        
        ; 統計を更新
        g_flask_use_count[flaskName]++
        g_flask_last_use_time[flaskName] := A_TickCount
        g_flask_stats.totalUses++
        
        ; チャージを消費
        if (config.maxCharges > 0 && config.chargePerUse > 0) {
            chargeInfo := g_flask_charge_tracker[flaskName]
            chargeInfo.currentCharges -= config.chargePerUse
            chargeInfo.lastUseTime := A_TickCount
        }
        
        ; 平均間隔を更新
        UpdateFlaskStats(flaskName)
        
        ; パフォーマンス計測終了
        duration := EndPerfTimer("Flask_" . flaskName, "FlaskManager")
        
        LogDebug("FlaskManager", Format("Flask '{}' used (key: {}, count: {}, duration: {}ms)", 
            flaskName, config.key, g_flask_use_count[flaskName], duration))
        
        return true
        
    } catch as e {
        g_flask_stats.errors++
        LogError("FlaskManager", Format("Failed to use flask '{}': {}", flaskName, e.Message))
        return false
    }
}

; --- 個別フラスコタイマーの停止 ---
StopFlaskTimer(flaskName) {
    global g_flask_timer_handles, g_flask_active_flasks
    
    try {
        if (g_flask_timer_handles.Has(flaskName)) {
            timerName := g_flask_timer_handles[flaskName]
            StopManagedTimer(timerName)
            g_flask_timer_handles.Delete(flaskName)
        }
        
        if (g_flask_active_flasks.Has(flaskName)) {
            g_flask_active_flasks.Delete(flaskName)
        }
        
        LogDebug("FlaskManager", Format("Flask '{}' timer stopped", flaskName))
        
    } catch as e {
        LogError("FlaskManager", Format("Failed to stop flask '{}' timer: {}", flaskName, e.Message))
    }
}

; --- レガシー対応: マナフラスコ使用 ---
UseManaFlask() {
    global g_flask_configs
    
    if (g_flask_configs.Has("mana")) {
        config := g_flask_configs["mana"]
        return UseFlask("mana", config)
    }
    return false
}

; --- フラスコタイミングリセット ---
ResetFlaskTiming() {
    global g_flask_configs, g_flask_active_flasks
    
    try {
        ; 全てのタイマーを停止
        for flaskName in g_flask_active_flasks {
            StopFlaskTimer(flaskName)
        }
        
        Sleep(100)
        
        ; 有効なフラスコを再開
        for flaskName, config in g_flask_configs {
            if (config.enabled) {
                if (StartFlaskTimer(flaskName, config)) {
                    g_flask_active_flasks[flaskName] := true
                }
            }
        }
        
        LogInfo("FlaskManager", "Flask timing reset completed")
        
    } catch as e {
        LogError("FlaskManager", "Failed to reset flask timing: " . e.Message)
    }
}

; --- フラスコ自動化の停止 ---
StopFlaskAutomation() {
    global g_flask_timer_active, g_flask_active_flasks, g_flask_timer_handles
    
    try {
        g_flask_timer_active := false
        
        ; 全てのフラスコタイマーを停止
        for flaskName in g_flask_active_flasks {
            StopFlaskTimer(flaskName)
        }
        
        ; チャージ回復タイマーを停止
        StopManagedTimer("FlaskChargeRecovery")
        
        ; コレクションをクリア
        g_flask_active_flasks.Clear()
        g_flask_timer_handles.Clear()
        
        LogInfo("FlaskManager", "Flask automation stopped")
        
    } catch as e {
        LogError("FlaskManager", "Failed to stop flask automation: " . e.Message)
    }
}

; --- フラスコ自動化の一時停止 ---
PauseFlaskAutomation() {
    global g_flask_automation_paused
    
    g_flask_automation_paused := true
    LogInfo("FlaskManager", "Flask automation paused")
}

; --- フラスコ自動化の再開 ---
ResumeFlaskAutomation() {
    global g_flask_automation_paused
    
    g_flask_automation_paused := false
    LogInfo("FlaskManager", "Flask automation resumed")
}

; --- 手動フラスコ使用 ---
ManualUseFlask(flaskName) {
    global g_flask_configs
    
    if (!g_flask_configs.Has(flaskName)) {
        LogWarn("FlaskManager", Format("Unknown flask: {}", flaskName))
        return false
    }
    
    config := g_flask_configs[flaskName]
    if (UseFlask(flaskName, config)) {
        LogInfo("FlaskManager", Format("Manually used flask: {}", flaskName))
        return true
    }
    
    return false
}