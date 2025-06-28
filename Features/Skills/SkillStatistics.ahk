; ===================================================================
; スキル統計・監視機能
; パフォーマンス統計、デバッグ情報、実行統計の管理
; ===================================================================

; --- グローバル変数 ---
global g_skill_stats := Map()

; --- 統計の初期化 ---
InitializeSkillStats() {
    global g_skill_stats
    
    skills := ["E", "R", "T", "4"]
    for skill in skills {
        g_skill_stats[skill] := {
            count: 0,
            lastUse: 0,
            totalDelay: 0,
            avgDelay: 0,
            errors: 0
        }
    }
    
    LogDebug("SkillStatistics", "Skill statistics initialized for legacy skills")
}

; --- スキル統計の更新（改善版） ---
UpdateSkillStats(skill) {
    global g_skill_stats, g_skill_last_use
    
    if (!g_skill_stats.Has(skill)) {
        g_skill_stats[skill] := {
            count: 0,
            lastUse: 0,
            totalDelay: 0,
            avgDelay: 0,
            errors: 0
        }
    }
    
    stats := g_skill_stats[skill]
    stats.count++
    
    ; 前回からの遅延を計算
    if (stats.lastUse > 0) {
        delay := A_TickCount - stats.lastUse
        stats.totalDelay += delay
        stats.avgDelay := Round(stats.totalDelay / stats.count)
    }
    
    stats.lastUse := A_TickCount
}

; --- スキル統計の取得（拡張版） ---
GetSkillStats() {
    global g_skill_stats, g_wine_current_stage
    
    ; Wine of the Prophetのステージ情報を追加
    if (g_skill_stats.Has("4")) {
        g_skill_stats["4"].currentStage := g_wine_current_stage
    }
    
    return g_skill_stats
}

; --- パフォーマンス統計の取得 ---
GetSkillPerformanceStats() {
    global g_skill_configs, g_skill_enabled, g_skill_timers, g_skill_stats
    
    performanceStats := {
        totalSkills: g_skill_configs.Count,
        activeSkills: 0,
        runningTimers: g_skill_timers.Count,
        totalExecutions: 0,
        totalErrors: 0,
        avgInterval: 0,
        memoryUsage: 0,
        skillsByPriority: Map()
    }
    
    ; 優先度別統計
    Loop 5 {
        performanceStats.skillsByPriority[A_Index] := []
    }
    
    ; スキル統計を集計
    totalIntervals := 0
    intervalCount := 0
    
    for skill, config in g_skill_configs {
        if (g_skill_enabled[skill]) {
            performanceStats.activeSkills++
            
            ; 優先度別分類
            if (config.HasOwnProp("priority") && config.priority >= 1 && config.priority <= 5) {
                performanceStats.skillsByPriority[config.priority].Push(skill)
            }
            
            ; 実行統計
            if (g_skill_stats.Has(skill)) {
                stats := g_skill_stats[skill]
                performanceStats.totalExecutions += stats.count
                performanceStats.totalErrors += stats.errors
                
                if (stats.avgDelay > 0) {
                    totalIntervals += stats.avgDelay
                    intervalCount++
                }
            }
            
            ; 設定された間隔を平均に追加
            if (config.HasOwnProp("minInterval") && config.HasOwnProp("maxInterval")) {
                avgConfigInterval := (config.minInterval + config.maxInterval) / 2
                totalIntervals += avgConfigInterval
                intervalCount++
            }
        }
    }
    
    ; 平均間隔を計算
    if (intervalCount > 0) {
        performanceStats.avgInterval := Round(totalIntervals / intervalCount)
    }
    
    return performanceStats
}

; --- デバッグ情報の取得 ---
GetSkillDebugInfo() {
    global g_skill_configs, g_skill_enabled, g_skill_timers
    global g_wine_current_stage, g_macro_start_time
    
    debugInfo := []
    debugInfo.Push("=== Skill Automation Debug ===")
    debugInfo.Push(Format("Active Timers: {}", g_skill_timers.Count))
    
    ; パフォーマンス統計を表示
    perfStats := GetSkillPerformanceStats()
    debugInfo.Push(Format("Total Skills: {} | Active: {} | Timers: {}", 
        perfStats.totalSkills, perfStats.activeSkills, perfStats.runningTimers))
    debugInfo.Push(Format("Executions: {} | Errors: {} | Avg Interval: {}ms", 
        perfStats.totalExecutions, perfStats.totalErrors, perfStats.avgInterval))
    debugInfo.Push("")
    
    ; 優先度別表示
    for priority, skills in perfStats.skillsByPriority {
        if (skills.Length > 0) {
            debugInfo.Push(Format("Priority {} ({} skills): {}", 
                priority, skills.Length, StrReplace(Array2String(skills), ",", ", ")))
        }
    }
    debugInfo.Push("")
    
    ; 各スキルの状態（上位5つのみ）
    skillCount := 0
    for skill, config in g_skill_configs {
        if (skillCount >= 5) {
            debugInfo.Push("... (showing top 5 skills)")
            break
        }
        
        status := g_skill_enabled[skill] ? "ON" : "OFF"
        if (g_skill_timers.Has(skill)) {
            status .= " (Active)"
        }
        
        stats := g_skill_stats.Has(skill == "Wine" ? "4" : skill) ? 
            g_skill_stats[skill == "Wine" ? "4" : skill] : {count: 0, errors: 0}
        
        debugInfo.Push(Format("{}: {} - Key:{} Uses:{} Errors:{}", 
            skill, status, 
            config.HasOwnProp("key") ? config.key : "?", 
            stats.count, 
            stats.errors))
        
        skillCount++
    }
    
    ; Wine of the Prophetの詳細
    if (g_skill_enabled.Has("Wine") && g_skill_enabled["Wine"]) {
        elapsedTime := A_TickCount - g_macro_start_time
        stageInfo := GetCurrentWineStage(elapsedTime)
        debugInfo.Push("")
        debugInfo.Push(Format("Wine Stage: {} ({}s elapsed)", 
            stageInfo.stage, Round(elapsedTime/1000)))
        debugInfo.Push(Format("Wine Delay: {}-{}ms", 
            stageInfo.minDelay, stageInfo.maxDelay))
    }
    
    return debugInfo
}

; --- 詳細統計レポートの生成 ---
GetDetailedSkillReport() {
    global g_skill_configs, g_skill_enabled, g_skill_stats, g_skill_timers
    
    report := []
    report.Push("=== Detailed Skill Automation Report ===")
    report.Push(Format("Generated: {}", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")))
    report.Push("")
    
    ; 概要統計
    perfStats := GetSkillPerformanceStats()
    report.Push("=== Summary ===")
    report.Push(Format("Total Configured Skills: {}", perfStats.totalSkills))
    report.Push(Format("Active Skills: {}", perfStats.activeSkills))
    report.Push(Format("Running Timers: {}", perfStats.runningTimers))
    report.Push(Format("Total Executions: {}", perfStats.totalExecutions))
    report.Push(Format("Total Errors: {}", perfStats.totalErrors))
    report.Push(Format("Average Interval: {}ms", perfStats.avgInterval))
    report.Push("")
    
    ; 優先度別詳細
    report.Push("=== Skills by Priority ===")
    Loop 5 {
        priority := A_Index
        skills := perfStats.skillsByPriority[priority]
        if (skills.Length > 0) {
            report.Push(Format("Priority {}: {} skills", priority, skills.Length))
            for skill in skills {
                config := g_skill_configs[skill]
                stats := g_skill_stats.Has(skill) ? g_skill_stats[skill] : {count: 0, avgDelay: 0, errors: 0}
                
                report.Push(Format("  - {}: Key='{}' Interval={}ms-{}ms Uses={} Errors={}", 
                    skill,
                    config.HasOwnProp("key") ? config.key : "?",
                    config.HasOwnProp("minInterval") ? config.minInterval : "?",
                    config.HasOwnProp("maxInterval") ? config.maxInterval : "?",
                    stats.count,
                    stats.errors))
            }
            report.Push("")
        }
    }
    
    ; Wine専用統計
    if (g_skill_enabled.Has("Wine") && g_skill_enabled["Wine"]) {
        wineStats := GetWineStageStats()
        report.Push("=== Wine of the Prophet ===")
        report.Push(Format("Current Stage: {}", wineStats.currentStage))
        report.Push(Format("Total Runtime: {}s", Round(wineStats.totalElapsedTime/1000)))
        report.Push(Format("Stage Runtime: {}s", Round(wineStats.stageElapsedTime/1000)))
        report.Push(Format("Stage Delay: {}ms-{}ms (avg: {}ms)", 
            wineStats.stageMinDelay, wineStats.stageMaxDelay, wineStats.stageAvgDelay))
        
        if (wineStats.nextStageTime > 0) {
            report.Push(Format("Next Stage in: {}s", Round(wineStats.nextStageTime/1000)))
        }
        report.Push("")
    }
    
    return report
}

; --- エラー統計の取得 ---
GetErrorStatistics() {
    global g_skill_stats
    
    errorStats := {
        totalErrors: 0,
        skillsWithErrors: 0,
        errorsBySkill: Map(),
        errorRate: 0.0
    }
    
    totalExecutions := 0
    
    for skill, stats in g_skill_stats {
        totalExecutions += stats.count
        errorStats.totalErrors += stats.errors
        
        if (stats.errors > 0) {
            errorStats.skillsWithErrors++
            errorStats.errorsBySkill[skill] := {
                errors: stats.errors,
                executions: stats.count,
                errorRate: stats.count > 0 ? Round((stats.errors / stats.count) * 100, 2) : 0
            }
        }
    }
    
    ; 全体エラー率を計算
    if (totalExecutions > 0) {
        errorStats.errorRate := Round((errorStats.totalErrors / totalExecutions) * 100, 2)
    }
    
    return errorStats
}

; --- 統計のリセット ---
ResetAllSkillStats() {
    global g_skill_stats
    
    for skill, stats in g_skill_stats {
        stats.count := 0
        stats.lastUse := 0
        stats.totalDelay := 0
        stats.avgDelay := 0
        stats.errors := 0
    }
    
    LogInfo("SkillStatistics", "All skill statistics reset")
    return true
}