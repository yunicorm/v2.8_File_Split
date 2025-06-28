; ===================================================================
; SkillAutomation分割後 直接関数テスト
; 関数の動作を直接確認
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; 結果出力
results := []

; ミニマルなConfigManagerモック
class ConfigManager {
    static Get(section, key, default) {
        ; Wine設定のモック
        if (section == "Wine") {
            switch key {
                case "Stage1_Time": return 60000
                case "Stage1_Min": return 22000
                case "Stage1_Max": return 22500
                case "Stage2_Time": return 90000
                case "Stage2_Min": return 19500
                case "Stage2_Max": return 20000
                case "Stage3_Time": return 120000
                case "Stage3_Min": return 17500
                case "Stage3_Max": return 18000
                case "Stage4_Time": return 170000
                case "Stage4_Min": return 16000
                case "Stage4_Max": return 16500
                case "Stage5_Min": return 14500
                case "Stage5_Max": return 15000
                default: return default
            }
        }
        return default
    }
}

; ログ関数
LogInfo(module, msg) { results.Push("[INFO] " . module . ": " . msg) }
LogDebug(module, msg) { results.Push("[DEBUG] " . module . ": " . msg) }
LogWarn(module, msg) { results.Push("[WARN] " . module . ": " . msg) }
LogError(module, msg) { results.Push("[ERROR] " . module . ": " . msg) }

; WineManagerのGetCurrentWineStage関数をテスト
TestGetCurrentWineStage() {
    results.Push("=== Testing GetCurrentWineStage Function ===")
    
    ; GetCurrentWineStage関数を定義（WineManager.ahkから抜粋）
    GetCurrentWineStage(elapsedTime) {
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
                maxTime: 999999999,
                minDelay: ConfigManager.Get("Wine", "Stage5_Min", 14500),
                maxDelay: ConfigManager.Get("Wine", "Stage5_Max", 15000)
            }
        ]
        
        for stageInfo in stages {
            if (elapsedTime < stageInfo.maxTime) {
                stageInfo.avgDelay := Round((stageInfo.minDelay + stageInfo.maxDelay) / 2)
                return stageInfo
            }
        }
        
        return stages[5]
    }
    
    ; 異なる時間でテスト
    testTimes := [
        {time: 0, expectedStage: 1},
        {time: 30000, expectedStage: 1},  ; 30秒
        {time: 70000, expectedStage: 2},  ; 70秒
        {time: 100000, expectedStage: 3}, ; 100秒
        {time: 150000, expectedStage: 4}, ; 150秒
        {time: 200000, expectedStage: 5}  ; 200秒
    ]
    
    allPassed := true
    for test in testTimes {
        stageInfo := GetCurrentWineStage(test.time)
        if (stageInfo.stage == test.expectedStage) {
            results.Push("✓ Time " . test.time . "ms -> Stage " . stageInfo.stage . " (delay: " . stageInfo.avgDelay . "ms)")
        } else {
            results.Push("✗ Time " . test.time . "ms -> Expected stage " . test.expectedStage . ", got " . stageInfo.stage)
            allPassed := false
        }
    }
    
    return allPassed
}

; 統計初期化関数のテスト
TestInitializeSkillStats() {
    results.Push("=== Testing InitializeSkillStats Function ===")
    
    ; グローバル変数
    global g_skill_stats := Map()
    
    ; InitializeSkillStats関数を定義（SkillStatistics.ahkから抜粋）
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
        
        LogDebug("SkillStatistics", "Skill statistics initialized for legacy skills")
    }
    
    ; 初期化前の状態確認
    initialCount := g_skill_stats.Count
    results.Push("Before init - stats count: " . initialCount)
    
    ; 初期化実行
    InitializeSkillStats()
    
    ; 初期化後の状態確認
    afterCount := g_skill_stats.Count
    results.Push("After init - stats count: " . afterCount)
    
    ; 各スキルの統計確認
    expectedSkills := ["E", "R", "T", "4"]
    allPassed := true
    
    for skill in expectedSkills {
        if (g_skill_stats.Has(skill)) {
            stats := g_skill_stats[skill]
            results.Push("✓ " . skill . " stats: count=" . stats.count . ", errors=" . stats.errors)
        } else {
            results.Push("✗ Missing stats for skill: " . skill)
            allPassed := false
        }
    }
    
    return allPassed
}

; 統計更新関数のテスト
TestUpdateSkillStats() {
    results.Push("=== Testing UpdateSkillStats Function ===")
    
    ; UpdateSkillStats関数を定義（SkillStatistics.ahkから抜粋）
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
        
        if (stats.lastUse > 0) {
            delay := A_TickCount - stats.lastUse
            stats.totalDelay += delay
            stats.avgDelay := Round(stats.totalDelay / stats.count)
        }
        
        stats.lastUse := A_TickCount
        
        LogDebug("SkillStatistics", Format("Skill '{}' stats updated - count: {}, avgDelay: {}ms", 
            skill, stats.count, stats.avgDelay))
    }
    
    ; グローバル変数初期化
    global g_skill_last_use := Map()
    
    ; テスト実行
    UpdateSkillStats("TEST_SKILL")
    Sleep(100)  ; 少し待機
    UpdateSkillStats("TEST_SKILL")  ; 2回目で遅延計算
    
    if (g_skill_stats.Has("TEST_SKILL")) {
        stats := g_skill_stats["TEST_SKILL"]
        results.Push("✓ TEST_SKILL updated - count: " . stats.count . ", avgDelay: " . stats.avgDelay)
        return stats.count == 2
    } else {
        results.Push("✗ TEST_SKILL stats not created")
        return false
    }
}

; 配列をチェックする関数のテスト
TestArray2String() {
    results.Push("=== Testing Array2String Function ===")
    
    ; Array2String関数を定義（SkillHelpers.ahkから抜粋）
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
    
    ; テスト配列
    testArray := ["skill1", "skill2", "skill3"]
    result := Array2String(testArray)
    expected := "skill1,skill2,skill3"
    
    if (result == expected) {
        results.Push("✓ Array2String: '" . result . "' == '" . expected . "'")
        return true
    } else {
        results.Push("✗ Array2String: Expected '" . expected . "', got '" . result . "'")
        return false
    }
}

; メインテスト実行
RunDirectTests() {
    results.Push("=== SkillAutomation Direct Function Tests ===")
    results.Push("")
    
    tests := [
        {name: "GetCurrentWineStage", func: TestGetCurrentWineStage},
        {name: "InitializeSkillStats", func: TestInitializeSkillStats},
        {name: "UpdateSkillStats", func: TestUpdateSkillStats},
        {name: "Array2String", func: TestArray2String}
    ]
    
    passed := 0
    failed := 0
    
    for test in tests {
        if (test.func()) {
            results.Push("✓ " . test.name . " PASSED")
            passed++
        } else {
            results.Push("✗ " . test.name . " FAILED")
            failed++
        }
        results.Push("")
    }
    
    results.Push("=== DIRECT TEST RESULTS ===")
    results.Push("Passed: " . passed)
    results.Push("Failed: " . failed)
    results.Push("Total: " . (passed + failed))
    
    if (failed == 0) {
        results.Push("🎉 ALL DIRECT TESTS PASSED!")
    } else {
        results.Push("❌ Some direct tests failed.")
    }
    
    ; 結果を出力
    outputText := ""
    for result in results {
        outputText .= result . "`n"
        OutputDebug(result)
    }
    
    ; ファイルに保存
    try {
        FileAppend(outputText, "direct_function_test_results.txt")
        OutputDebug("Results saved to: direct_function_test_results.txt")
    } catch {
        OutputDebug("Failed to save results")
    }
    
    ; メッセージボックスで結果表示
    MsgBox("Direct function tests completed!`n`nPassed: " . passed . "`nFailed: " . failed . "`n`nSee debug output for details.", "Test Results")
}

; F9でテスト実行
F9::RunDirectTests()

; 自動実行
RunDirectTests()

; ESCで終了
Esc::ExitApp()