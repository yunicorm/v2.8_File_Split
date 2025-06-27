; ===================================================================
; 設定とグローバル変数
; ===================================================================

; --- マクロ制御 ---
global g_macro_active := false
global g_macro_start_time := 0

; --- Tincture設定 ---
global g_tincture_active := false
global g_tincture_cooldown_end := 0
global g_tincture_retry_count := 0
global g_tincture_retry_max := 5

; --- マナ監視設定 ---
global g_mana_center_x := 3155 + (278 / 2)
global g_mana_center_y := 1161 + (278 / 2)
global g_mana_radius := 278 / 2
global g_mana_monitoring_enabled := true
global g_mana_fill_rate := 100
global g_last_mana_state := true
global g_mana_depleted := false
global g_mana_flask_key := "2"

; --- ロード画面検出 ---
global g_loading_screen_active := false
global g_was_macro_active_before_loading := false
global g_loading_check_enabled := true
global g_waiting_for_user_input := false

; --- UI要素 ---
global overlayGui := ""
global statusGui := ""
global debugGuis := []

; --- タイマー管理 ---
global g_flask_timer_active := false
global g_status_update_needed := false

; --- キー設定（カスタマイズ可能） ---
global KEY_TINCTURE := "3"
global KEY_MANA_FLASK := "2"
global KEY_SKILL_E := "E"
global KEY_SKILL_R := "R"
global KEY_SKILL_T := "T"
global KEY_WINE_PROPHET := "4"

; --- タイミング設定（ミリ秒） ---
global TIMING_SKILL_ER := {min: 1000, max: 1100}
global TIMING_SKILL_T := {min: 4100, max: 4200}
global TIMING_FLASK := {min: 4500, max: 4800}
global TIMING_MANA_DEPLETED_CD := 5410

; --- デバッグ設定 ---
global g_debug_mode := false
global g_log_enabled := false  ; 修正: falsからfalseに