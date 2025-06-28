; フラスコ設定のテストスクリプト
#Requires AutoHotkey v2.0

; 必要なモジュールを読み込み
#Include Utils\ConfigManager.ahk
#Include Utils\Logger.ahk
#Include UI\SettingsWindow.ahk

; テスト用のグローバル変数を初期化
global g_settings_gui := ""
global g_settings_tab := ""
global g_settings_open := false
global g_temp_config := Map()

; テスト実行
TestFlaskSettings()

TestFlaskSettings() {
    OutputDebug("=== フラスコ設定テスト開始 ===`n")
    
    ; ConfigManagerを初期化
    try {
        ConfigManager.Initialize()
        OutputDebug("ConfigManager初期化: 成功`n")
    } catch as e {
        OutputDebug("ConfigManager初期化: 失敗 - " . e.Message . "`n")
        return
    }
    
    ; デフォルト値での読み込みテスト
    OutputDebug("--- デフォルト値読み込みテスト ---`n")
    TestReadDefaults()
    
    ; 設定保存テスト
    OutputDebug("--- 設定保存テスト ---`n")
    TestSaveSettings()
    
    ; 設定読み込みテスト
    OutputDebug("--- 設定読み込みテスト ---`n")
    TestLoadSettings()
    
    ; フラスコタイプ変換テスト
    OutputDebug("--- フラスコタイプ変換テスト ---`n")
    TestFlaskTypeConversion()
    
    OutputDebug("=== フラスコ設定テスト完了 ===`n")
}

TestReadDefaults() {
    ; デフォルト値での読み込み
    flask1_enabled := ConfigManager.Get("Flask", "Flask1_Enabled", false)
    flask1_key := ConfigManager.Get("Flask", "Flask1_Key", "1")
    flask1_min := ConfigManager.Get("Flask", "Flask1_Min", "3000")
    flask1_type := ConfigManager.Get("Flask", "Flask1_Type", "Life")
    
    OutputDebug("Flask1_Enabled: " . flask1_enabled . "`n")
    OutputDebug("Flask1_Key: " . flask1_key . "`n")
    OutputDebug("Flask1_Min: " . flask1_min . "`n")
    OutputDebug("Flask1_Type: " . flask1_type . "`n")
}

TestSaveSettings() {
    ; テスト設定を保存
    ConfigManager.Set("Flask", "Flask1_Enabled", true)
    ConfigManager.Set("Flask", "Flask1_Key", "F1")
    ConfigManager.Set("Flask", "Flask1_Min", "2500")
    ConfigManager.Set("Flask", "Flask1_Max", "3000")
    ConfigManager.Set("Flask", "Flask1_Type", "Life")
    
    ConfigManager.Set("Flask", "Flask2_Enabled", true)
    ConfigManager.Set("Flask", "Flask2_Key", "F2")
    ConfigManager.Set("Flask", "Flask2_Min", "4000")
    ConfigManager.Set("Flask", "Flask2_Max", "4500")
    ConfigManager.Set("Flask", "Flask2_Type", "Mana")
    
    try {
        ConfigManager.Save()
        OutputDebug("設定保存: 成功`n")
    } catch as e {
        OutputDebug("設定保存: 失敗 - " . e.Message . "`n")
    }
}

TestLoadSettings() {
    ; 保存した設定を読み込み
    flask1_enabled := ConfigManager.Get("Flask", "Flask1_Enabled", false)
    flask1_key := ConfigManager.Get("Flask", "Flask1_Key", "1")
    flask1_min := ConfigManager.Get("Flask", "Flask1_Min", "3000")
    flask1_type := ConfigManager.Get("Flask", "Flask1_Type", "Life")
    
    flask2_enabled := ConfigManager.Get("Flask", "Flask2_Enabled", false)
    flask2_key := ConfigManager.Get("Flask", "Flask2_Key", "2")
    flask2_type := ConfigManager.Get("Flask", "Flask2_Type", "Mana")
    
    OutputDebug("読み込み後 Flask1_Enabled: " . flask1_enabled . "`n")
    OutputDebug("読み込み後 Flask1_Key: " . flask1_key . "`n")
    OutputDebug("読み込み後 Flask1_Min: " . flask1_min . "`n")
    OutputDebug("読み込み後 Flask1_Type: " . flask1_type . "`n")
    
    OutputDebug("読み込み後 Flask2_Enabled: " . flask2_enabled . "`n")
    OutputDebug("読み込み後 Flask2_Key: " . flask2_key . "`n")
    OutputDebug("読み込み後 Flask2_Type: " . flask2_type . "`n")
}

TestFlaskTypeConversion() {
    ; フラスコタイプ変換のテスト
    types := ["Life", "Mana", "Utility", "Quicksilver", "Unique"]
    
    Loop types.Length {
        typeName := types[A_Index]
        index := GetFlaskTypeIndex(typeName)
        convertedName := GetFlaskTypeName(index)
        
        OutputDebug("Type: " . typeName . " -> Index: " . index . " -> Name: " . convertedName . "`n")
        
        if (typeName != convertedName) {
            OutputDebug("エラー: タイプ変換が一致しません`n")
        }
    }
}

; ヘルパー関数（SettingsWindow.ahkから）
GetFlaskTypeIndex(typeName) {
    switch (typeName) {
        case "Life":
            return 1
        case "Mana":
            return 2
        case "Utility":
            return 3
        case "Quicksilver":
            return 4
        case "Unique":
            return 5
        default:
            return 1
    }
}

GetFlaskTypeName(index) {
    switch (index) {
        case 1:
            return "Life"
        case 2:
            return "Mana"
        case 3:
            return "Utility"
        case 4:
            return "Quicksilver"
        case 5:
            return "Unique"
        default:
            return "Life"
    }
}