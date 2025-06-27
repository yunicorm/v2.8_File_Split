; ===================================================================
; スキル自動化システム（設定対応版）
; E, R, T, 4キーの自動実行管理
; ===================================================================

; --- スキル自動化の開始 ---
StartSkillAutomation() {
    ; E, R キー
    StartManagedTimer("SkillE", PressEKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
    StartManagedTimer("SkillR", PressRKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
    
    ; T キー
    StartManagedTimer("SkillT", PressTKey, Random(TIMING_SKILL_T.min, TIMING_SKILL_T.max))
    
    ; 4 キー (Wine of the Prophet)
    StartManagedTimer("WineOfProphet", Loop4Key, 100)
    
    LogInfo("SkillAutomation", "Skill automation started")
}

; --- E キー押下 ---
PressEKey() {
    global g_macro_active, KEY_SKILL_E
    
    if (!g_macro_active) {
        StopManagedTimer("SkillE")
        return
    }
    
    try {
        Send(KEY_SKILL_E)
        StartManagedTimer("SkillE", PressEKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
        UpdateSkillStats("E")
        LogDebug("SkillAutomation", "E key pressed")
    } catch Error as e {
        LogError("SkillAutomation", "Failed to press E key: " . e.Message)
    }
}

; --- R キー押下 ---
PressRKey() {
    global g_macro_active, KEY_SKILL_R
    
    if (!g_macro_active) {
        StopManagedTimer("SkillR")
        return
    }
    
    try {
        Send(KEY_SKILL_R)
        StartManagedTimer("SkillR", PressRKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
        UpdateSkillStats("R")
        LogDebug("SkillAutomation", "R key pressed")
    } catch Error as e {
        LogError("SkillAutomation", "Failed to press R key: " . e.Message)
    }
}

; --- T キー押下 ---
PressTKey() {
    global g_macro_active, KEY_SKILL_T
    
    if (!g_macro_active) {
        StopManagedTimer("SkillT")
        return
    }
    
    try {
        Send(KEY_SKILL_T)
        StartManagedTimer("SkillT", PressTKey, Random(TIMING_SKILL_T.min, TIMING_SKILL_T.max))
        UpdateSkillStats("T")
        LogDebug("SkillAutomation", "T key pressed")
    } catch Error as e {
        LogError("SkillAutomation", "Failed to press T key: " . e.Message)
    }
}

; --- 4キーループ（Wine of the Prophet） ---
Loop4Key() {
    global g_macro_active, g_macro_start_time, KEY_WINE_PROPHET
    
    if (!g_macro_active) {
        StopManagedTimer("WineOfProphet")
        return
    }
    
    try {
        Send(KEY_WINE_PROPHET)
        UpdateSkillStats("4")
        
        ; 使用間隔の動的調整
        elapsedTime := A_TickCount - g_macro_start_time
        delay := CalculateWineDelayFromConfig(elapsedTime)
        
        StartManagedTimer("WineOfProphet", Loop4Key, delay)
        
        LogDebug("SkillAutomation", Format("Wine of Prophet used. Next in {}ms (elapsed: {}s)", 
            delay, Round(elapsedTime/1000)))
    } catch Error as e {
        LogError("SkillAutomation", "Failed to use Wine of Prophet: " . e.Message)
    }
}

; --- Wine of the Prophet遅延計算（設定ベース） ---
CalculateWineDelayFromConfig(elapsedTime) {
    ; 設定から段階を読み込み
    stage1Time := ConfigManager.Get("Wine", "Stage1_Time", 60000)
    stage2Time := ConfigManager.Get("Wine", "Stage2_Time", 90000)
    stage3Time := ConfigManager.Get("Wine", "Stage3_Time", 120000)
    stage4Time := ConfigManager.Get("Wine", "Stage4_Time", 170000)
    
    if (elapsedTime < stage1Time) {
        return Random(
            ConfigManager.Get("Wine", "Stage1_Min", 22000),
            ConfigManager.Get("Wine", "Stage1_Max", 22500)
        )
    } else if (elapsedTime < stage2Time) {
        return Random(
            ConfigManager.Get("Wine", "Stage2_Min", 19500),
            ConfigManager.Get("Wine", "Stage2_Max", 20000)
        )
    } else if (elapsedTime < stage3Time) {
        return Random(
            ConfigManager.Get("Wine", "Stage3_Min", 17500),
            ConfigManager.Get("Wine", "Stage3_Max", 18000)
        )
    } else if (elapsedTime < stage4Time) {
        return Random(
            ConfigManager.Get("Wine", "Stage4_Min", 16000),
            ConfigManager.Get("Wine", "Stage4_Max", 16500)
        )
    } else {
        return Random(
            ConfigManager.Get("Wine", "Stage5_Min", 14500),
            ConfigManager.Get("Wine", "Stage5_Max", 15000)
        )
    }
}

; --- スキル自動化の停止 ---
StopSkillAutomation() {
    StopManagedTimer("SkillE")
    StopManagedTimer("SkillR")
    StopManagedTimer("SkillT")
    StopManagedTimer("WineOfProphet")
    
    LogInfo("SkillAutomation", "Skill automation stopped")
}

; --- スキル統計（デバッグ用） ---
global g_skill_stats := Map()
g_skill_stats["E"] := {count: 0, lastUse: 0}
g_skill_stats["R"] := {count: 0, lastUse: 0}
g_skill_stats["T"] := {count: 0, lastUse: 0}
g_skill_stats["4"] := {count: 0, lastUse: 0}

UpdateSkillStats(skill) {
    global g_skill_stats
    
    if (g_skill_stats.Has(skill)) {
        g_skill_stats[skill].count++
        g_skill_stats[skill].lastUse := A_TickCount
    }
}

GetSkillStats() {
    global g_skill_stats
    return g_skill_stats
}

; --- カスタムスキル設定（将来の拡張用） ---
ConfigureSkills(skillConfig) {
    ; TODO: 実装予定
    LogInfo("SkillAutomation", "Custom skill configuration not yet implemented")
}