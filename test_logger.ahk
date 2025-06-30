#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "Utils/Logger.ahk"

; Logger単体テスト
try {
    MsgBox("Logger included successfully!")
} catch as e {
    MsgBox("Logger include failed: " . e.Message)
}