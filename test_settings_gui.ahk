; ===================================================================
; 設定GUI総合テストスクリプト
; SettingsWindow.ahkの全機能をテストします
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ユーティリティのインクルード
#Include "Utils\Logger.ahk"
#Include "Utils\ConfigManager.ahk"
#Include "UI\Overlay.ahk"
#Include "UI\SettingsWindow.ahk"

; グローバル変数
global g_test_results := []
global g_test_errors := []
global g_test_count := 0
global g_test_passed := 0

; テスト実行
try {
    ; ロガー初期化
    InitializeLogger()
    LogInfo("SettingsGUITest", "=== Settings GUI Comprehensive Test Starting ===")
    
    ; 設定読み込み
    if (!ConfigManager.Load()) {
        MsgBox("設定ファイルの読み込みに失敗しました", "エラー", "OK Icon!")
        ExitApp()
    }
    
    ; テスト実行
    RunAllTests()
    
    ; 結果表示
    ShowTestResults()
    
} catch Error as e {
    MsgBox("テストエラー: " . e.Message, "エラー", "OK Icon!")
    LogError("SettingsGUITest", "Test failed: " . e.Message)
}

; 全テスト実行
RunAllTests() {
    LogInfo("SettingsGUITest", "Starting comprehensive GUI tests...")
    
    ; 1. 基本動作テスト
    TestBasicOperation()
    Sleep(500)
    
    ; 2. 設定読み込み/保存テスト
    TestConfigLoadSave()
    Sleep(500)
    
    ; 3. エラーハンドリングテスト
    TestErrorHandling()
    Sleep(500)
    
    ; 4. バリデーションテスト
    TestValidation()
    Sleep(500)
    
    ; 5. 統合テスト
    TestIntegration()
}

; 1. 基本動作テスト
TestBasicOperation() {
    StartTest("基本動作テスト")
    
    try {
        ; 設定ウィンドウを開く
        TestStep("設定ウィンドウを開く")
        ShowSettingsWindow()
        Sleep(1000)
        
        if (g_settings_open && IsSet(g_settings_gui) && IsObject(g_settings_gui)) {
            PassTest("設定ウィンドウが正常に表示されました")
        } else {
            FailTest("設定ウィンドウの表示に失敗")
            return
        }
        
        ; タブ切り替えテスト
        TestStep("タブ切り替えテスト")
        g_settings_tab.Choose(1) ; フラスコタブ
        Sleep(200)
        g_settings_tab.Choose(2) ; スキルタブ
        Sleep(200)
        g_settings_tab.Choose(3) ; 一般タブ
        Sleep(200)
        PassTest("全タブの切り替えが正常に動作")
        
        ; ウィンドウを閉じる
        TestStep("ウィンドウを閉じる")
        CloseSettingsWindow()
        Sleep(500)
        
        if (!g_settings_open) {
            PassTest("ウィンドウが正常に閉じられました")
        } else {
            FailTest("ウィンドウを閉じることができませんでした")
        }
        
    } catch Error as e {
        FailTest("基本動作テストでエラー: " . e.Message)
    }
}

; 2. 設定読み込み/保存テスト
TestConfigLoadSave() {
    StartTest("設定読み込み/保存テスト")
    
    try {
        ; 設定ウィンドウを開く
        TestStep("設定値の読み込みテスト")
        ShowSettingsWindow()
        Sleep(500)
        
        ; 現在の設定値を確認
        flaskEnabled := g_settings_gui["Flask1_Enabled"].Checked
        skillName := g_settings_gui["Skill_1_1_Name"].Text
        debugMode := g_settings_gui["DebugMode"].Checked
        
        PassTest(Format("設定値読み込み完了 - Flask1: {}, Skill名: {}, Debug: {}", 
            flaskEnabled, skillName, debugMode))
        
        ; 設定値を変更
        TestStep("設定値の変更テスト")
        originalFlaskEnabled := g_settings_gui["Flask1_Enabled"].Checked
        g_settings_gui["Flask1_Enabled"].Checked := !originalFlaskEnabled
        g_settings_gui["Skill_1_1_Name"].Text := "テストスキル"
        
        ; 保存テスト
        TestStep("設定保存テスト")
        SaveSettings()
        Sleep(1000)
        
        ; 設定が保存されたか確認
        newFlaskEnabled := ConfigManager.Get("Flask", "Flask1_Enabled", false)
        newSkillName := ConfigManager.Get("Skill", "Skill_1_1_Name", "")
        
        if (newFlaskEnabled != originalFlaskEnabled && newSkillName == "テストスキル") {
            PassTest("設定の保存が正常に動作")
        } else {
            FailTest("設定の保存に失敗")
        }
        
        ; 元の設定に戻す
        g_settings_gui["Flask1_Enabled"].Checked := originalFlaskEnabled
        g_settings_gui["Skill_1_1_Name"].Text := skillName
        SaveSettings()
        
        CloseSettingsWindow()
        
    } catch Error as e {
        FailTest("設定読み込み/保存テストでエラー: " . e.Message)
    }
}

; 3. エラーハンドリングテスト
TestErrorHandling() {
    StartTest("エラーハンドリングテスト")
    
    try {
        ; 重複ウィンドウオープンテスト
        TestStep("重複ウィンドウオープンテスト")
        ShowSettingsWindow()
        Sleep(200)
        ShowSettingsWindow() ; 2回目の呼び出し
        Sleep(200)
        
        if (g_settings_open && IsSet(g_settings_gui)) {
            PassTest("重複オープン時の処理が正常")
        } else {
            FailTest("重複オープン処理に問題")
        }
        
        CloseSettingsWindow()
        
    } catch Error as e {
        FailTest("エラーハンドリングテストでエラー: " . e.Message)
    }
}

; 4. バリデーションテスト
TestValidation() {
    StartTest("入力値バリデーションテスト")
    
    try {
        ShowSettingsWindow()
        Sleep(500)
        
        ; 無効な値を設定
        TestStep("無効な値のテスト")
        g_settings_gui["Flask1_Min"].Text := "abc" ; 文字列
        g_settings_gui["Skill_1_1_Min"].Text := "-100" ; 負の値
        g_settings_gui["Mana_BlueThreshold"].Text := "300" ; 範囲外
        
        ; バリデーション実行
        errors := ValidateSkillSettings()
        
        if (errors.Length > 0) {
            PassTest(Format("バリデーションが正常に動作 ({} 個のエラーを検出)", errors.Length))
            for error in errors {
                LogInfo("SettingsGUITest", "バリデーションエラー: " . error)
            }
        } else {
            FailTest("バリデーションがエラーを検出しませんでした")
        }
        
        CloseSettingsWindow()
        
    } catch Error as e {
        FailTest("バリデーションテストでエラー: " . e.Message)
    }
}

; 5. 統合テスト
TestIntegration() {
    StartTest("統合テスト")
    
    try {
        TestStep("設定GUIの統合動作テスト")
        
        ; 設定を変更して保存
        ShowSettingsWindow()
        Sleep(500)
        
        ; フラスコ設定を変更
        g_settings_gui["Flask2_Enabled"].Checked := true
        g_settings_gui["Flask2_Min"].Text := "5000"
        g_settings_gui["Flask2_Max"].Text := "5500"
        
        ; スキル設定を変更
        g_settings_gui["Skill_1_1_Enabled"].Checked := true
        g_settings_gui["Skill_1_1_Key"].Text := "q"
        g_settings_gui["Skill_1_1_Min"].Text := "1000"
        g_settings_gui["Skill_1_1_Max"].Text := "1500"
        
        SaveSettings()
        Sleep(1000)
        
        ; 保存された設定を確認
        flask2Enabled := ConfigManager.Get("Flask", "Flask2_Enabled", false)
        skill11Enabled := ConfigManager.Get("Skill", "Skill_1_1_Enabled", false)
        
        if (flask2Enabled && skill11Enabled) {
            PassTest("統合テストが正常に完了")
        } else {
            FailTest("統合テストで設定の反映に失敗")
        }
        
        CloseSettingsWindow()
        
    } catch Error as e {
        FailTest("統合テストでエラー: " . e.Message)
    }
}

; テスト開始
StartTest(testName) {
    global g_test_count
    g_test_count++
    LogInfo("SettingsGUITest", "=== " . testName . " 開始 ===")
}

; テストステップ
TestStep(stepName) {
    LogInfo("SettingsGUITest", "ステップ: " . stepName)
}

; テスト成功
PassTest(message) {
    global g_test_passed, g_test_results
    g_test_passed++
    g_test_results.Push("✅ " . message)
    LogInfo("SettingsGUITest", "PASS: " . message)
}

; テスト失敗
FailTest(message) {
    global g_test_errors
    g_test_errors.Push("❌ " . message)
    LogError("SettingsGUITest", "FAIL: " . message)
}

; テスト結果表示
ShowTestResults() {
    global g_test_count, g_test_passed, g_test_results, g_test_errors
    
    resultText := []
    resultText.Push("=== 設定GUI テスト結果 ===")
    resultText.Push("")
    resultText.Push(Format("実行テスト数: {}", g_test_count))
    resultText.Push(Format("成功: {} / エラー: {}", g_test_passed, g_test_errors.Length))
    resultText.Push("")
    
    if (g_test_results.Length > 0) {
        resultText.Push("=== 成功項目 ===")
        for result in g_test_results {
            resultText.Push(result)
        }
        resultText.Push("")
    }
    
    if (g_test_errors.Length > 0) {
        resultText.Push("=== エラー項目 ===")
        for error in g_test_errors {
            resultText.Push(error)
        }
    }
    
    ; 結果をファイルに保存
    resultFile := A_ScriptDir . "\test_results_gui.txt"
    FileAppend(Array2String(resultText, "`n"), resultFile, "UTF-8")
    
    ; 結果を表示
    finalMessage := Format("設定GUIテスト完了`n`n成功: {} / エラー: {}`n`n詳細結果: {}", 
        g_test_passed, g_test_errors.Length, resultFile)
    
    MsgBox(finalMessage, "テスト結果", "OK " . (g_test_errors.Length > 0 ? "Icon!" : "Icon*"))
    
    LogInfo("SettingsGUITest", "=== Settings GUI Test Completed ===")
}

; 配列を文字列に変換（改行区切り）
Array2String(arr, separator := ",") {
    result := ""
    for index, value in arr {
        if (index > 1) {
            result .= separator
        }
        result .= value
    }
    return result
}