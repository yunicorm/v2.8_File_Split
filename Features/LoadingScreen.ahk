; ===================================================================
; ロード画面検出システム（エラーハンドリング強化版）
; エリア遷移時のマクロ自動制御とユーザー入力待機
; ===================================================================

; --- ロード画面検出の開始 ---
StartLoadingScreenDetection() {
    global g_loading_check_enabled
    
    if (g_loading_check_enabled) {
        interval := ConfigManager.Get("LoadingScreen", "CheckInterval", 250)
        StartManagedTimer("LoadingScreen", CheckLoadingScreenGGG, interval)
        LogInfo("LoadingScreen", "Loading screen detection started")
    }
}

; --- 改良版ロード画面検出（GGGロゴの歯車検出） ---
CheckLoadingScreenGGG() {
    global g_loading_screen_active, g_macro_active, g_was_macro_active_before_loading, g_waiting_for_user_input
    
    try {
        ; Path of Exileのロード画面の特徴：
        ; 1. 画面下部の歯車（GGGロゴ）エリア
        ; 2. エリア名表示部分
        ; 3. 中央のイラスト部分は暗めの色調
        
        ; 歯車エリアの座標（画面下部中央）
        screenHeight := ConfigManager.Get("Resolution", "ScreenHeight", 1440)
        screenWidth := ConfigManager.Get("Resolution", "ScreenWidth", 3440)
        gearAreaOffset := ConfigManager.Get("LoadingScreen", "GearAreaOffset", 200)
        
        gearAreaY := screenHeight - gearAreaOffset
        gearAreaX := screenWidth / 2
        
        ; 複数のポイントをチェック
        checkPoints := [
            {x: gearAreaX - 100, y: gearAreaY, name: "Left Gear"},
            {x: gearAreaX, y: gearAreaY, name: "Center"},
            {x: gearAreaX + 100, y: gearAreaY, name: "Right Gear"},
            {x: gearAreaX, y: gearAreaY - 50, name: "Area Name"},
            {x: gearAreaX, y: gearAreaY + 50, name: "Below Gear"}
        ]
        
        ; 金色/茶色系の色をカウント（GGGロゴの典型的な色）
        goldBrownCount := 0
        darkCount := 0
        darkThreshold := ConfigManager.Get("LoadingScreen", "DarkThreshold", 50)
        
        for point in checkPoints {
            try {
                color := SafePixelGetColor(point.x, point.y)
                
                ; 金色/茶色系の判定
                if (IsGoldBrownColor(color)) {
                    goldBrownCount++
                }
                
                ; 暗い色の判定
                if (IsDarkColor(color, darkThreshold)) {
                    darkCount++
                }
            } catch as e {
                LogDebug("LoadingScreen", Format("Failed to check point {}: {}", 
                    point.name, e.Message))
                darkCount++  ; エラー時は暗いとみなす
            }
        }
        
        ; UI要素が非表示かチェック（従来の方法も併用）
        uiHidden := !CheckUIElementsVisible()
        
        ; ロード画面の判定
        isLoading := (goldBrownCount >= 2 || (darkCount >= 4 && uiHidden))
        
        ; 状態変化の処理
        if (isLoading && !g_loading_screen_active) {
            HandleLoadingScreenEnter()
        } else if (!isLoading && g_loading_screen_active) {
            HandleLoadingScreenExit()
        }
        
    } catch as e {
        LogError("LoadingScreen", "Detection cycle failed: " . e.Message)
    }
}

; --- ロード画面開始時の処理 ---
HandleLoadingScreenEnter() {
    global g_loading_screen_active, g_macro_active, g_was_macro_active_before_loading, g_waiting_for_user_input
    
    g_loading_screen_active := true
    g_was_macro_active_before_loading := g_macro_active
    g_waiting_for_user_input := false
    
    if (g_macro_active) {
        ShowOverlay("ロード画面検出 - マクロ一時停止", 2000)
        try {
            ToggleMacro()  ; マクロをオフにする
            LogInfo("LoadingScreen", "Loading screen detected - macro paused")
        } catch as e {
            LogError("LoadingScreen", "Failed to pause macro: " . e.Message)
        }
    }
}

; --- ロード画面終了時の処理 ---
HandleLoadingScreenExit() {
    global g_loading_screen_active, g_was_macro_active_before_loading, g_waiting_for_user_input
    
    g_loading_screen_active := false
    
    if (g_was_macro_active_before_loading) {
        ; ユーザー入力待機モードに入る
        g_waiting_for_user_input := true
        ShowOverlay("ゲーム画面復帰 - クリックまたはキー入力でマクロ開始", 3000)
        
        ; 入力待機を開始
        StartManagedTimer("UserInput", WaitForUserInput, 50)
        LogInfo("LoadingScreen", "Game screen restored - waiting for user input")
    }
}

; --- UI要素の表示状態チェック ---
CheckUIElementsVisible() {
    global g_mana_center_x, g_mana_center_y
    
    try {
        ; マナオーブとヘルスオーブの位置で明度をチェック
        manaColor := SafePixelGetColor(g_mana_center_x, g_mana_center_y)
        
        ; ヘルスオーブの座標（設定から計算）
        screenWidth := ConfigManager.Get("Resolution", "ScreenWidth", 3440)
        screenHeight := ConfigManager.Get("Resolution", "ScreenHeight", 1440)
        healthX := ConfigManager.ScaleCoordinate(286 + 139, true)
        healthY := ConfigManager.ScaleCoordinate(1161 + 139, false)
        
        healthColor := SafePixelGetColor(healthX, healthY)
        
        manaB := GetColorBrightness(manaColor)
        healthB := GetColorBrightness(healthColor)
        
        ; どちらかのオーブが見える明度なら、UIは表示されている
        return (manaB > 30 || healthB > 30)
        
    } catch as e {
        LogError("LoadingScreen", "UI visibility check failed: " . e.Message)
        return false  ; エラー時はUIが見えないとみなす
    }
}

; --- ユーザー入力待機 ---
WaitForUserInput() {
    global g_waiting_for_user_input, g_macro_active
    
    if (!g_waiting_for_user_input) {
        StopManagedTimer("UserInput")
        return
    }
    
    ; ウィンドウがアクティブでない場合はスキップ
    if (!IsTargetWindowActive()) {
        return
    }
    
    try {
        ; 移動キー（WASD、矢印キー）やマウスクリックをチェック
        movementKeys := ["W", "A", "S", "D", "Up", "Down", "Left", "Right", 
                         "LButton", "RButton", "MButton", "Q", "E", "R", "T"]
        
        for key in movementKeys {
            if (GetKeyState(key, "P")) {
                HandleUserInput("Key: " . key)
                return
            }
        }
        
        ; スキル使用（1-5キー）もチェック
        Loop 5 {
            if (GetKeyState(A_Index, "P")) {
                HandleUserInput("Flask: " . A_Index)
                return
            }
        }
    } catch as e {
        LogError("LoadingScreen", "Input detection failed: " . e.Message)
    }
}

; --- ユーザー入力検出時の処理 ---
HandleUserInput(inputType) {
    global g_waiting_for_user_input
    
    g_waiting_for_user_input := false
    StopManagedTimer("UserInput")
    
    LogInfo("LoadingScreen", "User input detected: " . inputType)
    
    ; 少し待ってからマクロを開始（誤動作防止）
    SetTimer(() => StartMacroAfterInput(), -300)
}

; --- 入力検出後のマクロ開始 ---
StartMacroAfterInput() {
    global g_macro_active, g_was_macro_active_before_loading
    
    if (!g_macro_active && g_was_macro_active_before_loading && IsTargetWindowActive()) {
        try {
            ShowOverlay("ユーザー入力検出 - マクロ開始", 2000)
            ToggleMacro()
            g_was_macro_active_before_loading := false
            LogInfo("LoadingScreen", "Macro restarted after user input")
        } catch as e {
            LogError("LoadingScreen", "Failed to restart macro: " . e.Message)
            ShowOverlay("マクロ開始エラー", 2000)
        }
    }
}

; --- ロード画面検出の停止 ---
StopLoadingScreenDetection() {
    StopManagedTimer("LoadingScreen")
    StopManagedTimer("UserInput")
    LogInfo("LoadingScreen", "Loading screen detection stopped")
}