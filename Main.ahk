#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

; === インクルード順序が重要 ===
; ユーティリティを最初に読み込み
#Include "Utils\ConfigManager.ahk"
#Include "Utils\HotkeyValidator.ahk"
#Include "Utils\Logger.ahk"
#Include "Utils\ColorDetection.ahk"
#Include "Utils\Coordinates.ahk"

; 設定を読み込み
#Include "Config.ahk"

; コアシステム
#Include "Core\WindowManager.ahk"
#Include "Core\TimerManager.ahk"

; UI
#Include "UI\Overlay.ahk"
#Include "UI\StatusDisplay.ahk"
#Include "UI\DebugDisplay.ahk"

; 機能
#Include "Features\ManaMonitor.ahk"
#Include "Features\TinctureManager.ahk"
#Include "Features\FlaskManager.ahk"
#Include "Features\SkillAutomation.ahk"
#Include "Features\LoadingScreen.ahk"
#Include "Features\ClientLogMonitor.ahk"

; マクロコントローラー
#Include "Core\MacroController.ahk"

; ホットキー
#Include "Hotkeys\MainHotkeys.ahk"
#Include "Hotkeys\DebugHotkeys.ahk"

; === 初期化 ===
InitializeMacro()

; === メイン初期化関数 ===
InitializeMacro() {
    ; 設定ファイルを読み込み
    if (!ConfigManager.Load()) {
        MsgBox("設定ファイルの読み込みに失敗しました。", "エラー", "OK Icon!")
        ExitApp()
    }
    
    ; ログシステム初期化
    InitializeLogger()
    LogInfo("Main", "=== Path of Exile Macro Starting ===")
    
    ; 座標モードの設定
    CoordMode("Mouse", "Screen")
    CoordMode("ToolTip", "Screen")
    CoordMode("Pixel", "Screen")
    
    ; ウィンドウグループの設定
    GroupAdd("TargetWindows", "ahk_exe streaming_client.exe")
    GroupAdd("TargetWindows", "ahk_exe PathOfExileSteam.exe")
    
    ; ホットキーの検証
    HotkeyValidator.RegisterFromConfig()
    if (!HotkeyValidator.CheckConflicts()) {
        LogWarn("Main", "Hotkey conflicts detected")
    }
    
    ; グローバル変数を設定から初期化
    LoadConfigToGlobals()
    
    ; UI初期化
    CreateStatusOverlay()
    
    ; 古いログファイルをクリーンアップ
    CleanupOldLogs(ConfigManager.Get("General", "LogRetentionDays", 7))
    
    ; 終了時のクリーンアップ
    OnExit(ExitFunc)
    
    LogInfo("Main", "Initialization completed successfully")
    
    ; === 自動開始機能 ===
    if (ConfigManager.Get("General", "AutoStart", false)) {
        autoStartDelay := ConfigManager.Get("General", "AutoStartDelay", 2000)
        
        ShowOverlay(Format("マクロを{}秒後に自動開始します...", autoStartDelay/1000), autoStartDelay)
        LogInfo("Main", Format("Auto-start scheduled in {}ms", autoStartDelay))
        
        ; 指定時間後に自動開始（ウィンドウがアクティブな場合のみ）
        SetTimer(() => AutoStartMacro(), -autoStartDelay)
    } else {
        ShowOverlay("F12キーでマクロを開始してください", 3000)
    }
}

; === 自動開始関数 ===
AutoStartMacro() {
    global g_macro_active
    
    ; Path of Exileウィンドウがアクティブか確認
    if (IsTargetWindowActive()) {
        if (!g_macro_active) {
            ShowOverlay("マクロを自動開始します", 2000)
            ToggleMacro()
            LogInfo("Main", "Macro auto-started successfully")
        }
    } else {
        ; ウィンドウがアクティブでない場合は待機
        ShowOverlay("Path of Exileをアクティブにしてください", 3000)
        LogInfo("Main", "Auto-start delayed - waiting for active window")
        
        ; 再試行タイマーを設定
        SetTimer(() => WaitForWindowAndStart(), 1000)
    }
}

; === ウィンドウ待機と開始 ===
WaitForWindowAndStart() {
    global g_macro_active
    
    if (IsTargetWindowActive() && !g_macro_active) {
        SetTimer(() => WaitForWindowAndStart(), 0)  ; タイマー停止
        ShowOverlay("マクロを自動開始します", 2000)
        ToggleMacro()
        LogInfo("Main", "Macro auto-started after window became active")
    }
}

; === 設定からグローバル変数を読み込み ---
LoadConfigToGlobals() {
    ; Config.ahkの関数を呼び出し
    ApplyConfigSettings()
}

; === 終了処理 ===
ExitFunc(*) {
    LogInfo("Main", "=== Path of Exile Macro Shutting Down ===")
    StopAllTimers()
    CleanupUI()
}