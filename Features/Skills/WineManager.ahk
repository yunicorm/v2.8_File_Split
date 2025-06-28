; ===================================================================
; Wine of the Prophet 専用管理
; Wine of the Prophetの動的タイミング管理とステージ制御
; ===================================================================

; --- グローバル変数 ---
global g_wine_stage_start_time := 0
global g_wine_current_stage := 0

; --- Wine システム初期化 ---
InitializeWineSystem() {
    global g_macro_start_time, g_wine_stage_start_time, g_wine_current_stage
    
    g_wine_stage_start_time := g_macro_start_time
    g_wine_current_stage := 0
    
    LogDebug("WineManager", "Wine system initialized")
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
            LogInfo("WineManager", Format("Wine of the Prophet entered stage {} ({}ms delay)", 
                stageInfo.stage, stageInfo.avgDelay))
        }
        
        ; 次の使用をスケジュール
        config := g_skill_configs["Wine"]
        nextDelay := Random(stageInfo.minDelay, stageInfo.maxDelay)
        ScheduleNextSkillExecution("Wine", config, nextDelay)
        
        LogDebug("WineManager", Format("Wine used at stage {} ({}s elapsed), next in {}ms", 
            stageInfo.stage, Round(elapsedTime/1000), nextDelay))
        
    } catch as e {
        g_skill_stats["4"].errors++
        LogError("WineManager", "Failed to use Wine of Prophet: " . e.Message)
        
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

; --- Wineステージ統計の取得 ---
GetWineStageStats() {
    global g_wine_current_stage, g_wine_stage_start_time, g_macro_start_time
    
    elapsedTime := A_TickCount - g_macro_start_time
    stageElapsedTime := A_TickCount - g_wine_stage_start_time
    currentStageInfo := GetCurrentWineStage(elapsedTime)
    
    return {
        currentStage: g_wine_current_stage,
        totalElapsedTime: elapsedTime,
        stageElapsedTime: stageElapsedTime,
        stageMinDelay: currentStageInfo.minDelay,
        stageMaxDelay: currentStageInfo.maxDelay,
        stageAvgDelay: currentStageInfo.avgDelay,
        nextStageTime: currentStageInfo.maxTime - elapsedTime
    }
}

; --- Wine設定の動的更新 ---
UpdateWineConfiguration(wineConfig) {
    global g_skill_configs
    
    try {
        ; Wine設定を更新
        if (g_skill_configs.Has("Wine")) {
            config := g_skill_configs["Wine"]
            
            ; 動的タイミングが有効な場合のみ設定を適用
            if (wineConfig.HasOwnProp("dynamicTiming") && wineConfig.dynamicTiming) {
                config.isDynamic := true
                LogInfo("WineManager", "Dynamic Wine timing enabled")
            } else {
                config.isDynamic := false
                ; 固定間隔の場合
                if (wineConfig.HasOwnProp("fixedInterval")) {
                    config.minInterval := wineConfig.fixedInterval
                    config.maxInterval := wineConfig.fixedInterval
                    LogInfo("WineManager", Format("Fixed Wine timing set to {}ms", wineConfig.fixedInterval))
                }
            }
            
            g_skill_configs["Wine"] := config
            return true
        }
        
        return false
        
    } catch as e {
        LogError("WineManager", "Failed to update Wine configuration: " . e.Message)
        return false
    }
}

; --- Wineタイマーのリセット ---
ResetWineTimer() {
    global g_wine_stage_start_time, g_wine_current_stage, g_macro_start_time
    
    try {
        ; Wineステージをリセット
        g_wine_stage_start_time := g_macro_start_time
        g_wine_current_stage := 0
        
        ; Wineタイマーを再開始
        if (g_skill_configs.Has("Wine") && g_skill_enabled["Wine"]) {
            StopSkillTimer("Wine")
            Sleep(100)
            StartSkillTimer("Wine", g_skill_configs["Wine"])
            LogInfo("WineManager", "Wine timer reset to stage 1")
        }
        
        return true
        
    } catch as e {
        LogError("WineManager", "Failed to reset Wine timer: " . e.Message)
        return false
    }
}