; ===================================================================
; ログシステム - デバッグとトラブルシューティング用
; ===================================================================

; --- ログレベル定義 ---
global LOG_LEVEL := {
    DEBUG: 0,
    INFO: 1,
    WARN: 2,
    ERROR: 3
}

; --- 現在のログレベル ---
global g_current_log_level := LOG_LEVEL.INFO

; --- ログファイルパス ---
global g_log_file := A_ScriptDir . "\logs\macro_" . A_Now . ".log"

; --- ログ初期化 ---
InitializeLogger() {
    ; ログディレクトリを作成
    logDir := A_ScriptDir . "\logs"
    if (!DirExist(logDir)) {
        DirCreate(logDir)
    }
    
    ; 初期ログエントリ
    LogInfo("=== Path of Exile Macro Started ===")
    LogInfo("Version: 2.8.1")
    LogInfo("AutoHotkey: " . A_AhkVersion)
}

; --- ログ書き込み関数 ---
WriteLog(level, module, message) {
    global g_log_enabled, g_current_log_level, g_log_file
    
    if (!g_log_enabled || level < g_current_log_level) {
        return
    }
    
    ; タイムスタンプ
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    
    ; レベル名
    levelName := GetLogLevelName(level)
    
    ; ログエントリを作成
    logEntry := Format("[{}] [{}] [{}] {}`n", 
        timestamp, levelName, module, message)
    
    ; ファイルに書き込み
    try {
        FileAppend(logEntry, g_log_file)
    } catch {
        ; ログ書き込み失敗は無視
    }
    
    ; デバッグモードならコンソールにも出力
    if (g_debug_mode) {
        OutputDebug(logEntry)
    }
}

; --- ログレベル名を取得 ---
GetLogLevelName(level) {
    switch level {
        case 0: return "DEBUG"
        case 1: return "INFO"
        case 2: return "WARN"
        case 3: return "ERROR"
        default: return "UNKNOWN"
    }
}

; --- 便利なログ関数 ---
LogDebug(module, message) {
    WriteLog(LOG_LEVEL.DEBUG, module, message)
}

LogInfo(module, message) {
    WriteLog(LOG_LEVEL.INFO, module, message)
}

LogWarn(module, message) {
    WriteLog(LOG_LEVEL.WARN, module, message)
}

LogError(module, message) {
    WriteLog(LOG_LEVEL.ERROR, module, message)
}

; --- タイマー実行ログ ---
LogTimerExecution(timerName, duration := "") {
    msg := Format("Timer '{}' executed", timerName)
    if (duration != "") {
        msg .= Format(" ({}ms)", duration)
    }
    LogDebug("TimerManager", msg)
}

; --- マナ状態変化ログ ---
LogManaStateChange(oldState, newState, fillRate) {
    LogInfo("ManaMonitor", 
        Format("Mana state changed: {} -> {} ({}%)", 
            oldState ? "Has Mana" : "Depleted",
            newState ? "Has Mana" : "Depleted",
            fillRate))
}

; --- エラーログ with スタックトレース ---
LogErrorWithStack(module, message, errorObj := "") {
    fullMessage := message
    
    if (errorObj != "") {
        fullMessage .= Format("`nError: {}`nFile: {}`nLine: {}", 
            errorObj.Message,
            errorObj.File,
            errorObj.Line)
        
        if (errorObj.HasProp("Stack")) {
            fullMessage .= "`nStack: " . errorObj.Stack
        }
    }
    
    LogError(module, fullMessage)
}

; --- パフォーマンスログ ---
global g_performance_timers := Map()

StartPerfTimer(name) {
    global g_performance_timers
    g_performance_timers[name] := A_TickCount
}

EndPerfTimer(name, module := "Performance") {
    global g_performance_timers
    
    if (g_performance_timers.Has(name)) {
        duration := A_TickCount - g_performance_timers[name]
        LogDebug(module, Format("'{}' took {}ms", name, duration))
        g_performance_timers.Delete(name)
        return duration
    }
    
    return 0
}

; --- ログビューア ---
ShowLogViewer() {
    global g_log_file
    
    if (FileExist(g_log_file)) {
        Run("notepad.exe " . g_log_file)
    } else {
        MsgBox("No log file found")
    }
}

; --- 古いログファイルのクリーンアップ ---
CleanupOldLogs(daysToKeep := 7) {
    logDir := A_ScriptDir . "\logs"
    cutoffTime := A_Now
    cutoffTime := DateAdd(cutoffTime, -daysToKeep, "Days")
    
    Loop Files, logDir . "\macro_*.log" {
        fileTime := FileGetTime(A_LoopFilePath, "C")
        if (fileTime < cutoffTime) {
            try {
                FileDelete(A_LoopFilePath)
                LogInfo("Logger", "Deleted old log: " . A_LoopFileName)
            } catch {
                ; 削除失敗は無視
            }
        }
    }
}