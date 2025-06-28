; ===================================================================
; 設定検証専用モジュール
; 全設定の入力値検証とエラーチェック
; ===================================================================


; --- 全設定の検証統括 ---
ValidateAllSettings() {
    errors := []
    
    try {
        ; 各種設定の検証を実行
        ValidateSkillSettings(errors)
        ValidateFlaskSettings(errors)
        ValidateTinctureSettings(errors)
        ValidateGeneralSettings(errors)
        
        LogDebug("SettingsValidation", Format("Validation completed with {} errors", errors.Length))
        
    } catch Error as e {
        LogError("SettingsValidation", "Validation error: " . e.Message)
        errors.Push("検証中にエラーが発生しました: " . e.Message)
    }
    
    return errors
}

; --- スキル設定の検証 ---
ValidateSkillSettings(errors) {
    global g_settings_gui
    
    ; スキル設定の検証
    skillGroups := ["1_1", "1_2", "1_3", "1_4", "1_5", "2_1", "2_2", "2_3", "2_4", "2_5"]
    
    for skillId in skillGroups {
        controlName := "Skill_" . skillId
        
        ; 有効な場合のみ検証
        if (g_settings_gui[controlName . "_Enabled"].Checked) {
            ; キーの検証（空でないこと）
            key := Trim(g_settings_gui[controlName . "_Key"].Text)
            if (key = "") {
                errors.Push("スキル " . skillId . ": キーが空です")
            }
            
            ; 間隔の検証（数値のみ、正の値）
            minInterval := Trim(g_settings_gui[controlName . "_Min"].Text)
            maxInterval := Trim(g_settings_gui[controlName . "_Max"].Text)
            
            if (!IsValidInteger(minInterval) || Integer(minInterval) <= 0) {
                errors.Push("スキル " . skillId . ": 最小間隔は正の整数である必要があります")
            }
            
            if (!IsValidInteger(maxInterval) || Integer(maxInterval) <= 0) {
                errors.Push("スキル " . skillId . ": 最大間隔は正の整数である必要があります")
            }
            
            ; Min <= Max の検証
            if (IsValidInteger(minInterval) && IsValidInteger(maxInterval)) {
                if (Integer(minInterval) > Integer(maxInterval)) {
                    errors.Push("スキル " . skillId . ": 最小間隔は最大間隔以下である必要があります")
                }
            }
            
            ; 優先度の検証（1-5の範囲）
            priority := g_settings_gui[controlName . "_Priority"].Value
            if (priority < 1 || priority > 5) {
                errors.Push("スキル " . skillId . ": 優先度は1-5の範囲である必要があります")
            }
        }
    }
}

; --- フラスコ設定の検証 ---
ValidateFlaskSettings(errors) {
    global g_settings_gui
    
    Loop 5 {
        flaskNum := A_Index
        if (g_settings_gui["Flask" . flaskNum . "_Enabled"].Checked) {
            key := Trim(g_settings_gui["Flask" . flaskNum . "_Key"].Text)
            if (key = "") {
                errors.Push("フラスコ " . flaskNum . ": キーが空です")
            }
            
            minVal := Trim(g_settings_gui["Flask" . flaskNum . "_Min"].Text)
            maxVal := Trim(g_settings_gui["Flask" . flaskNum . "_Max"].Text)
            
            if (!IsValidInteger(minVal) || Integer(minVal) <= 0) {
                errors.Push("フラスコ " . flaskNum . ": 最小間隔は正の整数である必要があります")
            }
            
            if (!IsValidInteger(maxVal) || Integer(maxVal) <= 0) {
                errors.Push("フラスコ " . flaskNum . ": 最大間隔は正の整数である必要があります")
            }
            
            if (IsValidInteger(minVal) && IsValidInteger(maxVal) && Integer(minVal) > Integer(maxVal)) {
                errors.Push("フラスコ " . flaskNum . ": 最小間隔は最大間隔以下である必要があります")
            }
        }
    }
}

; --- Tincture設定の検証 ---
ValidateTinctureSettings(errors) {
    global g_settings_gui
    
    if (g_settings_gui["TinctureEnabled"].Checked) {
        key := Trim(g_settings_gui["TinctureKey"].Text)
        if (key = "") {
            errors.Push("Tincture: キーが空です")
        }
        
        ; 数値設定の検証
        retryMax := Trim(g_settings_gui["Tincture_RetryMax"].Text)
        retryInterval := Trim(g_settings_gui["Tincture_RetryInterval"].Text)
        verifyDelay := Trim(g_settings_gui["Tincture_VerifyDelay"].Text)
        depletedCooldown := Trim(g_settings_gui["Tincture_DepletedCooldown"].Text)
        
        if (!IsValidInteger(retryMax) || Integer(retryMax) < 0) {
            errors.Push("Tincture: リトライ最大回数は0以上の整数である必要があります")
        }
        
        if (!IsValidInteger(retryInterval) || Integer(retryInterval) < 0) {
            errors.Push("Tincture: リトライ間隔は0以上の整数である必要があります")
        }
        
        if (!IsValidInteger(verifyDelay) || Integer(verifyDelay) < 0) {
            errors.Push("Tincture: 検証遅延は0以上の整数である必要があります")
        }
        
        if (!IsValidInteger(depletedCooldown) || Integer(depletedCooldown) < 0) {
            errors.Push("Tincture: 枯渇クールダウンは0以上の整数である必要があります")
        }
    }
}

; --- 一般設定の検証 ---
ValidateGeneralSettings(errors) {
    global g_settings_gui
    
    ; 解像度設定の検証
    screenWidth := Trim(g_settings_gui["ScreenWidth"].Text)
    screenHeight := Trim(g_settings_gui["ScreenHeight"].Text)
    
    if (!IsValidInteger(screenWidth) || Integer(screenWidth) <= 0) {
        errors.Push("画面幅は正の整数である必要があります")
    }
    
    if (!IsValidInteger(screenHeight) || Integer(screenHeight) <= 0) {
        errors.Push("画面高さは正の整数である必要があります")
    }
    
    ; マナ設定の検証
    centerX := Trim(g_settings_gui["Mana_CenterX"].Text)
    centerY := Trim(g_settings_gui["Mana_CenterY"].Text)
    radius := Trim(g_settings_gui["Mana_Radius"].Text)
    blueThreshold := Trim(g_settings_gui["Mana_BlueThreshold"].Text)
    blueDominance := Trim(g_settings_gui["Mana_BlueDominance"].Text)
    monitorInterval := Trim(g_settings_gui["Mana_MonitorInterval"].Text)
    
    if (!IsValidInteger(centerX) || Integer(centerX) < 0) {
        errors.Push("マナ中心X座標は0以上の整数である必要があります")
    }
    
    if (!IsValidInteger(centerY) || Integer(centerY) < 0) {
        errors.Push("マナ中心Y座標は0以上の整数である必要があります")
    }
    
    if (!IsValidInteger(radius) || Integer(radius) <= 0) {
        errors.Push("マナ検出半径は正の整数である必要があります")
    }
    
    if (!IsValidInteger(blueThreshold) || Integer(blueThreshold) < 0 || Integer(blueThreshold) > 255) {
        errors.Push("マナ青閾値は0-255の範囲である必要があります")
    }
    
    if (!IsValidInteger(blueDominance) || Integer(blueDominance) < 0) {
        errors.Push("マナ青色優位性は0以上の整数である必要があります")
    }
    
    if (!IsValidInteger(monitorInterval) || Integer(monitorInterval) <= 0) {
        errors.Push("マナ監視間隔は正の整数である必要があります")
    }
    
    ; エリア検出設定の検証
    clientLogPath := Trim(g_settings_gui["ClientLog_Path"].Text)
    clientLogInterval := Trim(g_settings_gui["ClientLog_CheckInterval"].Text)
    
    if (g_settings_gui["ClientLog_Enabled"].Checked && clientLogPath == "") {
        errors.Push("ログ監視が有効な場合、Client.txtパスを指定する必要があります")
    }
    
    if (!IsValidInteger(clientLogInterval) || Integer(clientLogInterval) <= 0) {
        errors.Push("ログチェック間隔は正の整数である必要があります")
    }
    
    ; パフォーマンス設定の検証
    colorTimeout := Trim(g_settings_gui["ColorDetectTimeout"].Text)
    sampleRate := Trim(g_settings_gui["ManaSampleRate"].Text)
    
    if (!IsValidInteger(colorTimeout) || Integer(colorTimeout) <= 0) {
        errors.Push("色検出タイムアウトは正の整数である必要があります")
    }
    
    if (!IsValidInteger(sampleRate) || Integer(sampleRate) < 1 || Integer(sampleRate) > 10) {
        errors.Push("マナサンプルレートは1-10の範囲である必要があります")
    }
    
    ; UI設定の検証
    transparency := Trim(g_settings_gui["OverlayTransparency"].Text)
    fontSize := Trim(g_settings_gui["OverlayFontSize"].Text)
    
    if (!IsValidInteger(transparency) || Integer(transparency) < 0 || Integer(transparency) > 255) {
        errors.Push("オーバーレイ透明度は0-255の範囲である必要があります")
    }
    
    if (!IsValidInteger(fontSize) || Integer(fontSize) <= 0) {
        errors.Push("フォントサイズは正の整数である必要があります")
    }
    
    ; その他の数値設定
    maxLogSize := Trim(g_settings_gui["MaxLogSize"].Text)
    logRetentionDays := Trim(g_settings_gui["LogRetentionDays"].Text)
    autoStartDelay := Trim(g_settings_gui["AutoStartDelay"].Text)
    wineInterval := Trim(g_settings_gui["Wine_Interval"].Text)
    
    if (!IsValidInteger(maxLogSize) || Integer(maxLogSize) <= 0) {
        errors.Push("最大ログサイズは正の整数である必要があります")
    }
    
    if (!IsValidInteger(logRetentionDays) || Integer(logRetentionDays) <= 0) {
        errors.Push("ログ保持日数は正の整数である必要があります")
    }
    
    if (!IsValidInteger(autoStartDelay) || Integer(autoStartDelay) < 0) {
        errors.Push("自動開始遅延は0以上の整数である必要があります")
    }
    
    if (!IsValidInteger(wineInterval) || Integer(wineInterval) <= 0) {
        errors.Push("Wine段階間隔は正の整数である必要があります")
    }
}

