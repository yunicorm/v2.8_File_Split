; ===================================================================
; SkillAutomation分割後 簡単テスト
; 必要最小限の依存関係でテスト実行
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; テスト結果を保存
testResults := []

; ミニマルなMockを作成
CreateMockEnvironment() {
    ; グローバル変数の初期化
    global g_skill_configs := Map()
    global g_skill_enabled := Map()
    global g_skill_timers := Map()
    global g_skill_last_use := Map()
    global g_skill_stats := Map()
    global g_macro_active := false
    global g_macro_start_time := 0
    global g_wine_stage_start_time := 0
    global g_wine_current_stage := 0
    
    ; 設定定数
    global KEY_SKILL_E := "e"
    global KEY_SKILL_R := "r"
    global KEY_SKILL_T := "t"
    global KEY_WINE_PROPHET := "4"
    
    global TIMING_SKILL_ER := {min: 1000, max: 2000}
    global TIMING_SKILL_T := {min: 2000, max: 3000}
}

; Mock関数
LogInfo(module, message) {
    testResults.Push("[INFO] " . module . ": " . message)
}

LogDebug(module, message) {
    testResults.Push("[DEBUG] " . module . ": " . message)
}

LogWarn(module, message) {
    testResults.Push("[WARN] " . module . ": " . message)
}

LogError(module, message) {
    testResults.Push("[ERROR] " . module . ": " . message)
}

; Mock TimerManager関数
StartManagedTimer(name, callback, delay) {
    testResults.Push("[TIMER] Started: " . name . " with delay: " . delay)
    return true
}

StopManagedTimer(name) {
    testResults.Push("[TIMER] Stopped: " . name)
    return true
}

; Mock Send関数
Send(key) {
    testResults.Push("[SEND] Key: " . key)
}

; 個別テスト関数
TestSkillConfigurator() {
    testResults.Push("=== TEST: SkillConfigurator ===")
    
    try {
        ; SkillConfiguratorのみをテスト
        source := FileRead("Features/Skills/SkillConfigurator.ahk")
        
        ; InitializeSkillConfigs関数が存在するかチェック
        if (InStr(source, "InitializeSkillConfigs()")) {
            testResults.Push("✓ InitializeSkillConfigs function found")
        } else {
            testResults.Push("✗ InitializeSkillConfigs function missing")
            return false
        }
        
        ; InitializeNewSkillSystem関数が存在するかチェック
        if (InStr(source, "InitializeNewSkillSystem()")) {
            testResults.Push("✓ InitializeNewSkillSystem function found")
        } else {
            testResults.Push("✗ InitializeNewSkillSystem function missing")
            return false
        }
        
        testResults.Push("✓ SkillConfigurator structure test PASSED")
        return true
        
    } catch Error as e {
        testResults.Push("✗ SkillConfigurator test FAILED: " . e.Message)
        return false
    }
}

TestSkillController() {
    testResults.Push("=== TEST: SkillController ===")
    
    try {
        source := FileRead("Features/Skills/SkillController.ahk")
        
        ; 主要関数の存在確認
        functions := ["StartSkillAutomation", "StartNewSkillAutomation", "StartSkillTimer", "ExecuteSkill"]
        
        for func in functions {
            if (InStr(source, func . "()")) {
                testResults.Push("✓ " . func . " function found")
            } else {
                testResults.Push("✗ " . func . " function missing")
                return false
            }
        }
        
        testResults.Push("✓ SkillController structure test PASSED")
        return true
        
    } catch Error as e {
        testResults.Push("✗ SkillController test FAILED: " . e.Message)
        return false
    }
}

TestWineManager() {
    testResults.Push("=== TEST: WineManager ===")
    
    try {
        source := FileRead("Features/Skills/WineManager.ahk")
        
        ; Wine関連関数の存在確認
        functions := ["InitializeWineSystem", "ExecuteWineOfProphet", "GetCurrentWineStage"]
        
        for func in functions {
            if (InStr(source, func . "()")) {
                testResults.Push("✓ " . func . " function found")
            } else {
                testResults.Push("✗ " . func . " function missing")
                return false
            }
        }
        
        ; Wine設定の存在確認
        if (InStr(source, "WINE_TIMING_STAGES")) {
            testResults.Push("✓ WINE_TIMING_STAGES configuration found")
        } else {
            testResults.Push("✗ WINE_TIMING_STAGES configuration missing")
        }
        
        testResults.Push("✓ WineManager structure test PASSED")
        return true
        
    } catch Error as e {
        testResults.Push("✗ WineManager test FAILED: " . e.Message)
        return false
    }
}

TestSkillStatistics() {
    testResults.Push("=== TEST: SkillStatistics ===")
    
    try {
        source := FileRead("Features/Skills/SkillStatistics.ahk")
        
        ; 統計関数の存在確認
        functions := ["InitializeSkillStats", "UpdateSkillStats", "GetSkillPerformanceStats"]
        
        for func in functions {
            if (InStr(source, func . "()")) {
                testResults.Push("✓ " . func . " function found")
            } else {
                testResults.Push("✗ " . func . " function missing")
                return false
            }
        }
        
        testResults.Push("✓ SkillStatistics structure test PASSED")
        return true
        
    } catch Error as e {
        testResults.Push("✗ SkillStatistics test FAILED: " . e.Message)
        return false
    }
}

TestSkillHelpers() {
    testResults.Push("=== TEST: SkillHelpers ===")
    
    try {
        source := FileRead("Features/Skills/SkillHelpers.ahk")
        
        ; ヘルパー関数の存在確認
        functions := ["ManualExecuteSkill", "ManualStopAllSkills", "Array2String"]
        
        for func in functions {
            if (InStr(source, func . "(")) {
                testResults.Push("✓ " . func . " function found")
            } else {
                testResults.Push("✗ " . func . " function missing")
                return false
            }
        }
        
        testResults.Push("✓ SkillHelpers structure test PASSED")
        return true
        
    } catch Error as e {
        testResults.Push("✗ SkillHelpers test FAILED: " . e.Message)
        return false
    }
}

TestMainIntegration() {
    testResults.Push("=== TEST: Main Integration ===")
    
    try {
        mainSource := FileRead("Features/SkillAutomation.ahk")
        
        ; インクルードの存在確認
        includes := [
            "Features/Skills/SkillController.ahk",
            "Features/Skills/SkillConfigurator.ahk", 
            "Features/Skills/WineManager.ahk",
            "Features/Skills/SkillStatistics.ahk",
            "Features/Skills/SkillHelpers.ahk"
        ]
        
        for include in includes {
            if (InStr(mainSource, include)) {
                testResults.Push("✓ Include found: " . include)
            } else {
                testResults.Push("✗ Include missing: " . include)
                return false
            }
        }
        
        testResults.Push("✓ Main integration test PASSED")
        return true
        
    } catch Error as e {
        testResults.Push("✗ Main integration test FAILED: " . e.Message)
        return false
    }
}

; 全テスト実行
RunAllTests() {
    CreateMockEnvironment()
    
    testResults.Push("=== SkillAutomation Split Verification Test ===")
    testResults.Push("Testing file structure and function existence...")
    testResults.Push("")
    
    tests := [
        {name: "SkillConfigurator", func: TestSkillConfigurator},
        {name: "SkillController", func: TestSkillController},
        {name: "WineManager", func: TestWineManager},
        {name: "SkillStatistics", func: TestSkillStatistics},
        {name: "SkillHelpers", func: TestSkillHelpers},
        {name: "Main Integration", func: TestMainIntegration}
    ]
    
    passed := 0
    failed := 0
    
    for test in tests {
        if (test.func()) {
            passed++
        } else {
            failed++
        }
        testResults.Push("")
    }
    
    testResults.Push("=== TEST RESULTS ===")
    testResults.Push("Passed: " . passed)
    testResults.Push("Failed: " . failed)
    testResults.Push("Total: " . (passed + failed))
    
    if (failed == 0) {
        testResults.Push("🎉 ALL TESTS PASSED! SkillAutomation split is structurally sound!")
    } else {
        testResults.Push("❌ Some tests failed. Check the file structure.")
    }
    
    ; 結果をファイルに出力
    resultText := ""
    for result in testResults {
        resultText .= result . "`n"
    }
    
    try {
        FileAppend(resultText, "skill_automation_test_results.txt")
        testResults.Push("`nResults saved to: skill_automation_test_results.txt")
    } catch {
        testResults.Push("`nFailed to save results to file")
    }
    
    ; コンソールに出力
    for result in testResults {
        OutputDebug(result)
    }
}

; F9キーでテスト実行
F9::RunAllTests()

; 自動実行
RunAllTests()

; ESCで終了
Esc::ExitApp()