; ===================================================================
; FlaskManager分割後 包括的テスト
; 基本動作、チャージ管理、条件判定、設定管理、統計機能の全テスト
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; テスト結果格納
global testResults := []
global testsPassed := 0
global testsFailed := 0

; ミニマル環境の構築
CreateMockEnvironment() {
    ; グローバル変数の初期化（分割前の完全なセット）
    global g_flask_timer_handles := Map()
    global g_flask_automation_paused := false
    global g_flask_active_flasks := Map()
    global g_flask_charge_tracker := Map()
    global g_flask_configs := Map()
    global g_flask_use_count := Map()
    global g_flask_last_use_time := Map()
    global g_flask_stats := {
        totalUses: 0,
        averageInterval: 0,
        lastResetTime: A_TickCount,
        errors: 0,
        successRate: 100
    }
    
    ; マクロ状態
    global g_macro_active := true
    global g_flask_timer_active := false
    
    ; 設定定数
    global KEY_MANA_FLASK := "2"
    global TIMING_FLASK := {min: 3000, max: 3500}
    
    ; モック ConfigManager
    global ConfigManager := {
        Get: (section, key, default) => {
            switch section . "." . key {
                case "Flask.Flask1_Enabled": return false
                case "Flask.Flask2_Enabled": return false
                case "Flask.Flask3_Enabled": return false
                case "Flask.Flask4_Enabled": return false
                case "Flask.Flask5_Enabled": return false
                default: return default
            }
        }
    }
}

; Mock関数群
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

StartManagedTimer(name, callback, delay) {
    testResults.Push("[TIMER] Started: " . name . " with delay: " . delay)
    return true
}

StopManagedTimer(name) {
    testResults.Push("[TIMER] Stopped: " . name)
    return true
}

StartPerfTimer(name) {
    testResults.Push("[PERF] Started: " . name)
}

EndPerfTimer(name, module) {
    testResults.Push("[PERF] Ended: " . name . " in " . module)
    return Random(5, 15) ; 5-15ms のモック実行時間
}

MockSend(key) {
    testResults.Push("[SEND] Key: " . key)
}

; テストヘルパー関数
TestStart(testName) {
    testResults.Push("=== TEST: " . testName . " ===")
}

TestPass(testName) {
    global testsPassed
    testsPassed++
    testResults.Push("✓ " . testName . " PASSED")
}

TestFail(testName, reason) {
    global testsFailed
    testsFailed++
    testResults.Push("✗ " . testName . " FAILED: " . reason)
}

; 分割されたFlaskManagerをインクルード
#Include "Features/Flask/FlaskController.ahk"
#Include "Features/Flask/FlaskChargeManager.ahk"
#Include "Features/Flask/FlaskConditions.ahk"
#Include "Features/Flask/FlaskConfiguration.ahk"
#Include "Features/Flask/FlaskStatistics.ahk"

; ===================================================================
; テスト関数群
; ===================================================================

; 1. 基本動作テスト - フラスコ自動化開始/停止
TestBasicStartStop() {
    TestStart("Basic Start/Stop")
    
    try {
        ; 開始前状態確認
        if (g_flask_timer_active) {
            TestFail("Basic Start/Stop", "Timer already active before start")
            return
        }
        
        ; フラスコ自動化開始
        StartFlaskAutomation()
        
        if (!g_flask_timer_active) {
            TestFail("Basic Start/Stop", "Timer not activated after StartFlaskAutomation")
            return
        }
        
        ; 停止テスト
        StopFlaskAutomation()
        
        if (g_flask_timer_active) {
            TestFail("Basic Start/Stop", "Timer still active after StopFlaskAutomation")
            return
        }
        
        TestPass("Basic Start/Stop")
        
    } catch as e {
        TestFail("Basic Start/Stop", e.Message)
    }
}

; 2. 基本動作テスト - 個別フラスコ実行・タイマー管理
TestIndividualFlasks() {
    TestStart("Individual Flask Execution")
    
    try {
        ; テスト用フラスコ設定
        testConfig := {
            key: "1",
            type: "test",
            minInterval: 1000,
            maxInterval: 1500,
            enabled: true,
            priority: 1,
            maxCharges: 0,
            chargePerUse: 0,
            chargeGainRate: 0
        }
        
        g_flask_configs["test"] := testConfig
        
        ; タイマー開始テスト
        result := StartFlaskTimer("test", testConfig)
        
        if (!result) {
            TestFail("Individual Flask Execution", "StartFlaskTimer returned false")
            return
        }
        
        if (!g_flask_timer_handles.Has("test")) {
            TestFail("Individual Flask Execution", "Timer handle not registered")
            return
        }
        
        ; UseFlask直接テスト
        useResult := UseFlask("test", testConfig)
        
        if (!useResult) {
            TestFail("Individual Flask Execution", "UseFlask returned false")
            return
        }
        
        ; 使用回数チェック
        if (!g_flask_use_count.Has("test") || g_flask_use_count["test"] < 1) {
            TestFail("Individual Flask Execution", "Use count not incremented")
            return
        }
        
        ; タイマー停止テスト
        StopFlaskTimer("test")
        
        if (g_flask_timer_handles.Has("test")) {
            TestFail("Individual Flask Execution", "Timer handle not removed after stop")
            return
        }
        
        TestPass("Individual Flask Execution")
        
    } catch as e {
        TestFail("Individual Flask Execution", e.Message)
    }
}

; 3. チャージ管理テスト
TestChargeManagement() {
    TestStart("Charge Management")
    
    try {
        ; チャージ設定付きフラスコ
        chargeConfig := {
            key: "3",
            type: "charge_test",
            minInterval: 2000,
            maxInterval: 2500,
            enabled: true,
            priority: 1,
            maxCharges: 60,
            chargePerUse: 20,
            chargeGainRate: 2.0
        }
        
        g_flask_configs["charge_test"] := chargeConfig
        
        ; チャージトラッカー初期化テスト
        InitializeChargeTracker()
        
        if (!g_flask_charge_tracker.Has("charge_test")) {
            TestFail("Charge Management", "Charge tracker not initialized")
            return
        }
        
        chargeInfo := g_flask_charge_tracker["charge_test"]
        if (chargeInfo.currentCharges != 60) {
            TestFail("Charge Management", "Initial charges incorrect: " . chargeInfo.currentCharges)
            return
        }
        
        ; チャージ消費テスト
        consumeResult := ConsumeFlaskCharges("charge_test", 20)
        if (!consumeResult) {
            TestFail("Charge Management", "Charge consumption failed")
            return
        }
        
        if (chargeInfo.currentCharges != 40) {
            TestFail("Charge Management", "Charges not consumed correctly: " . chargeInfo.currentCharges)
            return
        }
        
        ; チャージ獲得テスト
        gainResult := GainFlaskCharges("charge_test", 10)
        if (!gainResult) {
            TestFail("Charge Management", "Charge gain failed")
            return
        }
        
        if (chargeInfo.currentCharges != 50) {
            TestFail("Charge Management", "Charges not gained correctly: " . chargeInfo.currentCharges)
            return
        }
        
        ; チャージ検証テスト
        validResult := ValidateFlaskCharges("charge_test", 20)
        if (!validResult) {
            TestFail("Charge Management", "Charge validation failed for sufficient charges")
            return
        }
        
        invalidResult := ValidateFlaskCharges("charge_test", 60)
        if (invalidResult) {
            TestFail("Charge Management", "Charge validation passed for insufficient charges")
            return
        }
        
        TestPass("Charge Management")
        
    } catch as e {
        TestFail("Charge Management", e.Message)
    }
}

; 4. 条件判定テスト
TestConditionSystem() {
    TestStart("Condition System")
    
    try {
        ; 基本条件関数の存在確認
        conditionFunctions := [
            "GetHealthPercentage", "IsMoving", "CheckHealthPercentage",
            "GetManaPercentage", "GetEnergyShieldPercentage", "IsInCombat",
            "IsBossFight", "HasCurse", "IsBurning", "IsChilled",
            "IsShocked", "IsPoisoned", "IsBleeding"
        ]
        
        for funcName in conditionFunctions {
            if (!IsSet(funcName)) {
                TestFail("Condition System", "Function not defined: " . funcName)
                return
            }
        }
        
        ; 複合条件テスト
        lowHealthResult := IsLowHealth(70)
        if (Type(lowHealthResult) != "Integer") {
            TestFail("Condition System", "IsLowHealth did not return boolean")
            return
        }
        
        lowManaResult := IsLowMana(50)
        if (Type(lowManaResult) != "Integer") {
            TestFail("Condition System", "IsLowMana did not return boolean")
            return
        }
        
        dangerResult := IsInDanger()
        if (Type(dangerResult) != "Integer") {
            TestFail("Condition System", "IsInDanger did not return boolean")
            return
        }
        
        ; 条件関数登録システムテスト
        InitializeConditionHelpers()
        
        if (!g_condition_functions.Has("lowHealth")) {
            TestFail("Condition System", "Condition function registration failed")
            return
        }
        
        ; 条件評価テスト
        evalResult := EvaluateCondition("lowHealth", [80])
        if (Type(evalResult) != "Integer") {
            TestFail("Condition System", "Condition evaluation failed")
            return
        }
        
        TestPass("Condition System")
        
    } catch as e {
        TestFail("Condition System", e.Message)
    }
}

; 5. 設定管理テスト
TestConfigurationManagement() {
    TestStart("Configuration Management")
    
    try {
        ; カスタム設定テスト
        customConfig := Map(
            "flask1", {
                key: "1",
                type: "life",
                minInterval: 4000,
                maxInterval: 4500,
                enabled: true,
                priority: 1
            },
            "flask2", {
                key: "2",
                type: "mana",
                minInterval: 3500,
                maxInterval: 4000,
                enabled: true,
                priority: 2
            }
        )
        
        configResult := ConfigureFlasks(customConfig)
        if (!configResult) {
            TestFail("Configuration Management", "ConfigureFlasks failed")
            return
        }
        
        if (g_flask_configs.Count != 2) {
            TestFail("Configuration Management", "Flask count incorrect: " . g_flask_configs.Count)
            return
        }
        
        if (!g_flask_configs.Has("flask1")) {
            TestFail("Configuration Management", "Flask1 not configured")
            return
        }
        
        ; トグル機能テスト
        toggleResult := ToggleFlask("flask1", false)
        if (!toggleResult) {
            TestFail("Configuration Management", "ToggleFlask failed")
            return
        }
        
        if (g_flask_configs["flask1"].enabled) {
            TestFail("Configuration Management", "Flask not disabled by toggle")
            return
        }
        
        ; プリセットテスト
        presetResult := ApplyFlaskPreset("basic")
        if (!presetResult) {
            TestFail("Configuration Management", "Preset application failed")
            return
        }
        
        TestPass("Configuration Management")
        
    } catch as e {
        TestFail("Configuration Management", e.Message)
    }
}

; 6. 統計機能テスト
TestStatistics() {
    TestStart("Statistics System")
    
    try {
        ; 統計リセット
        ResetFlaskStats()
        
        if (g_flask_stats.totalUses != 0) {
            TestFail("Statistics System", "Stats not reset properly")
            return
        }
        
        ; 成功記録テスト
        RecordFlaskSuccess("test_flask")
        
        if (!g_flask_use_count.Has("test_flask") || g_flask_use_count["test_flask"] != 1) {
            TestFail("Statistics System", "Success not recorded")
            return
        }
        
        ; エラー記録テスト
        RecordFlaskError("test_flask", "test_error")
        
        if (g_flask_stats.errors != 1) {
            TestFail("Statistics System", "Error not recorded")
            return
        }
        
        ; 統計取得テスト
        stats := GetFlaskStats()
        if (!stats.HasOwnProp("totalUses")) {
            TestFail("Statistics System", "Stats missing totalUses")
            return
        }
        
        ; 詳細統計テスト
        g_flask_configs["test_flask"] := {
            key: "1",
            type: "test",
            minInterval: 1000,
            maxInterval: 1500,
            enabled: true,
            priority: 1,
            maxCharges: 0,
            chargePerUse: 0,
            chargeGainRate: 0
        }
        
        detailedStats := GetDetailedFlaskStats("test_flask")
        if (!detailedStats.HasOwnProp("uses")) {
            TestFail("Statistics System", "Detailed stats missing uses")
            return
        }
        
        ; 効率レポートテスト
        report := GenerateFlaskEfficiencyReport()
        if (report.Length < 5) {
            TestFail("Statistics System", "Efficiency report too short")
            return
        }
        
        TestPass("Statistics System")
        
    } catch as e {
        TestFail("Statistics System", e.Message)
    }
}

; 7. エラーハンドリングテスト
TestErrorHandling() {
    TestStart("Error Handling")
    
    try {
        ; 無効なフラスコ名でのテスト
        invalidResult := UseFlask("invalid_flask", {})
        if (invalidResult) {
            TestFail("Error Handling", "UseFlask should fail with invalid flask")
            return
        }
        
        ; 無効な設定でのテスト
        try {
            ConfigureFlasks("invalid_config")
            TestFail("Error Handling", "ConfigureFlasks should fail with invalid config")
            return
        } catch {
            ; 期待されるエラー
        }
        
        ; 存在しない条件関数テスト
        unknownCondition := EvaluateCondition("unknown_condition", [])
        if (unknownCondition) {
            TestFail("Error Handling", "Unknown condition should return false")
            return
        }
        
        ; チャージ不足での使用テスト
        insufficientResult := ConsumeFlaskCharges("nonexistent", 100)
        if (insufficientResult) {
            TestFail("Error Handling", "Charge consumption should fail for nonexistent flask")
            return
        }
        
        TestPass("Error Handling")
        
    } catch as e {
        TestFail("Error Handling", e.Message)
    }
}

; メインテスト実行
RunAllTests() {
    testResults.Push("=== FlaskManager Split Test Suite ===")
    testResults.Push("Testing all 5 split modules...")
    testResults.Push("")
    
    ; 環境初期化
    CreateMockEnvironment()
    
    ; 全テスト実行
    TestBasicStartStop()
    TestIndividualFlasks()
    TestChargeManagement()
    TestConditionSystem()
    TestConfigurationManagement()
    TestStatistics()
    TestErrorHandling()
    
    ; 結果サマリー
    testResults.Push("")
    testResults.Push("=== TEST RESULTS ===")
    testResults.Push("Passed: " . testsPassed)
    testResults.Push("Failed: " . testsFailed)
    testResults.Push("Total: " . (testsPassed + testsFailed))
    
    if (testsFailed == 0) {
        testResults.Push("🎉 ALL TESTS PASSED! FlaskManager split is successful!")
    } else {
        testResults.Push("❌ Some tests failed. Check the implementation.")
    }
    
    ; 結果出力
    outputText := ""
    for result in testResults {
        outputText .= result . "`n"
        OutputDebug(result)
    }
    
    ; ファイルに保存
    try {
        FileAppend(outputText, "flask_manager_test_results.txt")
        OutputDebug("Results saved to: flask_manager_test_results.txt")
    } catch {
        OutputDebug("Failed to save results")
    }
    
    ; メッセージボックスで結果表示
    MsgBox("FlaskManager split tests completed!`n`nPassed: " . testsPassed . "`nFailed: " . testsFailed . "`n`nSee debug output for details.", "Test Results")
}

; ホットキー
F9::RunAllTests()

; 自動実行
RunAllTests()

; 終了
Esc::ExitApp()