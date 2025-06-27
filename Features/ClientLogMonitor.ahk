; ===================================================================
; Client.txtログ監視システム
; エリア移動をログファイルから検出して自動的にマクロを制御
; ===================================================================

; --- グローバル変数 ---
global g_client_log_path := ""  ; Config.iniから読み込む
global g_last_file_size := 0
global g_last_area_entry_time := ""
global g_log_monitor_enabled := true
global g_area_change_detected := false
global g_last_read_position := 0
global g_last_area_name := ""

; --- ログ監視の開始 ---
StartClientLogMonitoring() {
    global g_log_monitor_enabled, g_client_log_path, g_last_file_size
    
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
    if (!FileExist(g_client_log_path)) {
        LogError("ClientLogMonitor", "Client.txt not found at: " . g_client_log_path)
        ShowOverlay("Client.txtが見つかりません", 3000)
        
        ; 別の一般的なパスも試す
        alternatePath := "C:\Program Files\Steam\steamapps\common\Path of Exile\logs\Client.txt"
        if (FileExist(alternatePath)) {
            g_client_log_path := alternatePath
            LogInfo("ClientLogMonitor", "Found Client.txt at alternate path: " . alternatePath)
        } else {
            return false
        }
    }
    
    ; 初期ファイルサイズを記録
    try {
        g_last_file_size := FileGetSize(g_client_log_path)
        g_last_read_position := g_last_file_size
    } catch Error as e {
        LogError("ClientLogMonitor", "Failed to get initial file size: " . e.Message)
        return false
    }
    
    ; 監視間隔を設定から取得
    checkInterval := ConfigManager.Get("ClientLog", "CheckInterval", 250)
    
    ; 監視タイマーを開始
    StartManagedTimer("ClientLogMonitor", CheckClientLog, checkInterval)
    
    LogInfo("ClientLogMonitor", "Client log monitoring started at: " . g_client_log_path)
    ShowOverlay("ログベースエリア検出: 有効", 2000)
    return true
}

; --- ログファイルチェック ---
CheckClientLog() {
    global g_client_log_path, g_last_file_size, g_macro_active
    global g_area_change_detected, g_last_read_position
    
    if (!g_log_monitor_enabled || !g_macro_active) {
        return
    }
    
    try {
        ; ファイルサイズをチェック
        currentSize := FileGetSize(g_client_log_path)
        
        ; ファイルが更新されていない場合はスキップ
        if (currentSize <= g_last_file_size) {
            return
        }
        
        ; 新しいデータを読み込む
        newEntries := ReadNewLogEntries(g_last_file_size, currentSize)
        
        ; エリア移動をチェック
        if (CheckForAreaChange(newEntries)) {
            HandleAreaChangeDetected()
        }
        
        ; ファイルサイズを更新
        g_last_file_size := currentSize
        g_last_read_position := currentSize
        
    } catch Error as e {
        LogError("ClientLogMonitor", "Log check failed: " . e.Message)
    }
}

; --- 新しいログエントリを読み込み ---
ReadNewLogEntries(startPos, endPos) {
    global g_client_log_path
    
    try {
        ; ファイルを読み込み専用で開く
        file := FileOpen(g_client_log_path, "r")
        if (!file) {
            throw Error("Failed to open log file")
        }
        
        ; 読み込み位置に移動
        file.Seek(startPos)
        
        ; 新しいデータを読み込む（最大10KB）
        bytesToRead := Min(endPos - startPos, 10240)
        newData := file.Read(bytesToRead)
        
        file.Close()
        
        return newData
        
    } catch Error as e {
        LogError("ClientLogMonitor", "Failed to read log entries: " . e.Message)
        return ""
    }
}

; --- エリア変更をチェック ---
CheckForAreaChange(logData) {
    global g_last_area_entry_time, g_last_area_name
    
    ; "You have entered" パターンを検索
    ; 例: 2025/06/27 21:20:15 428895203 cff945b9 [INFO Client 11716] : You have entered The Sarn Encampment.
    pattern := "(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}).*\[INFO Client \d+\] : You have entered (.+)\."
    
    ; 最後のマッチを探す（最新のエリア移動）
    lastMatch := ""
    lastTimestamp := ""
    lastArea := ""
    
    startPos := 1
    while (RegExMatch(logData, pattern, &match, startPos)) {
        lastMatch := match[0]
        lastTimestamp := match[1]
        lastArea := match[2]
        startPos := match.Pos + match.Len
    }
    
    ; 新しいエリア移動が見つかった場合
    if (lastMatch != "" && lastTimestamp != g_last_area_entry_time) {
        g_last_area_entry_time := lastTimestamp
        g_last_area_name := lastArea
        
        LogInfo("ClientLogMonitor", Format("Area change detected: {} at {}", 
            lastArea, lastTimestamp))
        
        ShowOverlay(Format("エリア移動検出: {}", lastArea), 2000)
        
        return true
    }
    
    return false
}

; --- エリア変更検出時の処理 ---
HandleAreaChangeDetected() {
    global g_area_change_detected, g_was_macro_active_before_loading
    global g_macro_active, g_waiting_for_user_input
    
    g_area_change_detected := true
    g_was_macro_active_before_loading := g_macro_active
    
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

; --- エリア移動後のユーザー入力待機 ---
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
    
    ; 移動やアクションキーをチェック
    inputDetected := false
    detectedInput := ""
    
    ; 移動キー
    movementKeys := ["W", "A", "S", "D", "Up", "Down", "Left", "Right"]
    for key in movementKeys {
        if (GetKeyState(key, "P")) {
            inputDetected := true
            detectedInput := "Movement: " . key
            break
        }
    }
    
    ; マウスクリック
    if (!inputDetected) {
        mouseButtons := ["LButton", "RButton", "MButton"]
        for button in mouseButtons {
            if (GetKeyState(button, "P")) {
                inputDetected := true
                detectedInput := "Mouse: " . button
                break
            }
        }
    }
    
    ; スキルキー
    if (!inputDetected) {
        skillKeys := ["Q", "E", "R", "T", "1", "2", "3", "4", "5"]
        for key in skillKeys {
            if (GetKeyState(key, "P")) {
                inputDetected := true
                detectedInput := "Skill: " . key
                break
            }
        }
    }
    
    ; 入力が検出された場合
    if (inputDetected) {
        HandleUserInputAfterArea(detectedInput)
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
    
    ; 0.5秒待ってからマクロを再開（誤動作防止）
    if (g_was_macro_active_before_loading) {
        SetTimer(() => RestartMacroAfterArea(), -500)
    }
}

; --- エリア移動後のマクロ再開 ---
RestartMacroAfterArea() {
    global g_macro_active, g_was_macro_active_before_loading, g_last_area_name
    
    ; ハイドアウトや町などの非戦闘エリアをチェック
    if (IsNonCombatArea(g_last_area_name)) {
        ShowOverlay("非戦闘エリア - マクロ再開をスキップ", 2000)
        g_was_macro_active_before_loading := false
        LogInfo("ClientLogMonitor", Format("Non-combat area detected: {}", g_last_area_name))
        return
    }
    
    if (!g_macro_active && g_was_macro_active_before_loading && IsTargetWindowActive()) {
        ShowOverlay("プレイヤー入力検出 - マクロ再開", 2000)
        ToggleMacro()
        g_was_macro_active_before_loading := false
        
        LogInfo("ClientLogMonitor", "Macro restarted after area change")
    }
}

; --- 非戦闘エリアかチェック ---
IsNonCombatArea(areaName) {
    ; ハイドアウト
    if (InStr(areaName, "Hideout")) {
        return true
    }
    
    ; 町エリア
    townAreas := [
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
        "The Templar Laboratory"
    ]
    
    for town in townAreas {
        if (InStr(areaName, town)) {
            return true
        }
    }
    
    ; Aspirants' Plaza（ラビリンス待機エリア）
    if (InStr(areaName, "Aspirants' Plaza") || InStr(areaName, "Aspirant's Plaza")) {
        return true
    }
    
    return false
}

; --- ログ監視の停止 ---
StopClientLogMonitoring() {
    StopManagedTimer("ClientLogMonitor")
    StopManagedTimer("UserInputAfterArea")
    
    LogInfo("ClientLogMonitor", "Client log monitoring stopped")
}

; --- 最後の行を効率的に読み込む（別アプローチ） ---
ReadLastLines(filePath, numLines := 10) {
    try {
        ; ファイル全体を読み込む代わりに、末尾から読む
        file := FileOpen(filePath, "r")
        if (!file) {
            return ""
        }
        
        ; ファイルサイズを取得
        fileSize := file.Length
        
        ; 読み込み開始位置（最後の2KB程度）
        startPos := Max(0, fileSize - 2048)
        file.Seek(startPos)
        
        ; データを読み込む
        content := file.Read()
        file.Close()
        
        ; 行に分割して最後のN行を返す
        lines := StrSplit(content, "`n", "`r")
        result := []
        
        ; 最後のnumLines行を取得
        startIdx := Max(1, lines.Length - numLines + 1)
        Loop (lines.Length - startIdx + 1) {
            if (lines[startIdx + A_Index - 1] != "") {
                result.Push(lines[startIdx + A_Index - 1])
            }
        }
        
        return result
        
    } catch Error as e {
        LogError("ClientLogMonitor", "Failed to read last lines: " . e.Message)
        return []
    }
}

; --- デバッグ：最後のエリアエントリを表示 ---
ShowLastAreaEntry() {
    global g_client_log_path
    
    lines := ReadLastLines(g_client_log_path, 50)
    lastArea := ""
    
    for line in lines {
        if (InStr(line, "You have entered")) {
            lastArea := line
        }
    }
    
    if (lastArea != "") {
        ShowOverlay("最後のエリア: " . lastArea, 5000)
    } else {
        ShowOverlay("エリア移動ログが見つかりません", 3000)
    }
}