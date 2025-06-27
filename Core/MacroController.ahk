; ===================================================================
; マクロ制御の中核機能
; ===================================================================

; --- メインマクロトグル ---
ToggleMacro(*) {
    global g_macro_active
    
    ; 二重実行防止
    static lastExecutionTime := 0
    currentTime := A_TickCount
    
    if (currentTime - lastExecutionTime < 500) {
        return
    }
    lastExecutionTime := currentTime
    
    ; 状態を切り替え
    g_macro_active := !g_macro_active
    
    if (g_macro_active) {
        StartMacro()
    } else {
        StopMacro()
    }
}

; --- マクロ開始処理 ---
StartMacro() {
    global g_macro_start_time
    
    ; タイマーをクリア
    StopAllTimers()
    
    g_macro_start_time := A_TickCount
    
    ; 初期状態を設定
    InitializeManaState()
    ResetTinctureState()
    
    ShowOverlay("Macro Started", 1500)
    
    ; 初期アクションを実行
    PerformInitialActions()
    
    ; 各機能を開始
    StartSkillAutomation()
    StartFlaskAutomation()
    StartManaMonitoring()
    
    ; エリア検出方式を選択
    if (ConfigManager.Get("ClientLog", "Enabled", true)) {
        StartClientLogMonitoring()
    } else if (g_loading_check_enabled) {
        StartLoadingScreenDetection()
    }
    
    UpdateStatusOverlay()
}

; --- マクロ停止処理 ---
StopMacro() {
    StopAllTimers()
    UpdateStatusOverlay()
    ShowOverlay("Macro Stopped", 1500)
}

; --- 初期アクション実行 ---
PerformInitialActions() {
    global KEY_TINCTURE, KEY_MANA_FLASK, g_tincture_active
    
    ; 初回Tincture使用
    Send(KEY_TINCTURE)
    g_tincture_active := true
    
    ; 少し待機
    Sleep(100)
    
    ; 初回マナフラスコ使用
    Send(KEY_MANA_FLASK)
    
    LogInfo("MacroController", "Initial actions performed")
}