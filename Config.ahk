; ===================================================================
; 設定とグローバル変数
; INIファイルから読み込まれた値で初期化
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
global g_mana_center_x := 3294
global g_mana_center_y := 1300
global g_mana_radius := 139
global g_mana_monitoring_enabled := true
global g_mana_fill_rate := 100
global g_last_mana_state := true
global g_mana_depleted := false
global g_mana_flask_key := "2"
global g_mana_optimized := true

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

; --- キー設定 ---
global KEY_TINCTURE := "3"
global KEY_MANA_FLASK := "2"
global KEY_SKILL_E := "E"
global KEY_SKILL_R := "R"
global KEY_SKILL_T := "T"
global KEY_WINE_PROPHET := "4"

; --- タイミング設定 ---
global TIMING_SKILL_ER := {min: 1000, max: 1100}
global TIMING_SKILL_T := {min: 4100, max: 4200}
global TIMING_FLASK := {min: 4500, max: 4800}
global TIMING_MANA_DEPLETED_CD := 5410

; --- デバッグ設定 ---
global g_debug_mode := false
global g_log_enabled := true

; === 設定を適用する関数 ===
ApplyConfigSettings() {
    ; デバッグ設定
    g_debug_mode := ConfigManager.Get("General", "DebugMode", false)
    g_log_enabled := ConfigManager.Get("General", "LogEnabled", true)
    
    ; マナ設定
    g_mana_center_x := ConfigManager.ScaleCoordinate(
        ConfigManager.Get("Mana", "CenterX", 3294), true)
    g_mana_center_y := ConfigManager.ScaleCoordinate(
        ConfigManager.Get("Mana", "CenterY", 1300), false)
    g_mana_radius := ConfigManager.ScaleCoordinate(
        ConfigManager.Get("Mana", "Radius", 139), true)
    g_mana_optimized := ConfigManager.Get("Mana", "OptimizedDetection", true)
    
    ; Tincture設定
    g_tincture_retry_max := ConfigManager.Get("Tincture", "RetryMax", 5)
    TIMING_MANA_DEPLETED_CD := ConfigManager.Get("Tincture", "DepletedCooldown", 5410)
    
    ; キー設定
    KEY_TINCTURE := ConfigManager.Get("Keys", "Tincture", "3")
    KEY_MANA_FLASK := ConfigManager.Get("Keys", "ManaFlask", "2")
    KEY_SKILL_E := ConfigManager.Get("Keys", "SkillE", "E")
    KEY_SKILL_R := ConfigManager.Get("Keys", "SkillR", "R")
    KEY_SKILL_T := ConfigManager.Get("Keys", "SkillT", "T")
    KEY_WINE_PROPHET := ConfigManager.Get("Keys", "WineProphet", "4")
    g_mana_flask_key := KEY_MANA_FLASK
    
    ; タイミング設定
    TIMING_SKILL_ER := {
        min: ConfigManager.Get("Timing", "SkillER_Min", 1000),
        max: ConfigManager.Get("Timing", "SkillER_Max", 1100)
    }
    TIMING_SKILL_T := {
        min: ConfigManager.Get("Timing", "SkillT_Min", 4100),
        max: ConfigManager.Get("Timing", "SkillT_Max", 4200)
    }
    TIMING_FLASK := {
        min: ConfigManager.Get("Timing", "Flask_Min", 4500),
        max: ConfigManager.Get("Timing", "Flask_Max", 4800)
    }
    
    ; ロード画面検出設定
    g_loading_check_enabled := ConfigManager.Get("LoadingScreen", "Enabled", true)
    
    LogInfo("Config", "Configuration applied from INI file")
}

; === 設定のリロード ===
ReloadConfiguration() {
    if (ConfigManager.Reload()) {
        ApplyConfigSettings()
        ShowOverlay("設定をリロードしました", 2000)
        LogInfo("Config", "Configuration reloaded")
        return true
    } else {
        ShowOverlay("設定のリロードに失敗しました", 2000)
        LogError("Config", "Failed to reload configuration")
        return false
    }
}