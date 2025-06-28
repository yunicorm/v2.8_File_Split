; ===================================================================
; タイマー管理システム（修正版）
; 全てのタイマーを一元管理し、確実な停止と開始を保証
; ===================================================================

; --- グローバル変数 ---
global g_active_timers := Map()
global g_timer_execution_count := Map()
global g_timer_errors := Map()
global g_timer_executing := Map()  ; 実行中フラグ
global g_timer_priorities := Map()  ; 優先度管理
global g_timer_performance := Map()  ; パフォーマンス統計

; --- タイマー優先度定義 ---
class TimerPriority {
    static CRITICAL := 1    ; マナ監視など
    static HIGH := 2        ; Tincture管理など
    static NORMAL := 3      ; スキル実行など
    static LOW := 4         ; UI更新など
}

; --- タイマーを登録して開始（改善版） ---
StartManagedTimer(timerName, callback, period, priority := TimerPriority.NORMAL) {
    global g_active_timers, g_timer_executing, g_timer_priorities
    global g_timer_execution_count, g_timer_errors
    
    ; 実行中チェック
    if (g_timer_executing.Has(timerName) && g_timer_executing[timerName]) {
        LogWarn("TimerManager", Format("Timer '{}' is currently executing, skipping registration", timerName))
        return false
    }
    
    ; 既存のタイマーがあれば停止
    if (g_active_timers.Has(timerName)) {
        LogDebug("TimerManager", Format("Stopping existing timer '{}'", timerName))
        StopManagedTimer(timerName)
        
        ; 少し待機（既存タイマーの完全停止を確保）
        Sleep(50)
    }
    
    try {
        ; ラッパー関数を作成（エラーハンドリングとパフォーマンス計測）
        wrappedCallback := CreateTimerWrapper(timerName, callback)
        
        ; タイマーを開始
        SetTimer(wrappedCallback, period)
        
        ; 管理情報を登録
        g_active_timers[timerName] := {
            callback: callback,
            wrappedCallback: wrappedCallback,
            period: period,
            startTime: A_TickCount,
            lastExecutionTime: 0,
            priority: priority
        }
        
        g_timer_priorities[timerName] := priority
        g_timer_executing[timerName] := false
        
        ; 統計を初期化
        if (!g_timer_execution_count.Has(timerName)) {
            g_timer_execution_count[timerName] := 0
        }
        if (!g_timer_errors.Has(timerName)) {
            g_timer_errors[timerName] := 0
        }
        
        LogDebug("TimerManager", Format("Timer '{}' started with period {}ms (Priority: {})", 
            timerName, period, priority))
        
        return true
        
    } catch as e {
        LogError("TimerManager", Format("Failed to start timer '{}': {}", timerName, e.Message))
        return false
    }
}

; --- タイマーラッパー作成 ---
CreateTimerWrapper(timerName, callback) {
    return () => ExecuteTimerCallback(timerName, callback)
}

; --- タイマーコールバック実行（エラーハンドリング付き） ---
ExecuteTimerCallback(timerName, callback) {
    global g_timer_executing, g_timer_execution_count, g_timer_errors
    global g_active_timers, g_timer_performance
    
    ; 実行中フラグをチェック（二重実行防止）
    if (g_timer_executing.Has(timerName) && g_timer_executing[timerName]) {
        LogWarn("TimerManager", Format("Timer '{}' is already executing, skipping", timerName))
        return
    }
    
    ; タイマーが無効化されているかチェック
    if (!g_active_timers.Has(timerName)) {
        LogDebug("TimerManager", Format("Timer '{}' has been stopped, skipping execution", timerName))
        return
    }
    
    g_timer_executing[timerName] := true
    startTime := A_TickCount
    
    try {
        ; 実行カウントを増加
        g_timer_execution_count[timerName]++
        
        ; コールバックを実行
        callback()
        
        ; 実行時間を記録
        executionTime := A_TickCount - startTime
        
        ; パフォーマンス統計を更新
        UpdateTimerPerformance(timerName, executionTime)
        
        ; 実行情報を更新
        if (g_active_timers.Has(timerName)) {
            g_active_timers[timerName].lastExecutionTime := A_TickCount
        }
        
        ; 遅い実行を警告
        if (executionTime > 200) {  ; 200ms以上
            LogWarn("TimerManager", Format("Timer '{}' took {}ms to execute", timerName, executionTime))
        }
        
    } catch as e {
        g_timer_errors[timerName]++
        LogError("TimerManager", Format("Error in timer '{}' (errors: {}): {}", 
            timerName, g_timer_errors[timerName], e.Message))
        
        ; エラーが多い場合はタイマーを停止
        if (g_timer_errors[timerName] > 10) {
            LogError("TimerManager", Format("Timer '{}' has too many errors, stopping", timerName))
            StopManagedTimer(timerName)
        }
    } finally {
        g_timer_executing[timerName] := false
    }
}

; --- パフォーマンス統計の更新 ---
UpdateTimerPerformance(timerName, executionTime) {
    global g_timer_performance
    
    if (!g_timer_performance.Has(timerName)) {
        g_timer_performance[timerName] := {
            totalTime: 0,
            count: 0,
            maxTime: 0,
            minTime: 999999,
            avgTime: 0
        }
    }
    
    perf := g_timer_performance[timerName]
    perf.totalTime += executionTime
    perf.count++
    perf.maxTime := Max(perf.maxTime, executionTime)
    perf.minTime := Min(perf.minTime, executionTime)
    perf.avgTime := Round(perf.totalTime / perf.count, 2)
}

; --- 特定のタイマーを停止（改善版） ---
StopManagedTimer(timerName) {
    global g_active_timers, g_timer_executing
    
    if (!g_active_timers.Has(timerName)) {
        LogDebug("TimerManager", Format("Timer '{}' is not active", timerName))
        return false
    }
    
    try {
        timerInfo := g_active_timers[timerName]
        
        ; タイマーを停止
        SetTimer(timerInfo.wrappedCallback, 0)
        
        ; 実行中の場合は完了を待つ
        if (g_timer_executing.Has(timerName) && g_timer_executing[timerName]) {
            LogDebug("TimerManager", Format("Waiting for timer '{}' to complete", timerName))
            
            ; 最大1秒待機
            waitStart := A_TickCount
            while (g_timer_executing[timerName] && A_TickCount - waitStart < 1000) {
                Sleep(10)
            }
            
            if (g_timer_executing[timerName]) {
                LogWarn("TimerManager", Format("Timer '{}' did not complete in time", timerName))
            }
        }
        
        ; 管理情報を削除
        g_active_timers.Delete(timerName)
        if (g_timer_executing.Has(timerName)) {
            g_timer_executing.Delete(timerName)
        }
        if (g_timer_priorities.Has(timerName)) {
            g_timer_priorities.Delete(timerName)
        }
        
        LogDebug("TimerManager", Format("Timer '{}' stopped", timerName))
        return true
        
    } catch as e {
        LogError("TimerManager", Format("Failed to stop timer '{}': {}", timerName, e.Message))
        return false
    }
}

; --- 全てのタイマーを停止（優先度順） ---
StopAllTimers() {
    global g_active_timers, g_timer_priorities
    
    LogInfo("TimerManager", "Stopping all timers")
    
    ; 優先度順にソート（低優先度から停止）
    sortedTimers := []
    for timerName, _ in g_active_timers {
        sortedTimers.Push({
            name: timerName,
            priority: g_timer_priorities.Has(timerName) ? g_timer_priorities[timerName] : TimerPriority.NORMAL
        })
    }
    
    ; 優先度でソート（降順）
    Loop sortedTimers.Length - 1 {
        i := A_Index
        Loop sortedTimers.Length - i {
            j := A_Index + i
            if (sortedTimers[i].priority < sortedTimers[j].priority) {
                temp := sortedTimers[i]
                sortedTimers[i] := sortedTimers[j]
                sortedTimers[j] := temp
            }
        }
    }
    
    ; 順番に停止
    for timer in sortedTimers {
        StopManagedTimer(timer.name)
    }
    
    ; グローバルフラグもリセット
    global g_flask_timer_active, g_tincture_retry_count
    g_flask_timer_active := false
    g_tincture_retry_count := 0
    
    ; エリア検出も停止
    ; 依存モジュールの停止関数を呼び出し（存在する場合のみ）
    try {
        StopClientLogMonitoring()
    } catch {
        ; 関数が定義されていない場合は無視
    }
    
    try {
        StopLoadingScreenDetection()
    } catch {
        ; 関数が定義されていない場合は無視
    }
    
    ; 統計をクリア
    global g_timer_execution_count, g_timer_errors, g_timer_performance
    if (IsObject(g_timer_execution_count)) {
        g_timer_execution_count.Clear()
    }
    if (IsObject(g_timer_errors)) {
        g_timer_errors.Clear()
    }
    if (IsObject(g_timer_performance)) {
        g_timer_performance.Clear()
    }
    
    LogInfo("TimerManager", "All timers stopped")
}

; --- タイマーの状態を取得 ---
IsTimerActive(timerName) {
    global g_active_timers
    return g_active_timers.Has(timerName)
}

; --- タイマーの実行状態を取得 ---
IsTimerExecuting(timerName) {
    global g_timer_executing
    return g_timer_executing.Has(timerName) && g_timer_executing[timerName]
}

; --- アクティブなタイマーのリストを取得（詳細版） ---
GetActiveTimers() {
    global g_active_timers, g_timer_execution_count, g_timer_errors
    timerList := []
    
    for timerName, timerInfo in g_active_timers {
        timerList.Push({
            name: timerName,
            runTime: A_TickCount - timerInfo.startTime,
            period: timerInfo.period,
            priority: timerInfo.priority,
            executionCount: g_timer_execution_count.Has(timerName) ? g_timer_execution_count[timerName] : 0,
            errorCount: g_timer_errors.Has(timerName) ? g_timer_errors[timerName] : 0,
            lastExecutionTime: timerInfo.lastExecutionTime
        })
    }
    
    return timerList
}

; --- タイマーのパフォーマンス統計を取得 ---
GetTimerPerformanceStats() {
    global g_timer_performance
    return g_timer_performance
}

; --- デバッグ用：全タイマーの状態を表示（拡張版） ---
ShowTimerDebugInfoDetailed() {
    global g_active_timers, g_timer_execution_count, g_timer_errors, g_timer_performance
    
    debugText := "=== Active Timers ===`n"
    debugText .= Format("Total: {} timers`n`n", g_active_timers.Count)
    
    ; 優先度順にソート
    activeTimers := GetActiveTimers()
    
    ; 優先度でソート
    Loop activeTimers.Length - 1 {
        i := A_Index
        Loop activeTimers.Length - i {
            j := A_Index + i
            if (activeTimers[i].priority > activeTimers[j].priority) {
                temp := activeTimers[i]
                activeTimers[i] := activeTimers[j]
                activeTimers[j] := temp
            }
        }
    }
    
    for timer in activeTimers {
        runTime := Round(timer.runTime / 1000, 1)
        errorRate := timer.executionCount > 0 ? Round(timer.errorCount / timer.executionCount * 100, 1) : 0
        
        debugText .= Format("[P{}] {}: {}s ({}ms) - Exec: {} Err: {} ({}%)`n", 
            timer.priority,
            timer.name, 
            runTime, 
            timer.period,
            timer.executionCount,
            timer.errorCount,
            errorRate)
        
        ; パフォーマンス情報
        if (g_timer_performance.Has(timer.name)) {
            perf := g_timer_performance[timer.name]
            debugText .= Format("  Perf: Avg {}ms, Max {}ms, Min {}ms`n", 
                perf.avgTime, perf.maxTime, perf.minTime)
        }
    }
    
    if (g_active_timers.Count == 0) {
        debugText .= "No active timers"
    }
    
    ShowOverlay(debugText, 5000)
}

; --- タイマーの優先度を変更 ---
ChangeTimerPriority(timerName, newPriority) {
    global g_timer_priorities, g_active_timers
    
    if (g_active_timers.Has(timerName)) {
        g_timer_priorities[timerName] := newPriority
        g_active_timers[timerName].priority := newPriority
        
        LogInfo("TimerManager", Format("Timer '{}' priority changed to {}", timerName, newPriority))
        return true
    }
    
    return false
}

; --- 一時的にタイマーを停止 ---
PauseTimer(timerName) {
    global g_active_timers
    
    if (g_active_timers.Has(timerName)) {
        timerInfo := g_active_timers[timerName]
        SetTimer(timerInfo.wrappedCallback, 0)
        timerInfo.paused := true
        
        LogDebug("TimerManager", Format("Timer '{}' paused", timerName))
        return true
    }
    
    return false
}

; --- タイマーを再開 ---
ResumeTimer(timerName) {
    global g_active_timers
    
    if (g_active_timers.Has(timerName) && g_active_timers[timerName].HasOwnProp("paused") && g_active_timers[timerName].paused) {
        timerInfo := g_active_timers[timerName]
        SetTimer(timerInfo.wrappedCallback, timerInfo.period)
        timerInfo.paused := false
        
        LogDebug("TimerManager", Format("Timer '{}' resumed", timerName))
        return true
    }
    
    return false
}

; --- タイマー管理統計の取得 ---
GetTimerManagerStats() {
    global g_active_timers, g_timer_execution_count, g_timer_errors
    
    totalExecutions := 0
    totalErrors := 0
    
    for _, count in g_timer_execution_count {
        totalExecutions += count
    }
    
    for _, count in g_timer_errors {
        totalErrors += count
    }
    
    return {
        activeTimers: g_active_timers.Count,
        totalExecutions: totalExecutions,
        totalErrors: totalErrors,
        errorRate: totalExecutions > 0 ? Round(totalErrors / totalExecutions * 100, 2) : 0
    }
}