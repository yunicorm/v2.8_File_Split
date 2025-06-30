; ===================================================================
; フラスコタブ専用モジュール
; フラスコ・Tincture設定のGUI作成と処理
; ===================================================================

; --- フラスコタブを作成 ---
CreateFlaskTab() {
    global g_settings_gui, g_settings_tab
    
    g_settings_tab.UseTab(1)
    
    ; フラスコ設定グループ
    flaskGroup := g_settings_gui.Add("GroupBox", "x30 y60 w740 h280", "フラスコ設定")
    
    ; ヘッダー
    g_settings_gui.Add("Text", "x50 y85", "有効")
    g_settings_gui.Add("Text", "x100 y85", "フラスコ")
    g_settings_gui.Add("Text", "x190 y85", "キー")
    g_settings_gui.Add("Text", "x260 y85", "間隔 Min (ms)")
    g_settings_gui.Add("Text", "x370 y85", "間隔 Max (ms)")
    g_settings_gui.Add("Text", "x480 y85", "タイプ")
    
    ; Flask 1
    g_settings_gui.Add("CheckBox", "x50 y110 vFlask1_Enabled")
    g_settings_gui.Add("Text", "x100 y113", "Flask 1")
    g_settings_gui.Add("Edit", "x190 y110 w50 vFlask1_Key")
    g_settings_gui.Add("Edit", "x260 y110 w60 vFlask1_Min")
    g_settings_gui.Add("Edit", "x370 y110 w60 vFlask1_Max")
    g_settings_gui.Add("DropDownList", "x480 y110 w100 vFlask1_Type", ["Life", "Mana", "Utility", "Quicksilver", "Unique"])
    
    ; Flask 2
    g_settings_gui.Add("CheckBox", "x50 y140 vFlask2_Enabled")
    g_settings_gui.Add("Text", "x100 y143", "Flask 2")
    g_settings_gui.Add("Edit", "x190 y140 w50 vFlask2_Key")
    g_settings_gui.Add("Edit", "x260 y140 w60 vFlask2_Min")
    g_settings_gui.Add("Edit", "x370 y140 w60 vFlask2_Max")
    g_settings_gui.Add("DropDownList", "x480 y140 w100 vFlask2_Type", ["Life", "Mana", "Utility", "Quicksilver", "Unique"])
    
    ; Flask 3
    g_settings_gui.Add("CheckBox", "x50 y170 vFlask3_Enabled")
    g_settings_gui.Add("Text", "x100 y173", "Flask 3")
    g_settings_gui.Add("Edit", "x190 y170 w50 vFlask3_Key")
    g_settings_gui.Add("Edit", "x260 y170 w60 vFlask3_Min")
    g_settings_gui.Add("Edit", "x370 y170 w60 vFlask3_Max")
    g_settings_gui.Add("DropDownList", "x480 y170 w100 vFlask3_Type", ["Life", "Mana", "Utility", "Quicksilver", "Unique"])
    
    ; Flask 4
    g_settings_gui.Add("CheckBox", "x50 y200 vFlask4_Enabled")
    g_settings_gui.Add("Text", "x100 y203", "Flask 4")
    g_settings_gui.Add("Edit", "x190 y200 w50 vFlask4_Key")
    g_settings_gui.Add("Edit", "x260 y200 w60 vFlask4_Min")
    g_settings_gui.Add("Edit", "x370 y200 w60 vFlask4_Max")
    g_settings_gui.Add("DropDownList", "x480 y200 w100 vFlask4_Type", ["Life", "Mana", "Utility", "Quicksilver", "Unique"])
    
    ; Flask 5
    g_settings_gui.Add("CheckBox", "x50 y230 vFlask5_Enabled")
    g_settings_gui.Add("Text", "x100 y233", "Flask 5")
    g_settings_gui.Add("Edit", "x190 y230 w50 vFlask5_Key")
    g_settings_gui.Add("Edit", "x260 y230 w60 vFlask5_Min")
    g_settings_gui.Add("Edit", "x370 y230 w60 vFlask5_Max")
    g_settings_gui.Add("DropDownList", "x480 y230 w100 vFlask5_Type", ["Life", "Mana", "Utility", "Quicksilver", "Unique"])
    
    ; フラスコ全体有効化
    g_settings_gui.Add("CheckBox", "x50 y270 vFlaskEnabled", "フラスコ自動使用を有効化")
    
    ; Tincture設定グループ
    tinctureGroup := g_settings_gui.Add("GroupBox", "x30 y360 w740 h140", "Tincture設定")
    
    g_settings_gui.Add("Text", "x50 y390", "リトライ最大回数:")
    g_settings_gui.Add("Edit", "x180 y387 w80 vTincture_RetryMax")
    
    g_settings_gui.Add("Text", "x50 y420", "リトライ間隔 (ms):")
    g_settings_gui.Add("Edit", "x180 y417 w80 vTincture_RetryInterval")
    
    g_settings_gui.Add("Text", "x300 y390", "検証遅延 (ms):")
    g_settings_gui.Add("Edit", "x420 y387 w80 vTincture_VerifyDelay")
    
    g_settings_gui.Add("Text", "x300 y420", "枯渇クールダウン (ms):")
    g_settings_gui.Add("Edit", "x420 y417 w80 vTincture_DepletedCooldown")
    
    g_settings_gui.Add("Text", "x50 y450", "Tinctureキー:")
    g_settings_gui.Add("Edit", "x150 y447 w50 vTinctureKey")
    
    g_settings_gui.Add("CheckBox", "x250 y450 vTinctureEnabled", "Tincture使用を有効化")
}

; --- フラスコ設定を読み込み ---
LoadFlaskSettings() {
    global g_settings_gui
    
    try {
        ; フラスコ設定
        g_settings_gui["Flask1_Enabled"].Checked := ConfigManager.Get("Flask", "Flask1_Enabled", false)
        g_settings_gui["Flask1_Key"].Text := ConfigManager.Get("Flask", "Flask1_Key", "1")
        g_settings_gui["Flask1_Min"].Text := ConfigManager.Get("Flask", "Flask1_Min", "3000")
        g_settings_gui["Flask1_Max"].Text := ConfigManager.Get("Flask", "Flask1_Max", "3500")
        g_settings_gui["Flask1_Type"].Choose(GetFlaskTypeIndex(ConfigManager.Get("Flask", "Flask1_Type", "Life")))
        
        g_settings_gui["Flask2_Enabled"].Checked := ConfigManager.Get("Flask", "Flask2_Enabled", true)
        g_settings_gui["Flask2_Key"].Text := ConfigManager.Get("Flask", "Flask2_Key", "2")
        g_settings_gui["Flask2_Min"].Text := ConfigManager.Get("Flask", "Flask2_Min", "4500")
        g_settings_gui["Flask2_Max"].Text := ConfigManager.Get("Flask", "Flask2_Max", "4800")
        g_settings_gui["Flask2_Type"].Choose(GetFlaskTypeIndex(ConfigManager.Get("Flask", "Flask2_Type", "Mana")))
        
        g_settings_gui["Flask3_Enabled"].Checked := ConfigManager.Get("Flask", "Flask3_Enabled", false)
        g_settings_gui["Flask3_Key"].Text := ConfigManager.Get("Flask", "Flask3_Key", "3")
        g_settings_gui["Flask3_Min"].Text := ConfigManager.Get("Flask", "Flask3_Min", "5000")
        g_settings_gui["Flask3_Max"].Text := ConfigManager.Get("Flask", "Flask3_Max", "5500")
        g_settings_gui["Flask3_Type"].Choose(GetFlaskTypeIndex(ConfigManager.Get("Flask", "Flask3_Type", "Utility")))
        
        g_settings_gui["Flask4_Enabled"].Checked := ConfigManager.Get("Flask", "Flask4_Enabled", false)
        g_settings_gui["Flask4_Key"].Text := ConfigManager.Get("Flask", "Flask4_Key", "4")
        g_settings_gui["Flask4_Min"].Text := ConfigManager.Get("Flask", "Flask4_Min", "8000")
        g_settings_gui["Flask4_Max"].Text := ConfigManager.Get("Flask", "Flask4_Max", "8500")
        g_settings_gui["Flask4_Type"].Choose(GetFlaskTypeIndex(ConfigManager.Get("Flask", "Flask4_Type", "Utility")))
        
        g_settings_gui["Flask5_Enabled"].Checked := ConfigManager.Get("Flask", "Flask5_Enabled", false)
        g_settings_gui["Flask5_Key"].Text := ConfigManager.Get("Flask", "Flask5_Key", "5")
        g_settings_gui["Flask5_Min"].Text := ConfigManager.Get("Flask", "Flask5_Min", "6000")
        g_settings_gui["Flask5_Max"].Text := ConfigManager.Get("Flask", "Flask5_Max", "6500")
        g_settings_gui["Flask5_Type"].Choose(GetFlaskTypeIndex(ConfigManager.Get("Flask", "Flask5_Type", "Quicksilver")))
        
        g_settings_gui["FlaskEnabled"].Checked := ConfigManager.Get("General", "FlaskEnabled", true)
        
        ; Tincture設定
        g_settings_gui["Tincture_RetryMax"].Text := ConfigManager.Get("Tincture", "RetryMax", "3")
        g_settings_gui["Tincture_RetryInterval"].Text := ConfigManager.Get("Tincture", "RetryInterval", "500")
        g_settings_gui["Tincture_VerifyDelay"].Text := ConfigManager.Get("Tincture", "VerifyDelay", "200")
        g_settings_gui["Tincture_DepletedCooldown"].Text := ConfigManager.Get("Tincture", "DepletedCooldown", "3000")
        g_settings_gui["TinctureKey"].Text := ConfigManager.Get("Keys", "Tincture", "e")
        g_settings_gui["TinctureEnabled"].Checked := ConfigManager.Get("General", "TinctureEnabled", true)
        
    } catch as e {
        LogError("FlaskTab", "Failed to load flask settings: " . e.Message)
    }
}

; --- フラスコ設定を保存 ---
SaveFlaskSettings() {
    global g_settings_gui
    
    try {
        LogDebug("FlaskTab", "SaveFlaskSettings開始")
        LogDebug("FlaskTab", "g_settings_gui type: " . Type(g_settings_gui))
        ; フラスコ設定を保存
        ConfigManager.Set("Flask", "Flask1_Enabled", g_settings_gui["Flask1_Enabled"].Checked)
        ConfigManager.Set("Flask", "Flask1_Key", g_settings_gui["Flask1_Key"].Text)
        ConfigManager.Set("Flask", "Flask1_Min", g_settings_gui["Flask1_Min"].Text)
        ConfigManager.Set("Flask", "Flask1_Max", g_settings_gui["Flask1_Max"].Text)
        ConfigManager.Set("Flask", "Flask1_Type", GetFlaskTypeName(g_settings_gui["Flask1_Type"].Value))
        
        ConfigManager.Set("Flask", "Flask2_Enabled", g_settings_gui["Flask2_Enabled"].Checked)
        ConfigManager.Set("Flask", "Flask2_Key", g_settings_gui["Flask2_Key"].Text)
        ConfigManager.Set("Flask", "Flask2_Min", g_settings_gui["Flask2_Min"].Text)
        ConfigManager.Set("Flask", "Flask2_Max", g_settings_gui["Flask2_Max"].Text)
        ConfigManager.Set("Flask", "Flask2_Type", GetFlaskTypeName(g_settings_gui["Flask2_Type"].Value))
        
        ConfigManager.Set("Flask", "Flask3_Enabled", g_settings_gui["Flask3_Enabled"].Checked)
        ConfigManager.Set("Flask", "Flask3_Key", g_settings_gui["Flask3_Key"].Text)
        ConfigManager.Set("Flask", "Flask3_Min", g_settings_gui["Flask3_Min"].Text)
        ConfigManager.Set("Flask", "Flask3_Max", g_settings_gui["Flask3_Max"].Text)
        ConfigManager.Set("Flask", "Flask3_Type", GetFlaskTypeName(g_settings_gui["Flask3_Type"].Value))
        
        ConfigManager.Set("Flask", "Flask4_Enabled", g_settings_gui["Flask4_Enabled"].Checked)
        ConfigManager.Set("Flask", "Flask4_Key", g_settings_gui["Flask4_Key"].Text)
        ConfigManager.Set("Flask", "Flask4_Min", g_settings_gui["Flask4_Min"].Text)
        ConfigManager.Set("Flask", "Flask4_Max", g_settings_gui["Flask4_Max"].Text)
        ConfigManager.Set("Flask", "Flask4_Type", GetFlaskTypeName(g_settings_gui["Flask4_Type"].Value))
        
        ConfigManager.Set("Flask", "Flask5_Enabled", g_settings_gui["Flask5_Enabled"].Checked)
        ConfigManager.Set("Flask", "Flask5_Key", g_settings_gui["Flask5_Key"].Text)
        ConfigManager.Set("Flask", "Flask5_Min", g_settings_gui["Flask5_Min"].Text)
        ConfigManager.Set("Flask", "Flask5_Max", g_settings_gui["Flask5_Max"].Text)
        ConfigManager.Set("Flask", "Flask5_Type", GetFlaskTypeName(g_settings_gui["Flask5_Type"].Value))
        
        ConfigManager.Set("General", "FlaskEnabled", g_settings_gui["FlaskEnabled"].Checked)
        
        ; Tincture設定を保存
        ConfigManager.Set("Tincture", "RetryMax", g_settings_gui["Tincture_RetryMax"].Text)
        ConfigManager.Set("Tincture", "RetryInterval", g_settings_gui["Tincture_RetryInterval"].Text)
        ConfigManager.Set("Tincture", "VerifyDelay", g_settings_gui["Tincture_VerifyDelay"].Text)
        ConfigManager.Set("Tincture", "DepletedCooldown", g_settings_gui["Tincture_DepletedCooldown"].Text)
        ConfigManager.Set("Keys", "Tincture", g_settings_gui["TinctureKey"].Text)
        ConfigManager.Set("General", "TinctureEnabled", g_settings_gui["TinctureEnabled"].Checked)
        
        LogDebug("FlaskTab", "ConfigManager.Set calls completed successfully")
        
    } catch as e {
        LogError("FlaskTab", "Failed to save flask settings: " . e.Message)
        LogError("FlaskTab", "Error details - File: " . (e.HasProp("File") ? e.File : "Unknown") . " Line: " . (e.HasProp("Line") ? e.Line : "Unknown"))
        throw e
    }
}

; --- フラスコタイプのヘルパー関数 ---
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

; --- FlaskManagerの設定を更新 ---
UpdateFlaskManagerConfig() {
    try {
        ; 新しいフラスコ設定マップを作成
        flaskConfig := Map()
        
        ; 各フラスコの設定を読み込み
        Loop 5 {
    flaskNum := A_Index
            enabled := ConfigManager.Get("Flask", "Flask" . flaskNum . "_Enabled", false)
            
            if (enabled) {
                flaskConfig["flask" . flaskNum] := {
                    key: ConfigManager.Get("Flask", "Flask" . flaskNum . "_Key", "" . flaskNum),
                    type: StrLower(ConfigManager.Get("Flask", "Flask" . flaskNum . "_Type", "Life")),
                    minInterval: Integer(ConfigManager.Get("Flask", "Flask" . flaskNum . "_Min", "3000")),
                    maxInterval: Integer(ConfigManager.Get("Flask", "Flask" . flaskNum . "_Max", "3500")),
                    enabled: true,
                    priority: flaskNum
                }
            }
        }
        
        ; FlaskManagerの設定を更新（関数が存在する場合のみ）
        if (IsSet(ConfigureFlasks)) {
            ConfigureFlasks(flaskConfig)
            LogInfo("FlaskTab", "FlaskManager configuration updated with " . flaskConfig.Count . " active flasks")
        } else {
            LogWarn("FlaskTab", "ConfigureFlasks function not available")
        }
        
    } catch as e {
        LogError("FlaskTab", "Failed to update FlaskManager config: " . e.Message)
    }
}