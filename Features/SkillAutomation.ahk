; ===================================================================
; スキル自動化システム（修正版）
; E, R, T, 4キーの自動実行管理（エラーハンドリングとタイミング管理強化）
; ===================================================================

; --- グローバル変数 ---
global g_skill_timers := Map()
global g_skill_stats := Map()
global g_skill_configs := Map()
global g_skill_last_use := Map()
global g_skill_enabled := Map()
global g_wine_stage_start_time := 0
global g_wine_current_stage := 0

; --- スキル設定の初期化 ---
InitializeSkillConfigs() {
    global g_skill_configs, g_skill_enabled
    
    ; スキル設定を定義
    g_skill_configs["E"] := {
        key: KEY_SKILL_E,
        minInterval: TIMING_SKILL_ER.min,
        maxInterval: TIMING_SKILL_ER.max,
        priority: 1,
        description: "Skill E"
    }
    
    g_skill_configs["R"] := {
        key: KEY_SKILL_R,
        minInterval: TIMING_SKILL_ER.min,
        maxInterval: TIMING_SKILL_ER.max,
        priority: 1,
        description: "Skill R"
    }
    
    g_skill_configs["T"] := {
        key: KEY_SKILL_T,
        minInterval: TIMING_SKILL_T.min,
        maxInterval: TIMING_SKILL_T.max,
        priority: 2,
        description: "Skill T"
    }
    
    g_skill_configs["Wine"] := {
        key: KEY_WINE_PROPHET,
        isDynamic: true,
        priority: 3,
        description: "Wine of the Prophet"
    }
    
    ; すべてのスキルを有効化
    for skill, _ in g_skill_configs {
        g_skill_enabled[skill] := true
    }
    
    ; 統計を初期化
    InitializeSkillStats()
    
    LogInfo("SkillAutomation", "Skill configurations initialized")
}

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
}

; --- スキル自動化の開始（改善版） ---
StartSkillAutomation() {
    global g_macro_start_time, g_wine_stage_start_time, g_wine_current_stage
    
    ; 設定を初期化
    InitializeSkillConfigs()
    
    ; Wine of the Prophetのタイマーをリセット
    g_wine_stage_start_time := g_macro_start_time
    g_wine_current_stage := 0
    
    ; 各スキルのタイマーを開始
    for skill, config in g_skill_configs {
        if (g_skill_enabled[skill]) {
            StartSkillTimer(skill, config)
        }
    }
    
    LogInfo("SkillAutomation", "Skill automation started with all timers")
}

; --- 個別スキルタイマーの開始 ---
StartSkillTimer(skill, config) {
    global g_skill_timers, g_skill_last_use
    
    try {
        ; 初回遅延を設定（スキルごとに異なる）
        initialDelay := 0
        switch skill {
            case "E": initialDelay := 100
            case "R": initialDelay := 200
            case "T": initialDelay := 300
            case "Wine": initialDelay := 1000
        }
        
        ; タイマー名を生成
        timerName := "Skill_" . skill
        
        ; コールバック関数を設定
        if (config.isDynamic) {
            callback := () => ExecuteWineOfProphet()
        } else {
            callback := () => ExecuteSkill(skill, config)
        }
        
        ; タイマーを開始
        StartManagedTimer(timerName, callback, -initialDelay)
        g_skill_timers[skill] := timerName
        g_skill_last_use[skill] := A_TickCount
        
        LogDebug("SkillAutomation", Format("Started timer for skill '{}' with {}ms initial delay", 
            skill, initialDelay))
        
    } catch Error as e {
        LogError("SkillAutomation", Format("Failed to start skill timer '{}': {}", 
            skill, e.Message))
    }
}

; --- スキル実行（汎用） ---
ExecuteSkill(skill, config) {
    global g_macro_active, g_skill_last_use, g_skill_stats
    
    ; マクロが非アクティブなら停止
    if (!g_macro_active || !g_skill_enabled[skill]) {
        StopSkillTimer(skill)
        return
    }
    
    try {
        ; 最小間隔のチェック（連続実行防止）
        timeSinceLastUse := A_TickCount - g_skill_last_use[skill]
        if (timeSinceLastUse < config.minInterval * 0.8) {
            LogWarn("SkillAutomation", Format("Skill '{}' execution too soon ({}ms), skipping", 
                skill, timeSinceLastUse))
            ; 次の実行をスケジュール
            ScheduleNextSkillExecution(skill, config, config.minInterval - timeSinceLastUse)
            return
        }
        
        ; スキルを実行
        Send(config.key)
        
        ; 統計を更新
        UpdateSkillStats(skill)
        g_skill_last_use[skill] := A_TickCount
        
        ; 次の実行をスケジュール
        nextDelay := Random(config.minInterval, config.maxInterval)
        ScheduleNextSkillExecution(skill, config, nextDelay)
        
        LogDebug("SkillAutomation", Format("Skill '{}' executed, next in {}ms", 
            skill, nextDelay))
        
    } catch Error as e {
        g_skill_stats[skill].errors++
        LogError("SkillAutomation", Format("Failed to execute skill '{}': {}", 
            skill, e.Message))
        
        ; エラー時も次の実行をスケジュール
        ScheduleNextSkillExecution(skill, config, config.maxInterval)
    }
}

; --- 次のスキル実行をスケジュール ---
ScheduleNextSkillExecution(skill, config, delay) {
    global g_macro_active, g_skill_timers
    
    if (!g_macro_active || !g_skill_enabled[skill]) {
        return
    }
    
    timerName := g_skill_timers[skill]
    
    if (config.isDynamic) {
        callback := () => ExecuteWineOfProphet()
    } else {
        callback := () => ExecuteSkill(skill, config)
    }
    
    StartManagedTimer(timerName, callback, -delay)
}

; --- Wine of the Prophet実行（改善版） ---
ExecuteWineOfProphet() {
    global g_macro_active, g_macro_start_time, KEY_WINE_PROPHET
    global g_wine_stage_start_time, g_wine_current_stage
    global g_skill_last_use, g_skill_stats, g_skill_configs
    
    if (!g_macro_active || !g_skill_enabled["Wine"]) {
        StopSkillTimer("Wine")
        return
    }
    
    try {
        ; 使用
        Send(KEY_WINE_PROPHET)
        UpdateSkillStats("4")  ; 統計は "4" キーとして記録
        g_skill_last_use["Wine"] := A_TickCount
        
        ; 現在のステージと次の遅延を計算
        elapsedTime := A_TickCount - g_macro_start_time
        stageInfo := GetCurrentWineStage(elapsedTime)
        
        ; ステージが変わった場合
        if (stageInfo.stage != g_wine_current_stage) {
            g_wine_current_stage := stageInfo.stage
            g_wine_stage_start_time := A_TickCount
            LogInfo("SkillAutomation", Format("Wine of the Prophet entered stage {} ({}ms delay)", 
                stageInfo.stage, stageInfo.avgDelay))
        }
        
        ; 次の使用をスケジュール
        config := g_skill_configs["Wine"]
        nextDelay := Random(stageInfo.minDelay, stageInfo.maxDelay)
        ScheduleNextSkillExecution("Wine", config, nextDelay)
        
        LogDebug("SkillAutomation", Format("Wine used at stage {} ({}s elapsed), next in {}ms", 
            stageInfo.stage, Round(elapsedTime/1000), nextDelay))
        
    } catch Error as e {
        g_skill_stats["4"].errors++
        LogError("SkillAutomation", "Failed to use Wine of Prophet: " . e.Message)
        
        ; エラー時は保守的な遅延
        config := g_skill_configs["Wine"]
        ScheduleNextSkillExecution("Wine", config, 20000)
    }
}

; --- Wine of the Prophetのステージ情報を取得 ---
GetCurrentWineStage(elapsedTime) {
    ; 設定から各ステージの情報を取得
    stages := [
        {
            stage: 1,
            maxTime: ConfigManager.Get("Wine", "Stage1_Time", 60000),
            minDelay: ConfigManager.Get("Wine", "Stage1_Min", 22000),
            maxDelay: ConfigManager.Get("Wine", "Stage1_Max", 22500)
        },
        {
            stage: 2,
            maxTime: ConfigManager.Get("Wine", "Stage2_Time", 90000),
            minDelay: ConfigManager.Get("Wine", "Stage2_Min", 19500),
            maxDelay: ConfigManager.Get("Wine", "Stage2_Max", 20000)
        },
        {
            stage: 3,
            maxTime: ConfigManager.Get("Wine", "Stage3_Time", 120000),
            minDelay: ConfigManager.Get("Wine", "Stage3_Min", 17500),
            maxDelay: ConfigManager.Get("Wine", "Stage3_Max", 18000)
        },
        {
            stage: 4,
            maxTime: ConfigManager.Get("Wine", "Stage4_Time", 170000),
            minDelay: ConfigManager.Get("Wine", "Stage4_Min", 16000),
            maxDelay: ConfigManager.Get("Wine", "Stage4_Max", 16500)
        },
        {
            stage: 5,
            maxTime: 999999999,  ; 最終ステージ
            minDelay: ConfigManager.Get("Wine", "Stage5_Min", 14500),
            maxDelay: ConfigManager.Get("Wine", "Stage5_Max", 15000)
        }
    ]
    
    ; 現在のステージを判定
    for stageInfo in stages {
        if (elapsedTime < stageInfo.maxTime) {
            stageInfo.avgDelay := Round((stageInfo.minDelay + stageInfo.maxDelay) / 2)
            return stageInfo
        }
    }
    
    ; フォールバック（通常は到達しない）
    return stages[5]
}

; --- 特定のスキルタイマーを停止 ---
StopSkillTimer(skill) {
    global g_skill_timers
    
    if (g_skill_timers.Has(skill)) {
        timerName := g_skill_timers[skill]
        StopManagedTimer(timerName)
        g_skill_timers.Delete(skill)
        
        LogDebug("SkillAutomation", Format("Stopped timer for skill '{}'", skill))
    }
}

; --- スキル自動化の停止 ---
StopSkillAutomation() {
    global g_skill_timers
    
    ; すべてのスキルタイマーを停止
    for skill, timerName in g_skill_timers {
        StopManagedTimer(timerName)
    }
    g_skill_timers.Clear()
    
    LogInfo("SkillAutomation", "Skill automation stopped")
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

; --- 特定スキルの有効/無効切り替え ---
ToggleSkill(skill, enabled := "") {
    global g_skill_enabled, g_skill_configs
    
    if (!g_skill_configs.Has(skill)) {
        LogWarn("SkillAutomation", Format("Unknown skill: {}", skill))
        return false
    }
    
    if (enabled == "") {
        enabled := !g_skill_enabled[skill]
    }
    
    g_skill_enabled[skill] := enabled
    
    if (enabled) {
        ; 有効化された場合はタイマーを開始
        config := g_skill_configs[skill]
        StartSkillTimer(skill, config)
    } else {
        ; 無効化された場合はタイマーを停止
        StopSkillTimer(skill)
    }
    
    LogInfo("SkillAutomation", Format("Skill '{}' {}", skill, enabled ? "enabled" : "disabled"))
    return true
}

; --- スキルタイミングのリセット ---
ResetSkillTimings() {
    global g_skill_timers, g_skill_configs, g_macro_active
    
    if (!g_macro_active) {
        return
    }
    
    LogInfo("SkillAutomation", "Resetting skill timings")
    
    ; 一時的にすべてのタイマーを停止
    tempDisabled := []
    for skill, timerName in g_skill_timers {
        if (g_skill_enabled[skill]) {
            tempDisabled.Push(skill)
            StopManagedTimer(timerName)
        }
    }
    g_skill_timers.Clear()
    
    Sleep(100)  ; 安定性のための短い待機
    
    ; 有効なスキルを再開始
    for skill in tempDisabled {
        if (g_skill_configs.Has(skill)) {
            config := g_skill_configs[skill]
            StartSkillTimer(skill, config)
        }
    }
    
    LogInfo("SkillAutomation", "Skill timings reset completed")
}

; --- 新しいスキル設定システムを初期化 ---
InitializeNewSkillSystem() {
    global g_skill_configs, g_skill_enabled, g_skill_stats
    
    try {
        ; 既存の設定をクリア
        g_skill_configs.Clear()
        g_skill_enabled.Clear()
        
        ; Config.iniから新しいスキル設定を読み込み
        skillGroups := ["1_1", "1_2", "1_3", "1_4", "1_5", "2_1", "2_2", "2_3", "2_4", "2_5"]
        
        for skillId in skillGroups {
            enabled := ConfigManager.Get("Skill", "Skill_" . skillId . "_Enabled", false)
            
            if (enabled) {
                name := ConfigManager.Get("Skill", "Skill_" . skillId . "_Name", "スキル" . skillId)
                key := ConfigManager.Get("Skill", "Skill_" . skillId . "_Key", "q")
                minInterval := Integer(ConfigManager.Get("Skill", "Skill_" . skillId . "_Min", "1000"))
                maxInterval := Integer(ConfigManager.Get("Skill", "Skill_" . skillId . "_Max", "1500"))
                priority := Integer(ConfigManager.Get("Skill", "Skill_" . skillId . "_Priority", "3"))
                
                skillKey := "Skill_" . skillId
                
                g_skill_configs[skillKey] := {
                    key: key,
                    name: name,
                    minInterval: minInterval,
                    maxInterval: maxInterval,
                    priority: priority,
                    group: StrSplit(skillId, "_")[1],
                    enabled: true
                }
                
                g_skill_enabled[skillKey] := true
                
                ; 統計を初期化
                if (!g_skill_stats.Has(skillKey)) {
                    g_skill_stats[skillKey] := {
                        count: 0,
                        lastUse: 0,
                        totalDelay: 0,
                        avgDelay: 0,
                        errors: 0
                    }
                }
                
                LogDebug("SkillAutomation", Format("Loaded skill {}: {} ({}ms-{}ms)", 
                    skillKey, name, minInterval, maxInterval))
            }
        }
        
        LogInfo("SkillAutomation", Format("New skill system initialized with {} skills", 
            g_skill_configs.Count))
        return true
        
    } catch Error as e {
        LogError("SkillAutomation", "Failed to initialize new skill system: " . e.Message)
        return false
    }
}

; --- カスタムスキル設定（実装版） ---
ConfigureSkills(skillConfig) {
    global g_skill_configs, g_skill_enabled
    
    ; 使用例：
    ; skillConfig := Map(
    ;     "Skill_1_1", {name: "Molten Strike", key: "Q", minInterval: 2000, maxInterval: 2500, enabled: true, priority: 1, group: 1},
    ;     "Skill_2_1", {name: "Default Attack", key: "LButton", minInterval: 500, maxInterval: 800, enabled: true, priority: 1, group: 2}
    ; )
    
    try {
        wasActive := g_macro_active
        if (wasActive) {
            StopSkillAutomation()
        }
        
        ; 既存の設定をクリア
        g_skill_configs.Clear()
        g_skill_enabled.Clear()
        
        ; 新しい設定を適用
        for skill, config in skillConfig {
            ; デフォルト値を設定
            if (!config.HasOwnProp("priority")) {
                config.priority := 3  ; デフォルト優先度
            }
            if (!config.HasOwnProp("name")) {
                config.name := skill
            }
            if (!config.HasOwnProp("group")) {
                config.group := 1
            }
            
            g_skill_configs[skill] := config
            g_skill_enabled[skill] := config.HasOwnProp("enabled") ? config.enabled : true
            
            ; 統計を初期化
            if (!g_skill_stats.Has(skill)) {
                g_skill_stats[skill] := {
                    count: 0,
                    lastUse: 0,
                    totalDelay: 0,
                    avgDelay: 0,
                    errors: 0
                }
            }
            
            LogDebug("SkillAutomation", Format("Configured skill {}: {} ({}ms-{}ms)", 
                skill, config.name, config.minInterval, config.maxInterval))
        }
        
        ; 自動化を再開
        if (wasActive) {
            StartSkillAutomation()
        }
        
        LogInfo("SkillAutomation", Format("Skill configuration updated ({} skills)", 
            skillConfig.Count))
        return true
        
    } catch Error as e {
        LogError("SkillAutomation", "Failed to configure skills: " . e.Message)
        return false
    }
}

; --- 新旧設定システム対応のスキル自動化開始 ---
StartNewSkillAutomation() {
    global g_macro_start_time, g_wine_stage_start_time, g_wine_current_stage
    
    try {
        ; 新しいスキルシステムを初期化
        if (!InitializeNewSkillSystem()) {
            LogWarn("SkillAutomation", "Failed to initialize new skill system, falling back to legacy")
            InitializeSkillConfigs()  ; レガシーシステムにフォールバック
        }
        
        ; Wine of the Prophetのタイマーをリセット
        g_wine_stage_start_time := g_macro_start_time
        g_wine_current_stage := 0
        
        ; 各スキルのタイマーを開始
        for skill, config in g_skill_configs {
            if (g_skill_enabled[skill]) {
                StartSkillTimer(skill, config)
            }
        }
        
        LogInfo("SkillAutomation", Format("New skill automation started with {} skills", 
            g_skill_configs.Count))
        return true
        
    } catch Error as e {
        LogError("SkillAutomation", "Failed to start new skill automation: " . e.Message)
        return false
    }
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

; --- ヘルパー関数: 配列を文字列に変換 ---
Array2String(arr) {
    result := ""
    for index, value in arr {
        if (index > 1) {
            result .= ","
        }
        result .= value
    }
    return result
}

; --- 手動スキル実行（テスト用） ---
ManualExecuteSkill(skill) {
    global g_skill_configs
    
    if (g_skill_configs.Has(skill)) {
        config := g_skill_configs[skill]
        Send(config.key)
        UpdateSkillStats(skill)
        LogInfo("SkillAutomation", Format("Manually executed skill '{}'", skill))
        return true
    }
    
    return false
}