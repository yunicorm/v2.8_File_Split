; ===================================================================
; Path of Exile マクロ v2.9.2
; メインエントリーポイント（修正版）
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

; === ウィンドウグループ定義 ===
GroupAdd("TargetWindows", "ahk_exe PathOfExileSteam.exe")
GroupAdd("TargetWindows", "ahk_exe streaming_client.exe")

; === ユーティリティのインクルード（最初に読み込む） ===
#Include "Utils/ConfigManager.ahk"
#Include "Utils/Logger.ahk"
#Include "Utils/ColorDetection.ahk"
#Include "Utils/Coordinates.ahk"
#Include "Utils/HotkeyValidator.ahk"
#Include "Utils/Validators.ahk"

; === UIのインクルード（ユーティリティの後） ===
#Include "UI/Overlay.ahk"
#Include "UI/StatusDisplay.ahk"
#Include "UI/DebugDisplay.ahk"
#Include "UI/SettingsWindow.ahk"

; === 設定のインクルード ===
#Include "Config.ahk"

; === コア機能のインクルード ===
#Include "Core/TimerManager.ahk"
#Include "Core/WindowManager.ahk"

; === 機能モジュールのインクルード ===
#Include "Utils/FindText.ahk"
#Include "Features/VisualDetection.ahk"
#Include "Features/ManaMonitor.ahk"
#Include "Features/TinctureManager.ahk"
#Include "Features/FlaskManager.ahk"
#Include "Features/SkillAutomation.ahk"
#Include "Features/LoadingScreen.ahk"
#Include "Features/ClientLogMonitor.ahk"

; === マクロコントローラーのインクルード ===
#Include "Core/MacroController.ahk"

; === ホットキーのインクルード（最後に読み込む） ===
#Include "Hotkeys/MainHotkeys.ahk"
#Include "Hotkeys/DebugHotkeys.ahk"

; === グローバル変数の追加初期化 ===
global g_auto_start_enabled := false
global g_auto_start_timer := ""
global g_auto_start_attempts := 0
global g_auto_start_max_attempts := 30  ; 30秒まで試行
global g_initialization_complete := false

; === グローバルエラーハンドラー ===
OnError(GlobalErrorHandler)

GlobalErrorHandler(exception, mode) {
    ; ログが初期化されているか確認
    if (IsSet(LogErrorWithStack)) {
        LogErrorWithStack("GlobalError", "Unhandled error", exception)
    }
    
    ; エラーメッセージを作成
    errorMsg := Format("エラーが発生しました:`n{}`nFile: {}`nLine: {}", 
        exception.Message, exception.HasProp("File") ? exception.File : "Unknown", exception.HasProp("Line") ? exception.Line : "Unknown")
    
    ; クリティカルなエラーの場合はマクロを停止
    if (InStr(exception.Message, "Critical") || InStr(exception.Message, "Access") || 
        InStr(exception.Message, "Memory")) {
        
        ; 初期化が完了している場合のみ緊急停止を実行
        if (g_initialization_complete) {
            try {
                EmergencyStopMacro()
            } catch {
                ; 緊急停止も失敗した場合は無視
            }
        }
        
        MsgBox(errorMsg . "`n`nマクロを停止します。", "重大なエラー", "OK Icon!")
        ExitApp()
    }
    
    ; 非クリティカルなエラーの場合は続行を許可
    return true
}

; === メイン処理 ===
try {
    ; ロガー初期化
    InitializeLogger()
    LogInfo("Main", "=== Path of Exile Macro v2.9.2 Starting ===")
    
    ; 設定読み込み
    if (!ConfigManager.Load()) {
        MsgBox("設定ファイルの読み込みに失敗しました", "エラー", "OK Icon!")
        ExitApp()
    }
    
    ; Logger設定適用（ConfigManager初期化後）
    ApplyLoggerConfig()
    
    ; 設定の検証
    if (ConfigManager.HasMethod("ValidateConfig")) {
        ConfigManager.ValidateConfig()
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
    
    ; 初期化完了フラグ
    g_initialization_complete := true
    
    ; 起動完了
    ShowOverlay("Path of Exile マクロ v2.9.2 起動完了", 3000)
    LogInfo("Main", "Initialization completed successfully")
    
    ; 自動開始チェック
    if (ConfigManager.Get("General", "AutoStart", false)) {
        g_auto_start_enabled := true
        g_auto_start_attempts := 0
        autoStartDelay := ConfigManager.Get("General", "AutoStartDelay", 2000)
        LogInfo("Main", Format("Auto-start scheduled in {}ms", autoStartDelay))
        g_auto_start_timer := SetTimer(TryAutoStart, -autoStartDelay)
    }
    
} catch as e {
    errorMsg := Format("初期化エラー: {}`nFile: {}`nLine: {}", 
        e.Message, e.HasProp("File") ? e.File : "Unknown", e.HasProp("Line") ? e.Line : "Unknown")
    
    MsgBox(errorMsg, "Path of Exile Macro - エラー", "OK Icon!")
    
    ; LogErrorWithStackが使用可能な場合のみ使用
    if (IsSet(LogErrorWithStack)) {
        LogErrorWithStack("Main", "Initialization failed", e)
    }
    
    ExitApp()
}

; === 自動開始処理（改善版） ===
TryAutoStart() {
    global g_auto_start_enabled, g_macro_active, g_auto_start_attempts, g_auto_start_max_attempts
    
    ; 無効化されているか、既にマクロが動作中の場合は終了
    if (!g_auto_start_enabled || g_macro_active) {
        g_auto_start_attempts := 0
        return
    }
    
    ; 最大試行回数をチェック
    g_auto_start_attempts++
    if (g_auto_start_attempts > g_auto_start_max_attempts) {
        g_auto_start_enabled := false
        g_auto_start_attempts := 0
        LogInfo("Main", "Auto-start timed out after 30 seconds")
        ShowOverlay("自動開始タイムアウト", 2000)
        return
    }
    
    ; Path of Exileがアクティブか確認
    if (WinActive("ahk_group TargetWindows")) {
        try {
            ToggleMacro()
            LogInfo("Main", "Macro auto-started after window became active")
            g_auto_start_enabled := false
            g_auto_start_attempts := 0
        } catch as e {
            LogError("Main", "Failed to auto-start macro: " . e.Message)
            ; エラーの場合は再試行
            SetTimer(TryAutoStart, -1000)
        }
    } else {
        ; まだアクティブでない場合は再試行
        LogDebug("Main", Format("Auto-start attempt {}/{} - waiting for active window", 
            g_auto_start_attempts, g_auto_start_max_attempts))
        SetTimer(TryAutoStart, -1000)
    }
}

; === スクリプト終了時の処理 ===
OnExit(ExitHandler)

ExitHandler(reason, exitCode) {
    LogInfo("Main", Format("=== Path of Exile Macro Shutting Down (Reason: {}) ===", reason))
    
    try {
        ; 自動開始を無効化
        g_auto_start_enabled := false
        
        ; 全タイマー停止
        StopAllTimers()
        
        ; UI クリーンアップ
        CleanupUI()
        
        ; ログをフラッシュ
        Sleep(100)
        
        LogInfo("Main", "Shutdown completed successfully")
    } catch as e {
        ; 終了処理中のエラーは無視
    }
    
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
        LogDebug("Main", "Macro is already active")
        return
    }
    
    ; ウィンドウチェック
    if (!IsTargetWindowActive()) {
        ShowOverlay("Path of Exileがアクティブではありません", 2000)
        return
    }
    
    try {
        g_macro_active := true
        g_macro_start_time := A_TickCount
        
        ; 初期アクション実行
        PerformInitialActions()
        
        ; 各システムを開始
        ; スキルシステム - 新しいシステムを優先的に使用
        if (ConfigManager.Get("General", "SkillEnabled", true)) {
            if (IsSet(StartNewSkillAutomation)) {
                StartNewSkillAutomation()
            } else {
                StartSkillAutomation()
            }
        }
        
        if (ConfigManager.Get("General", "FlaskEnabled", true)) {
            StartFlaskAutomation()
        }
        
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
        LogInfo("Main", "Macro started successfully")
        
    } catch as e {
        ; 開始に失敗した場合は状態をリセット
        g_macro_active := false
        StopAllTimers()
        
        ShowOverlay("マクロ開始エラー: " . e.Message, 3000)
        LogError("Main", "Failed to start macro: " . e.Message)
        throw
    }
}

; マクロ停止
StopMacro() {
    global g_macro_active
    
    if (!g_macro_active) {
        LogDebug("Main", "Macro is already stopped")
        return
    }
    
    try {
        g_macro_active := false
        
        ; 全システムを停止
        StopAllTimers()
        
        ; ステータス更新
        UpdateStatusOverlay()
        
        ShowOverlay("マクロ停止", 2000)
        LogInfo("Main", "Macro stopped successfully")
        
    } catch as e {
        ShowOverlay("マクロ停止エラー: " . e.Message, 3000)
        LogError("Main", "Error while stopping macro: " . e.Message)
    }
}

; マクロリセット
ResetMacro() {
    global g_macro_active
    
    LogInfo("Main", "Resetting macro")
    
    wasActive := g_macro_active
    
    try {
        ; 一旦停止
        if (g_macro_active) {
            StopMacro()
            Sleep(100)
        }
        
        ; 状態をリセット
        ResetTinctureState()
        InitializeManaState()
        
        ; タイマー管理状態もリセット
        global g_active_timers
        g_active_timers.Clear()
        
        ; 再開
        StartMacro()
        
        LogInfo("Main", "Macro reset completed")
        
    } catch as e {
        ShowOverlay("マクロリセットエラー: " . e.Message, 3000)
        LogError("Main", "Failed to reset macro: " . e.Message)
        
        ; エラーの場合は完全停止
        g_macro_active := false
        StopAllTimers()
    }
}

; 手動停止
ManualStopMacro() {
    global g_auto_start_enabled, g_auto_start_attempts
    
    g_auto_start_enabled := false
    g_auto_start_attempts := 0
    
    StopMacro()
    
    LogInfo("Main", "Macro manually stopped - auto-start disabled")
}

; 緊急停止
EmergencyStopMacro() {
    global g_auto_start_enabled, g_auto_start_attempts, g_macro_active
    
    LogWarn("Main", "Emergency stop initiated")
    
    ; 自動開始を完全に無効化
    g_auto_start_enabled := false
    g_auto_start_attempts := 0
    
    ; マクロ状態を強制的にオフ
    g_macro_active := false
    
    ; 全てのタイマーを強制停止
    try {
        StopAllTimers()
    } catch {
        ; エラーは無視
    }
    
    ; Tincture状態を強制リセット
    try {
        global g_tincture_active, g_tincture_retry_count
        g_tincture_active := false
        g_tincture_retry_count := 0
    } catch {
        ; エラーは無視
    }
    
    ShowOverlay("緊急停止 - 自動開始無効", 3000)
    LogWarn("Main", "Emergency stop completed - all automation disabled")
}

; === パフォーマンス監視（オプション） ===
StartPerformanceMonitoring() {
    if (ConfigManager.Get("Performance", "MonitoringEnabled", false)) {
        SetTimer(MonitorPerformance, 10000)  ; 10秒ごと
    }
}

MonitorPerformance() {
    global g_active_timers
    
    ; アクティブタイマー数をチェック
    timerCount := g_active_timers.Count
    if (timerCount > 20) {
        LogWarn("Performance", Format("High number of active timers: {}", timerCount))
    }
    
    ; メモリ使用量をチェック（将来の実装用）
    ; TODO: メモリ使用量の監視を実装
}