; ===================================================================
; Logger.ahk修正検証スクリプト
; g_log_enabled変数定義エラーの修正確認
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; === Logger.ahkインクルードテスト ===
try {
    FileAppend(A_Now . " - Testing Logger.ahk include`n", "logger_verification.log")
    
    #Include "Utils/Logger.ahk"
    
    FileAppend("Logger.ahk included successfully`n", "logger_verification.log")
    
    ; g_log_enabled変数の確認
    if (IsSet(g_log_enabled)) {
        FileAppend("g_log_enabled variable is defined: " . g_log_enabled . "`n", "logger_verification.log")
        MsgBox("✅ SUCCESS: g_log_enabled variable is properly defined`nValue: " . g_log_enabled, "Logger Fix Verification")
    } else {
        FileAppend("g_log_enabled variable is NOT defined`n", "logger_verification.log")
        MsgBox("❌ FAILED: g_log_enabled variable is still not defined", "Logger Fix Verification - ERROR")
    }
    
    ; Logger関数のテスト
    LogInfo("VerificationTest", "Testing Logger functionality after fix")
    FileAppend("Logger function test completed`n", "logger_verification.log")
    
    MsgBox("Logger.ahk fix verification completed successfully!`nCheck logger_verification.log for details.", "Verification Complete")
    
} catch as e {
    FileAppend(A_Now . " - ERROR: " . e.Message . "`n", "logger_verification.log")
    MsgBox("Logger.ahk fix verification FAILED:`n" . e.Message, "Verification Error")
}

ExitApp()