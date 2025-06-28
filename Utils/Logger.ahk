; ===================================================================
; ログシステム（修正版）
; 効率的なログ記録とメモリ管理
; ===================================================================

; --- ログレベル定義 ---
global LOG_LEVEL := {
    DEBUG: 0,
    INFO: 1,
    WARN: 2,
    ERROR: 3,
    CRITICAL: 4
}

; --- グローバル変数 ---
global g_current_log_level := LOG_LEVEL.INFO
global g_log_file := ""
global g_log_dir := A_ScriptDir . "\logs"
global g_log_buffer := []
global g_log_buffer_size := 50  ; バッファサイズ
global g_log_file_handle := ""
global g_log_write_count := 0
global g_log_rotation_in_progress := false
global g_log_stats := {
    totalLogs: 0,
    droppedLogs: 0,
    rotations: 0,
    writeErrors: 0
}

; --- ログ初期化（改善版） ---
InitializeLogger() {
    global g_log_file, g_log_dir, g_log_file_handle, g_current_log_level
    
    ; ログレベルを設定から取得
    if (ConfigManager.Get("General", "DebugMode", false)) {
        g_current_log_level := LOG_LEVEL.DEBUG
    }
    
    ; ログディレクトリを作成
    if (!DirExist(g_log_dir)) {
        try {
            DirCreate(g_log_dir)
        } catch Error as e {
            MsgBox("ログディレクトリの作成に失敗しました: " . e.Message, "エラー", "OK Icon!")
            return false
        }
    }
    
    ; ログファイル名を生成
    g_log_file := g_log_dir . "\macro_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".log"
    
    ; ログファイルを開く（追記モード、共有読み取り可能）
    try {
        g_log_file_handle := FileOpen(g_log_file, "a", "UTF-8-RAW")
        if (!g_log_file_handle) {
            throw Error("Failed to open log file")
        }
        
        ; バッファリングを有効化
        g_log_file_handle.Encoding := "UTF-8-RAW"
        
    } catch Error as e {
        ; ファイルハンドルが使えない場合は従来の方式にフォールバック
        g_log_file_handle := ""
        OutputDebug("Failed to open log file handle: " . e.Message)
    }
    
    ; 初期ログエントリ
    WriteLog(LOG_LEVEL.INFO, "Logger", "=== Path of Exile Macro Started ===")
    WriteLog(LOG_LEVEL.INFO, "Logger", "Version: v2.9.2")
    WriteLog(LOG_LEVEL.INFO, "Logger", "AutoHotkey: " . A_AhkVersion)
    WriteLog(LOG_LEVEL.INFO, "Logger", "Log Level: " . GetLogLevelName(g_current_log_level))
    
    ; バッファフラッシュタイマーを開始
    SetTimer(FlushLogBuffer, 1000)  ; 1秒ごと
    
    ; ログローテーションタイマーを開始
    SetTimer(CheckLogRotation, 60000)  ; 1分ごと
    
    ; 起動時クリーンアップ
    PerformStartupCleanup()
    
    return true
}

; --- ログ書き込み関数（改善版） ---
WriteLog(level, module, message) {
    global g_log_enabled, g_current_log_level, g_log_buffer
    global g_log_stats, g_log_buffer_size
    
    if (!g_log_enabled || level < g_current_log_level) {
        return
    }
    
    ; ファイルサイズチェック（書き込み前）
    CheckLogFileSizeBeforeWrite()
    
    g_log_stats.totalLogs++
    
    ; タイムスタンプ
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    
    ; レベル名
    levelName := GetLogLevelName(level)
    
    ; ログエントリを作成
    logEntry := Format("[{}] [{}] [{}] {}", 
        timestamp, levelName, module, message)
    
    ; バッファに追加
    g_log_buffer.Push({
        entry: logEntry,
        level: level,
        timestamp: A_TickCount
    })
    
    ; バッファサイズ制限
    if (g_log_buffer.Length > g_log_buffer_size) {
        ; 優先度の低いログを削除
        RemoveLowPriorityLogs()
    }
    
    ; 重要なログは即座にフラッシュ
    if (level >= LOG_LEVEL.ERROR) {
        FlushLogBuffer()
    }
    
    ; デバッグモードならコンソールにも出力
    if (g_current_log_level == LOG_LEVEL.DEBUG) {
        OutputDebug(logEntry)
    }
}

; --- 優先度の低いログを削除 ---
RemoveLowPriorityLogs() {
    global g_log_buffer, g_log_stats
    
    ; DEBUGレベルのログから削除
    newBuffer := []
    droppedCount := 0
    
    for log in g_log_buffer {
        if (log.level > LOG_LEVEL.DEBUG || newBuffer.Length < g_log_buffer_size - 10) {
            newBuffer.Push(log)
        } else {
            droppedCount++
        }
    }
    
    g_log_buffer := newBuffer
    g_log_stats.droppedLogs += droppedCount
    
    if (droppedCount > 0) {
        OutputDebug(Format("Dropped {} low priority logs", droppedCount))
    }
}

; --- ログバッファをフラッシュ ---
FlushLogBuffer() {
    global g_log_buffer, g_log_file, g_log_file_handle
    global g_log_write_count, g_log_stats
    
    if (g_log_buffer.Length == 0) {
        return
    }
    
    try {
        ; バッファの内容を結合
        logContent := ""
        for log in g_log_buffer {
            logContent .= log.entry . "`n"
        }
        
        ; ファイルに書き込み
        if (g_log_file_handle) {
            ; ファイルハンドルを使用
            g_log_file_handle.Write(logContent)
            g_log_file_handle.Flush()  ; 強制的にディスクに書き込み
        } else {
            ; 従来の方式
            FileAppend(logContent, g_log_file)
        }
        
        g_log_write_count += g_log_buffer.Length
        
        ; バッファをクリア
        g_log_buffer := []
        
    } catch Error as e {
        g_log_stats.writeErrors++
        OutputDebug("Failed to write log: " . e.Message)
        
        ; エラーが続く場合はファイルハンドルを再オープン
        if (g_log_stats.writeErrors > 5) {
            ReopenLogFile()
        }
    }
}

; --- ログファイルを再オープン ---
ReopenLogFile() {
    global g_log_file_handle, g_log_file, g_log_stats
    
    ; 既存のハンドルを閉じる
    if (g_log_file_handle) {
        try {
            g_log_file_handle.Close()
        } catch {
            ; エラーは無視
        }
    }
    
    ; 新しいハンドルを開く
    try {
        g_log_file_handle := FileOpen(g_log_file, "a", "UTF-8-RAW")
        g_log_stats.writeErrors := 0
        OutputDebug("Log file reopened successfully")
    } catch {
        g_log_file_handle := ""
    }
}

; --- ログローテーション（改善版） ---
; --- ログファイルサイズチェック（書き込み前）---
CheckLogFileSizeBeforeWrite() {
    global g_log_file, g_log_rotation_in_progress
    
    if (g_log_rotation_in_progress) {
        return
    }
    
    try {
        maxSize := ConfigManager.Get("General", "MaxLogSize", 5) * 1024 * 1024  ; MB to bytes
        
        ; ファイルサイズをチェック
        if (FileExist(g_log_file)) {
            currentSize := FileGetSize(g_log_file)
            if (currentSize > maxSize) {
                PerformLogRotation()
            }
        }
    } catch Error as e {
        OutputDebug("Log size check failed: " . e.Message)
    }
}

; --- ログローテーション実行 ---
PerformLogRotation() {
    global g_log_file, g_log_dir, g_log_file_handle
    global g_log_rotation_in_progress, g_log_stats, g_log_write_count
    
    g_log_rotation_in_progress := true
    
    try {
        ; バッファをフラッシュ
        FlushLogBuffer()
        
        ; ファイルハンドルを閉じる
        if (g_log_file_handle) {
            g_log_file_handle.Close()
            g_log_file_handle := ""
        }
        
        ; 古いログファイルを .old に改名
        oldFile := g_log_file
        backupFile := StrReplace(oldFile, ".log", ".old")
        
        ; 既存の .old ファイルがあれば削除
        if (FileExist(backupFile)) {
            try {
                FileDelete(backupFile)
            } catch {
                ; 削除失敗は無視
            }
        }
        
        ; ファイルを改名
        try {
            FileMove(oldFile, backupFile)
        } catch {
            ; 改名失敗時は削除を試行
            try {
                FileDelete(oldFile)
            } catch {
                ; 削除も失敗した場合は継続
            }
        }
        
        ; 新しいログファイルを作成
        g_log_file := g_log_dir . "\macro_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".log"
        
        ; ファイルハンドルを開く
        try {
            g_log_file_handle := FileOpen(g_log_file, "a", "UTF-8-RAW")
        } catch {
            g_log_file_handle := ""
        }
        
        g_log_write_count := 0
        g_log_stats.rotations++
        
        ; ローテーション完了ログ
        WriteLog(LOG_LEVEL.INFO, "Logger", 
            Format("Log rotation completed: {} -> {}", oldFile, g_log_file))
        
        ; 3世代以上の古いログを削除
        CleanupOldLogFiles()
        
    } catch Error as e {
        OutputDebug("Log rotation failed: " . e.Message)
    } finally {
        g_log_rotation_in_progress := false
    }
}

CheckLogRotation() {
    global g_log_file, g_log_dir, g_log_write_count
    global g_log_rotation_in_progress, g_log_stats
    
    if (g_log_rotation_in_progress) {
        return
    }
    
    try {
        maxSize := ConfigManager.Get("General", "MaxLogSize", 5) * 1024 * 1024  ; MB to bytes
        
        ; ファイルサイズをチェック
        currentSize := 0
        if (FileExist(g_log_file)) {
            currentSize := FileGetSize(g_log_file)
        }
        
        ; 書き込み回数でもチェック（パフォーマンス対策）
        if (currentSize > maxSize || g_log_write_count > 5000) {
            PerformLogRotation()
        }
    } catch Error as e {
        OutputDebug("Log rotation check failed: " . e.Message)
    }
}

; --- ログファイルを圧縮 ---
CompressLogFile(filePath) {
    try {
        ; TODO: 圧縮実装（7-zipなどの外部ツールを使用）
        ; 現在は未実装
    } catch {
        ; エラーは無視
    }
}

; --- ログレベル名を取得 ---
GetLogLevelName(level) {
    switch level {
        case 0: return "DEBUG"
        case 1: return "INFO"
        case 2: return "WARN"
        case 3: return "ERROR"
        case 4: return "CRITICAL"
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

LogCritical(module, message) {
    WriteLog(LOG_LEVEL.CRITICAL, module, message)
}

; --- エラーログ with スタックトレース（改善版） ---
LogErrorWithStack(module, message, errorObj := "") {
    fullMessage := message
    
    if (errorObj != "") {
        fullMessage .= Format("`n  Error: {}", errorObj.HasProp("Message") ? errorObj.Message : "Unknown")
        fullMessage .= Format("`n  File: {}", errorObj.HasProp("File") ? errorObj.File : "Unknown")
        fullMessage .= Format("`n  Line: {}", errorObj.HasProp("Line") ? errorObj.Line : "Unknown")
        
        if (errorObj.HasProp("Stack")) {
            fullMessage .= "`n  Stack: " . errorObj.Stack
        }
        
        ; 追加情報
        if (errorObj.HasProp("Extra")) {
            fullMessage .= "`n  Extra: " . errorObj.Extra
        }
    }
    
    LogError(module, fullMessage)
}

; --- パフォーマンスログ（改善版） ---
global g_performance_timers := Map()

StartPerfTimer(name) {
    global g_performance_timers
    g_performance_timers[name] := {
        start: A_TickCount,
        checkpoints: []
    }
}

AddPerfCheckpoint(name, checkpoint) {
    global g_performance_timers
    
    if (g_performance_timers.Has(name)) {
        g_performance_timers[name].checkpoints.Push({
            name: checkpoint,
            time: A_TickCount - g_performance_timers[name].start
        })
    }
}

EndPerfTimer(name, module := "Performance") {
    global g_performance_timers
    
    if (g_performance_timers.Has(name)) {
        timer := g_performance_timers[name]
        duration := A_TickCount - timer.start
        
        ; 詳細なログ
        if (timer.checkpoints.Length > 0) {
            checkpointInfo := ""
            for cp in timer.checkpoints {
                checkpointInfo .= Format(" [{}:{}ms]", cp.name, cp.time)
            }
            LogDebug(module, Format("'{}' took {}ms -{}", name, duration, checkpointInfo))
        } else {
            LogDebug(module, Format("'{}' took {}ms", name, duration))
        }
        
        g_performance_timers.Delete(name)
        return duration
    }
    
    return 0
}

; --- ログビューア（改善版） ---
ShowLogViewer() {
    global g_log_file
    
    ; バッファをフラッシュ
    FlushLogBuffer()
    
    if (FileExist(g_log_file)) {
        try {
            ; デフォルトのテキストエディタで開く
            Run(g_log_file)
        } catch Error as e {
            ; Notepadで開く
            try {
                Run("notepad.exe `"" . g_log_file . "`"")
            } catch {
                MsgBox("ログファイルを開けませんでした: " . e.Message, "エラー", "OK Icon!")
            }
        }
    } else {
        MsgBox("ログファイルが見つかりません", "情報", "OK Icon!")
    }
}

; --- 古いログファイルの世代管理クリーンアップ ---
CleanupOldLogFiles() {
    global g_log_dir
    
    try {
        ; .old ファイルのリストを取得
        oldFiles := []
        Loop Files, g_log_dir . "\macro_*.old" {
            oldFiles.Push({
                path: A_LoopFilePath,
                time: FileGetTime(A_LoopFilePath, "C")
            })
        }
        
        ; 時間順でソート（新しい順）
        if (oldFiles.Length > 0) {
            ; 簡単なバブルソート
            for i := 1 to oldFiles.Length - 1 {
                for j := 1 to oldFiles.Length - i {
                    if (oldFiles[j].time < oldFiles[j + 1].time) {
                        temp := oldFiles[j]
                        oldFiles[j] := oldFiles[j + 1]
                        oldFiles[j + 1] := temp
                    }
                }
            }
            
            ; 3世代以上は削除
            deletedCount := 0
            for i := 4 to oldFiles.Length {
                try {
                    FileDelete(oldFiles[i].path)
                    deletedCount++
                } catch {
                    ; 削除失敗は無視
                }
            }
            
            if (deletedCount > 0) {
                LogInfo("Logger", Format("Deleted {} old backup files", deletedCount))
            }
        }
    } catch Error as e {
        LogError("Logger", "Old file cleanup failed: " . e.Message)
    }
}

; --- 古いログファイルのクリーンアップ（日数ベース） ---
CleanupOldLogs(daysToKeep := "") {
    global g_log_dir
    
    if (daysToKeep == "") {
        daysToKeep := ConfigManager.Get("General", "LogRetentionDays", 3)
    }
    
    cutoffTime := A_Now
    cutoffTime := DateAdd(cutoffTime, -daysToKeep, "Days")
    
    deletedCount := 0
    totalSize := 0
    
    try {
        ; .log ファイルをチェック
        Loop Files, g_log_dir . "\macro_*.log" {
            fileTime := FileGetTime(A_LoopFilePath, "C")
            if (fileTime < cutoffTime) {
                try {
                    totalSize += FileGetSize(A_LoopFilePath)
                    FileDelete(A_LoopFilePath)
                    deletedCount++
                } catch {
                    ; 削除失敗は無視
                }
            }
        }
        
        ; .old ファイルもチェック
        Loop Files, g_log_dir . "\macro_*.old" {
            fileTime := FileGetTime(A_LoopFilePath, "C")
            if (fileTime < cutoffTime) {
                try {
                    totalSize += FileGetSize(A_LoopFilePath)
                    FileDelete(A_LoopFilePath)
                    deletedCount++
                } catch {
                    ; 削除失敗は無視
                }
            }
        }
        
        if (deletedCount > 0) {
            LogInfo("Logger", Format("Deleted {} old log files ({} KB)", 
                deletedCount, Round(totalSize / 1024)))
        }
    } catch Error as e {
        LogError("Logger", "Cleanup failed: " . e.Message)
    }
}

; --- ログ統計の取得 ---
GetLoggerStats() {
    global g_log_stats, g_log_buffer, g_log_write_count
    global g_log_file
    
    fileSize := 0
    if (FileExist(g_log_file)) {
        fileSize := FileGetSize(g_log_file)
    }
    
    return {
        totalLogs: g_log_stats.totalLogs,
        droppedLogs: g_log_stats.droppedLogs,
        dropRate: g_log_stats.totalLogs > 0 ? 
            Round(g_log_stats.droppedLogs / g_log_stats.totalLogs * 100, 2) : 0,
        rotations: g_log_stats.rotations,
        writeErrors: g_log_stats.writeErrors,
        bufferSize: g_log_buffer.Length,
        writeCount: g_log_write_count,
        fileSize: Round(fileSize / 1024, 2)  ; KB
    }
}

; --- ログレベルの動的変更 ---
SetLogLevel(level) {
    global g_current_log_level
    
    if (level >= LOG_LEVEL.DEBUG && level <= LOG_LEVEL.CRITICAL) {
        g_current_log_level := level
        LogInfo("Logger", "Log level changed to: " . GetLogLevelName(level))
        return true
    }
    
    return false
}

; --- 終了時のクリーンアップ ---
OnExit(LoggerCleanup)

; --- 起動時クリーンアップ ---
PerformStartupCleanup() {
    try {
        ; 日数ベースのクリーンアップ
        CleanupOldLogs()
        
        ; 世代管理クリーンアップ
        CleanupOldLogFiles()
        
        LogInfo("Logger", "Startup cleanup completed")
    } catch Error as e {
        LogError("Logger", "Startup cleanup failed: " . e.Message)
    }
}

LoggerCleanup(reason, exitCode) {
    ; バッファをフラッシュ
    FlushLogBuffer()
    
    ; ファイルハンドルを閉じる
    global g_log_file_handle
    if (g_log_file_handle) {
        try {
            g_log_file_handle.Close()
        } catch {
            ; エラーは無視
        }
    }
    
    return 0
}