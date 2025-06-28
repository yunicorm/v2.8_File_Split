; ===================================================================
; スキルタブ専用モジュール
; スキル・Wine設定のGUI作成と処理
; ===================================================================

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

; --- スキル設定を読み込み ---
LoadSkillSettings() {
    global g_settings_gui
    
    try {
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
        
    } catch as e {
        LogError("SkillTab", "Failed to load skill settings: " . e.Message)
    }
}

; --- スキル設定を保存 ---
SaveSkillSettings() {
    global g_settings_gui
    
    try {
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
        
    } catch as e {
        LogError("SkillTab", "Failed to save skill settings: " . e.Message)
        throw e
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
            LogInfo("SkillTab", "SkillManager configuration updated with " . skillConfig.Count . " active skills")
        } else {
            LogWarn("SkillTab", "ConfigureSkills function not available")
        }
        
        ; 古い形式との互換性（SkillAutomationが存在する場合）
        if (IsSet(UpdateSkillConfiguration)) {
            UpdateSkillConfiguration(skillConfig)
            LogInfo("SkillTab", "Legacy SkillAutomation updated")
        }
        
    } catch as e {
        LogError("SkillTab", "Failed to update SkillManager config: " . e.Message)
    }
}