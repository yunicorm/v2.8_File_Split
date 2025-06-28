; ===================================================================
; 一般タブ専用モジュール
; システム・デバッグ・マナ・エリア・パフォーマンス・UI設定のGUI作成と処理
; ===================================================================

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

; --- 一般設定を読み込み ---
LoadGeneralSettings() {
    global g_settings_gui
    
    try {
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
        
    } catch Error as e {
        LogError("GeneralTab", "Failed to load general settings: " . e.Message)
    }
}

; --- 一般設定を保存 ---
SaveGeneralSettings() {
    global g_settings_gui
    
    try {
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
        
    } catch Error as e {
        LogError("GeneralTab", "Failed to save general settings: " . e.Message)
        throw e
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
        LogInfo("GeneralTab", Format("Resolution detected: {}x{}", width, height))
        
    } catch Error as e {
        LogError("GeneralTab", "Failed to detect resolution: " . e.Message)
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
        LogInfo("GeneralTab", "Opened log folder: " . logPath)
    } catch Error as e {
        LogError("GeneralTab", "Failed to open log folder: " . e.Message)
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
                LogInfo("GeneralTab", "Logs cleared")
            }
        } catch Error as e {
            LogError("GeneralTab", "Failed to clear logs: " . e.Message)
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
        LogInfo("GeneralTab", Format("Mana position captured: X={}, Y={}", mouseX, mouseY))
        
    } catch Error as e {
        LogError("GeneralTab", "Failed to get mana position: " . e.Message)
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
            LogInfo("GeneralTab", "Client.txt path selected: " . selectedFile)
        }
        
    } catch Error as e {
        LogError("GeneralTab", "Failed to browse for Client.txt: " . e.Message)
    }
}