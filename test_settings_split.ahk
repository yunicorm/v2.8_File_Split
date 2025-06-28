; ===================================================================
; SettingsWindow分割後の動作確認テストスクリプト
; 分割されたモジュールの統合動作をテスト
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; 必要なユーティリティのインクルード
#Include "Utils\Logger.ahk"
#Include "Utils\ConfigManager.ahk"
#Include "UI\Overlay.ahk"

; 分割後のSettingsWindowをインクルード
#Include "UI\SettingsWindow.ahk"

; テスト結果格納
global g_test_results := []
global g_test_errors := []
global g_current_test := ""

; テスト開始
try {
    InitializeLogger()
    LogInfo("SettingsSplitTest", "=== SettingsWindow Split Test Starting ===")
    
    ; 設定読み込み
    if (!ConfigManager.Load()) {
        AddError("ConfigManager.Load()が失敗しました")
        ExitApp()
    }
    
    RunSplitTests()
    ShowTestResults()
    
} catch Error as e {
    MsgBox("テストエラー: " . e.Message, "エラー", "OK Icon!")
    LogError("SettingsSplitTest", "Test failed: " . e.Message)
}

; 分割テスト実行
RunSplitTests() {
    LogInfo("SettingsSplitTest", "Starting split module tests...")
    
    ; 1. 基本動作テスト
    TestBasicOperation()
    Sleep(1000)
    
    ; 2. 設定読み込みテスト
    TestSettingsLoad()
    Sleep(1000)
    
    ; 3. 設定保存テスト
    TestSettingsSave()
    Sleep(1000)
    
    ; 4. エラーハンドリングテスト
    TestErrorHandling()
    Sleep(1000)
    
    ; 5. 検証機能テスト
    TestValidation()
}

; 1. 基本動作テスト
TestBasicOperation() {
    StartTest("基本動作テスト")
    
    try {
        ; 設定ウィンドウを開く
        TestStep("分割されたSettingsWindowを開く")
        ShowSettingsWindow()
        Sleep(1000)
        
        if (g_settings_open && IsSet(g_settings_gui) && IsObject(g_settings_gui)) {
            PassTest("設定ウィンドウが正常に表示されました")
            
            ; タブ切り替えテスト
            TestStep("タブ切り替えテスト")
            g_settings_tab.Choose(1) ; フラスコタブ
            Sleep(200)
            g_settings_tab.Choose(2) ; スキルタブ
            Sleep(200)
            g_settings_tab.Choose(3) ; 一般タブ
            Sleep(200)
            PassTest("全タブの切り替えが正常に動作")
            
            ; ウィンドウサイズテスト
            TestStep("ウィンドウサイズテスト")
            if (IsSet(g_settings_gui.Pos)) {
                PassTest("ウィンドウサイズが適切に設定されています")
            } else {
                FailTest("ウィンドウサイズの取得に失敗")
            }
            
        } else {
            FailTest("設定ウィンドウの表示に失敗")
            return
        }
        
    } catch Error as e {
        FailTest("基本動作テストでエラー: " . e.Message)
    }
}

; 2. 設定読み込みテスト
TestSettingsLoad() {
    StartTest("設定読み込みテスト")
    
    try {
        TestStep("分割されたLoadCurrentSettings()の実行")
        LoadCurrentSettings()
        PassTest("LoadCurrentSettings()が正常に実行されました")
        
        ; 各モジュールの読み込み関数をテスト
        TestStep("FlaskTab.LoadFlaskSettings()テスト")
        LoadFlaskSettings()
        PassTest("フラスコ設定の読み込みが正常に完了")
        
        TestStep("SkillTab.LoadSkillSettings()テスト")
        LoadSkillSettings()
        PassTest("スキル設定の読み込みが正常に完了")
        
        TestStep("GeneralTab.LoadGeneralSettings()テスト")
        LoadGeneralSettings()
        PassTest("一般設定の読み込みが正常に完了")
        
        ; 設定値の確認
        TestStep("設定値の確認")
        if (IsSet(g_settings_gui["Flask1_Enabled"])) {
            flaskEnabled := g_settings_gui["Flask1_Enabled"].Checked
            PassTest(Format("Flask1設定読み込み確認: {}", flaskEnabled))
        } else {
            FailTest("Flask1_Enabledコントロールが見つかりません")
        }
        
        if (IsSet(g_settings_gui["Skill_1_1_Name"])) {
            skillName := g_settings_gui["Skill_1_1_Name"].Text
            PassTest(Format("Skill設定読み込み確認: {}", skillName))
        } else {
            FailTest("Skill_1_1_Nameコントロールが見つかりません")
        }
        
    } catch Error as e {
        FailTest("設定読み込みテストでエラー: " . e.Message)
    }
}

; 3. 設定保存テスト
TestSettingsSave() {
    StartTest("設定保存テスト")
    
    try {
        ; 設定値を変更
        TestStep("設定値の変更")
        originalFlaskKey := g_settings_gui["Flask1_Key"].Text
        g_settings_gui["Flask1_Key"].Text := "testkey"
        g_settings_gui["Skill_1_1_Name"].Text := "テストスキル分割"
        
        ; 各モジュールの保存関数をテスト
        TestStep("分割された保存関数のテスト")
        SaveFlaskSettings()
        PassTest("SaveFlaskSettings()が正常に実行")
        
        SaveSkillSettings()
        PassTest("SaveSkillSettings()が正常に実行")
        
        SaveGeneralSettings()
        PassTest("SaveGeneralSettings()が正常に実行")
        
        ; Config.ini保存
        TestStep("Config.ini保存")
        ConfigManager.Save()
        PassTest("ConfigManager.Save()が正常に実行")
        
        ; 設定の確認
        TestStep("保存された設定の確認")
        savedFlaskKey := ConfigManager.Get("Flask", "Flask1_Key", "")
        savedSkillName := ConfigManager.Get("Skill", "Skill_1_1_Name", "")
        
        if (savedFlaskKey == "testkey" && savedSkillName == "テストスキル分割") {
            PassTest("設定が正常に保存されました")
        } else {
            FailTest(Format("設定保存の確認に失敗: Flask1_Key={}, Skill_1_1_Name={}", savedFlaskKey, savedSkillName))
        }
        
        ; 元に戻す
        g_settings_gui["Flask1_Key"].Text := originalFlaskKey
        g_settings_gui["Skill_1_1_Name"].Text := "スキル1-1"
        SaveFlaskSettings()
        SaveSkillSettings()
        ConfigManager.Save()
        
    } catch Error as e {
        FailTest("設定保存テストでエラー: " . e.Message)
    }
}

; 4. エラーハンドリングテスト
TestErrorHandling() {
    StartTest("エラーハンドリングテスト")
    
    try {
        ; 重複ウィンドウオープンテスト
        TestStep("重複ウィンドウオープンテスト")
        ShowSettingsWindow() ; 既に開いているはず
        Sleep(200)
        ShowSettingsWindow() ; 2回目の呼び出し
        Sleep(200)
        
        if (g_settings_open && IsSet(g_settings_gui)) {
            PassTest("重複オープン時の処理が正常")
        } else {
            FailTest("重複オープン処理に問題")
        }
        
        ; ウィンドウクローズテスト
        TestStep("ウィンドウクローズテスト")
        CloseSettingsWindow()
        Sleep(500)
        
        if (!g_settings_open) {
            PassTest("ウィンドウが正常に閉じられました")
        } else {
            FailTest("ウィンドウを閉じることができませんでした")
        }
        
    } catch Error as e {
        FailTest("エラーハンドリングテストでエラー: " . e.Message)
    }
}

; 5. 検証機能テスト
TestValidation() {
    StartTest("検証機能テスト")
    
    try {
        ; 設定ウィンドウを開き直す
        ShowSettingsWindow()
        Sleep(500)
        
        ; 無効な値を設定
        TestStep("無効な値のテスト")
        g_settings_gui["Flask1_Min"].Text := "abc" ; 文字列
        g_settings_gui["Skill_1_1_Min"].Text := "-100" ; 負の値
        g_settings_gui["Mana_BlueThreshold"].Text := "300" ; 範囲外
        
        ; 検証実行
        TestStep("ValidateAllSettings()実行")
        errors := ValidateAllSettings()
        
        if (errors.Length > 0) {
            PassTest(Format("検証が正常に動作 ({} 個のエラーを検出)", errors.Length))
            for error in errors {
                LogInfo("SettingsSplitTest", "検証エラー: " . error)
            }
        } else {
            FailTest("検証がエラーを検出しませんでした")
        }
        
        ; 設定を元に戻す
        g_settings_gui["Flask1_Min"].Text := "3000"
        g_settings_gui["Skill_1_1_Min"].Text := "1000"
        g_settings_gui["Mana_BlueThreshold"].Text := "100"
        
        CloseSettingsWindow()
        
    } catch Error as e {
        FailTest("検証機能テストでエラー: " . e.Message)
    }
}

; テスト開始
StartTest(testName) {
    global g_current_test
    g_current_test := testName
    LogInfo("SettingsSplitTest", "=== " . testName . " 開始 ===")
}

; テストステップ
TestStep(stepName) {
    LogInfo("SettingsSplitTest", "ステップ: " . stepName)
}

; テスト成功
PassTest(message) {
    global g_test_results
    g_test_results.Push("✅ " . g_current_test . ": " . message)
    LogInfo("SettingsSplitTest", "PASS: " . message)
}

; テスト失敗
FailTest(message) {
    global g_test_errors
    g_test_errors.Push("❌ " . g_current_test . ": " . message)
    LogError("SettingsSplitTest", "FAIL: " . message)
}

; エラー追加
AddError(message) {
    global g_test_errors
    g_test_errors.Push("❌ " . message)
    LogError("SettingsSplitTest", "ERROR: " . message)
}

; テスト結果表示
ShowTestResults() {
    global g_test_results, g_test_errors
    
    resultText := []
    resultText.Push("=== SettingsWindow分割後 動作確認結果 ===")
    resultText.Push("")
    resultText.Push(Format("成功: {} / エラー: {}", g_test_results.Length, g_test_errors.Length))
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
        resultText.Push("")
    }
    
    resultText.Push("=== 結論 ===")
    if (g_test_errors.Length == 0) {
        resultText.Push("✅ SettingsWindow分割は成功しています")
        resultText.Push("全ての機能が正常に動作することを確認")
    } else {
        resultText.Push("⚠️ 修正が必要な問題が発見されました")
        resultText.Push("上記のエラー項目を確認してください")
    }
    
    ; 結果をファイルに保存
    resultFile := A_ScriptDir . "\settings_split_test_results.txt"
    resultContent := ""
    for line in resultText {
        resultContent .= line . "`n"
    }
    FileAppend(resultContent, resultFile, "UTF-8")
    
    ; 結果を表示
    finalMessage := Format("SettingsWindow分割テスト完了`n`n成功: {} / エラー: {}`n`n詳細結果: {}", 
        g_test_results.Length, g_test_errors.Length, resultFile)
    
    MsgBox(finalMessage, "テスト結果", "OK " . (g_test_errors.Length > 0 ? "Icon!" : "Icon*"))
    
    LogInfo("SettingsSplitTest", "=== SettingsWindow Split Test Completed ===")
}