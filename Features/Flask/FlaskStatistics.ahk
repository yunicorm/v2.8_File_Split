; ===================================================================
; フラスコ統計・監視機能 - 統計情報・使用履歴・デバッグ情報
; フラスコの使用統計、パフォーマンス監視、デバッグ情報を担当
; ===================================================================

; --- グローバル変数 ---
global g_flask_use_count := Map()
global g_flask_last_use_time := Map()
global g_flask_stats := {
    totalUses: 0,
    averageInterval: 0,
    lastResetTime: 0,
    errors: 0,
    successRate: 100
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
    
    ; 成功率の更新
    if (g_flask_stats.totalUses > 0) {
        g_flask_stats.successRate := Round((1 - g_flask_stats.errors / g_flask_stats.totalUses) * 100, 2)
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
        uptime: Round((A_TickCount - g_flask_stats.lastResetTime) / 1000, 1),
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
            active: g_flask_active_flasks.Has(flaskName),
            usesPerMinute: stats.uptime > 0 ? Round(count / (stats.uptime / 60), 2) : 0
        }
    }
    
    return stats
}

; --- 詳細フラスコ統計の取得 ---
GetDetailedFlaskStats(flaskName) {
    global g_flask_configs, g_flask_use_count, g_flask_last_use_time
    global g_flask_charge_tracker, g_flask_stats
    
    if (!g_flask_configs.Has(flaskName)) {
        return {}
    }
    
    config := g_flask_configs[flaskName]
    uses := g_flask_use_count.Has(flaskName) ? g_flask_use_count[flaskName] : 0
    lastUse := g_flask_last_use_time.Has(flaskName) ? g_flask_last_use_time[flaskName] : 0
    chargeInfo := g_flask_charge_tracker.Has(flaskName) ? g_flask_charge_tracker[flaskName] : {}
    
    uptime := A_TickCount - g_flask_stats.lastResetTime
    
    ; 効率計算
    expectedUses := uptime > 0 ? uptime / ((config.minInterval + config.maxInterval) / 2) : 0
    efficiency := expectedUses > 0 ? Round((uses / expectedUses) * 100, 1) : 0
    
    return {
        name: flaskName,
        enabled: config.enabled,
        type: config.type,
        key: config.key,
        priority: config.priority,
        uses: uses,
        expectedUses: Round(expectedUses, 1),
        efficiency: efficiency,
        lastUseAgo: lastUse > 0 ? Round((A_TickCount - lastUse) / 1000, 1) : 0,
        intervalConfig: Format("{}-{}ms", config.minInterval, config.maxInterval),
        charges: chargeInfo.HasOwnProp("currentCharges") ? chargeInfo.currentCharges : "N/A",
        maxCharges: config.maxCharges,
        chargePercentage: config.maxCharges > 0 && chargeInfo.HasOwnProp("currentCharges") ? 
            Round((chargeInfo.currentCharges / config.maxCharges) * 100, 1) : 0,
        usesPerMinute: uptime > 0 ? Round(uses / (uptime / 60000), 2) : 0
    }
}

; --- フラスコパフォーマンス統計の取得 ---
GetFlaskPerformanceStats() {
    global g_flask_configs, g_flask_active_flasks
    
    performanceStats := {
        configuredFlasks: g_flask_configs.Count,
        activeFlasks: g_flask_active_flasks.Count,
        activationRate: g_flask_configs.Count > 0 ? 
            Round((g_flask_active_flasks.Count / g_flask_configs.Count) * 100, 1) : 0,
        flasksByType: Map(),
        flasksByPriority: Map()
    }
    
    ; タイプ別・優先度別の集計
    for flaskName, config in g_flask_configs {
        ; タイプ別
        if (!performanceStats.flasksByType.Has(config.type)) {
            performanceStats.flasksByType[config.type] := 0
        }
        performanceStats.flasksByType[config.type]++
        
        ; 優先度別
        priority := config.HasOwnProp("priority") ? config.priority : 5
        if (!performanceStats.flasksByPriority.Has(priority)) {
            performanceStats.flasksByPriority[priority] := 0
        }
        performanceStats.flasksByPriority[priority]++
    }
    
    return performanceStats
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
    debugInfo.Push(Format("Average Interval: {}ms | Uptime: {}s", 
        stats.averageInterval, stats.uptime))
    
    return debugInfo
}

; --- フラスコ使用履歴（簡易版） ---
global g_flask_usage_history := []
global g_max_history_entries := 100

; --- 使用履歴の記録 ---
RecordFlaskUsage(flaskName, success := true, errorMsg := "") {
    global g_flask_usage_history, g_max_history_entries
    
    entry := {
        timestamp: A_TickCount,
        flaskName: flaskName,
        success: success,
        error: errorMsg,
        timeString: FormatTime(, "HH:mm:ss")
    }
    
    g_flask_usage_history.Push(entry)
    
    ; 履歴のサイズ制限
    while (g_flask_usage_history.Length > g_max_history_entries) {
        g_flask_usage_history.RemoveAt(1)
    }
}

; --- 使用履歴の取得 ---
GetFlaskUsageHistory(limit := 20) {
    global g_flask_usage_history
    
    history := []
    startIndex := Max(1, g_flask_usage_history.Length - limit + 1)
    
    Loop (g_flask_usage_history.Length - startIndex + 1) {
        i := startIndex + A_Index - 1
        if (i <= g_flask_usage_history.Length) {
            history.Push(g_flask_usage_history[i])
        }
    }
    
    return history
}

; --- 統計のリセット ---
ResetFlaskStats() {
    global g_flask_stats, g_flask_use_count, g_flask_last_use_time, g_flask_usage_history
    
    g_flask_stats := {
        totalUses: 0,
        averageInterval: 0,
        lastResetTime: A_TickCount,
        errors: 0,
        successRate: 100
    }
    
    g_flask_use_count.Clear()
    g_flask_last_use_time.Clear()
    g_flask_usage_history := []
    
    LogInfo("FlaskStatistics", "Flask statistics reset")
}

; --- エラー統計の更新 ---
RecordFlaskError(flaskName, errorType := "general") {
    global g_flask_stats
    
    g_flask_stats.errors++
    
    ; 使用履歴に記録
    RecordFlaskUsage(flaskName, false, errorType)
    
    ; 成功率を更新
    if (g_flask_stats.totalUses > 0) {
        g_flask_stats.successRate := Round((1 - g_flask_stats.errors / g_flask_stats.totalUses) * 100, 2)
    }
    
    LogDebug("FlaskStatistics", Format("Recorded error for flask '{}': {}", flaskName, errorType))
}

; --- 成功使用の記録 ---
RecordFlaskSuccess(flaskName) {
    global g_flask_use_count, g_flask_last_use_time
    
    ; 統計更新
    if (!g_flask_use_count.Has(flaskName)) {
        g_flask_use_count[flaskName] := 0
    }
    g_flask_use_count[flaskName]++
    g_flask_last_use_time[flaskName] := A_TickCount
    
    ; 使用履歴に記録
    RecordFlaskUsage(flaskName, true)
}

; --- フラスコ効率レポートの生成 ---
GenerateFlaskEfficiencyReport() {
    report := []
    report.Push("=== Flask Efficiency Report ===")
    report.Push("")
    
    globalStats := GetFlaskStats()
    report.Push(Format("Overall Success Rate: {}%", globalStats.successRate))
    report.Push(Format("Total Uses: {} over {}s", globalStats.totalUses, globalStats.uptime))
    report.Push("")
    
    ; 個別フラスコの効率
    for flaskName in g_flask_configs {
        detailedStats := GetDetailedFlaskStats(flaskName)
        report.Push(Format("{}: {}% efficiency ({} uses, {} expected)", 
            flaskName, detailedStats.efficiency, detailedStats.uses, detailedStats.expectedUses))
    }
    
    ; パフォーマンス統計
    perfStats := GetFlaskPerformanceStats()
    report.Push("")
    report.Push(Format("Flask Activation Rate: {}% ({}/{})", 
        perfStats.activationRate, perfStats.activeFlasks, perfStats.configuredFlasks))
    
    return report
}

; --- 統計エクスポート ---
ExportFlaskStatistics() {
    return {
        globalStats: GetFlaskStats(),
        performanceStats: GetFlaskPerformanceStats(),
        recentHistory: GetFlaskUsageHistory(50),
        detailedStats: GetDetailedStatsForAllFlasks()
    }
}

; --- 全フラスコの詳細統計取得 ---
GetDetailedStatsForAllFlasks() {
    detailed := Map()
    for flaskName in g_flask_configs {
        detailed[flaskName] := GetDetailedFlaskStats(flaskName)
    }
    return detailed
}

; --- 統計の定期更新 ---
ScheduleStatsUpdate() {
    ; 統計の定期更新（10秒間隔）
    SetTimer(UpdateFlaskStats, 10000)
    LogDebug("FlaskStatistics", "Scheduled periodic stats updates")
}

; --- 統計更新の停止 ---
StopStatsUpdate() {
    ; 定期更新を停止
    SetTimer(UpdateFlaskStats, 0)
    LogDebug("FlaskStatistics", "Stopped periodic stats updates")
}