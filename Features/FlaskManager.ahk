; ===================================================================
; フラスコ管理システム
; マナフラスコの自動使用とタイミング管理
; ===================================================================

; --- フラスコ自動化の開始 ---
StartFlaskAutomation() {
    global g_flask_timer_active, KEY_MANA_FLASK
    
    ; 即座にマナフラスコを使用
    Send(KEY_MANA_FLASK)
    
    ; フラスコループを開始
    g_flask_timer_active := true
    StartManagedTimer("ManaFlask", UseManaFlask, Random(TIMING_FLASK.min, TIMING_FLASK.max))
    
    LogInfo("FlaskManager", "Flask automation started")
}

; --- マナフラスコ使用 ---
UseManaFlask() {
    global g_macro_active, g_mana_flask_key, g_flask_timer_active
    
    if (!g_macro_active) {
        g_flask_timer_active := false
        StopManagedTimer("ManaFlask")
        return
    }
    
    // フラスコ使用前に再度フラグチェック
    if (!g_flask_timer_active) {
        StopManagedTimer("ManaFlask")
        return
    }
    
    StartPerfTimer("FlaskUse")
    Send(g_mana_flask_key)
    flaskDuration := EndPerfTimer("FlaskUse", "FlaskManager")
    
    // 次のフラスコ使用をスケジュール
    nextDelay := Random(TIMING_FLASK.min, TIMING_FLASK.max)
    StartManagedTimer("ManaFlask", UseManaFlask, nextDelay)
    
    LogDebug("FlaskManager", Format("Mana flask used. Next in {}ms", nextDelay))
}

; --- フラスコタイミングのリセット ---
ResetFlaskTiming() {
    global g_flask_timer_active, g_mana_flask_key
    
    // 一旦停止
    StopManagedTimer("ManaFlask")
    g_flask_timer_active := false
    
    Sleep(100)
    
    // 即座に使用
    Send(g_mana_flask_key)
    
    // 新しいタイミングで再開
    g_flask_timer_active := true
    StartManagedTimer("ManaFlask", UseManaFlask, Random(TIMING_FLASK.min, TIMING_FLASK.max))
    
    LogInfo("FlaskManager", "Flask timing reset")
}

; --- フラスコ自動化の停止 ---
StopFlaskAutomation() {
    global g_flask_timer_active
    
    g_flask_timer_active := false
    StopManagedTimer("ManaFlask")
    
    LogInfo("FlaskManager", "Flask automation stopped")
}

; --- カスタムフラスコ設定（将来の拡張用） ---
ConfigureFlasks(flaskConfig) {
    ; 例：
    ; flaskConfig := {
    ;     1: {key: "1", type: "life", threshold: 50},
    ;     2: {key: "2", type: "mana", threshold: 30},
    ;     3: {key: "3", type: "utility", cooldown: 5000},
    ;     4: {key: "4", type: "utility", cooldown: 8000},
    ;     5: {key: "5", type: "quicksilver", cooldown: 6000}
    ; }
    
    ; TODO: 実装予定
    LogInfo("FlaskManager", "Custom flask configuration not yet implemented")
}

; --- フラスコ使用統計（デバッグ用） ---
global g_flask_stats := {
    totalUses: 0,
    lastUseTime: 0,
    averageInterval: 0
}

UpdateFlaskStats() {
    global g_flask_stats
    
    currentTime := A_TickCount
    
    if (g_flask_stats.lastUseTime > 0) {
        interval := currentTime - g_flask_stats.lastUseTime
        
        ; 移動平均の計算
        if (g_flask_stats.averageInterval == 0) {
            g_flask_stats.averageInterval := interval
        } else {
            g_flask_stats.averageInterval := Round((g_flask_stats.averageInterval * 0.9) + (interval * 0.1))
        }
    }
    
    g_flask_stats.totalUses++
    g_flask_stats.lastUseTime := currentTime
}

GetFlaskStats() {
    global g_flask_stats
    return g_flask_stats
}