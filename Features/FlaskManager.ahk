; ===================================================================
; フラスコ管理システム（完全修正版）
; マナフラスコの自動使用とタイミング管理（拡張対応）
; ===================================================================

; --- グローバル変数 ---
global g_flask_timer_handles := Map()
global g_flask_use_count := Map()
global g_flask_last_use_time := Map()
global g_flask_configs := Map()
global g_flask_automation_paused := false
global g_flask_active_flasks := Map()
global g_flask_charge_tracker := Map()
global g_flask_stats := {
    totalUses: 0,
    averageInterval: 0,
    lastResetTime: 0,
    errors: 0,
    successRate: 100
}

; --- フラスコ設定の初期化（拡張版） ---
InitializeFlaskConfigs() {
    global g_flask_configs, KEY_MANA_FLASK
    
    ; マナフラスコ（デフォルト）
    g_flask_configs["mana"] := {
        key: KEY_MANA_FLASK,
        type: "mana",
        minInterval: TIMING_FLASK.min,
        maxInterval: TIMING_FLASK.max,
        enabled: true,
        priority: 1,
        charges: 0,
        maxCharges: 0,
        chargePerUse: 0,
        chargeGainRate: 0
    }
    
    ; 他のフラスコ設定のテンプレート（将来の拡張用）
    g_flask_configs["life"] := {
        key: "1",
        type: "life",
        minInterval: 5000,
        maxInterval: 5500,
        enabled: false,
        priority: 2,
        charges: 0,
        maxCharges: 0,
        chargePerUse: 0,
        chargeGainRate: 0,
        useCondition: () => CheckHealthPercentage() < 70
    }
    
    g_flask_configs["quicksilver"] := {
        key: "5",
        type: "quicksilver",
        minInterval: 6000,
        maxInterval: 6500,
        enabled: false,
        priority: 3,
        charges: 0,
        maxCharges: 0,
        chargePerUse: 0,
        chargeGainRate: 0,
        useCondition: () => IsMoving()
    }
    
    ; チャージトラッカーを初期化
    InitializeChargeTracker()
    
    LogDebug("FlaskManager", "Flask configurations initialized with extended settings")
}

; --- チャージトラッカーの初期化 ---
InitializeChargeTracker() {
    global g_flask_charge_tracker
    
    for flaskName, config in g_flask_configs {
        g_flask_charge_tracker[flaskName] := {
            currentCharges: config.maxCharges,
            lastGainTime: A_TickCount,
            lastUseTime: 0
        }
    }
}

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
        
    } catch Error as e {
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
        
    } catch Error as e {
        g_flask_stats.errors++
        g_flask_stats.successRate := Round((1 - g_flask_stats.errors / g_flask_stats.totalUses) * 100, 2)
        LogError("FlaskManager", Format("Failed to use flask '{}': {}", flaskName, e.Message))
        return false
    }
}

; --- フラスコチャージの更新 ---
UpdateFlaskCharges() {
    global g_flask_charge_tracker, g_flask_configs, g_macro_active
    
    if (!g_macro_active) {
        return
    }
    
    currentTime := A_TickCount
    
    for flaskName, config in g_flask_configs {
        if (config.chargeGainRate > 0 && config.maxCharges > 0) {
            chargeInfo := g_flask_charge_tracker[flaskName]
            
            ; 最後の獲得からの経過時間
            timeSinceGain := currentTime - chargeInfo.lastGainTime
            
            ; チャージ獲得計算
            chargesGained := (timeSinceGain / 1000) * config.chargeGainRate
            
            if (chargesGained >= 1) {
                chargeInfo.currentCharges := Min(
                    chargeInfo.currentCharges + Floor(chargesGained),
                    config.maxCharges
                )
                chargeInfo.lastGainTime := currentTime
                
                LogDebug("FlaskManager", Format("Flask '{}' gained {} charges ({}/{})", 
                    flaskName, Floor(chargesGained), 
                    chargeInfo.currentCharges, config.maxCharges))
            }
        }
    }
}

; --- 特定フラスコのタイマー停止 ---
StopFlaskTimer(flaskName) {
    global g_flask_timer_handles, g_flask_active_flasks
    
    if (g_flask_timer_handles.Has(flaskName)) {
        timerName := g_flask_timer_handles[flaskName]
        StopManagedTimer(timerName)
        g_flask_timer_handles.Delete(flaskName)
        g_flask_active_flasks.Delete(flaskName)
        
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
        
        ; 次の使用をスケジュール
        delay := Random(config.minInterval, config.maxInterval)
        StartManagedTimer("ManaFlask", UseManaFlask, -delay)
    }
}

; --- フラスコタイミングのリセット（改善版） ---
ResetFlaskTiming() {
    global g_flask_timer_active, g_flask_configs, g_flask_automation_paused
    global g_flask_timer_handles, g_flask_active_flasks
    
    LogInfo("FlaskManager", "Resetting flask timing")
    
    ; 一時的に自動化を停止
    g_flask_automation_paused := true
    
    ; 全てのタイマーを停止
    for flaskName, timerName in g_flask_timer_handles {
        StopManagedTimer(timerName)
    }
    g_flask_timer_handles.Clear()
    g_flask_active_flasks.Clear()
    
    Sleep(100)  ; 安定性のための待機
    
    ; 自動化を再開
    g_flask_automation_paused := false
    
    if (g_flask_timer_active) {
        ; 各フラスコを即座に使用して再開
        for flaskName, config in g_flask_configs {
            if (config.enabled) {
                if (StartFlaskTimer(flaskName, config)) {
                    g_flask_active_flasks[flaskName] := true
                }
            }
        }
    }
    
    LogInfo("FlaskManager", "Flask timing reset completed")
}

; --- フラスコ自動化の停止 ---
StopFlaskAutomation() {
    global g_flask_timer_active, g_flask_timer_handles
    
    g_flask_timer_active := false
    
    ; チャージ回復タイマーを停止
    StopManagedTimer("FlaskChargeRecovery")
    
    ; 全てのフラスコタイマーを停止
    for flaskName, timerName in g_flask_timer_handles {
        StopManagedTimer(timerName)
    }
    g_flask_timer_handles.Clear()
    g_flask_active_flasks.Clear()
    
    ; 互換性のためのタイマーも停止
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
    global g_flask_stats, g_flask_last_use_time, g_flask_use_count
    
    if (flaskName != "" && g_flask_use_count.Has(flaskName) && g_flask_use_count[flaskName] > 1) {
        ; 特定フラスコの統計更新
        ; 将来的に詳細な統計を実装
    }
    
    ; 全体の平均間隔を更新
    totalTime := A_TickCount - g_flask_stats.lastResetTime
    if (g_flask_stats.totalUses > 1 && totalTime > 0) {
        g_flask_stats.averageInterval := Round(totalTime / (g_flask_stats.totalUses - 1))
    }
}

; --- フラスコ統計の取得（拡張版） ---
GetFlaskStats() {
    global g_flask_stats, g_flask_use_count, g_flask_last_use_time
    global g_flask_charge_tracker, g_flask_active_flasks
    
    stats := {
        totalUses: g_flask_stats.totalUses,
        averageInterval: g_flask_stats.averageInterval,
        errors: g_flask_stats.errors,
        errorRate: g_flask_stats.totalUses > 0 ? 
            Round(g_flask_stats.errors / g_flask_stats.totalUses * 100, 2) : 0,
        successRate: g_flask_stats.successRate,
        activeFlasks: g_flask_active_flasks.Count,
        flasks: Map()
    }
    
    ; 個別フラスコの統計
    for flaskName, count in g_flask_use_count {
        lastUse := g_flask_last_use_time.Has(flaskName) ? 
            Round((A_TickCount - g_flask_last_use_time[flaskName]) / 1000, 1) : 0
        
        chargeInfo := g_flask_charge_tracker.Has(flaskName) ? 
            g_flask_charge_tracker[flaskName] : {currentCharges: 0}
            
        stats.flasks[flaskName] := {
            uses: count,
            lastUseAgo: lastUse,
            charges: chargeInfo.currentCharges,
            active: g_flask_active_flasks.Has(flaskName)
        }
    }
    
    return stats
}

; --- カスタムフラスコ設定（完全実装版） ---
ConfigureFlasks(flaskConfig) {
    global g_flask_configs, g_flask_charge_tracker
    
    /*
    使用例：
    flaskConfig := Map(
        "1", {
            key: "1", 
            type: "life", 
            minInterval: 5000, 
            maxInterval: 5500, 
            enabled: true,
            priority: 1,
            maxCharges: 60,
            chargePerUse: 20,
            chargeGainRate: 6,
            useCondition: () => GetHealthPercentage() < 70
        },
        "2", {
            key: "2", 
            type: "mana", 
            minInterval: 4500, 
            maxInterval: 4800, 
            enabled: true,
            priority: 2
        },
        "3", {
            key: "3", 
            type: "utility", 
            minInterval: 5000, 
            maxInterval: 5000, 
            enabled: true,
            priority: 3
        },
        "4", {
            key: "4", 
            type: "utility", 
            minInterval: 8000, 
            maxInterval: 8000, 
            enabled: true,
            priority: 4
        },
        "5", {
            key: "5", 
            type: "quicksilver", 
            minInterval: 6000, 
            maxInterval: 6500, 
            enabled: true,
            priority: 5,
            useCondition: () => IsMoving()
        }
    )
    */
    
    try {
        ; 既存の自動化を停止
        wasActive := g_flask_timer_active
        if (wasActive) {
            StopFlaskAutomation()
        }
        
        ; 設定をクリア
        g_flask_configs.Clear()
        g_flask_charge_tracker.Clear()
        
        ; 新しい設定を適用
        for name, config in flaskConfig {
            ; デフォルト値を設定
            if (!config.HasOwnProp("priority")) {
                config.priority := 5
            }
            if (!config.HasOwnProp("maxCharges")) {
                config.maxCharges := 0
            }
            if (!config.HasOwnProp("chargePerUse")) {
                config.chargePerUse := 0
            }
            if (!config.HasOwnProp("chargeGainRate")) {
                config.chargeGainRate := 0
            }
            
            g_flask_configs[name] := config
            
            ; チャージトラッカーを初期化
            g_flask_charge_tracker[name] := {
                currentCharges: config.maxCharges,
                lastGainTime: A_TickCount,
                lastUseTime: 0
            }
        }
        
        ; 自動化を再開
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
    global g_flask_configs, g_flask_active_flasks
    
    if (!g_flask_configs.Has(flaskName)) {
        return false
    }
    
    if (enabled == "") {
        enabled := !g_flask_configs[flaskName].enabled
    }
    
    g_flask_configs[flaskName].enabled := enabled
    
    if (enabled) {
        if (g_flask_timer_active && !g_flask_active_flasks.Has(flaskName)) {
            StartFlaskTimer(flaskName, g_flask_configs[flaskName])
        }
    } else {
        StopFlaskTimer(flaskName)
    }
    
    LogInfo("FlaskManager", Format("Flask '{}' {}", flaskName, enabled ? "enabled" : "disabled"))
    return true
}

; --- デバッグ情報の取得（拡張版） ---
GetFlaskDebugInfo() {
    global g_flask_configs, g_flask_timer_handles, g_flask_charge_tracker
    global g_flask_automation_paused, g_flask_active_flasks
    
    debugInfo := []
    debugInfo.Push("=== Flask Manager Debug ===")
    debugInfo.Push(Format("Active: {} | Paused: {} | Flasks: {}", 
        g_flask_timer_active ? "Yes" : "No",
        g_flask_automation_paused ? "Yes" : "No",
        g_flask_active_flasks.Count))
    debugInfo.Push("")
    
    for flaskName, config in g_flask_configs {
        status := config.enabled ? "ON" : "OFF"
        if (g_flask_timer_handles.Has(flaskName)) {
            status .= " (Active)"
        }
        
        uses := g_flask_use_count.Has(flaskName) ? g_flask_use_count[flaskName] : 0
        
        chargeText := ""
        if (config.maxCharges > 0) {
            chargeInfo := g_flask_charge_tracker[flaskName]
            chargeText := Format(" Charges:{}/{}", 
                Round(chargeInfo.currentCharges), config.maxCharges)
        }
        
        debugInfo.Push(Format("{}: {} - Key:{} Uses:{} Interval:{}-{}ms{}", 
            flaskName, status, config.key, uses, 
            config.minInterval, config.maxInterval, chargeText))
    }
    
    ; 統計情報
    stats := GetFlaskStats()
    debugInfo.Push("")
    debugInfo.Push(Format("Total Uses: {} | Errors: {} | Success Rate: {}%", 
        stats.totalUses, stats.errors, stats.successRate))
    
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

; --- ヘルパー関数（条件チェック用） ---
GetHealthPercentage() {
    ; TODO: 実際のヘルス％を取得する実装
    return 100
}

IsMoving() {
    ; TODO: 移動中かどうかを判定する実装
    return false
}

CheckHealthPercentage() {
    return GetHealthPercentage()
}