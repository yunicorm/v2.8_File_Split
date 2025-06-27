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
global g_log_file := ""
global g_log_dir := A_ScriptDir . "\logs"

; --- ログ初期化 ---
InitializeLogger() {
    global g_log_file, g_log_dir
    
    ; ログディレクトリを作成
    if (!DirExist(g_log_dir)) {
        DirCreate(g_log_dir)
    }
    
    ; ログファイル名を生成
    g_log_file := g_log_dir . "\macro_" . A_Now . ".log"
    
    ; 初期ログエントリ
    WriteLog(LOG_LEVEL.INFO, "Logger", "=== Path of Exile Macro Started ===")
    WriteLog(LOG_LEVEL.INFO, "Logger", "Version: 2.8.2")
    WriteLog(LOG_LEVEL.INFO, "Logger", "AutoHotkey: " . A_AhkVersion)
    
    ; ログローテーションをチェック
    CheckLogRotation()
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
    } catch Error as e {
        ; ログ書き込み失敗
        OutputDebug("Failed to write log: " . e.Message)
    }
    
    ; デバッグモードならコンソールにも出力
    if (ConfigManager.Get("General", "DebugMode", false)) {
        OutputDebug(logEntry)
    }
}

; --- ログローテーション ---
CheckLogRotation() {
    global g_log_file, g_log_dir
    
    try {
        maxSize := ConfigManager.Get("General", "MaxLogSize", 10) * 1024 * 1024  ; MB to bytes
        
        if (FileExist(g_log_file)) {
            currentSize := FileGetSize(g_log_file)
            
            if (currentSize > maxSize) {
                ; 新しいログファイルを作成
                oldFile := g_log_file
                g_log_file := g_log_dir . "\macro_" . A_Now . ".log"
                
                WriteLog(LOG_LEVEL.INFO, "Logger", 
                    Format("Log rotation: {} -> {}", oldFile, g_log_file))
                
                ; 古いファイルをアーカイブ
                archiveName := StrReplace(oldFile, ".log", "_archived.log")
                try {
                    FileMove(oldFile, archiveName, 1)
                } catch {
                    ; アーカイブ失敗は無視
                }
            }
        }
    } catch Error as e {
        OutputDebug("Log rotation check failed: " . e.Message)
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
        try {
            Run("notepad.exe " . g_log_file)
        } catch Error as e {
            MsgBox("ログファイルを開けませんでした: " . e.Message, "エラー", "OK Icon!")
        }
    } else {
        MsgBox("ログファイルが見つかりません", "情報", "OK Icon!")
    }
}

; --- 古いログファイルのクリーンアップ ---
CleanupOldLogs(daysToKeep := 7) {
    global g_log_dir
    
    cutoffTime := A_Now
    cutoffTime := DateAdd(cutoffTime, -daysToKeep, "Days")
    
    try {
        Loop Files, g_log_dir . "\macro_*.log" {
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
    } catch Error as e {
        LogError("Logger", "Cleanup failed: " . e.Message)
    }
}

; --- 定期的なログローテーションチェック ---
SetTimer(CheckLogRotation, 3600000)  ; 1時間ごとにチェック