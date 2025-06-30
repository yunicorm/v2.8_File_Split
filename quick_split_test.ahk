; ===================================================================
; SettingsWindow分割後 クイック動作確認
; 基本的な構文エラーと関数存在確認
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; 最小限のインクルード
#Include "Utils\Logger.ahk"
#Include "Utils\ConfigManager.ahk"
#Include "UI\Overlay.ahk"

; 分割後のSettingsWindow
#Include "UI\SettingsWindow.ahk"

; クイックテスト実行
try {
    LogInfo("QuickTest", "=== SettingsWindow分割後 クイック確認開始 ===")
    
    ; 1. 基本的なConfigManager初期化
    if (!ConfigManager.Load()) {
        LogError("QuickTest", "ConfigManager.Load() failed")
        MsgBox("Config.iniの読み込みに失敗しました", "エラー", "OK Icon!")
        ExitApp()
    }
    LogInfo("QuickTest", "✅ ConfigManager.Load() 成功")
    
    ; 2. 関数存在確認
    TestFunctionExists()
    
    ; 3. 基本的なウィンドウ作成テスト
    TestWindowCreation()
    
    ; 4. 設定読み込み関数テスト
    TestSettingsLoad()
    
    ; 5. 検証関数テスト
    TestValidationFunctions()
    
    MsgBox("✅ クイック確認完了`n`n全ての基本機能が正常に動作します。`n`n詳細なテストは手動で実行してください。", "成功", "OK Icon*")
    LogInfo("QuickTest", "✅ クイック確認完了 - 全て正常")
    
} catch as e {
    errorMsg := "❌ クイック確認でエラーが発生:`n`n" . e.Message
    if (e.HasProp("Line")) {
        errorMsg .= "`n行番号: " . e.Line
    }
    if (e.HasProp("File")) {
        errorMsg .= "`nファイル: " . e.File
    }
    
    MsgBox(errorMsg, "エラー", "OK Icon!")
    LogError("QuickTest", "Quick test failed: " . e.Message)
}

; 関数存在確認
TestFunctionExists() {
    LogInfo("QuickTest", "関数存在確認を開始...")
    
    ; メイン関数
    if (!IsSet(ShowSettingsWindow)) {
        throw Error("ShowSettingsWindow関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ ShowSettingsWindow関数が存在")
    
    if (!IsSet(CreateSettingsWindow)) {
        throw Error("CreateSettingsWindow関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ CreateSettingsWindow関数が存在")
    
    ; タブ作成関数
    if (!IsSet(CreateFlaskTab)) {
        throw Error("CreateFlaskTab関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ CreateFlaskTab関数が存在")
    
    if (!IsSet(CreateSkillTab)) {
        throw Error("CreateSkillTab関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ CreateSkillTab関数が存在")
    
    if (!IsSet(CreateGeneralTab)) {
        throw Error("CreateGeneralTab関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ CreateGeneralTab関数が存在")
    
    ; 設定関数
    if (!IsSet(LoadCurrentSettings)) {
        throw Error("LoadCurrentSettings関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ LoadCurrentSettings関数が存在")
    
    if (!IsSet(SaveSettings)) {
        throw Error("SaveSettings関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ SaveSettings関数が存在")
    
    ; 検証関数
    if (!IsSet(ValidateAllSettings)) {
        throw Error("ValidateAllSettings関数が見つかりません")
    }
    LogInfo("QuickTest", "✅ ValidateAllSettings関数が存在")
    
    LogInfo("QuickTest", "✅ 全ての必要な関数が存在することを確認")
}

; ウィンドウ作成テスト
TestWindowCreation() {
    LogInfo("QuickTest", "ウィンドウ作成テストを開始...")
    
    try {
        ; SettingsWindowを作成
        CreateSettingsWindow()
        LogInfo("QuickTest", "✅ CreateSettingsWindow()実行成功")
        
        ; グローバル変数の確認
        if (!IsSet(g_settings_gui)) {
            throw Error("g_settings_gui変数が設定されていません")
        }
        LogInfo("QuickTest", "✅ g_settings_gui変数が正常に設定")
        
        if (!IsSet(g_settings_tab)) {
            throw Error("g_settings_tab変数が設定されていません")
        }
        LogInfo("QuickTest", "✅ g_settings_tab変数が正常に設定")
        
        ; GUIオブジェクトの確認
        if (!IsObject(g_settings_gui)) {
            throw Error("g_settings_guiがオブジェクトではありません")
        }
        LogInfo("QuickTest", "✅ g_settings_guiが正常なGUIオブジェクト")
        
        ; タブコントロールの確認
        if (!IsObject(g_settings_tab)) {
            throw Error("g_settings_tabがオブジェクトではありません")
        }
        LogInfo("QuickTest", "✅ g_settings_tabが正常なタブオブジェクト")
        
        ; ウィンドウを閉じる
        CloseSettingsWindow()
        LogInfo("QuickTest", "✅ CloseSettingsWindow()実行成功")
        
    } catch as e {
        throw Error("ウィンドウ作成テストに失敗: " . e.Message)
    }
}

; 設定読み込み関数テスト
TestSettingsLoad() {
    LogInfo("QuickTest", "設定読み込み関数テストを開始...")
    
    try {
        ; ウィンドウを再作成
        CreateSettingsWindow()
        
        ; 各タブの読み込み関数をテスト
        LoadFlaskSettings()
        LogInfo("QuickTest", "✅ LoadFlaskSettings()実行成功")
        
        LoadSkillSettings()
        LogInfo("QuickTest", "✅ LoadSkillSettings()実行成功")
        
        LoadGeneralSettings()
        LogInfo("QuickTest", "✅ LoadGeneralSettings()実行成功")
        
        ; 統合読み込み関数をテスト
        LoadCurrentSettings()
        LogInfo("QuickTest", "✅ LoadCurrentSettings()実行成功")
        
        ; 基本的なコントロール存在確認
        if (!IsSet(g_settings_gui["Flask1_Enabled"])) {
            throw Error("Flask1_Enabledコントロールが作成されていません")
        }
        LogInfo("QuickTest", "✅ フラスココントロールが正常に作成")
        
        if (!IsSet(g_settings_gui["Skill_1_1_Name"])) {
            throw Error("Skill_1_1_Nameコントロールが作成されていません")
        }
        LogInfo("QuickTest", "✅ スキルコントロールが正常に作成")
        
        if (!IsSet(g_settings_gui["DebugMode"])) {
            throw Error("DebugModeコントロールが作成されていません")
        }
        LogInfo("QuickTest", "✅ 一般設定コントロールが正常に作成")
        
        CloseSettingsWindow()
        
    } catch as e {
        throw Error("設定読み込み関数テストに失敗: " . e.Message)
    }
}

; 検証関数テスト
TestValidationFunctions() {
    LogInfo("QuickTest", "検証関数テストを開始...")
    
    try {
        ; ウィンドウを再作成
        CreateSettingsWindow()
        LoadCurrentSettings()
        
        ; 正常な値での検証
        errors := ValidateAllSettings()
        LogInfo("QuickTest", Format("✅ ValidateAllSettings()実行成功 (エラー数: {})", errors.Length))
        
        ; 無効な値を設定してテスト
        g_settings_gui["Flask1_Min"].Text := "abc"
        g_settings_gui["Mana_BlueThreshold"].Text := "300"
        
        errors := ValidateAllSettings()
        if (errors.Length == 0) {
            throw Error("検証関数がエラーを検出していません")
        }
        LogInfo("QuickTest", Format("✅ 検証関数が正常にエラーを検出 (エラー数: {})", errors.Length))
        
        CloseSettingsWindow()
        
    } catch as e {
        throw Error("検証関数テストに失敗: " . e.Message)
    }
}