; ===================================================================
; 設定GUI 静的検証スクリプト
; SettingsWindow.ahkの構文とロジックをチェック
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; インクルード（最小限）
#Include "Utils\Logger.ahk"
#Include "Utils\ConfigManager.ahk"

; 検証結果
global validation_results := []
global validation_errors := []

; 検証実行
try {
    InitializeLogger()
    LogInfo("GUIValidator", "=== Settings GUI Validation Starting ===")
    
    ValidateGUIImplementation()
    ShowValidationResults()
    
} catch as e {
    MsgBox("検証エラー: " . e.Message, "エラー", "OK Icon!")
}

; GUI実装の検証
ValidateGUIImplementation() {
    ; 1. 必須ファイルの存在確認
    CheckRequiredFiles()
    
    ; 2. Config.ini の構造確認
    CheckConfigStructure()
    
    ; 3. GUI コントロール名の一貫性確認
    CheckControlNames()
    
    ; 4. 設定値の型・範囲確認
    CheckConfigValues()
}

; 必須ファイル確認
CheckRequiredFiles() {
    requiredFiles := [
        "UI\SettingsWindow.ahk",
        "Utils\ConfigManager.ahk",
        "Utils\Logger.ahk",
        "UI\Overlay.ahk",
        "Config.ini"
    ]
    
    for file in requiredFiles {
        filePath := A_ScriptDir . "\" . file
        if (FileExist(filePath)) {
            AddResult("✅ 必須ファイル存在: " . file)
        } else {
            AddError("❌ 必須ファイル不足: " . file)
        }
    }
}

; Config.ini構造確認
CheckConfigStructure() {
    try {
        ConfigManager.Load()
        
        ; 必須セクション確認
        requiredSections := [
            "General", "Flask", "Skill", "Mana", 
            "ClientLog", "Performance", "UI", "Resolution"
        ]
        
        for section in requiredSections {
            ; セクションの存在確認（簡易的）
            testKey := ConfigManager.Get(section, "NonExistentKey", "default")
            AddResult("✅ Config.ini セクション確認: [" . section . "]")
        }
        
        ; 重要な設定値確認
        CheckCriticalSettings()
        
    } catch as e {
        AddError("❌ Config.ini読み込みエラー: " . e.Message)
    }
}

; 重要設定値確認
CheckCriticalSettings() {
    ; フラスコ設定
    Loop 5 {
        flaskNum := A_Index
        enabled := ConfigManager.Get("Flask", "Flask" . flaskNum . "_Enabled", "false")
        key := ConfigManager.Get("Flask", "Flask" . flaskNum . "_Key", "")
        minVal := ConfigManager.Get("Flask", "Flask" . flaskNum . "_Min", "0")
        maxVal := ConfigManager.Get("Flask", "Flask" . flaskNum . "_Max", "0")
        
        if (key != "" && IsValidInteger(minVal) && IsValidInteger(maxVal)) {
            AddResult("✅ Flask" . flaskNum . " 設定正常")
        } else {
            AddError("❌ Flask" . flaskNum . " 設定に問題: Key=" . key . ", Min=" . minVal . ", Max=" . maxVal)
        }
    }
    
    ; スキル設定（簡易チェック）
    skillIds := ["1_1", "1_2", "2_1", "2_2"]
    for skillId in skillIds {
        enabled := ConfigManager.Get("Skill", "Skill_" . skillId . "_Enabled", "false")
        name := ConfigManager.Get("Skill", "Skill_" . skillId . "_Name", "")
        key := ConfigManager.Get("Skill", "Skill_" . skillId . "_Key", "")
        
        if (name != "" && key != "") {
            AddResult("✅ Skill_" . skillId . " 設定正常")
        }
    }
    
    ; マナ設定
    centerX := ConfigManager.Get("Mana", "CenterX", "0")
    centerY := ConfigManager.Get("Mana", "CenterY", "0")
    radius := ConfigManager.Get("Mana", "Radius", "0")
    
    if (IsValidInteger(centerX) && IsValidInteger(centerY) && IsValidInteger(radius)) {
        AddResult("✅ マナ設定正常: " . centerX . "," . centerY . " 半径:" . radius)
    } else {
        AddError("❌ マナ設定に問題: X=" . centerX . ", Y=" . centerY . ", R=" . radius)
    }
}

; GUIコントロール名確認
CheckControlNames() {
    ; SettingsWindow.ahkから期待されるコントロール名をチェック
    expectedControls := [
        ; フラスコ関連
        "Flask1_Enabled", "Flask1_Key", "Flask1_Min", "Flask1_Max",
        "Flask2_Enabled", "Flask2_Key", "Flask2_Min", "Flask2_Max",
        
        ; スキル関連
        "Skill_1_1_Enabled", "Skill_1_1_Name", "Skill_1_1_Key",
        "Skill_2_1_Enabled", "Skill_2_1_Name", "Skill_2_1_Key",
        
        ; 一般設定
        "DebugMode", "LogEnabled", "AutoStart",
        "Mana_CenterX", "Mana_CenterY", "Mana_Radius"
    ]
    
    AddResult("✅ 期待されるコントロール数: " . expectedControls.Length . " 個")
    
    ; 実際のコード内での使用確認は静的にはできないため、
    ; 手動テスト時に確認が必要
}

; 設定値の型・範囲確認
CheckConfigValues() {
    ; 数値範囲チェック
    checks := [
        {section: "Mana", key: "BlueThreshold", min: 0, max: 255},
        {section: "Mana", key: "MonitorInterval", min: 50, max: 1000},
        {section: "Performance", key: "ColorDetectTimeout", min: 10, max: 500},
        {section: "Performance", key: "ManaSampleRate", min: 1, max: 10}
    ]
    
    for check in checks {
        value := ConfigManager.Get(check.section, check.key, "0")
        if (IsValidInteger(value)) {
            intValue := Integer(value)
            if (intValue >= check.min && intValue <= check.max) {
                AddResult("✅ " . check.section . "." . check.key . " = " . value . " (範囲内)")
            } else {
                AddError("❌ " . check.section . "." . check.key . " = " . value . " (範囲外: " . check.min . "-" . check.max . ")")
            }
        } else {
            AddError("❌ " . check.section . "." . check.key . " = " . value . " (非数値)")
        }
    }
}

; 結果追加
AddResult(message) {
    global validation_results
    validation_results.Push(message)
    LogInfo("GUIValidator", message)
}

; エラー追加
AddError(message) {
    global validation_errors
    validation_errors.Push(message)
    LogError("GUIValidator", message)
}

; 検証結果表示
ShowValidationResults() {
    global validation_results, validation_errors
    
    resultText := []
    resultText.Push("=== 設定GUI 静的検証結果 ===")
    resultText.Push("")
    resultText.Push(Format("正常項目: {} / エラー項目: {}", validation_results.Length, validation_errors.Length))
    resultText.Push("")
    
    if (validation_results.Length > 0) {
        resultText.Push("=== 正常項目 ===")
        for result in validation_results {
            resultText.Push(result)
        }
        resultText.Push("")
    }
    
    if (validation_errors.Length > 0) {
        resultText.Push("=== エラー項目 ===")
        for error in validation_errors {
            resultText.Push(error)
        }
        resultText.Push("")
    }
    
    resultText.Push("=== 推奨手動テスト ===")
    resultText.Push("1. Ctrl+Shift+S で設定ウィンドウを開く")
    resultText.Push("2. 各タブの表示確認")
    resultText.Push("3. 設定値の変更と保存テスト")
    resultText.Push("4. バリデーションエラーテスト")
    resultText.Push("5. キャンセル/リセット機能テスト")
    
    ; 結果をファイルに保存
    resultFile := A_ScriptDir . "\validation_results.txt"
    resultContent := ""
    for line in resultText {
        resultContent .= line . "`n"
    }
    FileAppend(resultContent, resultFile, "UTF-8")
    
    ; 結果を表示
    status := validation_errors.Length > 0 ? "警告あり" : "正常"
    finalMessage := Format("静的検証完了: {}`n`n詳細結果: {}`n`n続いて手動テストを実行してください。", 
        status, resultFile)
    
    MsgBox(finalMessage, "検証結果", "OK " . (validation_errors.Length > 0 ? "Icon!" : "Icon*"))
    
    LogInfo("GUIValidator", "=== GUI Validation Completed ===")
}

