; ===================================================================
; マクロコントローラー
; マクロの初期アクションと状態管理
; ===================================================================

; --- 初期アクション実行 ---
PerformInitialActions() {
    global g_tincture_active, g_flask_timer_active
    
    ; Tinctureの状態をリセット
    ResetTinctureState()
    
    ; 即座にTinctureを使用
    InitialTinctureUse()
    
    ; マナ状態を初期化
    InitializeManaState()
    
    LogInfo("MacroController", "Initial actions performed")
}