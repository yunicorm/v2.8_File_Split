; ===================================================================
; スキル設定テスト スクリプト
; 新しいスキル設定システムのテスト用
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ユーティリティのインクルード
#Include "Utils\Logger.ahk"
#Include "Utils\ConfigManager.ahk"

; テスト実行
try {
    ; ロガー初期化
    InitializeLogger()
    LogInfo("SkillTest", "=== Skill Configuration Test Starting ===")
    
    ; 設定読み込み
    if (!ConfigManager.Load()) {
        MsgBox("設定ファイルの読み込みに失敗しました", "エラー", "OK Icon!")
        ExitApp()
    }
    
    ; スキル設定をテスト
    TestSkillConfiguration()
    
} catch Error as e {
    MsgBox("テストエラー: " . e.Message, "エラー", "OK Icon!")
    LogError("SkillTest", "Test failed: " . e.Message)
}

; スキル設定をテスト
TestSkillConfiguration() {
    LogInfo("SkillTest", "Testing skill configuration...")
    
    ; 有効なスキルを検索
    skillGroups := ["1_1", "1_2", "1_3", "1_4", "1_5", "2_1", "2_2", "2_3", "2_4", "2_5"]
    activeSkills := []
    
    for skillId in skillGroups {
        enabled := ConfigManager.Get("Skill", "Skill_" . skillId . "_Enabled", false)
        
        if (enabled) {
            name := ConfigManager.Get("Skill", "Skill_" . skillId . "_Name", "スキル" . skillId)
            key := ConfigManager.Get("Skill", "Skill_" . skillId . "_Key", "q")
            minInterval := Integer(ConfigManager.Get("Skill", "Skill_" . skillId . "_Min", "1000"))
            maxInterval := Integer(ConfigManager.Get("Skill", "Skill_" . skillId . "_Max", "1500"))
            priority := Integer(ConfigManager.Get("Skill", "Skill_" . skillId . "_Priority", "3"))
            
            skillInfo := {
                id: skillId,
                name: name,
                key: key,
                minInterval: minInterval,
                maxInterval: maxInterval,
                priority: priority
            }
            
            activeSkills.Push(skillInfo)
            LogInfo("SkillTest", Format("Found active skill: {} - {} ({}ms-{}ms) Priority:{} Key:{}", 
                skillId, name, minInterval, maxInterval, priority, key))
        }
    }
    
    LogInfo("SkillTest", Format("Total active skills found: {}", activeSkills.Length))
    
    ; 設定検証
    errorCount := 0
    for skill in activeSkills {
        ; キー検証
        if (skill.key == "") {
            LogError("SkillTest", Format("Skill {} has empty key", skill.id))
            errorCount++
        }
        
        ; 間隔検証
        if (skill.minInterval <= 0 || skill.maxInterval <= 0) {
            LogError("SkillTest", Format("Skill {} has invalid intervals", skill.id))
            errorCount++
        }
        
        if (skill.minInterval > skill.maxInterval) {
            LogError("SkillTest", Format("Skill {} min interval > max interval", skill.id))
            errorCount++
        }
        
        ; 優先度検証
        if (skill.priority < 1 || skill.priority > 5) {
            LogError("SkillTest", Format("Skill {} priority out of range (1-5)", skill.id))
            errorCount++
        }
    }
    
    ; パフォーマンス予測を計算
    performancePrediction := CalculatePerformancePrediction(activeSkills)
    
    if (errorCount == 0) {
        LogInfo("SkillTest", "All skill configurations are valid!")
        resultMessage := Format("テスト完了:`n" .
            "有効なスキル: {}`n" .
            "エラー: 0`n" .
            "予想負荷: {}%`n" .
            "予想メモリ使用量: {}KB`n" .
            "平均実行間隔: {}ms`n`n" .
            "設定は正常です。", 
            activeSkills.Length, 
            performancePrediction.cpuLoad,
            performancePrediction.memoryKB,
            performancePrediction.avgInterval)
        MsgBox(resultMessage, "テスト結果", "OK Icon!")
    } else {
        LogError("SkillTest", Format("Found {} configuration errors", errorCount))
        MsgBox(Format("テスト完了:`n有効なスキル: {}`nエラー: {}`n`n詳細はログを確認してください。", activeSkills.Length, errorCount), "テスト結果", "OK Icon!")
    }
}

; パフォーマンス予測を計算
CalculatePerformancePrediction(skills) {
    totalTimers := skills.Length
    minInterval := 999999
    totalInterval := 0
    
    for skill in skills {
        avgInterval := (skill.minInterval + skill.maxInterval) / 2
        totalInterval += avgInterval
        
        if (skill.minInterval < minInterval) {
            minInterval := skill.minInterval
        }
    }
    
    avgInterval := totalInterval / skills.Length
    
    ; 負荷予測（経験的数値）
    ; 基本負荷: スキル数 * 2%
    ; 最小間隔が短いほど追加負荷
    baseCpuLoad := totalTimers * 2
    intervalPenalty := minInterval < 1000 ? (1000 - minInterval) / 100 : 0
    cpuLoad := Min(baseCpuLoad + intervalPenalty, 95)
    
    ; メモリ予測（スキルあたり約50KB + オーバーヘッド）
    memoryKB := totalTimers * 50 + 200
    
    return {
        cpuLoad: Round(cpuLoad, 1),
        memoryKB: Round(memoryKB),
        avgInterval: Round(avgInterval),
        totalTimers: totalTimers
    }
}