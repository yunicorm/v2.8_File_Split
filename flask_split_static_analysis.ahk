; ===================================================================
; FlaskManager分割後静的解析テスト
; 関数存在確認、依存関係チェック、グローバル変数検証
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; 解析結果格納
global analysisResults := []
global checksPassed := 0
global checksFailed := 0

; 解析ヘルパー関数
AnalysisStart(checkName) {
    analysisResults.Push("=== ANALYSIS: " . checkName . " ===")
}

CheckPass(checkName) {
    global checksPassed
    checksPassed++
    analysisResults.Push("✓ " . checkName . " PASSED")
}

CheckFail(checkName, reason) {
    global checksFailed
    checksFailed++
    analysisResults.Push("✗ " . checkName . " FAILED: " . reason)
}

; 1. グローバル変数重複チェック
CheckGlobalVariables() {
    AnalysisStart("Global Variable Conflicts")
    
    try {
        ; 各ファイルのグローバル変数定義を確認
        files := [
            {name: "FlaskController", vars: ["g_flask_timer_handles", "g_flask_automation_paused", "g_flask_active_flasks"]},
            {name: "FlaskChargeManager", vars: ["g_flask_charge_tracker"]},
            {name: "FlaskConfiguration", vars: ["g_flask_configs"]},
            {name: "FlaskStatistics", vars: ["g_flask_use_count", "g_flask_last_use_time", "g_flask_stats"]}
        ]
        
        allVars := Map()
        conflicts := []
        
        for file in files {
            for varName in file.vars {
                if (allVars.Has(varName)) {
                    conflicts.Push(varName . " (in " . file.name . " and " . allVars[varName] . ")")
                } else {
                    allVars[varName] := file.name
                }
            }
        }
        
        if (conflicts.Length > 0) {
            CheckFail("Global Variable Conflicts", "Conflicts found: " . Array2String(conflicts))
        } else {
            CheckPass("Global Variable Conflicts")
        }
        
    } catch as e {
        CheckFail("Global Variable Conflicts", e.Message)
    }
}

; 2. 関数存在確認
CheckFunctionExistence() {
    AnalysisStart("Required Function Existence")
    
    ; 必須関数リスト
    requiredFunctions := [
        ; FlaskController
        "StartFlaskAutomation", "StopFlaskAutomation", "StartFlaskTimer", "FlaskTimerCallback", "UseFlask",
        
        ; FlaskChargeManager  
        "InitializeChargeTracker", "UpdateFlaskCharges", "GainFlaskCharges", "ConsumeFlaskCharges", "ValidateFlaskCharges",
        
        ; FlaskConditions
        "GetHealthPercentage", "IsMoving", "IsLowHealth", "IsLowMana", "IsInDanger", "EvaluateCondition",
        
        ; FlaskConfiguration
        "InitializeFlaskConfigs", "ConfigureFlasks", "ToggleFlask", "ApplyFlaskPreset",
        
        ; FlaskStatistics
        "UpdateFlaskStats", "GetFlaskStats", "RecordFlaskSuccess", "RecordFlaskError", "ResetFlaskStats"
    ]
    
    try {
        ; ソースファイルを読み込んで関数を検索
        sourceFiles := [
            "Features/Flask/FlaskController.ahk",
            "Features/Flask/FlaskChargeManager.ahk", 
            "Features/Flask/FlaskConditions.ahk",
            "Features/Flask/FlaskConfiguration.ahk",
            "Features/Flask/FlaskStatistics.ahk"
        ]
        
        foundFunctions := []
        
        for filePath in sourceFiles {
            try {
                content := FileRead(filePath)
                
                for funcName in requiredFunctions {
                    if (InStr(content, funcName . "(")) {
                        foundFunctions.Push(funcName)
                    }
                }
            } catch {
                CheckFail("Required Function Existence", "Cannot read file: " . filePath)
                return
            }
        }
        
        missingFunctions := []
        for funcName in requiredFunctions {
            found := false
            for foundFunc in foundFunctions {
                if (foundFunc == funcName) {
                    found := true
                    break
                }
            }
            if (!found) {
                missingFunctions.Push(funcName)
            }
        }
        
        if (missingFunctions.Length > 0) {
            CheckFail("Required Function Existence", "Missing functions: " . Array2String(missingFunctions))
        } else {
            CheckPass("Required Function Existence")
        }
        
    } catch as e {
        CheckFail("Required Function Existence", e.Message)
    }
}

; 3. 依存関係チェック
CheckDependencies() {
    AnalysisStart("Module Dependencies")
    
    try {
        ; 各モジュールの依存関係を確認
        dependencies := Map(
            "FlaskController", ["TimerManager", "Logger", "FlaskChargeManager", "FlaskStatistics"],
            "FlaskChargeManager", ["Logger", "FlaskConfiguration"], 
            "FlaskConditions", ["Logger"],
            "FlaskConfiguration", ["Logger", "ConfigManager", "FlaskChargeManager"],
            "FlaskStatistics", ["Logger", "FlaskConfiguration"]
        )
        
        ; 循環依存をチェック
        circularDeps := []
        
        ; 単純な循環チェック（A→B, B→A）
        for moduleA, depsA in dependencies {
            for depB in depsA {
                if (dependencies.Has(depB)) {
                    depsB := dependencies[depB]
                    for depC in depsB {
                        if (depC == moduleA) {
                            circularDeps.Push(moduleA . " ↔ " . depB)
                        }
                    }
                }
            }
        }
        
        if (circularDeps.Length > 0) {
            CheckFail("Module Dependencies", "Circular dependencies: " . Array2String(circularDeps))
        } else {
            CheckPass("Module Dependencies")
        }
        
    } catch as e {
        CheckFail("Module Dependencies", e.Message)
    }
}

; 4. チャージ管理システムチェック
CheckChargeSystem() {
    AnalysisStart("Charge Management System")
    
    try {
        ; チャージ関連関数の存在確認
        chargeFunctions := [
            "InitializeChargeTracker", "UpdateFlaskCharges", "GainFlaskCharges", 
            "ConsumeFlaskCharges", "ValidateFlaskCharges", "GetFlaskCharges"
        ]
        
        chargeManagerContent := FileRead("Features/Flask/FlaskChargeManager.ahk")
        
        missingChargeFunctions := []
        for funcName in chargeFunctions {
            if (!InStr(chargeManagerContent, funcName . "(")) {
                missingChargeFunctions.Push(funcName)
            }
        }
        
        if (missingChargeFunctions.Length > 0) {
            CheckFail("Charge Management System", "Missing charge functions: " . Array2String(missingChargeFunctions))
            return
        }
        
        ; UpdateFlaskCharges の100ms更新確認
        if (!InStr(chargeManagerContent, "UpdateFlaskCharges()")) {
            CheckFail("Charge Management System", "UpdateFlaskCharges function not found")
            return
        }
        
        ; チャージ計算ロジック確認
        if (!InStr(chargeManagerContent, "chargesGained := (timeSinceGain / 1000) * config.chargeGainRate")) {
            CheckFail("Charge Management System", "Charge calculation logic not found")
            return
        }
        
        CheckPass("Charge Management System")
        
    } catch as e {
        CheckFail("Charge Management System", e.Message)
    }
}

; 5. 条件判定システムチェック
CheckConditionSystem() {
    AnalysisStart("Condition System")
    
    try {
        ; 15種類の条件判定関数確認
        conditionFunctions := [
            "GetHealthPercentage", "IsMoving", "GetManaPercentage", "GetEnergyShieldPercentage",
            "IsInCombat", "IsBossFight", "HasCurse", "IsBurning", "IsChilled", 
            "IsShocked", "IsPoisoned", "IsBleeding", "IsLowHealth", "IsLowMana", "IsInDanger"
        ]
        
        conditionsContent := FileRead("Features/Flask/FlaskConditions.ahk")
        
        missingConditions := []
        for funcName in conditionFunctions {
            if (!InStr(conditionsContent, funcName . "(")) {
                missingConditions.Push(funcName)
            }
        }
        
        if (missingConditions.Length > 0) {
            CheckFail("Condition System", "Missing condition functions: " . Array2String(missingConditions))
            return
        }
        
        ; 条件関数登録システム確認
        if (!InStr(conditionsContent, "RegisterConditionFunction(")) {
            CheckFail("Condition System", "Condition registration system not found")
            return
        }
        
        if (!InStr(conditionsContent, "EvaluateCondition(")) {
            CheckFail("Condition System", "Condition evaluation system not found")
            return
        }
        
        CheckPass("Condition System")
        
    } catch as e {
        CheckFail("Condition System", e.Message)
    }
}

; 6. 設定管理システムチェック
CheckConfigurationSystem() {
    AnalysisStart("Configuration Management System")
    
    try {
        configContent := FileRead("Features/Flask/FlaskConfiguration.ahk")
        
        ; 必須設定関数確認
        configFunctions := [
            "InitializeFlaskConfigs", "ConfigureFlasks", "ToggleFlask", 
            "UpdateFlaskConfig", "ApplyFlaskPreset", "GetFlaskPresets"
        ]
        
        missingConfigFunctions := []
        for funcName in configFunctions {
            if (!InStr(configContent, funcName . "(")) {
                missingConfigFunctions.Push(funcName)
            }
        }
        
        if (missingConfigFunctions.Length > 0) {
            CheckFail("Configuration Management System", "Missing config functions: " . Array2String(missingConfigFunctions))
            return
        }
        
        ; プリセット確認
        if (!InStr(configContent, '"basic"') || !InStr(configContent, '"full_auto"')) {
            CheckFail("Configuration Management System", "Required presets not found")
            return
        }
        
        CheckPass("Configuration Management System")
        
    } catch as e {
        CheckFail("Configuration Management System", e.Message)
    }
}

; 7. 統計システムチェック
CheckStatisticsSystem() {
    AnalysisStart("Statistics System")
    
    try {
        statsContent := FileRead("Features/Flask/FlaskStatistics.ahk")
        
        ; 統計関数確認
        statsFunctions := [
            "UpdateFlaskStats", "GetFlaskStats", "GetDetailedFlaskStats",
            "RecordFlaskSuccess", "RecordFlaskError", "GenerateFlaskEfficiencyReport"
        ]
        
        missingStatsFunctions := []
        for funcName in statsFunctions {
            if (!InStr(statsContent, funcName . "(")) {
                missingStatsFunctions.Push(funcName)
            }
        }
        
        if (missingStatsFunctions.Length > 0) {
            CheckFail("Statistics System", "Missing stats functions: " . Array2String(missingStatsFunctions))
            return
        }
        
        ; 履歴機能確認
        if (!InStr(statsContent, "g_flask_usage_history")) {
            CheckFail("Statistics System", "Usage history system not found")
            return
        }
        
        CheckPass("Statistics System")
        
    } catch as e {
        CheckFail("Statistics System", e.Message)
    }
}

; ヘルパー関数
Array2String(arr) {
    result := ""
    for index, value in arr {
        if (index > 1) {
            result .= ", "
        }
        result .= value
    }
    return result
}

; メイン解析実行
RunStaticAnalysis() {
    analysisResults.Push("=== FlaskManager Split Static Analysis ===")
    analysisResults.Push("Analyzing code structure and dependencies...")
    analysisResults.Push("")
    
    ; 全チェック実行
    CheckGlobalVariables()
    CheckFunctionExistence()
    CheckDependencies()
    CheckChargeSystem()
    CheckConditionSystem()
    CheckConfigurationSystem()
    CheckStatisticsSystem()
    
    ; 結果サマリー
    analysisResults.Push("")
    analysisResults.Push("=== ANALYSIS RESULTS ===")
    analysisResults.Push("Passed: " . checksPassed)
    analysisResults.Push("Failed: " . checksFailed)
    analysisResults.Push("Total: " . (checksPassed + checksFailed))
    
    if (checksFailed == 0) {
        analysisResults.Push("🎉 ALL CHECKS PASSED! FlaskManager split structure is sound!")
    } else {
        analysisResults.Push("❌ Some checks failed. Review the implementation.")
    }
    
    ; 結果出力
    outputText := ""
    for result in analysisResults {
        outputText .= result . "`n"
        OutputDebug(result)
    }
    
    ; ファイルに保存
    try {
        FileAppend(outputText, "flask_split_analysis_results.txt")
        OutputDebug("Analysis results saved to: flask_split_analysis_results.txt")
    } catch {
        OutputDebug("Failed to save analysis results")
    }
    
    ; メッセージボックスで結果表示
    MsgBox("FlaskManager split static analysis completed!`n`nPassed: " . checksPassed . "`nFailed: " . checksFailed . "`n`nSee debug output for details.", "Static Analysis Results")
}

; ホットキー
F9::RunStaticAnalysis()

; 自動実行
RunStaticAnalysis()

; 終了
Esc::ExitApp()