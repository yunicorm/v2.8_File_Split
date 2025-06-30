; ===================================================================
; Client.txtログ監視システム（修正版）
; エリア移動をログファイルから検出して自動的にマクロを制御
; ===================================================================

; --- グローバル変数 ---
global g_client_log_path := ""
global g_log_file_handle := ""  ; ファイルハンドルを保持
global g_last_file_size := 0
global g_last_area_entry_time := ""
global g_log_monitor_enabled := true
global g_area_change_detected := false
global g_last_read_position := 0
global g_last_area_name := ""
global g_read_buffer_size := 4096  ; 読み込みバッファサイズ
global g_area_history := []  ; エリア履歴
global g_monitor_errors := 0

; --- ログ監視の開始 ---
StartClientLogMonitoring() {
    global g_log_monitor_enabled, g_client_log_path, g_last_file_size
    global g_log_file_handle, g_monitor_errors
    
    ; エラーカウントをリセット
    g_monitor_errors := 0
    
    ; 設定からパスを取得
    g_client_log_path := ConfigManager.Get("ClientLog", "Path", 
        "C:\Program Files (x86)\Steam\steamapps\common\Path of Exile\logs\Client.txt")
    
    ; 設定を確認
    g_log_monitor_enabled := ConfigManager.Get("ClientLog", "Enabled", true)
    
    if (!g_log_monitor_enabled) {
        LogInfo("ClientLogMonitor", "Client log monitoring is disabled in config")
        return false
    }
    
    ; ログファイルの存在確認
    if (!ValidateLogFile()) {
        return false
    }
    
    try {
        ; ファイルハンドルを開く（読み込み専用、共有モード）
        g_log_file_handle := FileOpen(g_client_log_path, "r-d", "UTF-8")
        if (!g_log_file_handle) {
            throw Error("Failed to open log file")
        }
        
        ; ファイルの最後に移動
        g_log_file_handle.Seek(0, 2)  ; ファイル末尾
        g_last_file_size := g_log_file_handle.Pos
        g_last_read_position := g_last_file_size
        
        ; 監視間隔を設定から取得
        checkInterval := ConfigManager.Get("ClientLog", "CheckInterval", 250)
        
        ; 監視タイマーを開始
        StartManagedTimer("ClientLogMonitor", CheckClientLog, checkInterval)
        
        LogInfo("ClientLogMonitor", "Client log monitoring started at: " . g_client_log_path)
        ShowOverlay("ログベースエリア検出: 有効", 2000)
        
        return true
        
    } catch as e {
        LogError("ClientLogMonitor", "Failed to start monitoring: " . e.Message)
        CloseLogFile()
        return false
    }
}

; --- ログファイルの検証 ---
ValidateLogFile() {
    global g_client_log_path
    
    ; プライマリパスの確認
    if (FileExist(g_client_log_path)) {
        return true
    }
    
    LogError("ClientLogMonitor", "Client.txt not found at: " . g_client_log_path)
    
    ; 代替パスのリスト
    alternatePaths := [
        "C:\Program Files\Steam\steamapps\common\Path of Exile\logs\Client.txt",
        "C:\Steam\steamapps\common\Path of Exile\logs\Client.txt",
        "D:\Steam\steamapps\common\Path of Exile\logs\Client.txt",
        A_MyDocuments . "\My Games\Path of Exile\logs\Client.txt"
    ]
    
    ; 代替パスを試す
    for path in alternatePaths {
        if (FileExist(path)) {
            g_client_log_path := path
            LogInfo("ClientLogMonitor", "Found Client.txt at alternate path: " . path)
            
            ; 設定を更新
            ConfigManager.Set("ClientLog", "Path", path)
            return true
        }
    }
    
    ShowOverlay("Client.txtが見つかりません", 3000)
    return false
}

; --- ログファイルチェック（最適化版） ---
CheckClientLog() {
    global g_client_log_path, g_last_file_size, g_macro_active
    global g_area_change_detected, g_last_read_position
    global g_log_file_handle, g_monitor_errors
    
    if (!g_log_monitor_enabled || !g_log_file_handle) {
        return
    }
    
    try {
        ; 現在のファイルサイズを取得
        g_log_file_handle.Seek(0, 2)  ; ファイル末尾
        currentSize := g_log_file_handle.Pos
        
        ; ファイルが更新されていない場合はスキップ
        if (currentSize <= g_last_read_position) {
            return
        }
        
        ; ファイルが縮小した場合（ログローテーション）
        if (currentSize < g_last_file_size) {
            HandleLogRotation()
            return
        }
        
        ; 新しいデータを読み込む
        newEntries := ReadNewLogEntries(g_last_read_position, currentSize)
        
        if (newEntries != "") {
            ; エリア移動をチェック
            if (CheckForAreaChange(newEntries)) {
                HandleAreaChangeDetected()
            }
            
            ; その他の重要なイベントをチェック
            CheckForOtherEvents(newEntries)
        }
        
        ; 読み込み位置を更新
        g_last_file_size := currentSize
        g_last_read_position := currentSize
        
        ; エラーカウントをリセット
        g_monitor_errors := 0
        
    } catch as e {
        g_monitor_errors++
        LogError("ClientLogMonitor", Format("Log check failed (errors: {}): {}", 
            g_monitor_errors, e.Message))
        
        ; エラーが続く場合はファイルハンドルを再オープン
        if (g_monitor_errors > 5) {
            ReopenClientLogFile()
        }
    }
}

; --- 新しいログエントリを読み込み（最適化版） ---
ReadNewLogEntries(startPos, endPos) {
    global g_log_file_handle, g_read_buffer_size
    
    try {
        if (!g_log_file_handle) {
            throw Error("Log file handle is not open")
        }
        
        ; 読み込みサイズを制限（メモリ使用量対策）
        bytesToRead := Min(endPos - startPos, g_read_buffer_size)
        
        ; 読み込み位置に移動
        g_log_file_handle.Seek(startPos)
        
        ; データを読み込む
        newData := g_log_file_handle.Read(bytesToRead)
        
        ; 部分的な行の処理
        if (bytesToRead < endPos - startPos) {
            ; 最後の改行までを含める
            lastNewline := InStr(newData, "`n", , -1)
            if (lastNewline > 0) {
                newData := SubStr(newData, 1, lastNewline)
                global g_last_read_position
                g_last_read_position := startPos + lastNewline
            }
        }
        
        return newData
        
    } catch as e {
        LogError("ClientLogMonitor", "Failed to read log entries: " . e.Message)
        return ""
    }
}

; --- エリア変更をチェック（改善版） ---
CheckForAreaChange(logData) {
    global g_last_area_entry_time, g_last_area_name, g_area_history
    
    ; パターンを事前コンパイル（パフォーマンス向上）
    static pattern := "(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}).*\[INFO Client \d+\] : You have entered (.+)\."
    static instancePattern := "(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}).*\[INFO Client \d+\] Generating level (\d+) area `"(.+)`""
    
    ; 最新のエリア移動を検索
    lastMatch := ""
    lastTimestamp := ""
    lastArea := ""
    isNewInstance := false
    
    ; "You have entered" パターン
    startPos := 1
    while (RegExMatch(logData, pattern, &match, startPos)) {
        lastMatch := match[0]
        lastTimestamp := match[1]
        lastArea := match[2]
        startPos := match.Pos + match.Len
    }
    
    ; 新規インスタンス生成パターンもチェック
    startPos := 1
    while (RegExMatch(logData, instancePattern, &match, startPos)) {
        if (match[1] > lastTimestamp) {  ; より新しい場合
            lastTimestamp := match[1]
            lastArea := match[3]
            isNewInstance := true
        }
        startPos := match.Pos + match.Len
    }
    
    ; 新しいエリア移動が見つかった場合
    if (lastMatch != "" || isNewInstance) && (lastTimestamp != g_last_area_entry_time) {
        g_last_area_entry_time := lastTimestamp
        g_last_area_name := lastArea
        
        ; エリア履歴に追加（最大10件）
        g_area_history.InsertAt(1, {
            timestamp: lastTimestamp,
            area: lastArea,
            isNewInstance: isNewInstance
        })
        
        if (g_area_history.Length > 10) {
            g_area_history.RemoveAt(11)
        }
        
        LogInfo("ClientLogMonitor", Format("Area change detected: {} at {} {}", 
            lastArea, lastTimestamp, isNewInstance ? "(new instance)" : ""))
        
        ShowOverlay(Format("エリア移動検出: {}", lastArea), 2000)
        
        return true
    }
    
    return false
}

; --- その他の重要なイベントをチェック ---
CheckForOtherEvents(logData) {
    ; 死亡検出
    if (InStr(logData, "has been slain") || InStr(logData, "You have died")) {
        LogInfo("ClientLogMonitor", "Death detected")
        ShowOverlay("死亡検出", 2000)
    }
    
    ; 切断検出
    if (InStr(logData, "Disconnected from server") || InStr(logData, "Lost connection")) {
        LogWarn("ClientLogMonitor", "Disconnection detected")
        ShowOverlay("切断検出", 2000)
    }
    
    ; レベルアップ検出
    if (RegExMatch(logData, "is now level (\d+)", &match)) {
        LogInfo("ClientLogMonitor", Format("Level up detected: {}", match[1]))
        ShowOverlay(Format("レベルアップ: {}", match[1]), 2000)
    }
}

; --- エリア変更検出時の処理 ---
HandleAreaChangeDetected() {
    global g_area_change_detected, g_was_macro_active_before_loading
    global g_macro_active, g_waiting_for_user_input, g_last_area_name
    
    g_area_change_detected := true
    g_was_macro_active_before_loading := g_macro_active
    
    ; 非戦闘エリアかチェック
    if (IsNonCombatArea(g_last_area_name)) {
        LogInfo("ClientLogMonitor", Format("Non-combat area detected: {}", g_last_area_name))
        
        if (g_macro_active) {
            ShowOverlay("非戦闘エリア - マクロ停止", 2000)
            ToggleMacro()
        }
        return
    }
    
    if (g_macro_active) {
        ; マクロを一時停止
        ShowOverlay("エリア移動検出 - マクロ一時停止", 2000)
        ToggleMacro()  ; マクロをオフにする
        
        ; ユーザー入力待機を開始
        g_waiting_for_user_input := true
        StartManagedTimer("UserInputAfterArea", WaitForUserInputAfterArea, 50)
        
        LogInfo("ClientLogMonitor", "Macro paused due to area change")
    }
}

; --- エリア移動後のユーザー入力待機（改善版） ---
WaitForUserInputAfterArea() {
    global g_waiting_for_user_input, g_was_macro_active_before_loading
    
    if (!g_waiting_for_user_input) {
        StopManagedTimer("UserInputAfterArea")
        return
    }
    
    ; ウィンドウがアクティブでない場合はスキップ
    if (!IsTargetWindowActive()) {
        return
    }
    
    ; より効率的な入力検出
    static inputKeys := ["W", "A", "S", "D", "Up", "Down", "Left", "Right",
                        "LButton", "RButton", "MButton",
                        "Q", "E", "R", "T", "1", "2", "3", "4", "5"]
    
    for key in inputKeys {
        if (GetKeyState(key, "P")) {
            HandleUserInputAfterArea(key)
            return
        }
    }
}

; --- エリア移動後の入力検出時の処理 ---
HandleUserInputAfterArea(inputType) {
    global g_waiting_for_user_input, g_was_macro_active_before_loading
    global g_area_change_detected
    
    g_waiting_for_user_input := false
    g_area_change_detected := false
    StopManagedTimer("UserInputAfterArea")
    
    LogInfo("ClientLogMonitor", "User input detected after area change: " . inputType)
    
    ; 設定に基づいて自動再開するか判断
    autoRestartDelay := 500
    if (ConfigManager.Get("ClientLog", "RestartInTown", false) || 
        !IsNonCombatArea(g_last_area_name)) {
        if (g_was_macro_active_before_loading) {
            SetTimer(() => RestartMacroAfterArea(), -autoRestartDelay)
        }
    }
}

; --- エリア移動後のマクロ再開 ---
RestartMacroAfterArea() {
    global g_macro_active, g_was_macro_active_before_loading, g_last_area_name
    
    if (!g_macro_active && g_was_macro_active_before_loading && IsTargetWindowActive()) {
        ShowOverlay("プレイヤー入力検出 - マクロ再開", 2000)
        ToggleMacro()
        g_was_macro_active_before_loading := false
        
        LogInfo("ClientLogMonitor", "Macro restarted after area change")
    }
}

; --- 非戦闘エリアかチェック（拡張版） ---
IsNonCombatArea(areaName) {
    ; ハイドアウト
    if (InStr(areaName, "Hideout")) {
        return true
    }
    
    ; メインメニュー
    if (InStr(areaName, "Main Menu") || InStr(areaName, "Character Selection")) {
        return true
    }
    
    ; 町エリア（拡張リスト）
    static townAreas := [
        "Lioneye's Watch",
        "The Forest Encampment", 
        "The Sarn Encampment",
        "Highgate",
        "Overseer's Tower",
        "The Bridge Encampment",
        "Oriath",
        "The Karui Shores",
        "Kirac's Vault",
        "The Rogue Harbour",
        "The Templar Laboratory",
        "Expedition Camp",
        "The Azurite Mine",
        "Tane's Laboratory"
    ]
    
    for town in townAreas {
        if (InStr(areaName, town)) {
            return true
        }
    }
    
    ; Aspirants' Plaza（ラビリンス待機エリア）
    if (InStr(areaName, "Aspirant") && InStr(areaName, "Plaza")) {
        return true
    }
    
    ; メナジェリー
    if (InStr(areaName, "Menagerie")) {
        return true
    }
    
    return false
}

; --- ログローテーションの処理 ---
HandleLogRotation() {
    global g_last_file_size, g_last_read_position
    
    LogInfo("ClientLogMonitor", "Log rotation detected")
    
    ; ファイルの最初から読み始める
    g_last_file_size := 0
    g_last_read_position := 0
    
    ; ファイルハンドルを再オープン
    ReopenClientLogFile()
}

; --- クライアントログファイルの再オープン ---
ReopenClientLogFile() {
    global g_log_file_handle, g_client_log_path, g_monitor_errors
    
    CloseLogFile()
    
    try {
        g_log_file_handle := FileOpen(g_client_log_path, "r-d", "UTF-8")
        if (g_log_file_handle) {
            g_monitor_errors := 0
            LogInfo("ClientLogMonitor", "Log file reopened successfully")
        }
    } catch as e {
        LogError("ClientLogMonitor", "Failed to reopen log file: " . e.Message)
    }
}

; --- ログファイルを閉じる ---
CloseLogFile() {
    global g_log_file_handle
    
    if (g_log_file_handle) {
        try {
            g_log_file_handle.Close()
        } catch {
            ; エラーは無視
        }
        g_log_file_handle := ""
    }
}

; --- ログ監視の停止 ---
StopClientLogMonitoring() {
    StopManagedTimer("ClientLogMonitor")
    StopManagedTimer("UserInputAfterArea")
    
    CloseLogFile()
    
    LogInfo("ClientLogMonitor", "Client log monitoring stopped")
}

; --- エリア履歴を取得 ---
GetAreaHistory() {
    global g_area_history
    return g_area_history
}

; --- デバッグ：最後のエリアエントリを表示 ---
ShowLastAreaEntry() {
    global g_last_area_name, g_last_area_entry_time, g_area_history
    
    if (g_last_area_name != "") {
        debugInfo := []
        debugInfo.Push("=== エリア移動履歴 ===")
        debugInfo.Push(Format("最新: {} ({})", g_last_area_name, g_last_area_entry_time))
        debugInfo.Push("")
        
        for i, entry in g_area_history {
            if (i > 5) {  ; 最新5件まで
                break
            }
            debugInfo.Push(Format("{}: {} {}", 
                entry.timestamp, 
                entry.area,
                entry.isNewInstance ? "[New]" : ""))
        }
        
        ShowMultiLineOverlay(debugInfo, 5000)
    } else {
        ShowOverlay("エリア移動ログが見つかりません", 3000)
    }
}

; --- 監視統計の取得 ---
GetClientLogMonitorStats() {
    global g_monitor_errors, g_area_history, g_last_file_size
    global g_read_buffer_size
    
    return {
        errors: g_monitor_errors,
        areaCount: g_area_history.Length,
        fileSize: Round(g_last_file_size / 1024, 2),  ; KB
        bufferSize: g_read_buffer_size,
        lastArea: g_last_area_name
    }
}