; ===================================================================
; ホットキー検証システム
; ホットキーの重複チェックと競合検出
; ===================================================================

class HotkeyValidator {
    static hotkeys := Map()
    static conflicts := []
    
    ; --- ホットキーを登録 ---
    static Register(key, function, description := "") {
        ; キーを正規化
        normalizedKey := this.NormalizeKey(key)
        
        if (this.hotkeys.Has(normalizedKey)) {
            ; 重複を検出
            conflict := {
                key: key,
                existing: this.hotkeys[normalizedKey],
                new: {function: function, description: description}
            }
            this.conflicts.Push(conflict)
            
            LogWarn("HotkeyValidator", 
                Format("Hotkey conflict detected: {} already assigned to {}", 
                    key, this.hotkeys[normalizedKey].description))
        } else {
            this.hotkeys[normalizedKey] := {
                originalKey: key,
                function: function,
                description: description
            }
        }
    }
    
    ; --- キーを正規化（大文字小文字、修飾キーの順序を統一） ---
    static NormalizeKey(key) {
        ; 修飾キーを分離
        modifiers := []
        baseKey := key
        
        ; 修飾キーをチェック
        if (InStr(key, "^")) {
            modifiers.Push("Ctrl")
            baseKey := StrReplace(baseKey, "^", "")
        }
        if (InStr(key, "!")) {
            modifiers.Push("Alt")
            baseKey := StrReplace(baseKey, "!", "")
        }
        if (InStr(key, "+")) {
            modifiers.Push("Shift")
            baseKey := StrReplace(baseKey, "+", "")
        }
        if (InStr(key, "#")) {
            modifiers.Push("Win")
            baseKey := StrReplace(baseKey, "#", "")
        }
        
        ; 修飾キーをソート
        if (modifiers.Length > 0) {
            ; カスタムソート実装
            sortedModifiers := this.SortModifiers(modifiers)
            normalizedKey := ""
            for mod in sortedModifiers {
                normalizedKey .= mod . "+"
            }
            normalizedKey .= StrUpper(baseKey)
        } else {
            normalizedKey := StrUpper(baseKey)
        }
        
        return normalizedKey
    }
    
    ; --- 修飾キーをソート ---
    static SortModifiers(modifiers) {
        ; 修飾キーの優先順位
        order := Map("Ctrl", 1, "Alt", 2, "Shift", 3, "Win", 4)
        
        ; バブルソート
        n := modifiers.Length
        Loop n - 1 {
            Loop n - A_Index {
                if (order[modifiers[A_Index]] > order[modifiers[A_Index + 1]]) {
                    temp := modifiers[A_Index]
                    modifiers[A_Index] := modifiers[A_Index + 1]
                    modifiers[A_Index + 1] := temp
                }
            }
        }
        
        return modifiers
    }
    
    ; --- 設定からホットキーを自動登録 ---
    static RegisterFromConfig() {
        ; メインホットキー
        this.Register("F12", "ToggleMacro", "マクロ切り替え")
        this.Register("^F12", "EmergencyStop", "緊急停止")
        this.Register("+F12", "RestartMacro", "マクロ再起動")
        this.Register("!F12", "ReloadConfig", "設定リロード")
        this.Register("Pause", "PauseMacro", "一時停止")
        this.Register("ScrollLock", "ToggleStatus", "ステータス表示")
        
        ; デバッグホットキー
        this.Register("F11", "ShowManaDebug", "マナデバッグ")
        this.Register("F10", "ToggleLoadingDetection", "ロード画面検出")
        this.Register("F9", "ToggleWaitMode", "待機モード切り替え")
        this.Register("F8", "ShowTimerDebug", "タイマーデバッグ")
        this.Register("F7", "ShowFullDebug", "完全デバッグ")
        this.Register("F6", "ShowLogViewer", "ログビューア")
        
        this.Register("^d", "ToggleDebugMode", "デバッグモード")
        this.Register("^l", "ToggleLogging", "ログ記録")
        this.Register("^t", "TestOverlay", "テストオーバーレイ")
        this.Register("^m", "ManualManaCheck", "手動マナチェック")
        this.Register("^s", "ShowCoordinates", "座標表示")
        this.Register("^r", "ResetMacroState", "状態リセット")
        this.Register("^p", "PerformanceTest", "パフォーマンステスト")
        
        ; グローバルホットキー
        this.Register("^!F12", "RestartScript", "スクリプト再起動")
        this.Register("^!+F12", "ExitScript", "スクリプト終了")
    }
    
    ; --- 競合をチェック ---
    static CheckConflicts() {
        if (this.conflicts.Length > 0) {
            message := "以下のホットキーが重複しています:`n`n"
            
            for conflict in this.conflicts {
                message .= Format("キー: {}`n", conflict.key)
                message .= Format("  既存: {}`n", conflict.existing.description)
                message .= Format("  新規: {}`n`n", conflict.new.description)
            }
            
            message .= "設定を確認してください。"
            
            result := MsgBox(message, "ホットキー競合検出", "OKCancel Icon!")
            if (result == "Cancel") {
                ExitApp()
            }
            
            return false
        }
        
        return true
    }
    
    ; --- 登録されたホットキーを表示 ---
    static ShowRegistered() {
        info := "=== 登録済みホットキー ===`n`n"
        
        ; キーでソート
        sortedKeys := []
        for key, data in this.hotkeys {
            sortedKeys.Push(key)
        }
        
        ; 簡易ソート
        n := sortedKeys.Length
        Loop n - 1 {
            Loop n - A_Index {
                if (sortedKeys[A_Index] > sortedKeys[A_Index + 1]) {
                    temp := sortedKeys[A_Index]
                    sortedKeys[A_Index] := sortedKeys[A_Index + 1]
                    sortedKeys[A_Index + 1] := temp
                }
            }
        }
        
        for key in sortedKeys {
            data := this.hotkeys[key]
            info .= Format("{}: {}`n", data.originalKey, data.description)
        }
        
        ShowMultiLineOverlay(StrSplit(info, "`n"), 5000)
    }
}