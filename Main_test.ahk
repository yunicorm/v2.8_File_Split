#Requires AutoHotkey v2.0
#SingleInstance Force

; === 段階的テスト ===

; Step 1: Logger only
#Include "Utils/Logger.ahk"

try {
    MsgBox("Step 1: Logger included successfully!")
} catch as e {
    MsgBox("Step 1 failed: " . e.Message)
    ExitApp()
}