#Requires AutoHotkey v2.0

 ===================================================================
; 設定ファイル管理システム
; INIファイルの読み込みと設定値の管理
; ===================================================================

class ConfigManager {
    static configFile := A_ScriptDir . "\Config.ini"
    static config := Map()
    static isLoaded := false
    
    ; --- 設定を読み込み ---
    static Load() {
        if (!FileExist(this.configFile)) {
            this.CreateDefaultConfig()
        }
        
        try {
            ; 各セクションを読み込み
            sections := ["General", "Resolution", "Mana", "Tincture", "Keys", 
                        "Timing", "Wine", "LoadingScreen", "UI", "Performance"]
            
            for section in sections {
                this.config[section] := Map()
                
                ; セクション内のすべてのキーを取得
                sectionContent := IniRead(this.configFile, section)
                
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
                        this.config[section][key] := this.ParseValue(value)
                    }
                }
            }
            
            this.isLoaded := true
            LogInfo("ConfigManager", "Configuration loaded successfully")
            return true
            
        } catch Error as e {
            LogError("ConfigManager", "Failed to load config: " . e.Message)
            return false
        }
    }
    
    ; --- 値の型変換 ---
    static ParseValue(value) {
        ; ブール値
        if (value = "true" || value = "false") {
            return value = "true"
        }
        
        ; 数値
        if (IsNumber(value)) {
            return Number(value)
        }
        
        ; 文字列
        return value
    }
    
    ; --- 設定値を取得 ---
    static Get(section, key, defaultValue := "") {
        if (!this.isLoaded) {
            this.Load()
        }
        
        if (this.config.Has(section) && this.config[section].Has(key)) {
            return this.config[section][key]
        }
        
        return defaultValue
    }
    
    ; --- 設定値を更新 ---
    static Set(section, key, value) {
        if (!this.config.Has(section)) {
            this.config[section] := Map()
        }
        
        this.config[section][key] := value
        
        ; INIファイルに書き込み
        try {
            IniWrite(value, this.configFile, section, key)
            return true
        } catch {
            return false
        }
    }
    
    ; --- デフォルト設定ファイルを作成 ---
    static CreateDefaultConfig() {
        defaultConfig := "
(
; Path of Exile Macro Configuration File
; 解像度: 3440x1440 用のデフォルト設定

[General]
DebugMode=false
LogEnabled=true
MaxLogSize=10
LogRetentionDays=7

[Resolution]
ScreenWidth=3440
ScreenHeight=1440

[Mana]
CenterX=3294
CenterY=1300
Radius=139
BlueThreshold=40
BlueDominance=20
MonitorInterval=100
OptimizedDetection=true

[Tincture]
RetryMax=5
RetryInterval=500
VerifyDelay=1000
DepletedCooldown=5410

[Keys]
Tincture=3
ManaFlask=2
SkillE=E
SkillR=R
SkillT=T
WineProphet=4

[Timing]
SkillER_Min=1000
SkillER_Max=1100
SkillT_Min=4100
SkillT_Max=4200
Flask_Min=4500
Flask_Max=4800

[Wine]
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
Enabled=true
CheckInterval=250
GearAreaOffset=200
DarkThreshold=50

[UI]
StatusWidth=220
StatusHeight=150
StatusOffsetY=250
OverlayFontSize=28
OverlayDuration=2000
OverlayTransparency=220

[Performance]
ManaSampleRate=5
ColorDetectTimeout=50
)"
        
        try {
            FileAppend(defaultConfig, this.configFile)
            LogInfo("ConfigManager", "Default configuration file created")
        } catch Error as e {
            LogError("ConfigManager", "Failed to create default config: " . e.Message)
        }
    }
    
    ; --- 設定をリロード ---
    static Reload() {
        this.isLoaded := false
        return this.Load()
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
}