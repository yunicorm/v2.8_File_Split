; ===================================================================
; 設定ウィンドウ メイン管理
; GUI作成、イベント処理、設定統括制御
; ===================================================================

; --- グローバル変数 ---
global g_settings_gui := ""
global g_settings_tab := ""
global g_settings_open := false
global g_temp_config := Map()

; --- 設定ウィンドウを表示 ---
ShowSettingsWindow() {
    global g_settings_gui, g_settings_open
    
    ; 既に開いている場合は前面に表示
    if (g_settings_open && IsSet(g_settings_gui) && IsObject(g_settings_gui)) {
        try {
            g_settings_gui.Show()
            return
        } catch {
            ; エラーの場合は再作成
        }
    }
    
    try {
        CreateSettingsWindow()
        LoadCurrentSettings()
        g_settings_gui.Show()
        g_settings_open := true
        
        LogInfo("SettingsWindow", "Settings window opened")
        
    } catch as e {
        ; 詳細なエラー情報をログに記録
        errorDetails := Format("Error: {} | File: {} | Line: {} | Stack: {}", 
            e.Message, 
            e.HasProp("File") ? e.File : "Unknown",
            e.HasProp("Line") ? e.Line : "Unknown",
            e.HasProp("Stack") ? e.Stack : "No stack trace")
        
        LogError("SettingsWindow", "Failed to show settings window: " . errorDetails)
        ShowOverlay("設定ウィンドウの表示に失敗しました", 3000)
    }
}

; --- 設定ウィンドウを作成 ---
CreateSettingsWindow() {
    global g_settings_gui, g_settings_tab
    
    ; 既存のGUIを破棄
    if (IsSet(g_settings_gui) && IsObject(g_settings_gui)) {
        try {
            g_settings_gui.Destroy()
        } catch {
            ; エラーは無視
        }
    }
    
    ; メインウィンドウを作成
    g_settings_gui := Gui("+Resize -MaximizeBox", "Path of Exile Macro - 設定")
    g_settings_gui.BackColor := "White"
    g_settings_gui.MarginX := 15
    g_settings_gui.MarginY := 15
    
    ; ウィンドウサイズを設定
    g_settings_gui.OnEvent("Size", SettingsWindow_Resize)
    g_settings_gui.OnEvent("Close", SettingsWindow_Close)
    
    ; タブコントロールを作成
    g_settings_tab := g_settings_gui.Add("Tab3", "x15 y15 w770 h520", ["フラスコ", "スキル", "一般"])
    g_settings_tab.OnEvent("Change", Tab_Change)
    
    ; 各タブの内容を作成
    CreateFlaskTab()
    CreateSkillTab()
    CreateGeneralTab()
    
    ; ボタンを作成
    CreateButtons()
    
    ; 初期タブを選択
    g_settings_tab.Choose(1)
}

; --- ボタンを作成 ---
CreateButtons() {
    global g_settings_gui
    
    ; 下部にボタンを配置
    g_settings_gui.Add("Button", "x530 y550 w100 h30 vSaveButton", "保存").OnEvent("Click", SaveSettings)
    g_settings_gui.Add("Button", "x640 y550 w100 h30 vCancelButton", "キャンセル").OnEvent("Click", CancelSettings)
    g_settings_gui.Add("Button", "x420 y550 w100 h30 vResetButton", "リセット").OnEvent("Click", ResetSettings)
}

; --- 現在の設定を読み込み ---
LoadCurrentSettings() {
    global g_temp_config
    
    try {
        ; 一時的な設定マップをクリア
        g_temp_config := Map()
        
        ; 各タブの設定を読み込み
        LoadFlaskSettings()
        LoadSkillSettings()
        LoadGeneralSettings()
        
        LogDebug("SettingsWindow", "Settings loaded successfully")
        
    } catch as e {
        LogError("SettingsWindow", "Failed to load settings: " . e.Message)
        ShowOverlay("設定の読み込みに失敗しました", 3000)
    }
}

; --- 設定を保存 ---
SaveSettings(*) {
    global g_settings_gui, g_settings_open
    
    try {
        ; 入力値を検証
        validationErrors := ValidateAllSettings()
        
        if (validationErrors.Length > 0) {
            errorMessage := "設定に以下のエラーがあります:`n`n"
            for error in validationErrors {
                errorMessage .= "• " . error . "`n"
            }
            
            MsgBox(errorMessage, "設定エラー", "OK Icon!")
            LogWarn("SettingsWindow", "Validation failed: " . validationErrors.Length . " errors")
            return
        }
        
        ; 各タブの設定を保存
        SaveFlaskSettings()
        SaveSkillSettings()
        SaveGeneralSettings()
        
        ; 設定を保存
        ConfigManager.Save()
        
        ; マネージャーの設定を更新
        UpdateFlaskManagerConfig()
        UpdateSkillManagerConfig()
        
        ShowOverlay("設定を保存しました", 2000)
        LogInfo("SettingsWindow", "Settings saved successfully")
        
        ; ウィンドウを閉じる
        CloseSettingsWindow()
        
    } catch as e {
        LogError("SettingsWindow", "Failed to save settings: " . e.Message)
        ShowOverlay("設定の保存に失敗しました", 3000)
    }
}

; --- 設定をキャンセル ---
CancelSettings(*) {
    CloseSettingsWindow()
    LogDebug("SettingsWindow", "Settings cancelled")
}

; --- 設定をリセット ---
ResetSettings(*) {
    result := MsgBox("設定をデフォルト値にリセットしますか？", "確認", "YesNo Icon?")
    if (result = "Yes") {
        try {
            ConfigManager.ResetToDefaults()
            LoadCurrentSettings()
            ShowOverlay("設定をリセットしました", 2000)
            LogInfo("SettingsWindow", "Settings reset to defaults")
        } catch as e {
            LogError("SettingsWindow", "Failed to reset settings: " . e.Message)
            ShowOverlay("設定のリセットに失敗しました", 3000)
        }
    }
}

; --- 設定ウィンドウを閉じる ---
CloseSettingsWindow() {
    global g_settings_gui, g_settings_open
    
    try {
        if (IsSet(g_settings_gui) && IsObject(g_settings_gui)) {
            g_settings_gui.Hide()
        }
        g_settings_open := false
        
    } catch as e {
        LogError("SettingsWindow", "Error closing settings window: " . e.Message)
    }
}

; --- イベントハンドラー ---
SettingsWindow_Resize(*) {
    ; ウィンドウリサイズ時の処理（将来の拡張用）
}

SettingsWindow_Close(*) {
    CloseSettingsWindow()
}

Tab_Change(*) {
    ; タブ変更時の処理（将来の拡張用）
    global g_settings_tab
    if (IsSet(g_settings_tab)) {
        currentTab := g_settings_tab.Value
        LogDebug("SettingsWindow", "Tab changed to: " . currentTab)
    }
}