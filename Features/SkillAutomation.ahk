; ===================================================================
; スキル自動化システム
; E, R, T, 4キーの自動実行管理
; ===================================================================

; --- スキル自動化の開始 ---
StartSkillAutomation() {
    ; E, R キー (1秒間隔)
    StartManagedTimer("SkillE", PressEKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
    StartManagedTimer("SkillR", PressRKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
    
    ; T キー (4秒間隔)
    StartManagedTimer("SkillT", PressTKey, Random(TIMING_SKILL_T.min, TIMING_SKILL_T.max))
    
    ; 4 キー (Wine of the Prophet - 動的間隔)
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
    
    Send(KEY_SKILL_E)
    StartManagedTimer("SkillE", PressEKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
    
    LogDebug("SkillAutomation", "E key pressed")
}

; --- R キー押下 ---
PressRKey() {
    global g_macro_active, KEY_SKILL_R
    
    if (!g_macro_active) {
        StopManagedTimer("SkillR")
        return
    }
    
    Send(KEY_SKILL_R)
    StartManagedTimer("SkillR", PressRKey, Random(TIMING_SKILL_ER.min, TIMING_SKILL_ER.max))
    
    LogDebug("SkillAutomation", "R key pressed")
}

; --- T キー押下 ---
PressTKey() {
    global g_macro_active, KEY_SKILL_T
    
    if (!g_macro_active) {
        StopManagedTimer("SkillT")
        return
    }
    
    Send(KEY_SKILL_T)
    StartManagedTimer("SkillT", PressTKey, Random(TIMING_SKILL_T.min, TIMING_SKILL_T.max))
    
    LogDebug("SkillAutomation", "T key pressed")
}

; --- 4キーループ（Wine of the Prophet） ---
Loop4Key() {
    global g_macro_active, g_macro_start_time, KEY_WINE_PROPHET
    
    if (!g_macro_active) {
        StopManagedTimer("WineOfProphet")
        return
    }
    
    Send(KEY_WINE_PROPHET)
    
    ; 使用間隔の動的調整
    elapsedTime := A_TickCount - g_macro_start_time
    delay := CalculateWineDelay(elapsedTime)
    
    StartManagedTimer("WineOfProphet", Loop4Key, delay)
    
    LogDebug("SkillAutomation", Format("Wine of Prophet used. Next in {}ms (elapsed: {}s)", 
        delay, Round(elapsedTime/1000)))
}

; --- Wine of the Prophet遅延計算 ---
CalculateWineDelay(elapsedTime) {
    ; 時間経過に応じた段階的な調整
    if (elapsedTime < 60000) {          ; 60秒未満
        return Random(22000, 22500)
    } else if (elapsedTime < 90000) {   ; 90秒未満
        return Random(19500, 20000)
    } else if (elapsedTime < 120000) {  ; 120秒未満
        return Random(17500, 18000)
    } else if (elapsedTime < 170000) {  ; 170秒未満
        return Random(16000, 16500)
    } else {                             ; 170秒以上
        return Random(14500, 15000)
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
    ; 例：
    ; skillConfig := {
    ;     E: {enabled: true, interval: 1000, key: "E"},
    ;     R: {enabled: true, interval: 1000, key: "R"},
    ;     T: {enabled: true, interval: 4000, key: "T"},
    ;     Custom1: {enabled: false, interval: 2000, key: "Q"}
    ; }
    
    ; TODO: 実装予定
    LogInfo("SkillAutomation", "Custom skill configuration not yet implemented")
}