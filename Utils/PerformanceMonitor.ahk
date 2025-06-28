class PerformanceMonitor {
    static metrics := Map()
    static enabled := false
    
    static Start() {
        this.enabled := ConfigManager.Get("Performance", "MonitoringEnabled", false)
        if (this.enabled) {
            SetTimer(ObjBindMethod(this, "CollectMetrics"), 5000)
        }
    }
    
    static CollectMetrics() {
        ; CPU使用率、メモリ使用量などを収集
        this.metrics["timestamp"] := A_TickCount
        this.metrics["activeTimers"] := g_active_timers.Count
        this.metrics["logSize"] := FileGetSize(g_log_file)
        
        ; パフォーマンス問題を検出
        if (this.metrics["activeTimers"] > 20) {
            LogWarn("Performance", "Too many active timers: " . this.metrics["activeTimers"])
        }
    }
}