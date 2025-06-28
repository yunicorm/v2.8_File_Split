; ===================================================================
; スキルヘルパー機能
; 共通ユーティリティ・ヘルパー関数・テスト機能
; ===================================================================


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
        LogInfo("SkillHelpers", Format("Manually executed skill '{}'", skill))
        return true
    }
    
    LogWarn("SkillHelpers", Format("Cannot manually execute unknown skill '{}'", skill))
    return false
}

; --- 全スキルの手動停止 ---
ManualStopAllSkills() {
    global g_skill_timers
    
    try {
        stoppedCount := 0
        for skill, timerName in g_skill_timers {
            StopSkillTimer(skill)
            stoppedCount++
        }
        
        LogInfo("SkillHelpers", Format("Manually stopped {} skill timers", stoppedCount))
        return stoppedCount
        
    } catch Error as e {
        LogError("SkillHelpers", "Failed to stop all skills: " . e.Message)
        return -1
    }
}

; --- スキル設定の検証 ---
ValidateSkillConfig(skill, config) {
    errors := []
    
    ; 必須プロパティのチェック
    if (!config.HasOwnProp("key") || config.key == "") {
        errors.Push("Key is required and cannot be empty")
    }
    
    ; 間隔設定のチェック（動的でない場合）
    if (!config.HasOwnProp("isDynamic") || !config.isDynamic) {
        if (!config.HasOwnProp("minInterval") || !IsValidInteger(config.minInterval) || config.minInterval <= 0) {
            errors.Push("minInterval must be a positive integer")
        }
        
        if (!config.HasOwnProp("maxInterval") || !IsValidInteger(config.maxInterval) || config.maxInterval <= 0) {
            errors.Push("maxInterval must be a positive integer")
        }
        
        if (config.HasOwnProp("minInterval") && config.HasOwnProp("maxInterval")) {
            if (config.minInterval > config.maxInterval) {
                errors.Push("minInterval cannot be greater than maxInterval")
            }
        }
    }
    
    ; 優先度のチェック
    if (config.HasOwnProp("priority")) {
        if (!IsValidInteger(config.priority) || config.priority < 1 || config.priority > 5) {
            errors.Push("priority must be an integer between 1 and 5")
        }
    }
    
    if (errors.Length > 0) {
        LogWarn("SkillHelpers", Format("Validation errors for skill '{}': {}", skill, Array2String(errors)))
    }
    
    return errors
}

; --- スキル設定のサニタイズ ---
SanitizeSkillConfig(config) {
    sanitized := {}
    
    ; 基本プロパティをコピー
    for prop, value in config.OwnProps() {
        sanitized.%prop% := value
    }
    
    ; デフォルト値を設定
    if (!sanitized.HasOwnProp("priority")) {
        sanitized.priority := 3
    }
    
    if (!sanitized.HasOwnProp("name")) {
        sanitized.name := "Unknown Skill"
    }
    
    if (!sanitized.HasOwnProp("group")) {
        sanitized.group := 1
    }
    
    if (!sanitized.HasOwnProp("enabled")) {
        sanitized.enabled := true
    }
    
    ; 範囲チェック
    if (sanitized.priority < 1) {
        sanitized.priority := 1
    } else if (sanitized.priority > 5) {
        sanitized.priority := 5
    }
    
    return sanitized
}

; --- スキル情報の簡易表示 ---
GetSkillSummary(skill) {
    global g_skill_configs, g_skill_enabled, g_skill_stats
    
    if (!g_skill_configs.Has(skill)) {
        return Format("Skill '{}' not found", skill)
    }
    
    config := g_skill_configs[skill]
    enabled := g_skill_enabled.Has(skill) ? g_skill_enabled[skill] : false
    stats := g_skill_stats.Has(skill) ? g_skill_stats[skill] : {count: 0, errors: 0, avgDelay: 0}
    
    summary := Format("Skill '{}': ", skill)
    summary .= Format("Key='{}' ", config.HasOwnProp("key") ? config.key : "?")
    summary .= Format("Status={} ", enabled ? "ON" : "OFF")
    
    if (config.HasOwnProp("minInterval") && config.HasOwnProp("maxInterval")) {
        summary .= Format("Interval={}ms-{}ms ", config.minInterval, config.maxInterval)
    } else if (config.HasOwnProp("isDynamic") && config.isDynamic) {
        summary .= "Interval=Dynamic "
    }
    
    summary .= Format("Uses={} Errors={}", stats.count, stats.errors)
    
    if (stats.avgDelay > 0) {
        summary .= Format(" AvgDelay={}ms", stats.avgDelay)
    }
    
    return summary
}

; --- デバッグ用：設定ダンプ ---
DumpSkillConfigurations() {
    global g_skill_configs, g_skill_enabled
    
    dump := []
    dump.Push("=== Skill Configuration Dump ===")
    dump.Push(Format("Total Skills: {}", g_skill_configs.Count))
    dump.Push("")
    
    for skill, config in g_skill_configs {
        enabled := g_skill_enabled.Has(skill) ? g_skill_enabled[skill] : false
        
        dump.Push(Format("Skill: {} ({})", skill, enabled ? "ENABLED" : "DISABLED"))
        
        for prop, value in config.OwnProps() {
            dump.Push(Format("  {}: {}", prop, value))
        }
        
        dump.Push("")
    }
    
    return dump
}


; --- スキル名の正規化 ---
NormalizeSkillName(skillName) {
    ; 先頭・末尾の空白を削除
    normalized := Trim(skillName)
    
    ; 空文字列の場合はデフォルト名を返す
    if (normalized == "") {
        return "Unknown_Skill"
    }
    
    ; 特殊文字を置換（ログやファイル名で問題を起こす文字）
    normalized := StrReplace(normalized, " ", "_")
    normalized := StrReplace(normalized, ":", "_")
    normalized := StrReplace(normalized, "/", "_")
    normalized := StrReplace(normalized, "\", "_")
    
    return normalized
}

; --- 簡単なベンチマーク機能 ---
BenchmarkSkillExecution(skill, iterations := 10) {
    global g_skill_configs
    
    if (!g_skill_configs.Has(skill)) {
        LogError("SkillHelpers", Format("Cannot benchmark unknown skill '{}'", skill))
        return false
    }
    
    LogInfo("SkillHelpers", Format("Starting benchmark for skill '{}' ({} iterations)", skill, iterations))
    
    startTime := A_TickCount
    successCount := 0
    
    Loop iterations {
        try {
            if (ManualExecuteSkill(skill)) {
                successCount++
            }
            Sleep(50)  ; 短い間隔で実行
        } catch Error as e {
            LogWarn("SkillHelpers", Format("Benchmark iteration {} failed: {}", A_Index, e.Message))
        }
    }
    
    endTime := A_TickCount
    totalTime := endTime - startTime
    avgTime := totalTime / iterations
    
    LogInfo("SkillHelpers", Format("Benchmark completed: {}/{} successful, avg {}ms per execution", 
        successCount, iterations, Round(avgTime, 1)))
    
    return {
        skill: skill,
        iterations: iterations,
        successful: successCount,
        totalTime: totalTime,
        avgTime: avgTime,
        successRate: Round((successCount / iterations) * 100, 1)
    }
}