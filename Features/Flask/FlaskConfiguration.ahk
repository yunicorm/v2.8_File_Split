; ===================================================================
; フラスコ設定管理 - 設定読み込み・初期化・適用
; フラスコ設定の管理と動的設定変更を担当
; ===================================================================

; --- グローバル変数 ---
global g_flask_configs := Map()

; --- フラスコ設定の初期化（拡張版） ---
InitializeFlaskConfigs() {
    global g_flask_configs, KEY_MANA_FLASK
    
    ; マナフラスコ（デフォルト）
    g_flask_configs["mana"] := {
        key: KEY_MANA_FLASK,
        type: "mana",
        minInterval: TIMING_FLASK.min,
        maxInterval: TIMING_FLASK.max,
        enabled: true,
        priority: 1,
        charges: 0,
        maxCharges: 0,
        chargePerUse: 0,
        chargeGainRate: 0
    }
    
    ; 他のフラスコ設定のテンプレート（将来の拡張用）
    g_flask_configs["life"] := {
        key: "1",
        type: "life",
        minInterval: 5000,
        maxInterval: 5500,
        enabled: false,
        priority: 2,
        charges: 0,
        maxCharges: 0,
        chargePerUse: 0,
        chargeGainRate: 0,
        useCondition: () => CheckHealthPercentage() < 70
    }
    
    g_flask_configs["quicksilver"] := {
        key: "5",
        type: "quicksilver",
        minInterval: 6000,
        maxInterval: 6500,
        enabled: false,
        priority: 3,
        charges: 0,
        maxCharges: 0,
        chargePerUse: 0,
        chargeGainRate: 0,
        useCondition: () => IsMoving()
    }
    
    ; チャージトラッカーを初期化
    InitializeChargeTracker()
    
    LogDebug("FlaskManager", "Flask configurations initialized with extended settings")
}

; --- フラスコの包括設定 ---
ConfigureFlasks(flaskConfig) {
    global g_flask_configs, g_flask_charge_tracker
    
    ; 使用例：
    ; flaskConfig := Map(
    ;     "1", {
    ;         key: "1", 
    ;         type: "life", 
    ;         minInterval: 5000, 
    ;         maxInterval: 5500, 
    ;         enabled: true,
    ;         priority: 1,
    ;         maxCharges: 60,
    ;         chargePerUse: 20,
    ;         chargeGainRate: 6,
    ;         useCondition: () => GetHealthPercentage() < 70
    ;     },
    ;     "2", {
    ;         key: "2", 
    ;         type: "mana", 
    ;         minInterval: 4500, 
    ;         maxInterval: 4800, 
    ;         enabled: true,
    ;         priority: 2
    ;     },
    ;     "3", {
    ;         key: "3", 
    ;         type: "utility", 
    ;         minInterval: 5000, 
    ;         maxInterval: 5000, 
    ;         enabled: true,
    ;         priority: 3
    ;     },
    ;     "4", {
    ;         key: "4", 
    ;         type: "utility", 
    ;         minInterval: 8000, 
    ;         maxInterval: 8000, 
    ;         enabled: true,
    ;         priority: 4
    ;     },
    ;     "5", {
    ;         key: "5", 
    ;         type: "quicksilver", 
    ;         minInterval: 6000, 
    ;         maxInterval: 6500, 
    ;         enabled: true,
    ;         priority: 5,
    ;         useCondition: () => IsMoving()
    ;     }
    ; )
    
    try {
        ; 既存の自動化を停止
        wasActive := g_flask_timer_active
        if (wasActive) {
            StopFlaskAutomation()
        }
        
        ; 設定をクリア
        g_flask_configs.Clear()
        g_flask_charge_tracker.Clear()
        
        ; 新しい設定を適用
        for name, config in flaskConfig {
            ; デフォルト値を設定
            if (!config.HasOwnProp("priority")) {
                config.priority := 5
            }
            if (!config.HasOwnProp("maxCharges")) {
                config.maxCharges := 0
            }
            if (!config.HasOwnProp("chargePerUse")) {
                config.chargePerUse := 0
            }
            if (!config.HasOwnProp("chargeGainRate")) {
                config.chargeGainRate := 0
            }
            
            g_flask_configs[name] := config
            
            ; チャージトラッカーを初期化
            g_flask_charge_tracker[name] := {
                currentCharges: config.maxCharges,
                lastGainTime: A_TickCount,
                lastUseTime: 0
            }
        }
        
        ; 自動化を再開
        if (wasActive) {
            StartFlaskAutomation()
        }
        
        LogInfo("FlaskManager", Format("Flask configuration updated ({} flasks)", flaskConfig.Count))
        return true
        
    } catch as e {
        LogError("FlaskManager", "Failed to configure flasks: " . e.Message)
        return false
    }
}

; --- 特定フラスコの有効/無効切り替え ---
ToggleFlask(flaskName, enabled := "") {
    global g_flask_configs, g_flask_active_flasks
    
    if (Type(g_flask_configs) == "Map") {
        if (!g_flask_configs.Has(flaskName)) {
            return false
        }
    } else {
        LogError("FlaskConfiguration", "g_flask_configs is not a Map: " . Type(g_flask_configs))
        return false
    }
    
    if (enabled == "") {
        enabled := !g_flask_configs[flaskName].enabled
    }
    
    g_flask_configs[flaskName].enabled := enabled
    
    if (enabled) {
        if (g_flask_timer_active) {
            if (Type(g_flask_active_flasks) == "Map" && !g_flask_active_flasks.Has(flaskName)) {
                StartFlaskTimer(flaskName, g_flask_configs[flaskName])
            } else if (Type(g_flask_active_flasks) != "Map") {
                LogError("FlaskConfiguration", "g_flask_active_flasks is not a Map: " . Type(g_flask_active_flasks))
            }
        }
    } else {
        StopFlaskTimer(flaskName)
    }
    
    LogInfo("FlaskManager", Format("Flask '{}' {}", flaskName, enabled ? "enabled" : "disabled"))
    return true
}

; --- 個別フラスコ設定の更新 ---
UpdateFlaskConfig(flaskName, configUpdates) {
    global g_flask_configs
    
    if (Type(g_flask_configs) == "Map") {
        if (!g_flask_configs.Has(flaskName)) {
            LogWarn("FlaskConfiguration", Format("Flask '{}' not found for update", flaskName))
            return false
        }
    } else {
        LogError("FlaskConfiguration", "g_flask_configs is not a Map: " . Type(g_flask_configs))
        return false
    }
    
    try {
        config := g_flask_configs[flaskName]
        
        ; 設定を更新
        for key, value in configUpdates {
            config[key] := value
        }
        
        ; 有効フラスコの場合はタイマーを再開
        if (config.enabled && g_flask_timer_active) {
            StopFlaskTimer(flaskName)
            Sleep(50)
            StartFlaskTimer(flaskName, config)
        }
        
        LogInfo("FlaskConfiguration", Format("Flask '{}' configuration updated", flaskName))
        return true
        
    } catch as e {
        LogError("FlaskConfiguration", Format("Failed to update flask '{}': {}", flaskName, e.Message))
        return false
    }
}

; --- 設定ファイルからフラスコ設定を読み込み ---
LoadFlaskConfigFromINI() {
    global g_flask_configs
    
    try {
        ; 5つのフラスコスロットを読み込み
        for flaskNum in [1, 2, 3, 4, 5] {
            enabled := ConfigManager.Get("Flask", Format("Flask{}_Enabled", flaskNum), false)
            key := ConfigManager.Get("Flask", Format("Flask{}_Key", flaskNum), flaskNum)
            
            ; Wine/Tincture競合チェック
            conflictCheck := CheckFlaskKeyConflict(key, flaskNum)
            
            LogDebug("FlaskConfiguration", Format("Flask{}: enabled={}, key={}, conflict={}", 
                flaskNum, enabled, key, conflictCheck.hasConflict))
            
            if (enabled && !conflictCheck.hasConflict) {
                flaskConfig := {
                    key: key,
                    type: ConfigManager.Get("Flask", Format("Flask{}_Type", flaskNum), "utility"),
                    minInterval: ConfigManager.Get("Flask", Format("Flask{}_Min", flaskNum), 5000),
                    maxInterval: ConfigManager.Get("Flask", Format("Flask{}_Max", flaskNum), 5500),
                    enabled: enabled,
                    priority: ConfigManager.Get("Flask", Format("Flask{}_Priority", flaskNum), flaskNum),
                    maxCharges: ConfigManager.Get("Flask", Format("Flask{}_MaxCharges", flaskNum), 0),
                    chargePerUse: ConfigManager.Get("Flask", Format("Flask{}_ChargePerUse", flaskNum), 0),
                    chargeGainRate: ConfigManager.Get("Flask", Format("Flask{}_ChargeGainRate", flaskNum), 0)
                }
                
                ; 条件設定（タイプ別）
                switch flaskConfig.type {
                    case "life":
                        threshold := ConfigManager.Get("Flask", Format("Flask{}_HealthThreshold", flaskNum), 70)
                        flaskConfig.useCondition := () => IsLowHealth(threshold)
                    case "mana":
                        threshold := ConfigManager.Get("Flask", Format("Flask{}_ManaThreshold", flaskNum), 50)
                        flaskConfig.useCondition := () => IsLowMana(threshold)
                    case "quicksilver":
                        flaskConfig.useCondition := () => ShouldUseQuicksilver()
                    case "utility":
                        ; ユーティリティは条件なし（常時使用）
                }
                
                g_flask_configs[Format("flask{}", flaskNum)] := flaskConfig
                LogDebug("FlaskConfiguration", Format("Flask{} loaded: key={}, type={}, min={}ms, max={}ms",
                    flaskNum, flaskConfig.key, flaskConfig.type, flaskConfig.minInterval, flaskConfig.maxInterval))
            } else if (enabled && conflictCheck.hasConflict) {
                LogWarn("FlaskConfiguration", Format("Flask{} disabled due to conflict: {} (key={})",
                    flaskNum, conflictCheck.reason, key))
            }
        }
        
        LogInfo("FlaskConfiguration", Format("Loaded {} flask configurations from INI", g_flask_configs.Count))
        return true
        
    } catch as e {
        LogError("FlaskConfiguration", "Failed to load flask config from INI: " . e.Message)
        return false
    }
}

; --- フラスコ設定の検証 ---
ValidateFlaskConfig(config) {
    requiredFields := ["key", "type", "minInterval", "maxInterval", "enabled"]
    
    for field in requiredFields {
        if (!config.HasOwnProp(field)) {
            LogError("FlaskConfiguration", Format("Missing required field: {}", field))
            return false
        }
    }
    
    ; 間隔の妥当性チェック
    if (config.minInterval < 100 || config.maxInterval < config.minInterval) {
        LogError("FlaskConfiguration", "Invalid interval configuration")
        return false
    }
    
    ; チャージ設定の整合性チェック
    if (config.HasOwnProp("maxCharges") && config.maxCharges > 0) {
        if (!config.HasOwnProp("chargePerUse") || config.chargePerUse <= 0) {
            LogWarn("FlaskConfiguration", "Flask has maxCharges but no chargePerUse")
        }
    }
    
    return true
}

; --- フラスコ設定のプリセット ---
GetFlaskPresets() {
    return {
        ; 基本的なライフ＋マナ構成
        basic: Map(
            "life", {
                key: "1",
                type: "life",
                minInterval: 4000,
                maxInterval: 4500,
                enabled: true,
                priority: 1,
                useCondition: () => IsLowHealth(75)
            },
            "mana", {
                key: "2",
                type: "mana",
                minInterval: 3500,
                maxInterval: 4000,
                enabled: true,
                priority: 2,
                useCondition: () => IsLowMana(50)
            }
        ),
        
        ; 完全自動構成（5フラスコ）
        full_auto: Map(
            "life", {
                key: "1",
                type: "life",
                minInterval: 5000,
                maxInterval: 5500,
                enabled: true,
                priority: 1,
                useCondition: () => IsLowHealth(70)
            },
            "mana", {
                key: "2",
                type: "mana",
                minInterval: 4500,
                maxInterval: 5000,
                enabled: true,
                priority: 2,
                useCondition: () => IsLowMana(60)
            },
            "utility1", {
                key: "3",
                type: "utility",
                minInterval: 6000,
                maxInterval: 6000,
                enabled: true,
                priority: 3
            },
            "utility2", {
                key: "4",
                type: "utility",
                minInterval: 8000,
                maxInterval: 8000,
                enabled: true,
                priority: 4
            },
            "quicksilver", {
                key: "5",
                type: "quicksilver",
                minInterval: 6000,
                maxInterval: 6500,
                enabled: true,
                priority: 5,
                useCondition: () => ShouldUseQuicksilver()
            }
        ),
        
        ; 戦闘重視構成
        combat: Map(
            "life", {
                key: "1",
                type: "life",
                minInterval: 3000,
                maxInterval: 3500,
                enabled: true,
                priority: 1,
                useCondition: () => IsLowHealth(80)
            },
            "defensive", {
                key: "2",
                type: "utility",
                minInterval: 4000,
                maxInterval: 4000,
                enabled: true,
                priority: 2,
                useCondition: () => ShouldUseDefensiveFlask()
            },
            "offensive", {
                key: "3",
                type: "utility",
                minInterval: 5000,
                maxInterval: 5000,
                enabled: true,
                priority: 3,
                useCondition: () => ShouldUseOffensiveFlask()
            }
        )
    }
}

; --- プリセット設定の適用 ---
ApplyFlaskPreset(presetName) {
    presets := GetFlaskPresets()
    
    if (!presets.HasOwnProp(presetName)) {
        LogError("FlaskConfiguration", Format("Unknown preset: {}", presetName))
        return false
    }
    
    try {
        ConfigureFlasks(presets[presetName])
        LogInfo("FlaskConfiguration", Format("Applied flask preset: {}", presetName))
        return true
    } catch as e {
        LogError("FlaskConfiguration", Format("Failed to apply preset '{}': {}", presetName, e.Message))
        return false
    }
}

; --- フラスコ設定のエクスポート ---
ExportFlaskConfig() {
    global g_flask_configs
    
    exportData := Map()
    for flaskName, config in g_flask_configs {
        ; 関数プロパティを除外してエクスポート
        exportConfig := {}
        for key, value in config {
            if (key != "useCondition") {
                exportConfig[key] := value
            }
        }
        exportData[flaskName] := exportConfig
    }
    
    return exportData
}

; --- フラスコ設定のリセット ---
ResetFlaskConfigs() {
    global g_flask_configs, g_flask_charge_tracker
    
    try {
        ; 自動化を停止
        wasActive := g_flask_timer_active
        if (wasActive) {
            StopFlaskAutomation()
        }
        
        ; 設定をクリア
        g_flask_configs.Clear()
        g_flask_charge_tracker.Clear()
        
        ; デフォルト設定を再初期化
        InitializeFlaskConfigs()
        
        LogInfo("FlaskConfiguration", "Flask configurations reset to defaults")
        return true
        
    } catch as e {
        LogError("FlaskConfiguration", "Failed to reset flask configs: " . e.Message)
        return false
    }
}

; --- Wine/Tincture競合チェック ---
CheckFlaskKeyConflict(key, flaskNum) {
    global KEY_TINCTURE, KEY_WINE_PROPHET
    
    ; TinctureとWine of the Prophetのキーを取得
    tinctureKey := ConfigManager.Get("Keys", "Tincture", "3")
    wineKey := ConfigManager.Get("Keys", "WineProphet", "4")
    
    ; 競合チェック
    if (key == tinctureKey) {
        return {
            hasConflict: true,
            reason: "Conflicts with Tincture system",
            conflictType: "Tincture"
        }
    }
    
    if (key == wineKey) {
        return {
            hasConflict: true,
            reason: "Conflicts with Wine of the Prophet system", 
            conflictType: "Wine"
        }
    }
    
    return {
        hasConflict: false,
        reason: "",
        conflictType: ""
    }
}