#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

; === インクルード順序が重要 ===
#Include "Config.ahk"
#Include "Utils\ColorDetection.ahk"
#Include "Utils\Coordinates.ahk"
#Include "Core\WindowManager.ahk"
#Include "Core\TimerManager.ahk"
#Include "UI\Overlay.ahk"
#Include "UI\StatusDisplay.ahk"
#Include "UI\DebugDisplay.ahk"
#Include "Features\ManaMonitor.ahk"
#Include "Features\TinctureManager.ahk"
#Include "Features\FlaskManager.ahk"
#Include "Features\SkillAutomation.ahk"
#Include "Features\LoadingScreen.ahk"
#Include "Core\MacroController.ahk"
#Include "Hotkeys\MainHotkeys.ahk"
#Include "Hotkeys\DebugHotkeys.ahk"

; === 初期化 ===
InitializeMacro()

; === メイン初期化関数 ===
InitializeMacro() {
    ; 座標モードの設定
    CoordMode("Mouse", "Screen")
    CoordMode("ToolTip", "Screen")
    CoordMode("Pixel", "Screen")
    
    ; ウィンドウグループの設定
    GroupAdd("TargetWindows", "ahk_exe streaming_client.exe")
    GroupAdd("TargetWindows", "ahk_exe PathOfExileSteam.exe")
    
    ; UI初期化
    CreateStatusOverlay()
    
    ; 終了時のクリーンアップ
    OnExit(ExitFunc)
}

; === 終了処理 ===
ExitFunc(*) {
    StopAllTimers()
    CleanupUI()
}