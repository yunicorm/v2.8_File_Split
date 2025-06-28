; ===================================================================
; フラスコ管理システム（修正版）
; マナフラスコの自動使用とタイミング管理
; ===================================================================

; --- グローバル変数 ---
global g_flask_timer_handles := Map()
global g_flask_use_count := Map()
global g_flask_last_use_time := Map()
global g_flask_configs := Map()
global g_flask_automation_paused := false
global g_flask_stats := {
    totalUses: 0,
    averageInterval: 0,
    lastResetTime: 0,
    errors: 0
}

; --- フラスコ設定の初期化 ---
InitializeFlaskConfigs() {
    global g_flask_configs, KEY_MANA_FLASK
    
    ; デフォルト設定（将来の拡張用）
    g_flask_configs["mana"] := {
        key: KEY_MANA_FLASK,
        type: "mana",
        minInterval: TIMING_FLASK.min,
        maxInterval: TIMING_FLASK.max,
        enabled: true,
        priority: 1,
        charges: 0,  // 将来の実装用
        maxCharges: 0
    }
    
    // 他のフラスコ設定（将来の拡張用）
    /*
    g_flask_configs["life"] := {
        key: "1",
        type: "life",
        minInterval: 5000,
        maxInterval: 5500,
        enabled: false,
        priority: 2
    }
    */
    
    LogDebug("FlaskManager", "Flask configurations initialized")
}

; --- フラスコ自動化の開始（改善版） ---
StartFlaskAutomation() {
    global g_flask_timer_active, g_flask_automation_paused
    global g_flask_stats
    
    // 設定を初期化
    InitializeFlaskConfigs()
    
    // 一時停止を解除
    g_flask_automation_paused := false
    
    // 統計をリセット
    g_flask_stats.lastResetTime := A_TickCount
    
    // 各フラスコの自動化を開始
    for flaskName, config in g_flask_configs {
        if (config.enabled) {
            StartFlaskTimer(flaskName, config)
        }
    }
    
    g_flask_timer_active := true
    
    LogInfo("FlaskManager", "Flask automation started")
}

; --- 個別フラスコタイマーの開始 ---
StartFlaskTimer(flaskName, config) {
    global g_flask_timer_handles, g_flask_use_count, g_flask_last_use_time
    
    // 統計を初期化
    if (!g_flask_use_count.Has(flaskName)) {
        g_flask_use_count[flaskName] := 0
    }
    
    // 即座に使用
    UseFlask(flaskName, config)
    
    // タイマーを開始
    delay := Random(config.minInterval, config.maxInterval)
    timerName := "Flask_" . flaskName
    
    StartManagedTimer(timerName, () => FlaskTimerCallback(flaskName), delay)
    g_flask_timer_handles[flaskName] := timerName
    
    LogDebug("FlaskManager", Format("Flask '{}' timer started ({}ms)", flaskName, delay))
}

; --- フラスコタイマーコールバック ---
FlaskTimerCallback(flaskName) {
    global g_macro_active, g_flask_timer_active, g_flask_automation_paused
    global g_flask_configs
    
    // マクロが非アクティブまたは一時停止中の場合
    if (!g_macro_active || !g_flask_timer_active || g_flask_automation_paused) {
        StopFlaskTimer(flaskName)
        return
    }
    
    config := g_flask_configs[flaskName]
    if (!config || !config.enabled) {
        return
    }
    
    // フラスコを使用
    UseFlask(flaskName, config)
    
    // 次の使用をスケジュール
    delay := Random(config.minInterval, config.maxInterval)
    timerName := g_flask_timer_handles[flaskName]
    
    StartManagedTimer(timerName, () => FlaskTimerCallback(flaskName), delay)
    
    LogDebug("FlaskManager", Format("Flask '{}' scheduled next use in {}ms", flaskName, delay))
}

; --- フラスコ使用（改善版） ---
UseFlask(flaskName, config) {
    global g_flask_use_count, g_flask_last_use_time, g_flask_stats
    
    try {
        // 最小間隔のチェック（誤動作防止）
        if (g_flask_last_use_time.Has(flaskName)) {
            timeSinceLastUse := A_TickCount - g_flask_last_use_time[flaskName]
            if (timeSinceLastUse < config.minInterval * 0.8) {  // 80%の余裕
                LogWarn("FlaskManager", Format("Flask '{}' use too soon ({}ms), skipping", 
                    flaskName, timeSinceLastUse))
                return false
            }
        }
        
        // パフォーマンス計測開始
        StartPerfTimer("Flask_" . flaskName)
        
        // キー送信
        Send(config.key)
        
        // 統計を更新
        g_flask_use_count[flaskName]++
        g_flask_last_use_time[flaskName] := A_TickCount
        g_flask_stats.totalUses++
        
        // 平均間隔を更新
        UpdateFlaskStats(flaskName)
        
        // パフォーマンス計測終了
        duration := EndPerfTimer("Flask_" . flaskName, "FlaskManager")
        
        LogDebug("FlaskManager", Format("Flask '{}' used (key: {}, count: {}, duration: {}ms)", 
            flaskName, config.key, g_flask_use_count[flaskName], duration))
        
        return true
        
    } catch Error as e {
        g_flask_stats.errors++
        LogError("FlaskManager", Format("Failed to use flask '{}': {}", flaskName, e.Message))
        return false
    }
}

; --- 特定フラスコのタイマー停止 ---
StopFlaskTimer(flaskName) {
    global g_flask_timer_handles
    
    if (g_flask_timer_handles.Has(flaskName)) {
        timerName := g_flask_timer_handles[flaskName]
        StopManagedTimer(timerName)
        g_flask_timer_handles.Delete(flaskName)
        
        LogDebug("FlaskManager", Format("Flask '{}' timer stopped", flaskName))
    }
}

; --- マナフラスコ使用（互換性のため維持） ---
UseManaFlask() {
    global g_macro_active, g_flask_timer_active, g_flask_configs
    
    if (!g_macro_active || !g_flask_timer_active) {
        StopFlaskTimer("mana")
        return
    }
    
    if (g_flask_configs.Has("mana")) {
        config := g_flask_configs["mana"]
        UseFlask("mana", config)
        
        // 次の使用をスケジュール
        delay := Random(config.minInterval, config.maxInterval)
        StartManagedTimer("ManaFlask", UseManaFlask, delay)
    }
}

; --- フラスコタイミングのリセット（改善版） ---
ResetFlaskTiming() {
    global g_flask_timer_active, g_flask_configs, g_flask_automation_paused
    
    LogInfo("FlaskManager", "Resetting flask timing")
    
    // 一時的に自動化を停止
    g_flask_automation_paused := true
    
    // 全てのタイマーを停止
    for flaskName, timerName in g_flask_timer_handles {
        StopManagedTimer(timerName)
    }
    g_flask_timer_handles.Clear()
    
    Sleep(100)  // 安定性のための待機
    
    // 自動化を再開
    g_flask_automation_paused := false
    
    if (g_flask_timer_active) {
        // 各フラスコを即座に使用して再開
        for flaskName, config in g_flask_configs {
            if (config.enabled) {
                StartFlaskTimer(flaskName, config)
            }
        }
    }
    
    LogInfo("FlaskManager", "Flask timing reset completed")
}

; --- フラスコ自動化の停止 ---
StopFlaskAutomation() {
    global g_flask_timer_active, g_flask_timer_handles
    
    g_flask_timer_active := false
    
    // 全てのフラスコタイマーを停止
    for flaskName, timerName in g_flask_timer_handles {
        StopManagedTimer(timerName)
    }
    g_flask_timer_handles.Clear()
    
    // 互換性のためのタイマーも停止
    StopManagedTimer("ManaFlask")
    
    LogInfo("FlaskManager", "Flask automation stopped")
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

; --- フラスコ統計の更新 ---
UpdateFlaskStats(flaskName := "") {
    global g_flask_stats, g_flask_last_use_time
    
    if (flaskName != "" && g_flask_use_count.Has(flaskName) && g_flask_use_count[flaskName] > 1) {
        // 特定フラスコの統計
        intervals := []
        
        // 使用履歴から間隔を計算（簡易版）
        if (g_flask_last_use_time.Has(flaskName)) {
            // 現在は最後の使用時間のみ記録
            // 将来的には履歴配列を保持
        }
    }
    
    // 全体の平均間隔を更新
    totalTime := A_TickCount - g_flask_stats.lastResetTime
    if (g_flask_stats.totalUses > 1 && totalTime > 0) {
        g_flask_stats.averageInterval := Round(totalTime / (g_flask_stats.totalUses - 1))
    }
}

; --- フラスコ統計の取得 ---
GetFlaskStats() {
    global g_flask_stats, g_flask_use_count, g_flask_last_use_time
    
    stats := {
        totalUses: g_flask_stats.totalUses,
        averageInterval: g_flask_stats.averageInterval,
        errors: g_flask_stats.errors,
        errorRate: g_flask_stats.totalUses > 0 ? 
            Round(g_flask_stats.errors / g_flask_stats.totalUses * 100, 2) : 0,
        flasks: Map()
    }
    
    // 個別フラスコの統計
    for flaskName, count in g_flask_use_count {
        lastUse := g_flask_last_use_time.Has(flaskName) ? 
            Round((A_TickCount - g_flask_last_use_time[flaskName]) / 1000, 1) : 0
            
        stats.flasks[flaskName] := {
            uses: count,
            lastUseAgo: lastUse
        }
    }
    
    return stats
}

; --- カスタムフラスコ設定（実装版） ---
ConfigureFlasks(flaskConfig) {
    global g_flask_configs
    
    /*
    使用例：
    flaskConfig := Map(
        "1", {key: "1", type: "life", minInterval: 5000, maxInterval: 5500, enabled: true},
        "2", {key: "2", type: "mana", minInterval: 4500, maxInterval: 4800, enabled: true},
        "3", {key: "3", type: "utility", minInterval: 5000, maxInterval: 5000, enabled: true},
        "4", {key: "4", type: "utility", minInterval: 8000, maxInterval: 8000, enabled: true},
        "5", {key: "5", type: "quicksilver", minInterval: 6000, maxInterval: 6500, enabled: true}
    )
    */
    
    try {
        // 既存の自動化を停止
        wasActive := g_flask_timer_active
        if (wasActive) {
            StopFlaskAutomation()
        }
        
        // 新しい設定を適用
        for name, config in flaskConfig {
            if (!config.HasOwnProp("priority")) {
                config.priority := 5  // デフォルト優先度
            }
            g_flask_configs[name] := config
        }
        
        // 自動化を再開
        if (wasActive) {
            StartFlaskAutomation()
        }
        
        LogInfo("FlaskManager", Format("Flask configuration updated ({} flasks)", flaskConfig.Count))
        return true
        
    } catch Error as e {
        LogError("FlaskManager", "Failed to configure flasks: " . e.Message)
        return false
    }
}

; --- 特定フラスコの有効/無効切り替え ---
ToggleFlask(flaskName, enabled := "") {
    global g_flask_configs
    
    if (!g_flask_configs.Has(flaskName)) {
        return false
    }
    
    if (enabled == "") {
        enabled := !g_flask_configs[flaskName].enabled
    }
    
    g_flask_configs[flaskName].enabled := enabled
    
    if (enabled) {
        StartFlaskTimer(flaskName, g_flask_configs[flaskName])
    } else {
        StopFlaskTimer(flaskName)
    }
    
    LogInfo("FlaskManager", Format("Flask '{}' {}", flaskName, enabled ? "enabled" : "disabled"))
    return true
}

; --- デバッグ情報の取得 ---
GetFlaskDebugInfo() {
    global g_flask_configs, g_flask_timer_handles
    
    debugInfo := []
    debugInfo.Push("=== Flask Manager Debug ===")
    debugInfo.Push(Format("Active: {} | Paused: {}", 
        g_flask_timer_active ? "Yes" : "No",
        g_flask_automation_paused ? "Yes" : "No"))
    debugInfo.Push("")
    
    for flaskName, config in g_flask_configs {
        status := config.enabled ? "ON" : "OFF"
        if (g_flask_timer_handles.Has(flaskName)) {
            status .= " (Active)"
        }
        
        uses := g_flask_use_count.Has(flaskName) ? g_flask_use_count[flaskName] : 0
        debugInfo.Push(Format("{}: {} - Key:{} Uses:{} Interval:{}-{}ms", 
            flaskName, status, config.key, uses, config.minInterval, config.maxInterval))
    }
    
    return debugInfo
}

; --- フラスコ使用の手動トリガー ---
ManualUseFlask(flaskName) {
    global g_flask_configs
    
    if (g_flask_configs.Has(flaskName)) {
        return UseFlask(flaskName, g_flask_configs[flaskName])
    }
    
    return false
}