; ===================================================================
; スキル設定管理 - 設定読み込み・初期化・適用
; レガシーと新システムの設定管理を担当
; ===================================================================

; --- グローバル変数 ---
global g_skill_configs := Map()

; --- スキル設定の初期化（レガシー） ---
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
    
    LogInfo("SkillConfigurator", "Legacy skill configurations initialized")
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
                
                LogDebug("SkillConfigurator", Format("Loaded skill {}: {} ({}ms-{}ms)", 
                    skillKey, name, minInterval, maxInterval))
            }
        }
        
        LogInfo("SkillConfigurator", Format("New skill system initialized with {} skills", 
            g_skill_configs.Count))
        return true
        
    } catch Error as e {
        LogError("SkillConfigurator", "Failed to initialize new skill system: " . e.Message)
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
            
            LogDebug("SkillConfigurator", Format("Configured skill {}: {} ({}ms-{}ms)", 
                skill, config.name, config.minInterval, config.maxInterval))
        }
        
        ; 自動化を再開
        if (wasActive) {
            StartSkillAutomation()
        }
        
        LogInfo("SkillConfigurator", Format("Skill configuration updated ({} skills)", 
            skillConfig.Count))
        return true
        
    } catch Error as e {
        LogError("SkillConfigurator", "Failed to configure skills: " . e.Message)
        return false
    }
}