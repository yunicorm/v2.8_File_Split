; ===================================================================
; SkillAutomation分割後テスト
; 基本動作、Wine動作、統計機能の包括的テスト
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; テスト用のミニマル設定
global g_skill_configs := Map()
global g_skill_enabled := Map()
global g_skill_timers := Map()
global g_skill_last_use := Map()
global g_skill_stats := Map()
global g_macro_active := false
global g_macro_start_time := 0
global g_wine_stage_start_time := 0
global g_wine_current_stage := 0

; テスト用の基本設定
KEY_SKILL_E := "e"
KEY_SKILL_R := "r"
KEY_SKILL_T := "t"
KEY_WINE_PROPHET := "4"

TIMING_SKILL_ER := {min: 1000, max: 2000}
TIMING_SKILL_T := {min: 2000, max: 3000}

; 基本的なLogger関数をシミュレート
LogInfo(module, message) {
    OutputDebug("[INFO] [" . module . "] " . message)
}

LogDebug(module, message) {
    OutputDebug("[DEBUG] [" . module . "] " . message)
}

LogWarn(module, message) {
    OutputDebug("[WARN] [" . module . "] " . message)
}

LogError(module, message) {
    OutputDebug("[ERROR] [" . module . "] " . message)
}

; 分割されたSkillAutomationモジュールをインクルード
#Include "Features/Skills/SkillController.ahk"
#Include "Features/Skills/SkillConfigurator.ahk"
#Include "Features/Skills/WineManager.ahk"
#Include "Features/Skills/SkillStatistics.ahk"
#Include "Features/Skills/SkillHelpers.ahk"

; ===================================================================
; テスト関数
; ===================================================================

; 1. 基本動作テスト - スキル自動化開始/停止
TestBasicStartStop() {
    OutputDebug("=== TEST 1: Basic Start/Stop ===")
    
    try {
        ; 開始前の状態確認
        OutputDebug("Before start - macro_active: " . g_macro_active)
        
        ; スキル自動化開始テスト
        g_macro_active := true
        g_macro_start_time := A_TickCount
        StartSkillAutomation()
        
        OutputDebug("After StartSkillAutomation - timers count: " . g_skill_timers.Count)
        
        ; 少し待機
        Sleep(1000)
        
        ; 停止テスト
        StopAllSkills()
        OutputDebug("After StopAllSkills - timers should be stopped")
        
        OutputDebug("TEST 1 PASSED")
        return true
        
    } catch as e {
        OutputDebug("TEST 1 FAILED: " . e.Message)
        return false
    }
}

; 2. 基本動作テスト - 各スキルの個別実行
TestIndividualSkills() {
    OutputDebug("=== TEST 2: Individual Skills ===")
    
    try {
        ; 統計初期化
        InitializeSkillStats()
        
        ; 各スキルの手動実行テスト
        skills := ["E", "R", "T"]
        for skill in skills {
            result := ManualExecuteSkill(skill)
            OutputDebug("Manual execute " . skill . ": " . (result ? "SUCCESS" : "FAILED"))
            
            if (!result) {
                OutputDebug("TEST 2 FAILED at skill: " . skill)
                return false
            }
        }
        
        OutputDebug("TEST 2 PASSED")
        return true
        
    } catch as e {
        OutputDebug("TEST 2 FAILED: " . e.Message)
        return false
    }
}

; 3. Wine動作テスト - Wine of the Prophet実行
TestWineExecution() {
    OutputDebug("=== TEST 3: Wine Execution ===")
    
    try {
        ; Wine系初期化
        InitializeWineSystem()
        
        ; Wine of the Prophet実行テスト
        g_macro_active := true
        g_skill_enabled["Wine"] := true
        
        ExecuteWineOfProphet()
        OutputDebug("Wine executed successfully")
        
        ; 実行後の状態確認
        OutputDebug("Wine last use: " . g_skill_last_use.Get("Wine", "N/A"))
        OutputDebug("Wine current stage: " . g_wine_current_stage)
        
        OutputDebug("TEST 3 PASSED")
        return true
        
    } catch as e {
        OutputDebug("TEST 3 FAILED: " . e.Message)
        return false
    }
}

; 4. Wine動作テスト - ステージ遷移確認
TestWineStages() {
    OutputDebug("=== TEST 4: Wine Stages ===")
    
    try {
        ; 異なる経過時間でのステージテスト
        testTimes := [0, 10000, 30000, 60000, 120000]  ; 0s, 10s, 30s, 1m, 2m
        
        for time in testTimes {
            stageInfo := GetCurrentWineStage(time)
            OutputDebug("Time: " . time . "ms -> Stage: " . stageInfo.stage . ", Delay: " . stageInfo.avgDelay . "ms")
        }
        
        OutputDebug("TEST 4 PASSED")
        return true
        
    } catch as e {
        OutputDebug("TEST 4 FAILED: " . e.Message)
        return false
    }
}

; 5. 統計機能テスト - 統計初期化
TestStatsInitialization() {
    OutputDebug("=== TEST 5: Stats Initialization ===")
    
    try {
        ; 統計初期化
        InitializeSkillStats()
        
        ; 初期化確認
        skills := ["E", "R", "T", "4"]
        for skill in skills {
            if (!g_skill_stats.Has(skill)) {
                OutputDebug("TEST 5 FAILED: Missing stats for " . skill)
                return false
            }
            
            stats := g_skill_stats[skill]
            OutputDebug("Stats for " . skill . " - count: " . stats.count . ", errors: " . stats.errors)
        }
        
        OutputDebug("TEST 5 PASSED")
        return true
        
    } catch as e {
        OutputDebug("TEST 5 FAILED: " . e.Message)
        return false
    }
}

; 6. 統計機能テスト - 統計更新・パフォーマンス監視
TestStatsUpdate() {
    OutputDebug("=== TEST 6: Stats Update ===")
    
    try {
        ; 統計更新テスト
        UpdateSkillStats("E")
        Sleep(100)
        UpdateSkillStats("E")  ; 2回目で遅延計算
        
        stats := g_skill_stats["E"]
        OutputDebug("E stats - count: " . stats.count . ", avgDelay: " . stats.avgDelay)
        
        if (stats.count != 2) {
            OutputDebug("TEST 6 FAILED: Expected count 2, got " . stats.count)
            return false
        }
        
        ; パフォーマンス統計取得テスト
        perfStats := GetSkillPerformanceStats()
        OutputDebug("Performance stats collected: " . perfStats.Count . " skills")
        
        OutputDebug("TEST 6 PASSED")
        return true
        
    } catch as e {
        OutputDebug("TEST 6 FAILED: " . e.Message)
        return false
    }
}

; 7. エラーハンドリングテスト
TestErrorHandling() {
    OutputDebug("=== TEST 7: Error Handling ===")
    
    try {
        ; 無効なスキル実行テスト
        result := ManualExecuteSkill("INVALID_SKILL")
        if (result) {
            OutputDebug("TEST 7 FAILED: Invalid skill should return false")
            return false
        }
        
        ; 無効な統計更新テスト（これは新しい統計を作成するはず）
        UpdateSkillStats("NEW_SKILL")
        if (!g_skill_stats.Has("NEW_SKILL")) {
            OutputDebug("TEST 7 FAILED: New skill stats should be created")
            return false
        }
        
        OutputDebug("TEST 7 PASSED")
        return true
        
    } catch as e {
        OutputDebug("TEST 7 FAILED: " . e.Message)
        return false
    }
}

; ===================================================================
; メインテスト実行
; ===================================================================

RunAllTests() {
    OutputDebug("=== SkillAutomation Split Test Suite ===")
    
    tests := [
        {name: "Basic Start/Stop", func: TestBasicStartStop},
        {name: "Individual Skills", func: TestIndividualSkills},
        {name: "Wine Execution", func: TestWineExecution},
        {name: "Wine Stages", func: TestWineStages},
        {name: "Stats Initialization", func: TestStatsInitialization},
        {name: "Stats Update", func: TestStatsUpdate},
        {name: "Error Handling", func: TestErrorHandling}
    ]
    
    passed := 0
    failed := 0
    
    for test in tests {
        OutputDebug("Running: " . test.name)
        if (test.func()) {
            passed++
            OutputDebug("✓ " . test.name . " PASSED")
        } else {
            failed++
            OutputDebug("✗ " . test.name . " FAILED")
        }
        OutputDebug("")
    }
    
    OutputDebug("=== TEST RESULTS ===")
    OutputDebug("Passed: " . passed)
    OutputDebug("Failed: " . failed)
    OutputDebug("Total: " . (passed + failed))
    
    if (failed == 0) {
        OutputDebug("🎉 ALL TESTS PASSED! SkillAutomation split is successful!")
    } else {
        OutputDebug("❌ Some tests failed. Check the implementation.")
    }
}

; テスト実行のホットキー
F9::RunAllTests()

; スクリプト開始時にテスト実行
RunAllTests()

; 終了用ホットキー
Esc::ExitApp()