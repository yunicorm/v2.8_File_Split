﻿#Requires AutoHotkey v2.0

; ===================================================================
; 設定ファイル管理システム（修正版）
; INIファイルの読み込み、検証、バックアップ機能付き
; ===================================================================

class ConfigManager {
    static configFile := A_ScriptDir . "\Config.ini"
    static backupDir := A_ScriptDir . "\backups"
    static config := Map()
    static isLoaded := false
    static isDirty := false
    static currentProfile := "default"
    static validationRules := Map()
    
    ; --- 初期化 ---
    static __New() {
        ; バックアップディレクトリを作成
        if (!DirExist(this.backupDir)) {
            try {
                DirCreate(this.backupDir)
            } catch {
                ; エラーは無視
            }
        }
        
        ; 検証ルールを設定
        this.InitializeValidationRules()
    }
    
    ; --- 検証ルールの初期化 ---
    static InitializeValidationRules() {
        ; 解像度設定
        this.validationRules["Resolution"] := Map(
            "ScreenWidth", Map("min", 800, "max", 7680, "type", "integer"),
            "ScreenHeight", Map("min", 600, "max", 4320, "type", "integer")
        )
        
        ; マナ設定
        this.validationRules["Mana"] := Map(
            "CenterX", Map("min", 0, "max", 7680, "type", "integer"),
            "CenterY", Map("min", 0, "max", 4320, "type", "integer"),
            "Radius", Map("min", 10, "max", 500, "type", "integer"),
            "BlueThreshold", Map("min", 0, "max", 255, "type", "integer"),
            "BlueDominance", Map("min", 0, "max", 255, "type", "integer"),
            "MonitorInterval", Map("min", 10, "max", 1000, "type", "integer"),
            "OptimizedDetection", Map("type", "boolean")
        )
        
        ; Tincture設定
        this.validationRules["Tincture"] := Map(
            "RetryMax", Map("min", 1, "max", 10, "type", "integer"),
            "RetryInterval", Map("min", 100, "max", 5000, "type", "integer"),
            "VerifyDelay", Map("min", 100, "max", 5000, "type", "integer"),
            "DepletedCooldown", Map("min", 1000, "max", 10000, "type", "integer")
        )
        
        ; タイミング設定
        this.validationRules["Timing"] := Map(
            "SkillER_Min", Map("min", 100, "max", 10000, "type", "integer"),
            "SkillER_Max", Map("min", 100, "max", 10000, "type", "integer"),
            "SkillT_Min", Map("min", 100, "max", 20000, "type", "integer"),
            "SkillT_Max", Map("min", 100, "max", 20000, "type", "integer"),
            "Flask_Min", Map("min", 100, "max", 20000, "type", "integer"),
            "Flask_Max", Map("min", 100, "max", 20000, "type", "integer")
        )
        
        ; 一般設定
        this.validationRules["General"] := Map(
            "DebugMode", Map("type", "boolean"),
            "LogEnabled", Map("type", "boolean"),
            "MaxLogSize", Map("min", 1, "max", 100, "type", "integer"),
            "LogRetentionDays", Map("min", 1, "max", 365, "type", "integer"),
            "AutoStart", Map("type", "boolean"),
            "AutoStartDelay", Map("min", 0, "max", 30000, "type", "integer")
        )
    }
    
    ; --- 設定を読み込み ---
    static Load(profileName := "default") {
        this.currentProfile := profileName
        configPath := this.GetProfilePath(profileName)
        
        ; プロファイルファイルが存在しない場合はデフォルトを使用
        if (!FileExist(configPath) && profileName != "default") {
            OutputDebug("ConfigManager: " . Format("Profile '{}' not found, using default", profileName))
            configPath := this.configFile
        }
        
        if (!FileExist(configPath)) {
            this.CreateDefaultConfig(configPath)
        }
        
        ; バックアップを作成
        this.CreateBackup(configPath)
        
        try {
            ; 各セクションを読み込み
            sections := ["General", "Resolution", "Mana", "Tincture", "Keys", 
                        "Timing", "Wine", "LoadingScreen", "ClientLog", "UI", "Performance", "Flask", "Skill", "VisualDetection"]
            
            for section in sections {
                this.config[section] := Map()
                
                ; セクション内のすべてのキーを取得
                try {
                    sectionContent := IniRead(configPath, section)
                    
                    ; 各行を解析
                    Loop Parse, sectionContent, "`n", "`r" {
                        if (A_LoopField == "") {
                            continue
                        }
                        
                        ; キーと値を分離
                        parts := StrSplit(A_LoopField, "=", , 2)
                        if (parts.Length == 2) {
                            key := Trim(parts[1])
                            value := Trim(parts[2])
                            
                            ; 値の型を推測して変換
                            parsedValue := this.ParseValue(value)
                            
                            ; 検証
                            if (this.ValidateValue(section, key, parsedValue)) {
                                this.config[section][key] := parsedValue
                            } else {
                                OutputDebug("ConfigManager WARNING: " . Format("Invalid value for {}.{}: {}", 
                                    section, key, value))
                            }
                        }
                    }
                } catch as e {
                    OutputDebug("ConfigManager ERROR: " . Format("Failed to read section {}: {}", 
                        section, e.Message))
                }
            }
            
            this.isLoaded := true
            this.isDirty := false
            
            ; 設定の検証と修正
            this.ValidateConfig()
            
            OutputDebug("ConfigManager: " . Format("Configuration loaded successfully (Profile: {})", 
                this.currentProfile))
            return true
            
        } catch as e {
            OutputDebug("ConfigManager ERROR: " . "Failed to load config: " . e.Message)
            return false
        }
    }
    
    ; --- プロファイルパスを取得 ---
    static GetProfilePath(profileName) {
        if (profileName == "default") {
            return this.configFile
        }
        return A_ScriptDir . "\Config_" . profileName . ".ini"
    }
    
    ; --- 値の型変換 ---
    static ParseValue(value) {
        ; 空文字列
        if (value == "") {
            return ""
        }
        
        ; ブール値
        valueLower := StrLower(value)
        if (valueLower == "true" || valueLower == "1" || valueLower == "yes" || valueLower == "on") {
            return true
        }
        if (valueLower == "false" || valueLower == "0" || valueLower == "no" || valueLower == "off") {
            return false
        }
        
        ; 数値（整数）
        if (RegExMatch(value, "^-?\d+$")) {
            return Integer(value)
        }
        
        ; 数値（小数）
        if (RegExMatch(value, "^-?\d+\.\d+$")) {
            return Float(value)
        }
        
        ; 文字列
        return value
    }
    
    ; --- 値の検証 ---
    static ValidateValue(section, key, value) {
        if (Type(this.validationRules) == "Map") {
            if (!this.validationRules.Has(section)) {
                return true  ; ルールがない場合は許可
            }
        } else {
            return true  ; ルールがない場合は許可
        }
        
        sectionRules := this.validationRules[section]
        if (Type(sectionRules) == "Map") {
            if (!sectionRules.Has(key)) {
                return true  ; ルールがない場合は許可
            }
        } else if (Type(sectionRules) == "Object") {
            if (!sectionRules.HasOwnProp(key)) {
                return true  ; ルールがない場合は許可
            }
        } else {
            return true  ; ルールがない場合は許可
        }
        
        rule := sectionRules[key]
        
        ; 型チェック
        ruleType := ""
        if (Type(rule) == "Map" && rule.Has("type")) {
            ruleType := rule["type"]
        } else if (Type(rule) == "Object" && rule.HasOwnProp("type")) {
            ruleType := rule.type
        }
        
        if (ruleType != "") {
            switch ruleType {
                case "boolean":
                    if (Type(value) != "Integer" && Type(value) != "String") {
                        return false
                    }
                case "integer":
                    if (Type(value) != "Integer" && !RegExMatch(String(value), "^\d+$")) {
                        return false
                    }
                case "string":
                    ; 文字列は常に有効
            }
        }
        
        ; 範囲チェック（数値のみ）
        if (IsNumber(value)) {
            numValue := Number(value)
            if (Type(rule) == "Map") {
                if (rule.Has("min") && numValue < rule["min"]) {
                    return false
                }
                if (rule.Has("max") && numValue > rule["max"]) {
                    return false
                }
            } else if (Type(rule) == "Object") {
                if (rule.HasOwnProp("min") && numValue < rule.min) {
                    return false
                }
                if (rule.HasOwnProp("max") && numValue > rule.max) {
                    return false
                }
            }
        }
        
        return true
    }
    
    ; --- 設定値を取得 ---
    static Get(section, key, defaultValue := "") {
        if (!this.isLoaded) {
            this.Load()
        }
        
        if (this.config.Has(section)) {
            if (Type(this.config[section]) == "Map") {
                if (this.config[section].Has(key)) {
                    return this.config[section][key]
                }
            } else if (HasMethod(this.config[section], "HasOwnProp")) {
                if (this.config[section].HasOwnProp(key)) {
                    return this.config[section].%key%
                }
            }
        }
        
        return defaultValue
    }
    
    ; --- 設定値を更新 ---
    static Set(section, key, value) {
        if (!this.config.Has(section)) {
            this.config[section] := Map()
        }
        
        ; セクションがMapでない場合は強制的にMapに変換
        if (Type(this.config[section]) != "Map") {
            this.config[section] := Map()
        }
        
        ; 値を検証
        if (!this.ValidateValue(section, key, value)) {
            OutputDebug("ConfigManager WARNING: " . Format("Invalid value for {}.{}: {}", section, key, value))
            return false
        }
        
        ; 値が変更されたかチェック
        oldValue := ""
        if (Type(this.config[section]) == "Map") {
            oldValue := this.config[section].Has(key) ? this.config[section][key] : ""
        } else if (HasMethod(this.config[section], "HasOwnProp")) {
            oldValue := this.config[section].HasOwnProp(key) ? this.config[section].%key% : ""
        }
        if (oldValue != value) {
            this.config[section][key] := value
            this.isDirty := true
            
            ; 自動保存（オプション）
            if (this.Get("General", "AutoSaveConfig", false)) {
                this.Save()
            }
        }
        
        return true
    }
    
    ; --- 設定を保存 ---
    static Save(profileName := "") {
        if (profileName == "") {
            profileName := this.currentProfile
        }
        
        configPath := this.GetProfilePath(profileName)
        
        try {
            ; INIファイルに書き込み
            for section, sectionData in this.config {
                for key, value in sectionData {
                    ; ブール値を文字列に変換
                    if (Type(value) == "Integer" && (value == 0 || value == 1)) {
                        isBoolean := false
                        if (Type(this.validationRules) == "Map" && this.validationRules.Has(section)) {
                            sectionRules := this.validationRules[section]
                            if (Type(sectionRules) == "Map" && sectionRules.Has(key)) {
                                rule := sectionRules[key]
                                if (Type(rule) == "Map" && rule.Has("type") && rule["type"] == "boolean") {
                                    isBoolean := true
                                } else if (Type(rule) == "Object" && rule.HasOwnProp("type") && rule.type == "boolean") {
                                    isBoolean := true
                                }
                            }
                        }
                        if (isBoolean) {
                            value := value ? "true" : "false"
                        }
                    }
                    
                    IniWrite(String(value), configPath, section, key)
                }
            }
            
            this.isDirty := false
            OutputDebug("ConfigManager: " . Format("Configuration saved (Profile: {})", profileName))
            return true
            
        } catch as e {
            OutputDebug("ConfigManager ERROR: " . "Failed to save config: " . e.Message)
            return false
        }
    }
    
    ; --- バックアップを作成 ---
    static CreateBackup(configPath := "") {
        if (configPath == "") {
            configPath := this.GetProfilePath(this.currentProfile)
        }
        
        if (!FileExist(configPath)) {
            return false
        }
        
        try {
            ; バックアップファイル名を生成
            timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
            backupFile := this.backupDir . "\Config_backup_" . timestamp . ".ini"
            
            ; ファイルをコピー
            FileCopy(configPath, backupFile, 0)
            
            ; 古いバックアップを削除
            this.CleanupOldBackups()
            
            OutputDebug("ConfigManager: " . "Backup created: " . backupFile)
            return true
            
        } catch as e {
            OutputDebug("ConfigManager ERROR: " . "Failed to create backup: " . e.Message)
            return false
        }
    }
    
    ; --- 古いバックアップを削除 ---
    static CleanupOldBackups(daysToKeep := 7) {
        try {
            cutoffTime := A_Now
            cutoffTime := DateAdd(cutoffTime, -daysToKeep, "Days")
            
            Loop Files, this.backupDir . "\Config_backup_*.ini" {
    fileTime := FileGetTime(A_LoopFilePath, "C")
                if (fileTime < cutoffTime) {
                    try {
                        FileDelete(A_LoopFilePath)
                        OutputDebug("ConfigManager: " . "Deleted old backup: " . A_LoopFileName)
                    } catch {
                        ; 削除失敗は無視
                    }
                }
            }
        } catch as e {
            OutputDebug("ConfigManager ERROR: " . "Backup cleanup failed: " . e.Message)
        }
    }
    
    ; --- 設定の検証と修正 ---
    static ValidateConfig() {
        modified := false
        
        ; 解像度の検証
        screenWidth := this.Get("Resolution", "ScreenWidth", 3440)
        screenHeight := this.Get("Resolution", "ScreenHeight", 1440)
        
        if (screenWidth < 800 || screenWidth > 7680) {
            this.Set("Resolution", "ScreenWidth", 3440)
            modified := true
        }
        if (screenHeight < 600 || screenHeight > 4320) {
            this.Set("Resolution", "ScreenHeight", 1440)
            modified := true
        }
        
        ; タイミング設定の検証（Min <= Max）
        timingPairs := [
            ["SkillER_Min", "SkillER_Max", 1000, 1100],
            ["SkillT_Min", "SkillT_Max", 4100, 4200],
            ["Flask_Min", "Flask_Max", 4500, 4800]
        ]
        
        for pair in timingPairs {
            minVal := this.Get("Timing", pair[1], pair[3])
            maxVal := this.Get("Timing", pair[2], pair[4])
            
            if (minVal > maxVal) {
                this.Set("Timing", pair[1], pair[3])
                this.Set("Timing", pair[2], pair[4])
                modified := true
                OutputDebug("ConfigManager WARNING: " . Format("Fixed timing values for {}/{}", pair[1], pair[2]))
            }
        }
        
        ; Wine設定の段階的チェック
        wineStages := ["Stage1", "Stage2", "Stage3", "Stage4", "Stage5"]
        prevTime := 0
        
        for i, stage in wineStages {
            if (i < 5) {  ; Stage5にはTimeがない
                stageTime := this.Get("Wine", stage . "_Time", 60000 * i)
                if (stageTime <= prevTime) {
                    this.Set("Wine", stage . "_Time", prevTime + 30000)
                    modified := true
                }
                prevTime := stageTime
            }
        }
        
        if (modified) {
            this.Save()
            OutputDebug("ConfigManager: " . "Configuration validated and corrected")
        }
    }
    
    ; --- デフォルト設定ファイルを作成 ---
    static CreateDefaultConfig(configPath := "") {
        if (configPath == "") {
            configPath := this.configFile
        }
        
        defaultConfig := "
(
; Path of Exile Macro Configuration File
; 解像度: 3440x1440 用のデフォルト設定

[General]
; デバッグモード (true/false)
DebugMode=false
; ログ記録 (true/false)
LogEnabled=true
; ログファイル最大サイズ (MB)
MaxLogSize=10
; ログ保持日数
LogRetentionDays=7
; マクロ自動開始 (true/false)
AutoStart=false
; 自動開始遅延 (ms)
AutoStartDelay=2000
; 設定自動保存
AutoSaveConfig=true

[Resolution]
; 画面解像度
ScreenWidth=3440
ScreenHeight=1440

[Mana]
; マナオーブ中心座標
CenterX=3294
CenterY=1300
; マナオーブ半径
Radius=139
; 青色検出閾値
BlueThreshold=40
; 青色優位性
BlueDominance=20
; 監視間隔 (ms)
MonitorInterval=100
; 最適化モード (true/false)
OptimizedDetection=true

[Tincture]
; 最大再試行回数
RetryMax=5
; 再試行間隔 (ms)
RetryInterval=500
; 効果確認待機時間 (ms)
VerifyDelay=1000
; マナ枯渇時クールダウン (ms)
DepletedCooldown=5410

[Keys]
; キー設定
Tincture=3
ManaFlask=2
SkillE=E
SkillR=R
SkillT=T
WineProphet=4

[Timing]
; スキルタイミング (ms)
SkillER_Min=1000
SkillER_Max=1100
SkillT_Min=4100
SkillT_Max=4200
Flask_Min=4500
Flask_Max=4800

[Wine]
; Wine of the Prophet 動的タイミング (ms)
Stage1_Time=60000
Stage1_Min=22000
Stage1_Max=22500
Stage2_Time=90000
Stage2_Min=19500
Stage2_Max=20000
Stage3_Time=120000
Stage3_Min=17500
Stage3_Max=18000
Stage4_Time=170000
Stage4_Min=16000
Stage4_Max=16500
Stage5_Min=14500
Stage5_Max=15000

[LoadingScreen]
; ロード画面検出（ピクセル方式）
Enabled=false
; 検出間隔 (ms)
CheckInterval=250
; GGGロゴY座標オフセット
GearAreaOffset=200
; 暗色閾値
DarkThreshold=50

[ClientLog]
; Client.txtログ監視（新方式）
Enabled=true
; ログファイルパス
Path=C:\Program Files (x86)\Steam\steamapps\common\Path of Exile\logs\Client.txt
; 監視間隔 (ms)
CheckInterval=250
; 非戦闘エリアでの自動再開
RestartInTown=false

[UI]
; ステータス表示位置
StatusWidth=220
StatusHeight=150
StatusOffsetY=250
; オーバーレイ設定
OverlayFontSize=28
OverlayDuration=2000
OverlayTransparency=220

[Performance]
; パフォーマンス設定
; マナ検出サンプルレート
ManaSampleRate=5
; 色検出タイムアウト (ms)
ColorDetectTimeout=50
; パフォーマンス監視
MonitoringEnabled=false
)"
        
        try {
            FileAppend(defaultConfig, configPath)
            OutputDebug("ConfigManager: " . "Default configuration file created")
            return true
        } catch as e {
            OutputDebug("ConfigManager ERROR: " . "Failed to create default config: " . e.Message)
            return false
        }
    }
    
    ; --- 設定をリロード ---
    static Reload() {
        this.isLoaded := false
        return this.Load(this.currentProfile)
    }
    
    ; --- 現在の解像度に合わせて座標をスケーリング ---
    static ScaleCoordinate(value, isX := true) {
        baseWidth := 3440
        baseHeight := 1440
        
        currentWidth := this.Get("Resolution", "ScreenWidth", baseWidth)
        currentHeight := this.Get("Resolution", "ScreenHeight", baseHeight)
        
        if (isX) {
            return Round(value * currentWidth / baseWidth)
        } else {
            return Round(value * currentHeight / baseHeight)
        }
    }
    
    ; --- プロファイルのリストを取得 ---
    static GetProfiles() {
        profiles := ["default"]
        
        try {
            Loop Files, A_ScriptDir . "\Config_*.ini" {
                ; ファイル名からプロファイル名を抽出
                if (RegExMatch(A_LoopFileName, "^Config_(.+)\.ini$", &match)) {
                    profiles.Push(match[1])
                }
            }
        } catch {
            ; エラーは無視
        }
        
        return profiles
    }
    
    ; --- プロファイルを切り替え ---
    static SwitchProfile(profileName) {
        ; 現在の設定を保存
        if (this.isDirty) {
            this.Save()
        }
        
        ; 新しいプロファイルを読み込み
        if (this.Load(profileName)) {
            this.currentProfile := profileName
            OutputDebug("ConfigManager: " . Format("Switched to profile: {}", profileName))
            return true
        }
        
        return false
    }
    
    ; --- 設定をエクスポート ---
    static Export(exportPath) {
        try {
            ; 現在の設定をエクスポート先にコピー
            configPath := this.GetProfilePath(this.currentProfile)
            FileCopy(configPath, exportPath, 1)
            OutputDebug("ConfigManager: " . Format("Configuration exported to: {}", exportPath))
            return true
        } catch as e {
            OutputDebug("ConfigManager ERROR: " . "Failed to export config: " . e.Message)
            return false
        }
    }
    
    ; --- 設定をインポート ---
    static Import(importPath) {
        if (!FileExist(importPath)) {
            OutputDebug("ConfigManager ERROR: " . "Import file not found: " . importPath)
            return false
        }
        
        try {
            ; バックアップを作成
            this.CreateBackup()
            
            ; インポートファイルを現在のプロファイルにコピー
            configPath := this.GetProfilePath(this.currentProfile)
            FileCopy(importPath, configPath, 1)
            
            ; 設定をリロード
            if (this.Reload()) {
                OutputDebug("ConfigManager: " . Format("Configuration imported from: {}", importPath))
                return true
            }
            
            return false
        } catch as e {
            OutputDebug("ConfigManager ERROR: " . "Failed to import config: " . e.Message)
            return false
        }
    }
}