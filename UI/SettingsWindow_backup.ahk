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
        
    } catch as e {
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
    
    ; スキル設定グループ
    skillGroup := g_settings_gui.Add("GroupBox", "x30 y60 w740 h400", "スキル設定")
    
    ; ヘッダー
    g_settings_gui.Add("Text", "x40 y85", "有効")
    g_settings_gui.Add("Text", "x80 y85", "スキル名")
    g_settings_gui.Add("Text", "x200 y85", "キー")
    g_settings_gui.Add("Text", "x270 y85", "間隔Min")
    g_settings_gui.Add("Text", "x340 y85", "間隔Max")
    g_settings_gui.Add("Text", "x410 y85", "優先度")
    
    ; Group 1 (Skill_1_1 ~ Skill_1_5)
    g_settings_gui.Add("Text", "x50 y110", "Group 1", "Bold")
    
    ; Skill_1_1
    g_settings_gui.Add("CheckBox", "x40 y130 vSkill_1_1_Enabled")
    g_settings_gui.Add("Edit", "x80 y127 w100 vSkill_1_1_Name")
    g_settings_gui.Add("Edit", "x200 y127 w50 vSkill_1_1_Key")
    g_settings_gui.Add("Edit", "x270 y127 w60 vSkill_1_1_Min")
    g_settings_gui.Add("Edit", "x340 y127 w60 vSkill_1_1_Max")
    g_settings_gui.Add("DropDownList", "x410 y127 w60 vSkill_1_1_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_1_2
    g_settings_gui.Add("CheckBox", "x40 y155 vSkill_1_2_Enabled")
    g_settings_gui.Add("Edit", "x80 y152 w100 vSkill_1_2_Name")
    g_settings_gui.Add("Edit", "x200 y152 w50 vSkill_1_2_Key")
    g_settings_gui.Add("Edit", "x270 y152 w60 vSkill_1_2_Min")
    g_settings_gui.Add("Edit", "x340 y152 w60 vSkill_1_2_Max")
    g_settings_gui.Add("DropDownList", "x410 y152 w60 vSkill_1_2_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_1_3
    g_settings_gui.Add("CheckBox", "x40 y180 vSkill_1_3_Enabled")
    g_settings_gui.Add("Edit", "x80 y177 w100 vSkill_1_3_Name")
    g_settings_gui.Add("Edit", "x200 y177 w50 vSkill_1_3_Key")
    g_settings_gui.Add("Edit", "x270 y177 w60 vSkill_1_3_Min")
    g_settings_gui.Add("Edit", "x340 y177 w60 vSkill_1_3_Max")
    g_settings_gui.Add("DropDownList", "x410 y177 w60 vSkill_1_3_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_1_4
    g_settings_gui.Add("CheckBox", "x40 y205 vSkill_1_4_Enabled")
    g_settings_gui.Add("Edit", "x80 y202 w100 vSkill_1_4_Name")
    g_settings_gui.Add("Edit", "x200 y202 w50 vSkill_1_4_Key")
    g_settings_gui.Add("Edit", "x270 y202 w60 vSkill_1_4_Min")
    g_settings_gui.Add("Edit", "x340 y202 w60 vSkill_1_4_Max")
    g_settings_gui.Add("DropDownList", "x410 y202 w60 vSkill_1_4_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_1_5
    g_settings_gui.Add("CheckBox", "x40 y230 vSkill_1_5_Enabled")
    g_settings_gui.Add("Edit", "x80 y227 w100 vSkill_1_5_Name")
    g_settings_gui.Add("Edit", "x200 y227 w50 vSkill_1_5_Key")
    g_settings_gui.Add("Edit", "x270 y227 w60 vSkill_1_5_Min")
    g_settings_gui.Add("Edit", "x340 y227 w60 vSkill_1_5_Max")
    g_settings_gui.Add("DropDownList", "x410 y227 w60 vSkill_1_5_Priority", ["1", "2", "3", "4", "5"])
    
    ; Group 2 (Skill_2_1 ~ Skill_2_5)
    g_settings_gui.Add("Text", "x50 y260", "Group 2", "Bold")
    
    ; Skill_2_1
    g_settings_gui.Add("CheckBox", "x40 y280 vSkill_2_1_Enabled")
    g_settings_gui.Add("Edit", "x80 y277 w100 vSkill_2_1_Name")
    g_settings_gui.Add("Edit", "x200 y277 w50 vSkill_2_1_Key")
    g_settings_gui.Add("Edit", "x270 y277 w60 vSkill_2_1_Min")
    g_settings_gui.Add("Edit", "x340 y277 w60 vSkill_2_1_Max")
    g_settings_gui.Add("DropDownList", "x410 y277 w60 vSkill_2_1_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_2_2
    g_settings_gui.Add("CheckBox", "x40 y305 vSkill_2_2_Enabled")
    g_settings_gui.Add("Edit", "x80 y302 w100 vSkill_2_2_Name")
    g_settings_gui.Add("Edit", "x200 y302 w50 vSkill_2_2_Key")
    g_settings_gui.Add("Edit", "x270 y302 w60 vSkill_2_2_Min")
    g_settings_gui.Add("Edit", "x340 y302 w60 vSkill_2_2_Max")
    g_settings_gui.Add("DropDownList", "x410 y302 w60 vSkill_2_2_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_2_3
    g_settings_gui.Add("CheckBox", "x40 y330 vSkill_2_3_Enabled")
    g_settings_gui.Add("Edit", "x80 y327 w100 vSkill_2_3_Name")
    g_settings_gui.Add("Edit", "x200 y327 w50 vSkill_2_3_Key")
    g_settings_gui.Add("Edit", "x270 y327 w60 vSkill_2_3_Min")
    g_settings_gui.Add("Edit", "x340 y327 w60 vSkill_2_3_Max")
    g_settings_gui.Add("DropDownList", "x410 y327 w60 vSkill_2_3_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_2_4
    g_settings_gui.Add("CheckBox", "x40 y355 vSkill_2_4_Enabled")
    g_settings_gui.Add("Edit", "x80 y352 w100 vSkill_2_4_Name")
    g_settings_gui.Add("Edit", "x200 y352 w50 vSkill_2_4_Key")
    g_settings_gui.Add("Edit", "x270 y352 w60 vSkill_2_4_Min")
    g_settings_gui.Add("Edit", "x340 y352 w60 vSkill_2_4_Max")
    g_settings_gui.Add("DropDownList", "x410 y352 w60 vSkill_2_4_Priority", ["1", "2", "3", "4", "5"])
    
    ; Skill_2_5
    g_settings_gui.Add("CheckBox", "x40 y380 vSkill_2_5_Enabled")
    g_settings_gui.Add("Edit", "x80 y377 w100 vSkill_2_5_Name")
    g_settings_gui.Add("Edit", "x200 y377 w50 vSkill_2_5_Key")
    g_settings_gui.Add("Edit", "x270 y377 w60 vSkill_2_5_Min")
    g_settings_gui.Add("Edit", "x340 y377 w60 vSkill_2_5_Max")
    g_settings_gui.Add("DropDownList", "x410 y377 w60 vSkill_2_5_Priority", ["1", "2", "3", "4", "5"])
    
    ; スキル自動化の全体設定
    g_settings_gui.Add("CheckBox", "x50 y420 vSkillEnabled", "スキル自動使用を有効化")
    
    ; Wine of the Prophet設定（簡素化）
    wineGroup := g_settings_gui.Add("GroupBox", "x30 y470 w740 h60", "Wine of the Prophet設定")
    
    g_settings_gui.Add("Text", "x50 y495", "Wine段階間隔 (ms):")
    g_settings_gui.Add("Edit", "x180 y492 w80 vWine_Interval")
    g_settings_gui.Add("CheckBox", "x280 y495 vWine_DynamicTiming", "動的タイミング調整を有効化")
}

; --- 一般タブを作成 ---
CreateGeneralTab() {
    global g_settings_gui, g_settings_tab
    
    g_settings_tab.UseTab(3)
    
    ; システム設定グループ
    systemGroup := g_settings_gui.Add("GroupBox", "x30 y60 w360 h140", "システム設定")
    
    g_settings_gui.Add("CheckBox", "x50 y90 vAutoStart", "マクロ自動開始")
    g_settings_gui.Add("Text", "x50 y120", "開始遅延 (ms):")
    g_settings_gui.Add("Edit", "x150 y117 w60 vAutoStartDelay")
    
    g_settings_gui.Add("Text", "x50 y150", "画面解像度:")
    g_settings_gui.Add("Edit", "x130 y147 w60 vScreenWidth")
    g_settings_gui.Add("Text", "x195 y150", "x")
    g_settings_gui.Add("Edit", "x210 y147 w60 vScreenHeight")
    g_settings_gui.Add("Button", "x280 y145 w80 h23 vDetectResolution", "自動検出").OnEvent("Click", DetectResolution)
    
    ; デバッグ・ログ設定
    debugGroup := g_settings_gui.Add("GroupBox", "x410 y60 w360 h140", "デバッグ・ログ設定")
    
    g_settings_gui.Add("CheckBox", "x430 y90 vDebugMode", "デバッグモード")
    g_settings_gui.Add("CheckBox", "x430 y120 vLogEnabled", "ログ記録")
    
    g_settings_gui.Add("Text", "x550 y90", "ログサイズ (MB):")
    g_settings_gui.Add("Edit", "x655 y87 w50 vMaxLogSize")
    
    g_settings_gui.Add("Text", "x550 y120", "保持日数:")
    g_settings_gui.Add("Edit", "x620 y117 w50 vLogRetentionDays")
    g_settings_gui.Add("Text", "x675 y120", "日")
    
    g_settings_gui.Add("Button", "x430 y160 w100 h25 vOpenLogFolder", "ログフォルダを開く").OnEvent("Click", OpenLogFolder)
    g_settings_gui.Add("Button", "x540 y160 w100 h25 vClearLogs", "ログをクリア").OnEvent("Click", ClearLogs)
    
    ; マナ検出設定
    manaGroup := g_settings_gui.Add("GroupBox", "x30 y210 w360 h180", "マナ検出設定")
    
    g_settings_gui.Add("Text", "x50 y240", "中心X座標:")
    g_settings_gui.Add("Edit", "x130 y237 w60 vMana_CenterX")
    g_settings_gui.Add("Text", "x200 y240", "Y座標:")
    g_settings_gui.Add("Edit", "x250 y237 w60 vMana_CenterY")
    g_settings_gui.Add("Button", "x320 y235 w60 h23 vGetManaPos", "取得").OnEvent("Click", GetManaPosition)
    
    g_settings_gui.Add("Text", "x50 y270", "検出半径:")
    g_settings_gui.Add("Edit", "x130 y267 w60 vMana_Radius")
    g_settings_gui.Add("Text", "x195 y270", "ピクセル")
    
    g_settings_gui.Add("Text", "x50 y300", "青色閾値:")
    g_settings_gui.Add("Edit", "x130 y297 w60 vMana_BlueThreshold")
    g_settings_gui.Add("Text", "x195 y300", "(0-255)")
    
    g_settings_gui.Add("Text", "x50 y330", "青色優位性:")
    g_settings_gui.Add("Edit", "x130 y327 w60 vMana_BlueDominance")
    
    g_settings_gui.Add("Text", "x50 y360", "監視間隔:")
    g_settings_gui.Add("Edit", "x130 y357 w60 vMana_MonitorInterval")
    g_settings_gui.Add("Text", "x195 y360", "ms")
    
    g_settings_gui.Add("CheckBox", "x250 y360 vMana_OptimizedDetection", "最適化検出")
    
    ; エリア検出設定
    areaGroup := g_settings_gui.Add("GroupBox", "x410 y210 w360 h180", "エリア検出設定")
    
    g_settings_gui.Add("CheckBox", "x430 y240 vClientLog_Enabled", "ログ監視を有効化")
    g_settings_gui.Add("Text", "x430 y270", "Client.txtパス:")
    g_settings_gui.Add("Edit", "x430 y290 w250 vClientLog_Path")
    g_settings_gui.Add("Button", "x690 y288 w70 h23 vBrowseLog", "参照...").OnEvent("Click", BrowseClientLog)
    
    g_settings_gui.Add("Text", "x430 y320", "チェック間隔:")
    g_settings_gui.Add("Edit", "x520 y317 w60 vClientLog_CheckInterval")
    g_settings_gui.Add("Text", "x585 y320", "ms")
    
    g_settings_gui.Add("CheckBox", "x430 y350 vClientLog_RestartInTown", "町での自動再開を有効化")
    
    ; パフォーマンス設定
    perfGroup := g_settings_gui.Add("GroupBox", "x30 y400 w360 h90", "パフォーマンス設定")
    
    g_settings_gui.Add("Text", "x50 y430", "色検出タイムアウト:")
    g_settings_gui.Add("Edit", "x180 y427 w60 vColorDetectTimeout")
    g_settings_gui.Add("Text", "x245 y430", "ms")
    
    g_settings_gui.Add("Text", "x50 y460", "マナサンプルレート:")
    g_settings_gui.Add("Edit", "x180 y457 w60 vManaSampleRate")
    g_settings_gui.Add("Text", "x245 y460", "(1-10)")
    
    ; UI設定
    uiGroup := g_settings_gui.Add("GroupBox", "x410 y400 w360 h90", "UI設定")
    
    g_settings_gui.Add("Text", "x430 y430", "オーバーレイ透明度:")
    g_settings_gui.Add("Edit", "x560 y427 w60 vOverlayTransparency")
    g_settings_gui.Add("Text", "x625 y430", "(0-255)")
    
    g_settings_gui.Add("Text", "x430 y460", "フォントサイズ:")
    g_settings_gui.Add("Edit", "x520 y457 w60 vOverlayFontSize")
    g_settings_gui.Add("Text", "x585 y460", "pt")
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
        ; Group 1 スキル (Skill_1_1 ~ Skill_1_5)
        g_settings_gui["Skill_1_1_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_1_1_Enabled", false)
        g_settings_gui["Skill_1_1_Name"].Text := ConfigManager.Get("Skill", "Skill_1_1_Name", "スキル1-1")
        g_settings_gui["Skill_1_1_Key"].Text := ConfigManager.Get("Skill", "Skill_1_1_Key", "q")
        g_settings_gui["Skill_1_1_Min"].Text := ConfigManager.Get("Skill", "Skill_1_1_Min", "1000")
        g_settings_gui["Skill_1_1_Max"].Text := ConfigManager.Get("Skill", "Skill_1_1_Max", "1500")
        g_settings_gui["Skill_1_1_Priority"].Choose(ConfigManager.Get("Skill", "Skill_1_1_Priority", "3"))
        
        g_settings_gui["Skill_1_2_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_1_2_Enabled", false)
        g_settings_gui["Skill_1_2_Name"].Text := ConfigManager.Get("Skill", "Skill_1_2_Name", "スキル1-2")
        g_settings_gui["Skill_1_2_Key"].Text := ConfigManager.Get("Skill", "Skill_1_2_Key", "w")
        g_settings_gui["Skill_1_2_Min"].Text := ConfigManager.Get("Skill", "Skill_1_2_Min", "1500")
        g_settings_gui["Skill_1_2_Max"].Text := ConfigManager.Get("Skill", "Skill_1_2_Max", "2000")
        g_settings_gui["Skill_1_2_Priority"].Choose(ConfigManager.Get("Skill", "Skill_1_2_Priority", "3"))
        
        g_settings_gui["Skill_1_3_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_1_3_Enabled", false)
        g_settings_gui["Skill_1_3_Name"].Text := ConfigManager.Get("Skill", "Skill_1_3_Name", "スキル1-3")
        g_settings_gui["Skill_1_3_Key"].Text := ConfigManager.Get("Skill", "Skill_1_3_Key", "e")
        g_settings_gui["Skill_1_3_Min"].Text := ConfigManager.Get("Skill", "Skill_1_3_Min", "2000")
        g_settings_gui["Skill_1_3_Max"].Text := ConfigManager.Get("Skill", "Skill_1_3_Max", "2500")
        g_settings_gui["Skill_1_3_Priority"].Choose(ConfigManager.Get("Skill", "Skill_1_3_Priority", "3"))
        
        g_settings_gui["Skill_1_4_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_1_4_Enabled", false)
        g_settings_gui["Skill_1_4_Name"].Text := ConfigManager.Get("Skill", "Skill_1_4_Name", "スキル1-4")
        g_settings_gui["Skill_1_4_Key"].Text := ConfigManager.Get("Skill", "Skill_1_4_Key", "r")
        g_settings_gui["Skill_1_4_Min"].Text := ConfigManager.Get("Skill", "Skill_1_4_Min", "3000")
        g_settings_gui["Skill_1_4_Max"].Text := ConfigManager.Get("Skill", "Skill_1_4_Max", "3500")
        g_settings_gui["Skill_1_4_Priority"].Choose(ConfigManager.Get("Skill", "Skill_1_4_Priority", "3"))
        
        g_settings_gui["Skill_1_5_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_1_5_Enabled", false)
        g_settings_gui["Skill_1_5_Name"].Text := ConfigManager.Get("Skill", "Skill_1_5_Name", "スキル1-5")
        g_settings_gui["Skill_1_5_Key"].Text := ConfigManager.Get("Skill", "Skill_1_5_Key", "t")
        g_settings_gui["Skill_1_5_Min"].Text := ConfigManager.Get("Skill", "Skill_1_5_Min", "4000")
        g_settings_gui["Skill_1_5_Max"].Text := ConfigManager.Get("Skill", "Skill_1_5_Max", "4500")
        g_settings_gui["Skill_1_5_Priority"].Choose(ConfigManager.Get("Skill", "Skill_1_5_Priority", "3"))
        
        ; Group 2 スキル (Skill_2_1 ~ Skill_2_5)
        g_settings_gui["Skill_2_1_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_2_1_Enabled", false)
        g_settings_gui["Skill_2_1_Name"].Text := ConfigManager.Get("Skill", "Skill_2_1_Name", "スキル2-1")
        g_settings_gui["Skill_2_1_Key"].Text := ConfigManager.Get("Skill", "Skill_2_1_Key", "LButton")
        g_settings_gui["Skill_2_1_Min"].Text := ConfigManager.Get("Skill", "Skill_2_1_Min", "500")
        g_settings_gui["Skill_2_1_Max"].Text := ConfigManager.Get("Skill", "Skill_2_1_Max", "800")
        g_settings_gui["Skill_2_1_Priority"].Choose(ConfigManager.Get("Skill", "Skill_2_1_Priority", "1"))
        
        g_settings_gui["Skill_2_2_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_2_2_Enabled", false)
        g_settings_gui["Skill_2_2_Name"].Text := ConfigManager.Get("Skill", "Skill_2_2_Name", "スキル2-2")
        g_settings_gui["Skill_2_2_Key"].Text := ConfigManager.Get("Skill", "Skill_2_2_Key", "RButton")
        g_settings_gui["Skill_2_2_Min"].Text := ConfigManager.Get("Skill", "Skill_2_2_Min", "800")
        g_settings_gui["Skill_2_2_Max"].Text := ConfigManager.Get("Skill", "Skill_2_2_Max", "1200")
        g_settings_gui["Skill_2_2_Priority"].Choose(ConfigManager.Get("Skill", "Skill_2_2_Priority", "2"))
        
        g_settings_gui["Skill_2_3_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_2_3_Enabled", false)
        g_settings_gui["Skill_2_3_Name"].Text := ConfigManager.Get("Skill", "Skill_2_3_Name", "スキル2-3")
        g_settings_gui["Skill_2_3_Key"].Text := ConfigManager.Get("Skill", "Skill_2_3_Key", "MButton")
        g_settings_gui["Skill_2_3_Min"].Text := ConfigManager.Get("Skill", "Skill_2_3_Min", "1200")
        g_settings_gui["Skill_2_3_Max"].Text := ConfigManager.Get("Skill", "Skill_2_3_Max", "1800")
        g_settings_gui["Skill_2_3_Priority"].Choose(ConfigManager.Get("Skill", "Skill_2_3_Priority", "3"))
        
        g_settings_gui["Skill_2_4_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_2_4_Enabled", false)
        g_settings_gui["Skill_2_4_Name"].Text := ConfigManager.Get("Skill", "Skill_2_4_Name", "スキル2-4")
        g_settings_gui["Skill_2_4_Key"].Text := ConfigManager.Get("Skill", "Skill_2_4_Key", "XButton1")
        g_settings_gui["Skill_2_4_Min"].Text := ConfigManager.Get("Skill", "Skill_2_4_Min", "2500")
        g_settings_gui["Skill_2_4_Max"].Text := ConfigManager.Get("Skill", "Skill_2_4_Max", "3000")
        g_settings_gui["Skill_2_4_Priority"].Choose(ConfigManager.Get("Skill", "Skill_2_4_Priority", "4"))
        
        g_settings_gui["Skill_2_5_Enabled"].Checked := ConfigManager.Get("Skill", "Skill_2_5_Enabled", false)
        g_settings_gui["Skill_2_5_Name"].Text := ConfigManager.Get("Skill", "Skill_2_5_Name", "スキル2-5")
        g_settings_gui["Skill_2_5_Key"].Text := ConfigManager.Get("Skill", "Skill_2_5_Key", "XButton2")
        g_settings_gui["Skill_2_5_Min"].Text := ConfigManager.Get("Skill", "Skill_2_5_Min", "5000")
        g_settings_gui["Skill_2_5_Max"].Text := ConfigManager.Get("Skill", "Skill_2_5_Max", "6000")
        g_settings_gui["Skill_2_5_Priority"].Choose(ConfigManager.Get("Skill", "Skill_2_5_Priority", "5"))
        
        g_settings_gui["SkillEnabled"].Checked := ConfigManager.Get("General", "SkillEnabled", true)
        
        ; Wine設定
        g_settings_gui["Wine_Interval"].Text := ConfigManager.Get("Wine", "WineInterval", "1000")
        g_settings_gui["Wine_DynamicTiming"].Checked := ConfigManager.Get("Wine", "DynamicTiming", true)
        
        ; 一般設定
        g_settings_gui["DebugMode"].Checked := ConfigManager.Get("General", "DebugMode", false)
        g_settings_gui["LogEnabled"].Checked := ConfigManager.Get("General", "LogEnabled", true)
        g_settings_gui["MaxLogSize"].Text := ConfigManager.Get("General", "MaxLogSize", "10")
        g_settings_gui["LogRetentionDays"].Text := ConfigManager.Get("General", "LogRetentionDays", "7")
        g_settings_gui["AutoStart"].Checked := ConfigManager.Get("General", "AutoStart", false)
        g_settings_gui["AutoStartDelay"].Text := ConfigManager.Get("General", "AutoStartDelay", "5000")
        
        ; 解像度設定
        g_settings_gui["ScreenWidth"].Text := ConfigManager.Get("Resolution", "ScreenWidth", "3440")
        g_settings_gui["ScreenHeight"].Text := ConfigManager.Get("Resolution", "ScreenHeight", "1440")
        
        ; マナ設定
        g_settings_gui["Mana_CenterX"].Text := ConfigManager.Get("Mana", "CenterX", "1720")
        g_settings_gui["Mana_CenterY"].Text := ConfigManager.Get("Mana", "CenterY", "1300")
        g_settings_gui["Mana_Radius"].Text := ConfigManager.Get("Mana", "Radius", "25")
        g_settings_gui["Mana_BlueThreshold"].Text := ConfigManager.Get("Mana", "BlueThreshold", "100")
        g_settings_gui["Mana_BlueDominance"].Text := ConfigManager.Get("Mana", "BlueDominance", "20")
        g_settings_gui["Mana_MonitorInterval"].Text := ConfigManager.Get("Mana", "MonitorInterval", "100")
        g_settings_gui["Mana_OptimizedDetection"].Checked := ConfigManager.Get("Mana", "OptimizedDetection", true)
        
        ; エリア検出設定
        g_settings_gui["ClientLog_Enabled"].Checked := ConfigManager.Get("ClientLog", "Enabled", true)
        g_settings_gui["ClientLog_Path"].Text := ConfigManager.Get("ClientLog", "Path", "C:\Program Files (x86)\Steam\steamapps\common\Path of Exile\logs\Client.txt")
        g_settings_gui["ClientLog_CheckInterval"].Text := ConfigManager.Get("ClientLog", "CheckInterval", "250")
        g_settings_gui["ClientLog_RestartInTown"].Checked := ConfigManager.Get("ClientLog", "RestartInTown", false)
        
        ; パフォーマンス設定
        g_settings_gui["ColorDetectTimeout"].Text := ConfigManager.Get("Performance", "ColorDetectTimeout", "50")
        g_settings_gui["ManaSampleRate"].Text := ConfigManager.Get("Performance", "ManaSampleRate", "5")
        
        ; UI設定
        g_settings_gui["OverlayTransparency"].Text := ConfigManager.Get("UI", "OverlayTransparency", "220")
        g_settings_gui["OverlayFontSize"].Text := ConfigManager.Get("UI", "OverlayFontSize", "28")
        
        LogDebug("SettingsWindow", "Settings loaded successfully")
        
    } catch as e {
        LogError("SettingsWindow", "Failed to load settings: " . e.Message)
        ShowOverlay("設定の読み込みに失敗しました", 3000)
    }
}

; --- 入力値を検証 ---
ValidateSkillSettings() {
    global g_settings_gui
    
    errors := []
    
    ; スキル設定の検証
    skillGroups := ["1_1", "1_2", "1_3", "1_4", "1_5", "2_1", "2_2", "2_3", "2_4", "2_5"]
    
    for skillId in skillGroups {
        controlName := "Skill_" . skillId
        
        ; 有効な場合のみ検証
        if (g_settings_gui[controlName . "_Enabled"].Checked) {
            ; キーの検証（空でないこと）
            key := Trim(g_settings_gui[controlName . "_Key"].Text)
            if (key = "") {
                errors.Push("スキル " . skillId . ": キーが空です")
            }
            
            ; 間隔の検証（数値のみ、正の値）
            minInterval := Trim(g_settings_gui[controlName . "_Min"].Text)
            maxInterval := Trim(g_settings_gui[controlName . "_Max"].Text)
            
            if (!IsInteger(minInterval) || Integer(minInterval) <= 0) {
                errors.Push("スキル " . skillId . ": 最小間隔は正の整数である必要があります")
            }
            
            if (!IsInteger(maxInterval) || Integer(maxInterval) <= 0) {
                errors.Push("スキル " . skillId . ": 最大間隔は正の整数である必要があります")
            }
            
            ; Min <= Max の検証
            if (IsInteger(minInterval) && IsInteger(maxInterval)) {
                if (Integer(minInterval) > Integer(maxInterval)) {
                    errors.Push("スキル " . skillId . ": 最小間隔は最大間隔以下である必要があります")
                }
            }
            
            ; 優先度の検証（1-5の範囲）
            priority := g_settings_gui[controlName . "_Priority"].Value
            if (priority < 1 || priority > 5) {
                errors.Push("スキル " . skillId . ": 優先度は1-5の範囲である必要があります")
            }
        }
    }
    
    ; フラスコとTincture設定も検証
    ValidateFlaskSettings(errors)
    ValidateTinctureSettings(errors)
    ValidateGeneralSettings(errors)
    
    return errors
}

ValidateFlaskSettings(errors) {
    global g_settings_gui
    
    Loop 5 {
        flaskNum := A_Index
        if (g_settings_gui["Flask" . flaskNum . "_Enabled"].Checked) {
            key := Trim(g_settings_gui["Flask" . flaskNum . "_Key"].Text)
            if (key = "") {
                errors.Push("フラスコ " . flaskNum . ": キーが空です")
            }
            
            minVal := Trim(g_settings_gui["Flask" . flaskNum . "_Min"].Text)
            maxVal := Trim(g_settings_gui["Flask" . flaskNum . "_Max"].Text)
            
            if (!IsInteger(minVal) || Integer(minVal) <= 0) {
                errors.Push("フラスコ " . flaskNum . ": 最小間隔は正の整数である必要があります")
            }
            
            if (!IsInteger(maxVal) || Integer(maxVal) <= 0) {
                errors.Push("フラスコ " . flaskNum . ": 最大間隔は正の整数である必要があります")
            }
            
            if (IsInteger(minVal) && IsInteger(maxVal) && Integer(minVal) > Integer(maxVal)) {
                errors.Push("フラスコ " . flaskNum . ": 最小間隔は最大間隔以下である必要があります")
            }
        }
    }
}

ValidateTinctureSettings(errors) {
    global g_settings_gui
    
    if (g_settings_gui["TinctureEnabled"].Checked) {
        key := Trim(g_settings_gui["TinctureKey"].Text)
        if (key = "") {
            errors.Push("Tincture: キーが空です")
        }
        
        ; 数値設定の検証
        retryMax := Trim(g_settings_gui["Tincture_RetryMax"].Text)
        retryInterval := Trim(g_settings_gui["Tincture_RetryInterval"].Text)
        verifyDelay := Trim(g_settings_gui["Tincture_VerifyDelay"].Text)
        depletedCooldown := Trim(g_settings_gui["Tincture_DepletedCooldown"].Text)
        
        if (!IsInteger(retryMax) || Integer(retryMax) < 0) {
            errors.Push("Tincture: リトライ最大回数は0以上の整数である必要があります")
        }
        
        if (!IsInteger(retryInterval) || Integer(retryInterval) < 0) {
            errors.Push("Tincture: リトライ間隔は0以上の整数である必要があります")
        }
        
        if (!IsInteger(verifyDelay) || Integer(verifyDelay) < 0) {
            errors.Push("Tincture: 検証遅延は0以上の整数である必要があります")
        }
        
        if (!IsInteger(depletedCooldown) || Integer(depletedCooldown) < 0) {
            errors.Push("Tincture: 枯渇クールダウンは0以上の整数である必要があります")
        }
    }
}

ValidateGeneralSettings(errors) {
    global g_settings_gui
    
    ; 解像度設定の検証
    screenWidth := Trim(g_settings_gui["ScreenWidth"].Text)
    screenHeight := Trim(g_settings_gui["ScreenHeight"].Text)
    
    if (!IsInteger(screenWidth) || Integer(screenWidth) <= 0) {
        errors.Push("画面幅は正の整数である必要があります")
    }
    
    if (!IsInteger(screenHeight) || Integer(screenHeight) <= 0) {
        errors.Push("画面高さは正の整数である必要があります")
    }
    
    ; マナ設定の検証
    centerX := Trim(g_settings_gui["Mana_CenterX"].Text)
    centerY := Trim(g_settings_gui["Mana_CenterY"].Text)
    radius := Trim(g_settings_gui["Mana_Radius"].Text)
    blueThreshold := Trim(g_settings_gui["Mana_BlueThreshold"].Text)
    blueDominance := Trim(g_settings_gui["Mana_BlueDominance"].Text)
    monitorInterval := Trim(g_settings_gui["Mana_MonitorInterval"].Text)
    
    if (!IsInteger(centerX) || Integer(centerX) < 0) {
        errors.Push("マナ中心X座標は0以上の整数である必要があります")
    }
    
    if (!IsInteger(centerY) || Integer(centerY) < 0) {
        errors.Push("マナ中心Y座標は0以上の整数である必要があります")
    }
    
    if (!IsInteger(radius) || Integer(radius) <= 0) {
        errors.Push("マナ検出半径は正の整数である必要があります")
    }
    
    if (!IsInteger(blueThreshold) || Integer(blueThreshold) < 0 || Integer(blueThreshold) > 255) {
        errors.Push("マナ青閾値は0-255の範囲である必要があります")
    }
    
    if (!IsInteger(blueDominance) || Integer(blueDominance) < 0) {
        errors.Push("マナ青色優位性は0以上の整数である必要があります")
    }
    
    if (!IsInteger(monitorInterval) || Integer(monitorInterval) <= 0) {
        errors.Push("マナ監視間隔は正の整数である必要があります")
    }
    
    ; エリア検出設定の検証
    clientLogPath := Trim(g_settings_gui["ClientLog_Path"].Text)
    clientLogInterval := Trim(g_settings_gui["ClientLog_CheckInterval"].Text)
    
    if (g_settings_gui["ClientLog_Enabled"].Checked && clientLogPath == "") {
        errors.Push("ログ監視が有効な場合、Client.txtパスを指定する必要があります")
    }
    
    if (!IsInteger(clientLogInterval) || Integer(clientLogInterval) <= 0) {
        errors.Push("ログチェック間隔は正の整数である必要があります")
    }
    
    ; パフォーマンス設定の検証
    colorTimeout := Trim(g_settings_gui["ColorDetectTimeout"].Text)
    sampleRate := Trim(g_settings_gui["ManaSampleRate"].Text)
    
    if (!IsInteger(colorTimeout) || Integer(colorTimeout) <= 0) {
        errors.Push("色検出タイムアウトは正の整数である必要があります")
    }
    
    if (!IsInteger(sampleRate) || Integer(sampleRate) < 1 || Integer(sampleRate) > 10) {
        errors.Push("マナサンプルレートは1-10の範囲である必要があります")
    }
    
    ; UI設定の検証
    transparency := Trim(g_settings_gui["OverlayTransparency"].Text)
    fontSize := Trim(g_settings_gui["OverlayFontSize"].Text)
    
    if (!IsInteger(transparency) || Integer(transparency) < 0 || Integer(transparency) > 255) {
        errors.Push("オーバーレイ透明度は0-255の範囲である必要があります")
    }
    
    if (!IsInteger(fontSize) || Integer(fontSize) <= 0) {
        errors.Push("フォントサイズは正の整数である必要があります")
    }
    
    ; その他の数値設定
    maxLogSize := Trim(g_settings_gui["MaxLogSize"].Text)
    logRetentionDays := Trim(g_settings_gui["LogRetentionDays"].Text)
    autoStartDelay := Trim(g_settings_gui["AutoStartDelay"].Text)
    wineInterval := Trim(g_settings_gui["Wine_Interval"].Text)
    
    if (!IsInteger(maxLogSize) || Integer(maxLogSize) <= 0) {
        errors.Push("最大ログサイズは正の整数である必要があります")
    }
    
    if (!IsInteger(logRetentionDays) || Integer(logRetentionDays) <= 0) {
        errors.Push("ログ保持日数は正の整数である必要があります")
    }
    
    if (!IsInteger(autoStartDelay) || Integer(autoStartDelay) < 0) {
        errors.Push("自動開始遅延は0以上の整数である必要があります")
    }
    
    if (!IsInteger(wineInterval) || Integer(wineInterval) <= 0) {
        errors.Push("Wine段階間隔は正の整数である必要があります")
    }
}

; --- 設定を保存 ---
SaveSettings(*) {
    global g_settings_gui, g_settings_open
    
    try {
        ; 入力値を検証
        validationErrors := ValidateSkillSettings()
        
        if (validationErrors.Length > 0) {
            errorMessage := "設定に以下のエラーがあります:`n`n"
            for error in validationErrors {
                errorMessage .= "• " . error . "`n"
            }
            
            MsgBox(errorMessage, "設定エラー", "OK Icon!")
            LogWarn("SettingsWindow", "Validation failed: " . validationErrors.Length . " errors")
            return
        }
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
        ; Group 1 スキル (Skill_1_1 ~ Skill_1_5)
        ConfigManager.Set("Skill", "Skill_1_1_Enabled", g_settings_gui["Skill_1_1_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_1_1_Name", g_settings_gui["Skill_1_1_Name"].Text)
        ConfigManager.Set("Skill", "Skill_1_1_Key", g_settings_gui["Skill_1_1_Key"].Text)
        ConfigManager.Set("Skill", "Skill_1_1_Min", g_settings_gui["Skill_1_1_Min"].Text)
        ConfigManager.Set("Skill", "Skill_1_1_Max", g_settings_gui["Skill_1_1_Max"].Text)
        ConfigManager.Set("Skill", "Skill_1_1_Priority", g_settings_gui["Skill_1_1_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_1_2_Enabled", g_settings_gui["Skill_1_2_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_1_2_Name", g_settings_gui["Skill_1_2_Name"].Text)
        ConfigManager.Set("Skill", "Skill_1_2_Key", g_settings_gui["Skill_1_2_Key"].Text)
        ConfigManager.Set("Skill", "Skill_1_2_Min", g_settings_gui["Skill_1_2_Min"].Text)
        ConfigManager.Set("Skill", "Skill_1_2_Max", g_settings_gui["Skill_1_2_Max"].Text)
        ConfigManager.Set("Skill", "Skill_1_2_Priority", g_settings_gui["Skill_1_2_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_1_3_Enabled", g_settings_gui["Skill_1_3_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_1_3_Name", g_settings_gui["Skill_1_3_Name"].Text)
        ConfigManager.Set("Skill", "Skill_1_3_Key", g_settings_gui["Skill_1_3_Key"].Text)
        ConfigManager.Set("Skill", "Skill_1_3_Min", g_settings_gui["Skill_1_3_Min"].Text)
        ConfigManager.Set("Skill", "Skill_1_3_Max", g_settings_gui["Skill_1_3_Max"].Text)
        ConfigManager.Set("Skill", "Skill_1_3_Priority", g_settings_gui["Skill_1_3_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_1_4_Enabled", g_settings_gui["Skill_1_4_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_1_4_Name", g_settings_gui["Skill_1_4_Name"].Text)
        ConfigManager.Set("Skill", "Skill_1_4_Key", g_settings_gui["Skill_1_4_Key"].Text)
        ConfigManager.Set("Skill", "Skill_1_4_Min", g_settings_gui["Skill_1_4_Min"].Text)
        ConfigManager.Set("Skill", "Skill_1_4_Max", g_settings_gui["Skill_1_4_Max"].Text)
        ConfigManager.Set("Skill", "Skill_1_4_Priority", g_settings_gui["Skill_1_4_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_1_5_Enabled", g_settings_gui["Skill_1_5_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_1_5_Name", g_settings_gui["Skill_1_5_Name"].Text)
        ConfigManager.Set("Skill", "Skill_1_5_Key", g_settings_gui["Skill_1_5_Key"].Text)
        ConfigManager.Set("Skill", "Skill_1_5_Min", g_settings_gui["Skill_1_5_Min"].Text)
        ConfigManager.Set("Skill", "Skill_1_5_Max", g_settings_gui["Skill_1_5_Max"].Text)
        ConfigManager.Set("Skill", "Skill_1_5_Priority", g_settings_gui["Skill_1_5_Priority"].Value)
        
        ; Group 2 スキル (Skill_2_1 ~ Skill_2_5)
        ConfigManager.Set("Skill", "Skill_2_1_Enabled", g_settings_gui["Skill_2_1_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_2_1_Name", g_settings_gui["Skill_2_1_Name"].Text)
        ConfigManager.Set("Skill", "Skill_2_1_Key", g_settings_gui["Skill_2_1_Key"].Text)
        ConfigManager.Set("Skill", "Skill_2_1_Min", g_settings_gui["Skill_2_1_Min"].Text)
        ConfigManager.Set("Skill", "Skill_2_1_Max", g_settings_gui["Skill_2_1_Max"].Text)
        ConfigManager.Set("Skill", "Skill_2_1_Priority", g_settings_gui["Skill_2_1_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_2_2_Enabled", g_settings_gui["Skill_2_2_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_2_2_Name", g_settings_gui["Skill_2_2_Name"].Text)
        ConfigManager.Set("Skill", "Skill_2_2_Key", g_settings_gui["Skill_2_2_Key"].Text)
        ConfigManager.Set("Skill", "Skill_2_2_Min", g_settings_gui["Skill_2_2_Min"].Text)
        ConfigManager.Set("Skill", "Skill_2_2_Max", g_settings_gui["Skill_2_2_Max"].Text)
        ConfigManager.Set("Skill", "Skill_2_2_Priority", g_settings_gui["Skill_2_2_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_2_3_Enabled", g_settings_gui["Skill_2_3_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_2_3_Name", g_settings_gui["Skill_2_3_Name"].Text)
        ConfigManager.Set("Skill", "Skill_2_3_Key", g_settings_gui["Skill_2_3_Key"].Text)
        ConfigManager.Set("Skill", "Skill_2_3_Min", g_settings_gui["Skill_2_3_Min"].Text)
        ConfigManager.Set("Skill", "Skill_2_3_Max", g_settings_gui["Skill_2_3_Max"].Text)
        ConfigManager.Set("Skill", "Skill_2_3_Priority", g_settings_gui["Skill_2_3_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_2_4_Enabled", g_settings_gui["Skill_2_4_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_2_4_Name", g_settings_gui["Skill_2_4_Name"].Text)
        ConfigManager.Set("Skill", "Skill_2_4_Key", g_settings_gui["Skill_2_4_Key"].Text)
        ConfigManager.Set("Skill", "Skill_2_4_Min", g_settings_gui["Skill_2_4_Min"].Text)
        ConfigManager.Set("Skill", "Skill_2_4_Max", g_settings_gui["Skill_2_4_Max"].Text)
        ConfigManager.Set("Skill", "Skill_2_4_Priority", g_settings_gui["Skill_2_4_Priority"].Value)
        
        ConfigManager.Set("Skill", "Skill_2_5_Enabled", g_settings_gui["Skill_2_5_Enabled"].Checked)
        ConfigManager.Set("Skill", "Skill_2_5_Name", g_settings_gui["Skill_2_5_Name"].Text)
        ConfigManager.Set("Skill", "Skill_2_5_Key", g_settings_gui["Skill_2_5_Key"].Text)
        ConfigManager.Set("Skill", "Skill_2_5_Min", g_settings_gui["Skill_2_5_Min"].Text)
        ConfigManager.Set("Skill", "Skill_2_5_Max", g_settings_gui["Skill_2_5_Max"].Text)
        ConfigManager.Set("Skill", "Skill_2_5_Priority", g_settings_gui["Skill_2_5_Priority"].Value)
        
        ConfigManager.Set("General", "SkillEnabled", g_settings_gui["SkillEnabled"].Checked)
        
        ; Wine設定を保存
        ConfigManager.Set("Wine", "WineInterval", g_settings_gui["Wine_Interval"].Text)
        ConfigManager.Set("Wine", "DynamicTiming", g_settings_gui["Wine_DynamicTiming"].Checked)
        
        ; 一般設定を保存
        ConfigManager.Set("General", "DebugMode", g_settings_gui["DebugMode"].Checked)
        ConfigManager.Set("General", "LogEnabled", g_settings_gui["LogEnabled"].Checked)
        ConfigManager.Set("General", "MaxLogSize", g_settings_gui["MaxLogSize"].Text)
        ConfigManager.Set("General", "LogRetentionDays", g_settings_gui["LogRetentionDays"].Text)
        ConfigManager.Set("General", "AutoStart", g_settings_gui["AutoStart"].Checked)
        ConfigManager.Set("General", "AutoStartDelay", g_settings_gui["AutoStartDelay"].Text)
        
        ; 解像度設定を保存
        ConfigManager.Set("Resolution", "ScreenWidth", g_settings_gui["ScreenWidth"].Text)
        ConfigManager.Set("Resolution", "ScreenHeight", g_settings_gui["ScreenHeight"].Text)
        
        ; マナ設定を保存
        ConfigManager.Set("Mana", "CenterX", g_settings_gui["Mana_CenterX"].Text)
        ConfigManager.Set("Mana", "CenterY", g_settings_gui["Mana_CenterY"].Text)
        ConfigManager.Set("Mana", "Radius", g_settings_gui["Mana_Radius"].Text)
        ConfigManager.Set("Mana", "BlueThreshold", g_settings_gui["Mana_BlueThreshold"].Text)
        ConfigManager.Set("Mana", "BlueDominance", g_settings_gui["Mana_BlueDominance"].Text)
        ConfigManager.Set("Mana", "MonitorInterval", g_settings_gui["Mana_MonitorInterval"].Text)
        ConfigManager.Set("Mana", "OptimizedDetection", g_settings_gui["Mana_OptimizedDetection"].Checked)
        
        ; エリア検出設定を保存
        ConfigManager.Set("ClientLog", "Enabled", g_settings_gui["ClientLog_Enabled"].Checked)
        ConfigManager.Set("ClientLog", "Path", g_settings_gui["ClientLog_Path"].Text)
        ConfigManager.Set("ClientLog", "CheckInterval", g_settings_gui["ClientLog_CheckInterval"].Text)
        ConfigManager.Set("ClientLog", "RestartInTown", g_settings_gui["ClientLog_RestartInTown"].Checked)
        
        ; パフォーマンス設定を保存
        ConfigManager.Set("Performance", "ColorDetectTimeout", g_settings_gui["ColorDetectTimeout"].Text)
        ConfigManager.Set("Performance", "ManaSampleRate", g_settings_gui["ManaSampleRate"].Text)
        
        ; UI設定を保存
        ConfigManager.Set("UI", "OverlayTransparency", g_settings_gui["OverlayTransparency"].Text)
        ConfigManager.Set("UI", "OverlayFontSize", g_settings_gui["OverlayFontSize"].Text)
        
        ; 設定を保存
        ConfigManager.Save()
        
        ; FlaskManagerの設定を更新
        UpdateFlaskManagerConfig()
        
        ; スキル管理システムの設定を更新
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
        
    } catch as e {
        LogError("SettingsWindow", "Failed to update FlaskManager config: " . e.Message)
    }
}

; --- スキル管理システムの設定を更新 ---
UpdateSkillManagerConfig() {
    try {
        ; 新しいスキル設定マップを作成
        skillConfig := Map()
        
        ; Group 1 スキルの設定を読み込み (Skill_1_1 ~ Skill_1_5)
        Loop 5 {
            skillNum := A_Index
            skillId := "Skill_1_" . skillNum
            enabled := ConfigManager.Get("Skill", skillId . "_Enabled", false)
            
            if (enabled) {
                skillConfig[skillId] := {
                    name: ConfigManager.Get("Skill", skillId . "_Name", "スキル1-" . skillNum),
                    key: ConfigManager.Get("Skill", skillId . "_Key", "q"),
                    minInterval: Integer(ConfigManager.Get("Skill", skillId . "_Min", "1000")),
                    maxInterval: Integer(ConfigManager.Get("Skill", skillId . "_Max", "1500")),
                    priority: Integer(ConfigManager.Get("Skill", skillId . "_Priority", "3")),
                    enabled: true,
                    group: 1
                }
            }
        }
        
        ; Group 2 スキルの設定を読み込み (Skill_2_1 ~ Skill_2_5)
        Loop 5 {
            skillNum := A_Index
            skillId := "Skill_2_" . skillNum
            enabled := ConfigManager.Get("Skill", skillId . "_Enabled", false)
            
            if (enabled) {
                skillConfig[skillId] := {
                    name: ConfigManager.Get("Skill", skillId . "_Name", "スキル2-" . skillNum),
                    key: ConfigManager.Get("Skill", skillId . "_Key", "LButton"),
                    minInterval: Integer(ConfigManager.Get("Skill", skillId . "_Min", "500")),
                    maxInterval: Integer(ConfigManager.Get("Skill", skillId . "_Max", "800")),
                    priority: Integer(ConfigManager.Get("Skill", skillId . "_Priority", "1")),
                    enabled: true,
                    group: 2
                }
            }
        }
        
        ; スキル管理システムの設定を更新（関数が存在する場合のみ）
        if (IsSet(ConfigureSkills)) {
            ConfigureSkills(skillConfig)
            LogInfo("SettingsWindow", "SkillManager configuration updated with " . skillConfig.Count . " active skills")
        } else {
            LogWarn("SettingsWindow", "ConfigureSkills function not available")
        }
        
        ; 古い形式との互換性（SkillAutomationが存在する場合）
        if (IsSet(UpdateSkillConfiguration)) {
            UpdateSkillConfiguration(skillConfig)
            LogInfo("SettingsWindow", "Legacy SkillAutomation updated")
        }
        
    } catch as e {
        LogError("SettingsWindow", "Failed to update SkillManager config: " . e.Message)
    }
}

; --- 解像度自動検出 ---
DetectResolution(*) {
    global g_settings_gui
    
    try {
        ; 現在のモニターの解像度を取得
        MonitorGetWorkArea(1, &left, &top, &right, &bottom)
        width := right - left
        height := bottom - top
        
        ; 設定フィールドに反映
        g_settings_gui["ScreenWidth"].Text := width
        g_settings_gui["ScreenHeight"].Text := height
        
        ShowOverlay(Format("解像度検出: {}x{}", width, height), 2000)
        LogInfo("SettingsWindow", Format("Resolution detected: {}x{}", width, height))
        
    } catch as e {
        LogError("SettingsWindow", "Failed to detect resolution: " . e.Message)
        ShowOverlay("解像度の検出に失敗しました", 2000)
    }
}

; --- ログフォルダを開く ---
OpenLogFolder(*) {
    try {
        logPath := A_ScriptDir . "\logs"
        if (!DirExist(logPath)) {
            DirCreate(logPath)
        }
        Run(logPath)
        LogInfo("SettingsWindow", "Opened log folder: " . logPath)
    } catch as e {
        LogError("SettingsWindow", "Failed to open log folder: " . e.Message)
        ShowOverlay("ログフォルダを開けませんでした", 2000)
    }
}

; --- ログをクリア ---
ClearLogs(*) {
    result := MsgBox("すべてのログファイルを削除しますか？", "確認", "YesNo Icon?")
    if (result == "Yes") {
        try {
            logPath := A_ScriptDir . "\logs"
            if (DirExist(logPath)) {
                ; ログファイルを削除
                Loop Files, logPath . "\*.log" {
                    try {
                        FileDelete(A_LoopFileFullPath)
                    } catch {
                        ; 使用中のファイルはスキップ
                    }
                }
                ShowOverlay("ログをクリアしました", 2000)
                LogInfo("SettingsWindow", "Logs cleared")
            }
        } catch as e {
            LogError("SettingsWindow", "Failed to clear logs: " . e.Message)
            ShowOverlay("ログのクリアに失敗しました", 2000)
        }
    }
}

; --- マナ座標取得 ---
GetManaPosition(*) {
    global g_settings_gui
    
    MsgBox("マナオーブの中心をクリックしてください。`n3秒後に座標を取得します。", "マナ座標取得", "OK Icon!")
    
    Sleep(3000)
    
    try {
        ; マウス座標を取得
        MouseGetPos(&mouseX, &mouseY)
        
        ; 設定フィールドに反映
        g_settings_gui["Mana_CenterX"].Text := mouseX
        g_settings_gui["Mana_CenterY"].Text := mouseY
        
        ShowOverlay(Format("マナ座標取得: X={}, Y={}", mouseX, mouseY), 3000)
        LogInfo("SettingsWindow", Format("Mana position captured: X={}, Y={}", mouseX, mouseY))
        
    } catch as e {
        LogError("SettingsWindow", "Failed to get mana position: " . e.Message)
        ShowOverlay("座標の取得に失敗しました", 2000)
    }
}

; --- Client.txtパス参照 ---
BrowseClientLog(*) {
    global g_settings_gui
    
    try {
        ; デフォルトパス
        defaultPath := "C:\Program Files (x86)\Steam\steamapps\common\Path of Exile\logs"
        
        ; ファイル選択ダイアログ
        selectedFile := FileSelect(3, defaultPath . "\Client.txt", "Client.txtファイルを選択", "Text files (*.txt)")
        
        if (selectedFile != "") {
            g_settings_gui["ClientLog_Path"].Text := selectedFile
            LogInfo("SettingsWindow", "Client.txt path selected: " . selectedFile)
        }
        
    } catch as e {
        LogError("SettingsWindow", "Failed to browse for Client.txt: " . e.Message)
    }
}