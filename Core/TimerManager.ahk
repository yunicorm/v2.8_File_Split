; ===================================================================
; タイマー管理システム
; 全てのタイマーを一元管理し、確実な停止と開始を保証
; ===================================================================

; --- アクティブなタイマーのリスト ---
global g_active_timers := Map()

; --- タイマーを登録して開始 ---
StartManagedTimer(timerName, callback, period) {
    global g_active_timers
    
    ; 既存のタイマーがあれば停止
    StopManagedTimer(timerName)
    
    ; タイマーを開始
    SetTimer(callback, period)
    
    ; リストに登録
    g_active_timers[timerName] := {
        callback: callback,
        period: period,
        startTime: A_TickCount
    }
}

; --- 特定のタイマーを停止 ---
StopManagedTimer(timerName) {
    global g_active_timers
    
    if (g_active_timers.Has(timerName)) {
        timerInfo := g_active_timers[timerName]
        SetTimer(timerInfo.callback, 0)
        g_active_timers.Delete(timerName)
    }
}

; --- 全てのタイマーを停止 ---
StopAllTimers() {
    global g_active_timers
    
    ; 各タイマーを停止
    for timerName, timerInfo in g_active_timers {
        SetTimer(timerInfo.callback, 0)
    }
    
    ; リストをクリア
    g_active_timers.Clear()
    
    ; フラグもリセット
    global g_flask_timer_active, g_tincture_retry_count
    g_flask_timer_active := false
    g_tincture_retry_count := 0
    
    ; エリア検出も停止
    try {
        StopClientLogMonitoring()
    } catch {
        ; エラーは無視
    }
    
    try {
        StopLoadingScreenDetection()
    } catch {
        ; エラーは無視
    }
}

; --- タイマーの状態を取得 ---
IsTimerActive(timerName) {
    global g_active_timers
    return g_active_timers.Has(timerName)
}

; --- アクティブなタイマーのリストを取得 ---
GetActiveTimers() {
    global g_active_timers
    timerList := []
    
    for timerName, timerInfo in g_active_timers {
        timerList.Push({
            name: timerName,
            runTime: A_TickCount - timerInfo.startTime,
            period: timerInfo.period
        })
    }
    
    return timerList
}

; --- デバッグ用：全タイマーの状態を表示 ---
ShowTimerDebugInfo() {
    global g_active_timers
    
    debugText := "=== Active Timers ===`n"
    debugText .= Format("Total: {} timers`n`n", g_active_timers.Count)
    
    for timerName, timerInfo in g_active_timers {
        runTime := Round((A_TickCount - timerInfo.startTime) / 1000, 1)
        debugText .= Format("{}: {}s ({}ms interval)`n", 
            timerName, runTime, timerInfo.period)
    }
    
    if (g_active_timers.Count == 0) {
        debugText .= "No active timers"
    }
    
    ShowOverlay(debugText, 3000)
}