; ===================================================================
; Path of Exile マクロ v2.9.1
; メインエントリーポイント
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

; === ウィンドウグループ定義 ===
GroupAdd("TargetWindows", "ahk_exe PathOfExileSteam.exe")
GroupAdd("TargetWindows", "ahk_exe streaming_client.exe")

; === ユーティリティのインクルード（最初に読み込む） ===
#Include "Utils\Logger.ahk"
#Include "Utils\ConfigManager.ahk"
#Include "Utils\ColorDetection.ahk"
#Include "Utils\Coordinates.ahk"
#Include "Utils\HotkeyValidator.ahk"

; === UIのインクルード（ユーティリティの後） ===
#Include "UI\Overlay.ahk"
#Include "UI\StatusDisplay.ahk"
#Include "UI\DebugDisplay.ahk"

; === 設定のインクルード ===
#Include "Config.ahk"

; === コア機能のインクルード ===
#Include "Core\TimerManager.ahk"
#Include "Core\WindowManager.ahk"

; === 機能モジュールのインクルード ===
#Include "Features\ManaMonitor.ahk"
#Include "Features\TinctureManager.ahk"
#Include "Features\FlaskManager.ahk"
#Include "Features\SkillAutomation.ahk"
#Include "Features\LoadingScreen.ahk"
#Include "Features\ClientLogMonitor.ahk"

; === マクロコントローラーのインクルード ===
#Include "Core\MacroController.ahk"

; === ホットキーのインクルード（最後に読み込む） ===
#Include "Hotkeys\MainHotkeys.ahk"
#Include "Hotkeys\DebugHotkeys.ahk"

; === グローバル変数の追加初期化 ===
global g_auto_start_enabled := false
global g_auto_start_timer := ""

; === メイン処理 ===
try {
    ; ロガー初期化
    InitializeLogger()
    LogInfo("Main", "=== Path of Exile Macro Starting ===")
    
    ; 設定読み込み
    if (!ConfigManager.Load()) {
        MsgBox("設定ファイルの読み込みに失敗しました", "エラー", "OK Icon!")
        ExitApp()
    }
    
    ; 設定を適用
    ApplyConfigSettings()
    
    ; ステータスオーバーレイ作成
    CreateStatusOverlay()
    
    ; ホットキー検証
    HotkeyValidator.RegisterFromConfig()
    if (!HotkeyValidator.CheckConflicts()) {
        LogWarn("Main", "Hotkey conflicts detected")
    }
    
    ; 起動完了
    ShowOverlay("Path of Exile マクロ v2.9.1 起動完了", 3000)
    LogInfo("Main", "Initialization completed successfully")
    
    ; 自動開始チェック
    if (ConfigManager.Get("General", "AutoStart", false)) {
        g_auto_start_enabled := true
        autoStartDelay := ConfigManager.Get("General", "AutoStartDelay", 2000)
        LogInfo("Main", Format("Auto-start scheduled in {}ms", autoStartDelay))
        g_auto_start_timer := SetTimer(TryAutoStart, -autoStartDelay)
    }
    
} catch Error as e {
    errorMsg := Format("初期化エラー: {}`nFile: {}`nLine: {}", 
        e.Message, e.File, e.Line)
    
    MsgBox(errorMsg, "Path of Exile Macro - エラー", "OK Icon!")
    
    ; LogErrorWithStackが使用可能な場合のみ使用
    if (IsSet(LogErrorWithStack)) {
        LogErrorWithStack("Main", "Initialization failed", e)
    }
    
    ExitApp()
}

; === 自動開始処理 ===
TryAutoStart() {
    global g_auto_start_enabled, g_macro_active
    
    if (!g_auto_start_enabled || g_macro_active) {
        return
    }
    
    ; Path of Exileがアクティブか確認
    if (WinActive("ahk_group TargetWindows")) {
        ToggleMacro()
        LogInfo("Main", "Macro auto-started after window became active")
        g_auto_start_enabled := false
    } else {
        ; まだアクティブでない場合は再試行
        LogInfo("Main", "Auto-start delayed - waiting for active window")
        SetTimer(TryAutoStart, -1000)
    }
}

; === スクリプト終了時の処理 ===
OnExit(ExitHandler)

ExitHandler(reason, exitCode) {
    LogInfo("Main", "=== Path of Exile Macro Shutting Down ===")
    
    ; 全タイマー停止
    StopAllTimers()
    
    ; UI クリーンアップ
    CleanupUI()
    
    ; ログをフラッシュ
    Sleep(100)
    
    return 0
}

; === マクロのメイン関数 ===

; マクロのトグル
ToggleMacro() {
    global g_macro_active
    
    if (g_macro_active) {
        StopMacro()
    } else {
        StartMacro()
    }
}

; マクロ開始
StartMacro() {
    global g_macro_active, g_macro_start_time
    
    if (g_macro_active) {
        return
    }
    
    ; ウィンドウチェック
    if (!IsTargetWindowActive()) {
        ShowOverlay("Path of Exileがアクティブではありません", 2000)
        return
    }
    
    g_macro_active := true
    g_macro_start_time := A_TickCount
    
    ; 初期アクション実行
    PerformInitialActions()
    
    ; 各システムを開始
    StartSkillAutomation()
    StartFlaskAutomation()
    StartManaMonitoring()
    
    ; エリア検出を開始（設定に基づく）
    if (ConfigManager.Get("ClientLog", "Enabled", true)) {
        StartClientLogMonitoring()
    } else if (ConfigManager.Get("LoadingScreen", "Enabled", false)) {
        StartLoadingScreenDetection()
    }
    
    ; ステータス更新
    UpdateStatusOverlay()
    
    ShowOverlay("マクロ開始", 2000)
    LogInfo("MacroController", "Macro started")
}

; マクロ停止
StopMacro() {
    global g_macro_active
    
    if (!g_macro_active) {
        return
    }
    
    g_macro_active := false
    
    ; 全システムを停止
    StopAllTimers()
    
    ; ステータス更新
    UpdateStatusOverlay()
    
    ShowOverlay("マクロ停止", 2000)
    LogInfo("MacroController", "Macro stopped")
}

; マクロリセット
ResetMacro() {
    global g_macro_active
    
    LogInfo("MainHotkeys", "F12 pressed - Resetting macro")
    
    wasActive := g_macro_active
    
    ; 一旦停止
    if (g_macro_active) {
        StopMacro()
        Sleep(100)
    }
    
    ; 状態をリセット
    ResetTinctureState()
    InitializeManaState()
    
    ; 再開
    StartMacro()
}

; 手動停止
ManualStopMacro() {
    global g_auto_start_enabled
    g_auto_start_enabled := false
    StopMacro()
    LogInfo("MacroController", "Macro manually stopped - auto-start disabled")
}

; 緊急停止
EmergencyStopMacro() {
    global g_auto_start_enabled
    g_auto_start_enabled := false
    StopMacro()
    ShowOverlay("緊急停止 - 自動開始無効", 3000)
    LogWarn("MacroController", "Emergency stop - auto-start disabled")
}