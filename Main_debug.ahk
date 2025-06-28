; ===================================================================
; AutoHotkey v2 起動診断スクリプト
; main.ahk実行問題の診断用
; ===================================================================

#Requires AutoHotkey v2.0
FileAppend(A_Now . " - Starting`n", "debug.log")
MsgBox("Test", "Debug")
ExitApp()