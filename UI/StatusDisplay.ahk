; ===================================================================
; ステータス表示UI
; ===================================================================

; --- ステータスオーバーレイ作成 ---
CreateStatusOverlay() {
    global statusGui
    
    statusGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
    statusGui.BackColor := "000000"
    RecreateStatusGui()
    
    ; 定期的にウィンドウ状態をチェック
    SetTimer(CheckWindowStatus, 100)
}

; --- ステータス更新 ---
UpdateStatusOverlay() {
    global g_status_update_needed
    g_status_update_needed := true
}

; --- GUI再作成 ---
RecreateStatusGui() {
    global statusGui, g_macro_active, g_mana_fill_rate
    global g_tincture_active, g_tincture_cooldown_end
    
    ; 既存のGUIをクリア
    if (statusGui && IsObject(statusGui)) {
        try {
            statusGui.Destroy()
        } catch {
            ; エラーは無視
        }
    }
    
    ; 新しいGUIを作成
    statusGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
    statusGui.BackColor := "000000"
    
    ; ステータステキストを追加
    BuildStatusText()
    
    WinSetTransparent(180, statusGui)
    
    ; 表示位置を設定
    if (WinActive("ahk_group TargetWindows")) {
        ShowStatusOverlay()
    }
}