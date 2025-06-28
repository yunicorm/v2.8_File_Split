; ===================================================================
; フラスコチャージマネージャー - チャージ管理・計算
; フラスコのチャージ追跡、獲得、消費の管理を担当
; ===================================================================

; --- グローバル変数 ---
global g_flask_charge_tracker := Map()

; --- チャージトラッカーの初期化 ---
InitializeChargeTracker() {
    global g_flask_charge_tracker
    
    for flaskName, config in g_flask_configs {
        g_flask_charge_tracker[flaskName] := {
            currentCharges: config.maxCharges,
            lastGainTime: A_TickCount,
            lastUseTime: 0
        }
    }
    
    LogDebug("FlaskChargeManager", "Charge tracker initialized for all flasks")
}

; --- フラスコチャージの更新 ---
UpdateFlaskCharges() {
    global g_flask_charge_tracker, g_flask_configs, g_macro_active
    
    if (!g_macro_active) {
        return
    }
    
    currentTime := A_TickCount
    
    for flaskName, config in g_flask_configs {
        if (config.chargeGainRate > 0 && config.maxCharges > 0) {
            chargeInfo := g_flask_charge_tracker[flaskName]
            
            ; 最後の獲得からの経過時間
            timeSinceGain := currentTime - chargeInfo.lastGainTime
            
            ; チャージ獲得計算
            chargesGained := (timeSinceGain / 1000) * config.chargeGainRate
            
            if (chargesGained >= 1) {
                chargeInfo.currentCharges := Min(
                    chargeInfo.currentCharges + Floor(chargesGained),
                    config.maxCharges
                )
                chargeInfo.lastGainTime := currentTime
                
                LogDebug("FlaskChargeManager", Format("Flask '{}' gained {} charges ({}/{})", 
                    flaskName, Floor(chargesGained), 
                    chargeInfo.currentCharges, config.maxCharges))
            }
        }
    }
}

; --- 特定フラスコのチャージ獲得 ---
GainFlaskCharges(flaskName, amount) {
    global g_flask_charge_tracker, g_flask_configs
    
    if (!g_flask_charge_tracker.Has(flaskName) || !g_flask_configs.Has(flaskName)) {
        return false
    }
    
    chargeInfo := g_flask_charge_tracker[flaskName]
    config := g_flask_configs[flaskName]
    
    oldCharges := chargeInfo.currentCharges
    chargeInfo.currentCharges := Min(chargeInfo.currentCharges + amount, config.maxCharges)
    actualGain := chargeInfo.currentCharges - oldCharges
    
    if (actualGain > 0) {
        chargeInfo.lastGainTime := A_TickCount
        LogDebug("FlaskChargeManager", Format("Flask '{}' manually gained {} charges ({}/{})", 
            flaskName, actualGain, chargeInfo.currentCharges, config.maxCharges))
        return true
    }
    
    return false
}

; --- 特定フラスコのチャージ消費 ---
ConsumeFlaskCharges(flaskName, amount) {
    global g_flask_charge_tracker
    
    if (!g_flask_charge_tracker.Has(flaskName)) {
        return false
    }
    
    chargeInfo := g_flask_charge_tracker[flaskName]
    
    if (chargeInfo.currentCharges >= amount) {
        chargeInfo.currentCharges -= amount
        chargeInfo.lastUseTime := A_TickCount
        
        LogDebug("FlaskChargeManager", Format("Flask '{}' consumed {} charges ({} remaining)", 
            flaskName, amount, chargeInfo.currentCharges))
        return true
    }
    
    LogWarn("FlaskChargeManager", Format("Flask '{}' insufficient charges for consumption: {} needed, {} available", 
        flaskName, amount, chargeInfo.currentCharges))
    return false
}

; --- フラスコチャージの検証 ---
ValidateFlaskCharges(flaskName, requiredCharges) {
    global g_flask_charge_tracker
    
    if (!g_flask_charge_tracker.Has(flaskName)) {
        return false
    }
    
    chargeInfo := g_flask_charge_tracker[flaskName]
    return chargeInfo.currentCharges >= requiredCharges
}

; --- フラスコチャージ情報の取得 ---
GetFlaskCharges(flaskName) {
    global g_flask_charge_tracker, g_flask_configs
    
    if (!g_flask_charge_tracker.Has(flaskName) || !g_flask_configs.Has(flaskName)) {
        return {
            currentCharges: 0,
            maxCharges: 0,
            chargePercentage: 0,
            lastGainTime: 0,
            lastUseTime: 0
        }
    }
    
    chargeInfo := g_flask_charge_tracker[flaskName]
    config := g_flask_configs[flaskName]
    
    chargePercentage := config.maxCharges > 0 ? 
        Round((chargeInfo.currentCharges / config.maxCharges) * 100, 1) : 0
    
    return {
        currentCharges: chargeInfo.currentCharges,
        maxCharges: config.maxCharges,
        chargePercentage: chargePercentage,
        chargeGainRate: config.chargeGainRate,
        chargePerUse: config.chargePerUse,
        lastGainTime: chargeInfo.lastGainTime,
        lastUseTime: chargeInfo.lastUseTime,
        timeSinceLastGain: A_TickCount - chargeInfo.lastGainTime,
        timeSinceLastUse: chargeInfo.lastUseTime > 0 ? A_TickCount - chargeInfo.lastUseTime : 0
    }
}

; --- 全フラスコのチャージ情報取得 ---
GetAllFlaskCharges() {
    global g_flask_charge_tracker
    
    chargeInfos := Map()
    
    for flaskName in g_flask_charge_tracker {
        chargeInfos[flaskName] := GetFlaskCharges(flaskName)
    }
    
    return chargeInfos
}

; --- フラスコチャージのリセット ---
ResetFlaskCharges(flaskName := "") {
    global g_flask_charge_tracker, g_flask_configs
    
    if (flaskName == "") {
        ; 全フラスコのチャージをリセット
        for flaskName, config in g_flask_configs {
            if (g_flask_charge_tracker.Has(flaskName)) {
                chargeInfo := g_flask_charge_tracker[flaskName]
                chargeInfo.currentCharges := config.maxCharges
                chargeInfo.lastGainTime := A_TickCount
                chargeInfo.lastUseTime := 0
            }
        }
        LogInfo("FlaskChargeManager", "All flask charges reset to maximum")
    } else {
        ; 特定フラスコのチャージをリセット
        if (g_flask_charge_tracker.Has(flaskName) && g_flask_configs.Has(flaskName)) {
            chargeInfo := g_flask_charge_tracker[flaskName]
            config := g_flask_configs[flaskName]
            chargeInfo.currentCharges := config.maxCharges
            chargeInfo.lastGainTime := A_TickCount
            chargeInfo.lastUseTime := 0
            
            LogInfo("FlaskChargeManager", Format("Flask '{}' charges reset to maximum ({})", 
                flaskName, config.maxCharges))
        }
    }
}

; --- チャージ回復速度の計算 ---
CalculateChargeRecoveryTime(flaskName, targetCharges) {
    global g_flask_configs
    
    if (!g_flask_configs.Has(flaskName)) {
        return -1
    }
    
    config := g_flask_configs[flaskName]
    if (config.chargeGainRate <= 0) {
        return -1  ; チャージ回復なし
    }
    
    chargeInfo := GetFlaskCharges(flaskName)
    chargesToGain := targetCharges - chargeInfo.currentCharges
    
    if (chargesToGain <= 0) {
        return 0  ; 既に目標に達している
    }
    
    recoveryTimeMs := (chargesToGain / config.chargeGainRate) * 1000
    return Round(recoveryTimeMs)
}

; --- チャージ効率の統計 ---
GetChargeEfficiencyStats(flaskName) {
    global g_flask_configs
    
    if (!g_flask_configs.Has(flaskName)) {
        return {}
    }
    
    chargeInfo := GetFlaskCharges(flaskName)
    config := g_flask_configs[flaskName]
    
    ; 効率計算
    chargeUtilization := chargeInfo.maxCharges > 0 ? 
        (chargeInfo.currentCharges / chargeInfo.maxCharges) : 0
    
    ; 回復速度評価
    recoveryRating := config.chargeGainRate > 0 ? "Fast" : "None"
    if (config.chargeGainRate > 0 && config.chargeGainRate < 0.5) {
        recoveryRating := "Slow"
    } else if (config.chargeGainRate >= 0.5 && config.chargeGainRate < 1.0) {
        recoveryRating := "Medium"
    }
    
    return {
        chargeUtilization: Round(chargeUtilization * 100, 1),
        recoveryRating: recoveryRating,
        recoveryRate: config.chargeGainRate,
        consumptionRate: config.chargePerUse,
        sustainabilityRatio: config.chargeGainRate > 0 ? 
            Round(config.chargeGainRate / config.chargePerUse, 2) : 0,
        timeToFullRecharge: CalculateChargeRecoveryTime(flaskName, config.maxCharges)
    }
}

; --- チャージトラッカーのクリーンアップ ---
CleanupChargeTracker() {
    global g_flask_charge_tracker
    
    ; 未使用のエントリを削除
    toDelete := []
    for flaskName in g_flask_charge_tracker {
        if (!g_flask_configs.Has(flaskName)) {
            toDelete.Push(flaskName)
        }
    }
    
    for flaskName in toDelete {
        g_flask_charge_tracker.Delete(flaskName)
        LogDebug("FlaskChargeManager", Format("Removed obsolete charge tracker for '{}'", flaskName))
    }
}