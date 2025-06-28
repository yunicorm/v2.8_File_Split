; ===================================================================
; 設定ウィンドウ GUI
; フラスコ、スキル、一般設定のタブ付きインターフェース
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
        
    } catch Error as e {
        LogError("SettingsWindow", "Failed to show settings window: " . e.Message)
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

; --- スキルタブを作成 ---
CreateSkillTab() {
    global g_settings_gui, g_settings_tab
    
    g_settings_tab.UseTab(2)
    
    ; ER（右クリック）スキル設定
    erGroup := g_settings_gui.Add("GroupBox", "x30 y60 w740 h120", "ER（右クリック）スキル")
    
    g_settings_gui.Add("Text", "x50 y90", "最小間隔 (ms):")
    g_settings_gui.Add("Edit", "x150 y87 w80 vSkillER_Min")
    g_settings_gui.Add("Text", "x250 y90", "最大間隔 (ms):")
    g_settings_gui.Add("Edit", "x350 y87 w80 vSkillER_Max")
    
    g_settings_gui.Add("Text", "x50 y120", "ERキー:")
    g_settings_gui.Add("Edit", "x120 y117 w50 vSkillER_Key")
    
    g_settings_gui.Add("CheckBox", "x200 y120 vSkillER_Enabled", "ERスキル自動使用を有効化")
    
    ; T（キーボード）スキル設定
    tGroup := g_settings_gui.Add("GroupBox", "x30 y200 w740 h120", "T（キーボード）スキル")
    
    g_settings_gui.Add("Text", "x50 y230", "最小間隔 (ms):")
    g_settings_gui.Add("Edit", "x150 y227 w80 vSkillT_Min")
    g_settings_gui.Add("Text", "x250 y230", "最大間隔 (ms):")
    g_settings_gui.Add("Edit", "x350 y227 w80 vSkillT_Max")
    
    g_settings_gui.Add("Text", "x50 y260", "Tキー:")
    g_settings_gui.Add("Edit", "x120 y257 w50 vSkillT_Key")
    
    g_settings_gui.Add("CheckBox", "x200 y260 vSkillT_Enabled", "Tスキル自動使用を有効化")
    
    ; Wine of the Prophet設定
    wineGroup := g_settings_gui.Add("GroupBox", "x30 y340 w740 h140", "Wine of the Prophet設定")
    
    g_settings_gui.Add("Text", "x50 y370", "Stage1間隔 (ms):")
    g_settings_gui.Add("Edit", "x160 y367 w80 vWine_Stage1")
    g_settings_gui.Add("Text", "x260 y370", "Stage2間隔 (ms):")
    g_settings_gui.Add("Edit", "x370 y367 w80 vWine_Stage2")
    
    g_settings_gui.Add("Text", "x50 y400", "Stage3間隔 (ms):")
    g_settings_gui.Add("Edit", "x160 y397 w80 vWine_Stage3")
    g_settings_gui.Add("Text", "x260 y400", "Stage4間隔 (ms):")
    g_settings_gui.Add("Edit", "x370 y397 w80 vWine_Stage4")
    
    g_settings_gui.Add("CheckBox", "x50 y430 vWine_DynamicTiming", "動的タイミング調整を有効化")
}

; --- 一般タブを作成 ---
CreateGeneralTab() {
    global g_settings_gui, g_settings_tab
    
    g_settings_tab.UseTab(3)
    
    ; デバッグ・ログ設定
    debugGroup := g_settings_gui.Add("GroupBox", "x30 y60 w740 h120", "デバッグ・ログ設定")
    
    g_settings_gui.Add("CheckBox", "x50 y90 vDebugMode", "デバッグモードを有効化")
    g_settings_gui.Add("CheckBox", "x50 y120 vLogEnabled", "ログ出力を有効化")
    
    g_settings_gui.Add("Text", "x250 y90", "最大ログサイズ (MB):")
    g_settings_gui.Add("Edit", "x380 y87 w80 vMaxLogSize")
    
    g_settings_gui.Add("Text", "x250 y120", "ログ保持日数:")
    g_settings_gui.Add("Edit", "x350 y117 w80 vLogRetentionDays")
    
    ; 自動開始設定
    autoGroup := g_settings_gui.Add("GroupBox", "x30 y200 w740 h100", "自動開始設定")
    
    g_settings_gui.Add("CheckBox", "x50 y230 vAutoStart", "自動開始を有効化")
    g_settings_gui.Add("Text", "x50 y260", "開始遅延 (ms):")
    g_settings_gui.Add("Edit", "x150 y257 w80 vAutoStartDelay")
    
    ; マナ検出設定
    manaGroup := g_settings_gui.Add("GroupBox", "x30 y320 w740 h140", "マナ検出設定")
    
    g_settings_gui.Add("Text", "x50 y350", "中心X座標:")
    g_settings_gui.Add("Edit", "x130 y347 w80 vMana_CenterX")
    g_settings_gui.Add("Text", "x230 y350", "中心Y座標:")
    g_settings_gui.Add("Edit", "x310 y347 w80 vMana_CenterY")
    
    g_settings_gui.Add("Text", "x50 y380", "検出半径:")
    g_settings_gui.Add("Edit", "x130 y377 w80 vMana_Radius")
    g_settings_gui.Add("Text", "x230 y380", "青閾値:")
    g_settings_gui.Add("Edit", "x290 y377 w80 vMana_BlueThreshold")
    
    g_settings_gui.Add("Text", "x50 y410", "監視間隔 (ms):")
    g_settings_gui.Add("Edit", "x150 y407 w80 vMana_MonitorInterval")
    
    g_settings_gui.Add("CheckBox", "x270 y410 vMana_OptimizedDetection", "最適化検出を有効化")
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
    global g_settings_gui, g_temp_config
    
    try {
        ; 一時的な設定マップをクリア
        g_temp_config := Map()
        
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
        
        ; スキル設定
        g_settings_gui["SkillER_Min"].Text := ConfigManager.Get("Timing", "SkillER_Min", "500")
        g_settings_gui["SkillER_Max"].Text := ConfigManager.Get("Timing", "SkillER_Max", "1000")
        g_settings_gui["SkillER_Key"].Text := ConfigManager.Get("Keys", "SkillER", "RButton")
        g_settings_gui["SkillER_Enabled"].Checked := ConfigManager.Get("General", "SkillER_Enabled", true)
        
        g_settings_gui["SkillT_Min"].Text := ConfigManager.Get("Timing", "SkillT_Min", "4000")
        g_settings_gui["SkillT_Max"].Text := ConfigManager.Get("Timing", "SkillT_Max", "7000")
        g_settings_gui["SkillT_Key"].Text := ConfigManager.Get("Keys", "SkillT", "t")
        g_settings_gui["SkillT_Enabled"].Checked := ConfigManager.Get("General", "SkillT_Enabled", true)
        
        ; Wine設定
        g_settings_gui["Wine_Stage1"].Text := ConfigManager.Get("Wine", "Stage1Interval", "1000")
        g_settings_gui["Wine_Stage2"].Text := ConfigManager.Get("Wine", "Stage2Interval", "800")
        g_settings_gui["Wine_Stage3"].Text := ConfigManager.Get("Wine", "Stage3Interval", "600")
        g_settings_gui["Wine_Stage4"].Text := ConfigManager.Get("Wine", "Stage4Interval", "400")
        g_settings_gui["Wine_DynamicTiming"].Checked := ConfigManager.Get("Wine", "DynamicTiming", true)
        
        ; 一般設定
        g_settings_gui["DebugMode"].Checked := ConfigManager.Get("General", "DebugMode", false)
        g_settings_gui["LogEnabled"].Checked := ConfigManager.Get("General", "LogEnabled", true)
        g_settings_gui["MaxLogSize"].Text := ConfigManager.Get("General", "MaxLogSize", "10")
        g_settings_gui["LogRetentionDays"].Text := ConfigManager.Get("General", "LogRetentionDays", "7")
        g_settings_gui["AutoStart"].Checked := ConfigManager.Get("General", "AutoStart", false)
        g_settings_gui["AutoStartDelay"].Text := ConfigManager.Get("General", "AutoStartDelay", "5000")
        
        ; マナ設定
        g_settings_gui["Mana_CenterX"].Text := ConfigManager.Get("Mana", "CenterX", "1720")
        g_settings_gui["Mana_CenterY"].Text := ConfigManager.Get("Mana", "CenterY", "1300")
        g_settings_gui["Mana_Radius"].Text := ConfigManager.Get("Mana", "Radius", "25")
        g_settings_gui["Mana_BlueThreshold"].Text := ConfigManager.Get("Mana", "BlueThreshold", "100")
        g_settings_gui["Mana_MonitorInterval"].Text := ConfigManager.Get("Mana", "MonitorInterval", "100")
        g_settings_gui["Mana_OptimizedDetection"].Checked := ConfigManager.Get("Mana", "OptimizedDetection", true)
        
        LogDebug("SettingsWindow", "Settings loaded successfully")
        
    } catch Error as e {
        LogError("SettingsWindow", "Failed to load settings: " . e.Message)
        ShowOverlay("設定の読み込みに失敗しました", 3000)
    }
}

; --- 設定を保存 ---
SaveSettings(*) {
    global g_settings_gui, g_settings_open
    
    try {
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
        
        ; スキル設定を保存
        ConfigManager.Set("Timing", "SkillER_Min", g_settings_gui["SkillER_Min"].Text)
        ConfigManager.Set("Timing", "SkillER_Max", g_settings_gui["SkillER_Max"].Text)
        ConfigManager.Set("Keys", "SkillER", g_settings_gui["SkillER_Key"].Text)
        ConfigManager.Set("General", "SkillER_Enabled", g_settings_gui["SkillER_Enabled"].Checked)
        
        ConfigManager.Set("Timing", "SkillT_Min", g_settings_gui["SkillT_Min"].Text)
        ConfigManager.Set("Timing", "SkillT_Max", g_settings_gui["SkillT_Max"].Text)
        ConfigManager.Set("Keys", "SkillT", g_settings_gui["SkillT_Key"].Text)
        ConfigManager.Set("General", "SkillT_Enabled", g_settings_gui["SkillT_Enabled"].Checked)
        
        ; Wine設定を保存
        ConfigManager.Set("Wine", "Stage1Interval", g_settings_gui["Wine_Stage1"].Text)
        ConfigManager.Set("Wine", "Stage2Interval", g_settings_gui["Wine_Stage2"].Text)
        ConfigManager.Set("Wine", "Stage3Interval", g_settings_gui["Wine_Stage3"].Text)
        ConfigManager.Set("Wine", "Stage4Interval", g_settings_gui["Wine_Stage4"].Text)
        ConfigManager.Set("Wine", "DynamicTiming", g_settings_gui["Wine_DynamicTiming"].Checked)
        
        ; 一般設定を保存
        ConfigManager.Set("General", "DebugMode", g_settings_gui["DebugMode"].Checked)
        ConfigManager.Set("General", "LogEnabled", g_settings_gui["LogEnabled"].Checked)
        ConfigManager.Set("General", "MaxLogSize", g_settings_gui["MaxLogSize"].Text)
        ConfigManager.Set("General", "LogRetentionDays", g_settings_gui["LogRetentionDays"].Text)
        ConfigManager.Set("General", "AutoStart", g_settings_gui["AutoStart"].Checked)
        ConfigManager.Set("General", "AutoStartDelay", g_settings_gui["AutoStartDelay"].Text)
        
        ; マナ設定を保存
        ConfigManager.Set("Mana", "CenterX", g_settings_gui["Mana_CenterX"].Text)
        ConfigManager.Set("Mana", "CenterY", g_settings_gui["Mana_CenterY"].Text)
        ConfigManager.Set("Mana", "Radius", g_settings_gui["Mana_Radius"].Text)
        ConfigManager.Set("Mana", "BlueThreshold", g_settings_gui["Mana_BlueThreshold"].Text)
        ConfigManager.Set("Mana", "MonitorInterval", g_settings_gui["Mana_MonitorInterval"].Text)
        ConfigManager.Set("Mana", "OptimizedDetection", g_settings_gui["Mana_OptimizedDetection"].Checked)
        
        ; 設定を保存
        ConfigManager.Save()
        
        ; FlaskManagerの設定を更新
        UpdateFlaskManagerConfig()
        
        ShowOverlay("設定を保存しました", 2000)
        LogInfo("SettingsWindow", "Settings saved successfully")
        
        ; ウィンドウを閉じる
        CloseSettingsWindow()
        
    } catch Error as e {
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
        } catch Error as e {
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
        
    } catch Error as e {
        LogError("SettingsWindow", "Error closing settings window: " . e.Message)
    }
}

; --- イベントハンドラー ---
SettingsWindow_Resize(GuiObj, MinMax, Width, Height) {
    ; ウィンドウリサイズ時の処理（将来の拡張用）
}

SettingsWindow_Close(GuiObj) {
    CloseSettingsWindow()
}

Tab_Change(GuiCtrlObj, Info) {
    ; タブ変更時の処理（将来の拡張用）
    LogDebug("SettingsWindow", "Tab changed to: " . Info)
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
            LogInfo("SettingsWindow", "FlaskManager configuration updated with " . flaskConfig.Count . " active flasks")
        } else {
            LogWarn("SettingsWindow", "ConfigureFlasks function not available")
        }
        
    } catch Error as e {
        LogError("SettingsWindow", "Failed to update FlaskManager config: " . e.Message)
    }
}