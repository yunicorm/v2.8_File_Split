; ===================================================================
; スキルコントローラー - メイン制御・タイマー管理
; スキル自動化の中央制御とタイマー管理を担当
; ===================================================================

; --- グローバル変数 ---
global g_skill_timers := Map()
global g_skill_last_use := Map()
global g_skill_enabled := Map()

; --- スキル自動化の開始（改善版） ---
StartSkillAutomation() {
    global g_macro_start_time
    
    ; 設定を初期化
    InitializeSkillConfigs()
    
    ; Wine of the Prophetのタイマーをリセット（WineManagerに委譲）
    InitializeWineSystem()
    
    ; 各スキルのタイマーを開始
    for skill, config in g_skill_configs {
        if (g_skill_enabled[skill]) {
            StartSkillTimer(skill, config)
        }
    }
    
    LogInfo("SkillAutomation", "Skill automation started with all timers")
}

; --- 新旧設定システム対応のスキル自動化開始 ---
StartNewSkillAutomation() {
    global g_macro_start_time
    
    try {
        ; 新しいスキルシステムを初期化
        if (!InitializeNewSkillSystem()) {
            LogWarn("SkillAutomation", "Failed to initialize new skill system, falling back to legacy")
            InitializeSkillConfigs()  ; レガシーシステムにフォールバック
        }
        
        ; Wine of the Prophetのタイマーをリセット（WineManagerに委譲）
        InitializeWineSystem()
        
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
            default:
                ; 新システムのスキルの場合、優先度に基づいて遅延を計算
                if (config.HasOwnProp("priority")) {
                    initialDelay := config.priority * 100
                } else {
                    initialDelay := 500
                }
        }
        
        ; タイマー名を生成
        timerName := "Skill_" . skill
        
        ; コールバック関数を設定
        if (config.HasOwnProp("isDynamic") && config.isDynamic) {
            callback := () => ExecuteWineOfProphet()
        } else {
            callback := () => ExecuteSkill(skill, config)
        }
        
        ; タイマーを開始
        StartManagedTimer(timerName, callback, -initialDelay)
        g_skill_timers[skill] := timerName
        g_skill_last_use[skill] := A_TickCount
        
        LogDebug("SkillController", Format("Started timer for skill '{}' with {}ms initial delay", 
            skill, initialDelay))
        
    } catch Error as e {
        LogError("SkillController", Format("Failed to start skill timer '{}': {}", 
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
            LogWarn("SkillController", Format("Skill '{}' execution too soon ({}ms), skipping", 
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
        
        LogDebug("SkillController", Format("Skill '{}' executed, next in {}ms", 
            skill, nextDelay))
        
    } catch Error as e {
        g_skill_stats[skill].errors++
        LogError("SkillController", Format("Failed to execute skill '{}': {}", 
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
    
    if (config.HasOwnProp("isDynamic") && config.isDynamic) {
        callback := () => ExecuteWineOfProphet()
    } else {
        callback := () => ExecuteSkill(skill, config)
    }
    
    StartManagedTimer(timerName, callback, -delay)
}

; --- 特定のスキルタイマーを停止 ---
StopSkillTimer(skill) {
    global g_skill_timers
    
    if (g_skill_timers.Has(skill)) {
        timerName := g_skill_timers[skill]
        StopManagedTimer(timerName)
        g_skill_timers.Delete(skill)
        
        LogDebug("SkillController", Format("Stopped timer for skill '{}'", skill))
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
    
    LogInfo("SkillController", "Skill automation stopped")
}

; --- 特定スキルの有効/無効切り替え ---
ToggleSkill(skill, enabled := "") {
    global g_skill_enabled, g_skill_configs
    
    if (!g_skill_configs.Has(skill)) {
        LogWarn("SkillController", Format("Unknown skill: {}", skill))
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
    
    LogInfo("SkillController", Format("Skill '{}' {}", skill, enabled ? "enabled" : "disabled"))
    return true
}

; --- スキルタイミングのリセット ---
ResetSkillTimings() {
    global g_skill_timers, g_skill_configs, g_macro_active
    
    if (!g_macro_active) {
        return
    }
    
    LogInfo("SkillController", "Resetting skill timings")
    
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
    
    LogInfo("SkillController", "Skill timings reset completed")
}