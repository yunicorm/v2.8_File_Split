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